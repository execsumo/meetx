import AppKit
import AudioToolbox
import AVFAudio
import AVFoundation
import Combine
import CoreAudio
import CoreGraphics
import Foundation
import IOKit.pwr_mgt
import ServiceManagement

// MARK: - Data Types

struct MeetingSnapshot {
    var title: String
    var startedAt: Date
    var teamsPID: pid_t?
}

struct RecordingSession {
    let title: String
    let startTime: Date
    let appAudioPath: URL
    let micAudioPath: URL
    var micDelaySeconds: TimeInterval
}

// MARK: - Meeting Detection

@MainActor
final class MeetingDetector {
    private(set) var isWatching = false
    private let onMeetingStarted: @MainActor (MeetingSnapshot) -> Void
    private let onMeetingEnded: @MainActor (MeetingSnapshot) -> Void
    private var activeSnapshot: MeetingSnapshot?
    private var pollingTask: Task<Void, Never>?
    private var consecutiveDetections = 0
    private var cooldownUntil: Date?

    private static let teamsProcessNames: Set<String> = [
        "Microsoft Teams",
        "Microsoft Teams (work or school)",
        "Microsoft Teams classic",
    ]

    init(
        onMeetingStarted: @escaping @MainActor (MeetingSnapshot) -> Void,
        onMeetingEnded: @escaping @MainActor (MeetingSnapshot) -> Void
    ) {
        self.onMeetingStarted = onMeetingStarted
        self.onMeetingEnded = onMeetingEnded
    }

    func startWatching() {
        isWatching = true
        startPolling()
    }

    func stopWatching() {
        isWatching = false
        pollingTask?.cancel()
        pollingTask = nil
        consecutiveDetections = 0
    }

    private func startPolling() {
        pollingTask?.cancel()
        pollingTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(3))
                guard let self, !Task.isCancelled else { break }
                self.poll()
            }
        }
    }

    private func poll() {
        if let cooldown = cooldownUntil, Date() < cooldown { return }
        cooldownUntil = nil

        let result = Self.detectTeamsMeeting()

        if result.detected {
            consecutiveDetections += 1
            if consecutiveDetections >= 2, activeSnapshot == nil {
                let title = Self.extractTeamsWindowTitle() ?? ""
                let snapshot = MeetingSnapshot(
                    title: title,
                    startedAt: Date(),
                    teamsPID: result.pid
                )
                activeSnapshot = snapshot
                onMeetingStarted(snapshot)
            }
        } else {
            consecutiveDetections = 0
            if let snapshot = activeSnapshot {
                activeSnapshot = nil
                cooldownUntil = Date().addingTimeInterval(5)
                onMeetingEnded(snapshot)
            }
        }
    }

    /// Poll IOPMCopyAssertionsByProcess for Teams holding a PreventUserIdleDisplaySleep assertion.
    private static func detectTeamsMeeting() -> (detected: Bool, pid: pid_t?) {
        let runningApps = NSWorkspace.shared.runningApplications
        let teamsApps = runningApps.filter { app in
            guard let name = app.localizedName else { return false }
            return teamsProcessNames.contains(name)
        }
        guard !teamsApps.isEmpty else { return (false, nil) }

        var assertionsByPid: Unmanaged<CFDictionary>?
        guard IOPMCopyAssertionsByProcess(&assertionsByPid) == kIOReturnSuccess,
              let dict = assertionsByPid?.takeRetainedValue() as NSDictionary?
        else {
            return (false, nil)
        }

        for app in teamsApps {
            let pid = app.processIdentifier
            guard let assertions = dict[NSNumber(value: pid)] as? [[String: Any]] else { continue }
            for assertion in assertions {
                if let type = assertion["AssertionType"] as? String,
                   type == "PreventUserIdleDisplaySleep"
                {
                    return (true, pid)
                }
            }
        }
        return (false, nil)
    }

    /// Extract the meeting title from the Teams window via CGWindowListCopyWindowInfo.
    /// Requires Screen Recording permission; returns nil if unavailable.
    private static func extractTeamsWindowTitle() -> String? {
        guard let windowList = CGWindowListCopyWindowInfo(
            [.optionOnScreenOnly, .excludeDesktopElements],
            kCGNullWindowID
        ) as? [[String: Any]] else {
            return nil
        }

        for window in windowList {
            guard let ownerName = window[kCGWindowOwnerName as String] as? String,
                  teamsProcessNames.contains(ownerName),
                  let title = window[kCGWindowName as String] as? String,
                  title.contains(" | Microsoft Teams")
            else { continue }
            let cleaned = title.replacingOccurrences(of: #"\s*\|\s*Microsoft Teams.*$"#, with: "", options: .regularExpression)
            return cleaned.isEmpty ? nil : cleaned
        }
        return nil
    }

    // MARK: - Simulation (development only)

    func simulateMeetingStart(title: String) {
        let snapshot = MeetingSnapshot(title: title, startedAt: Date(), teamsPID: nil)
        activeSnapshot = snapshot
        onMeetingStarted(snapshot)
    }

    func simulateMeetingEnd() {
        guard let snapshot = activeSnapshot else { return }
        activeSnapshot = nil
        onMeetingEnded(snapshot)
    }
}

// MARK: - Audio Recording

@MainActor
final class RecordingManager: ObservableObject {
    @Published private(set) var activeSession: RecordingSession?

    private var micEngine: AVAudioEngine?
    private var appEngine: AVAudioEngine?
    private var micAudioFile: AVAudioFile?
    private var appAudioFile: AVAudioFile?
    private var tapObjectID: AudioObjectID = 0
    private var maxDurationTask: Task<Void, Never>?
    private var micStartTime: Date?
    private var appStartTime: Date?

    /// AsyncStream publisher for mic buffers — v2 dictation will subscribe to this.
    private var micBufferContinuation: AsyncStream<AVAudioPCMBuffer>.Continuation?
    private(set) var micBufferStream: AsyncStream<AVAudioPCMBuffer>?

    func startRecording(title: String, teamsPID: pid_t?) throws {
        guard activeSession == nil else { return }

        let stamp = Formatting.recordingFileFormatter.string(from: Date())
        let base = FileManager.default.meetingTranscriberAppSupportDirectory
            .appendingPathComponent("recordings", isDirectory: true)
        try FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)

        let appPath = base.appendingPathComponent("\(stamp)_app.wav")
        let micPath = base.appendingPathComponent("\(stamp)_mic.wav")

        // Set up mic recording first
        try setupMicRecording(to: micPath)

        // Set up app audio recording if we have a Teams PID
        if let pid = teamsPID {
            do {
                try setupAppAudioRecording(pid: pid, to: appPath)
            } catch {
                // App audio is best-effort — continue with mic-only if tap fails
                NSLog("MeetingTranscriber: App audio tap failed: \(error.localizedDescription)")
            }
        }

        let micDelay: TimeInterval
        if let mic = micStartTime, let app = appStartTime {
            micDelay = mic.timeIntervalSince(app)
        } else {
            micDelay = 0
        }

        activeSession = RecordingSession(
            title: title,
            startTime: Date(),
            appAudioPath: appPath,
            micAudioPath: micPath,
            micDelaySeconds: micDelay
        )

        // 4-hour max recording duration
        maxDurationTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(4 * 3600))
            guard let self, !Task.isCancelled else { return }
            self.handleMaxDurationReached()
        }
    }

    func stopRecording() -> RecordingSession? {
        maxDurationTask?.cancel()
        maxDurationTask = nil

        teardownMicRecording()
        teardownAppAudioRecording()

        micBufferContinuation?.finish()
        micBufferContinuation = nil
        micBufferStream = nil
        micStartTime = nil
        appStartTime = nil

        defer { activeSession = nil }
        return activeSession
    }

    // MARK: - Mic Recording (AVAudioEngine)

    private func setupMicRecording(to url: URL) throws {
        let engine = AVAudioEngine()
        let inputNode = engine.inputNode
        let hwFormat = inputNode.outputFormat(forBus: 0)

        // Create the output file at the hardware format (will be resampled to 16kHz in pipeline)
        let fileSettings: [String: Any] = [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVSampleRateKey: hwFormat.sampleRate,
            AVNumberOfChannelsKey: 1,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsBigEndianKey: false,
        ]
        let file = try AVAudioFile(forWriting: url, settings: fileSettings)
        micAudioFile = file

        // Set up AsyncStream for v2 dictation
        let (stream, continuation) = AsyncStream<AVAudioPCMBuffer>.makeStream()
        micBufferStream = stream
        micBufferContinuation = continuation

        // Mono conversion format matching the file
        let monoFormat = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: hwFormat.sampleRate,
            channels: 1,
            interleaved: false
        )

        inputNode.installTap(onBus: 0, bufferSize: 4096, format: monoFormat) {
            [weak self] buffer, _ in
            try? file.write(from: buffer)
            self?.micBufferContinuation?.yield(buffer)
        }

        engine.prepare()
        try engine.start()
        micEngine = engine
        micStartTime = Date()
    }

    private func teardownMicRecording() {
        micEngine?.inputNode.removeTap(onBus: 0)
        micEngine?.stop()
        micEngine = nil
        micAudioFile = nil
    }

    // MARK: - App Audio Recording (CATapDescription + Process Tap)

    private func setupAppAudioRecording(pid: pid_t, to url: URL) throws {
        let tapDesc = CATapDescription(stereoMixdownOfProcesses: [AudioObjectID(pid)])
        tapDesc.name = "MeetingTranscriber"

        var objectID: AudioObjectID = 0
        let status = AudioHardwareCreateProcessTap(tapDesc, &objectID)
        guard status == noErr else {
            throw RecordingError.processTapFailed(status)
        }
        tapObjectID = objectID

        let engine = AVAudioEngine()
        let inputNode = engine.inputNode

        // Point the engine's input to the process tap device
        var deviceID = objectID
        let audioUnit = inputNode.audioUnit!
        let setErr = AudioUnitSetProperty(
            audioUnit,
            kAudioOutputUnitProperty_CurrentDevice,
            kAudioUnitScope_Global,
            0,
            &deviceID,
            UInt32(MemoryLayout<AudioObjectID>.size)
        )
        guard setErr == noErr else {
            AudioHardwareDestroyProcessTap(objectID)
            tapObjectID = 0
            throw RecordingError.deviceSetupFailed(setErr)
        }

        let hwFormat = inputNode.outputFormat(forBus: 0)
        let fileSettings: [String: Any] = [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVSampleRateKey: hwFormat.sampleRate,
            AVNumberOfChannelsKey: hwFormat.channelCount,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsBigEndianKey: false,
        ]
        let file = try AVAudioFile(forWriting: url, settings: fileSettings)
        appAudioFile = file

        inputNode.installTap(onBus: 0, bufferSize: 4096, format: hwFormat) { buffer, _ in
            try? file.write(from: buffer)
        }

        engine.prepare()
        try engine.start()
        appEngine = engine
        appStartTime = Date()
    }

    private func teardownAppAudioRecording() {
        appEngine?.inputNode.removeTap(onBus: 0)
        appEngine?.stop()
        appEngine = nil
        appAudioFile = nil

        if tapObjectID != 0 {
            AudioHardwareDestroyProcessTap(tapObjectID)
            tapObjectID = 0
        }
    }

    private func handleMaxDurationReached() {
        // TODO: enqueue current session and restart recording if meeting still active
        _ = stopRecording()
    }
}

enum RecordingError: LocalizedError {
    case processTapFailed(OSStatus)
    case deviceSetupFailed(OSStatus)

    var errorDescription: String? {
        switch self {
        case .processTapFailed(let code):
            return "Failed to create process audio tap (error \(code))"
        case .deviceSetupFailed(let code):
            return "Failed to configure tap audio device (error \(code))"
        }
    }
}

// MARK: - Model Catalog

@MainActor
final class ModelCatalog: ObservableObject {
    @Published private(set) var statuses: [ModelStatusItem] = ModelKind.allCases.map {
        let detail = $0 == .streamingPlaceholder ? "Reserved for v2 dictation" : "Download required"
        return ModelStatusItem(modelKind: $0, availability: .notDownloaded, detail: detail)
    }

    func markDownloading(_ kind: ModelKind) {
        update(kind, availability: .downloading, detail: "Downloading")
    }

    func markReady(_ kind: ModelKind) {
        update(kind, availability: .ready, detail: "Ready")
    }

    private func update(_ kind: ModelKind, availability: ModelAvailability, detail: String) {
        guard let index = statuses.firstIndex(where: { $0.modelKind == kind }) else { return }
        statuses[index] = ModelStatusItem(modelKind: kind, availability: availability, detail: detail)
    }
}

// MARK: - Permission Center

@MainActor
final class PermissionCenter: ObservableObject {
    @Published private(set) var statuses: [PermissionStatus] = []

    init() {
        refresh()
    }

    func refresh() {
        statuses = [
            PermissionStatus(
                id: "microphone",
                title: "Microphone",
                purpose: "Record your voice during meetings.",
                state: microphoneState()
            ),
            PermissionStatus(
                id: "screen",
                title: "Screen Recording",
                purpose: "Read Teams window title for meeting names.",
                state: screenRecordingState()
            ),
            PermissionStatus(
                id: "accessibility",
                title: "Accessibility",
                purpose: "Read Teams roster for automatic speaker naming.",
                state: accessibilityState()
            ),
        ]
    }

    func requestMicrophone() {
        AVCaptureDevice.requestAccess(for: .audio) { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }
    }

    func openScreenRecordingSettings() {
        CGRequestScreenCaptureAccess()
        openSystemSettings("x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture")
    }

    func openAccessibilitySettings() {
        openSystemSettings("x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")
    }

    private func microphoneState() -> PermissionState {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized: return .granted
        case .notDetermined: return .recommended
        default: return .unknown
        }
    }

    private func screenRecordingState() -> PermissionState {
        CGPreflightScreenCaptureAccess() ? .granted : .recommended
    }

    private func accessibilityState() -> PermissionState {
        AXIsProcessTrusted() ? .granted : .recommended
    }

    private func openSystemSettings(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        NSWorkspace.shared.open(url)
    }
}

// MARK: - Temp File Cleanup

enum TempFileCleanup {
    /// Delete recording WAVs older than 48 hours. Called on app launch.
    static func cleanStaleRecordings(activeJobPaths: Set<URL> = []) {
        let recordingsDir = FileManager.default.meetingTranscriberAppSupportDirectory
            .appendingPathComponent("recordings", isDirectory: true)
        let fm = FileManager.default

        guard let contents = try? fm.contentsOfDirectory(
            at: recordingsDir,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: [.skipsHiddenFiles]
        ) else { return }

        let cutoff = Date().addingTimeInterval(-48 * 3600)

        for fileURL in contents where fileURL.pathExtension == "wav" {
            // Don't delete files referenced by active pipeline jobs
            if activeJobPaths.contains(fileURL) { continue }

            guard let attrs = try? fm.attributesOfItem(atPath: fileURL.path),
                  let modified = attrs[.modificationDate] as? Date,
                  modified < cutoff
            else { continue }

            try? fm.removeItem(at: fileURL)
        }
    }
}

// MARK: - Launch at Login

enum LaunchAtLogin {
    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    static func setEnabled(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            NSLog("MeetingTranscriber: Launch at login toggle failed: \(error.localizedDescription)")
        }
    }
}

// MARK: - Transcript Writer

enum TranscriptWriter {
    static func write(document: TranscriptDocument, outputDirectory: URL) throws -> URL {
        try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)
        let prefix = Formatting.transcriptDatePrefixFormatter.string(from: document.startTime)
        let title = document.title.sanitizedFileName()
        var candidate = outputDirectory.appendingPathComponent("\(prefix)_\(title).md")
        var suffix = 2

        while FileManager.default.fileExists(atPath: candidate.path) {
            candidate = outputDirectory.appendingPathComponent("\(prefix)_\(title)_\(suffix).md")
            suffix += 1
        }

        let duration = document.endTime.timeIntervalSince(document.startTime)
        let header = """
        # \(document.title)

        **Date:** \(Formatting.transcriptDateFormatter.string(from: document.startTime)) – \(Formatting.transcriptDateFormatter.string(from: document.endTime).suffix(5))
        **Duration:** \(Int(duration) / 3600)h \((Int(duration) % 3600) / 60)m
        **Participants:** \(document.participants.joined(separator: ", "))

        ---

        """

        let body = document.segments.map { segment in
            "[\(segment.startTime.timestampString)] **\(segment.speaker):** \(segment.text)"
        }.joined(separator: "\n\n")

        try (header + body + "\n").write(to: candidate, atomically: true, encoding: .utf8)
        return candidate
    }
}

// MARK: - Pipeline Processor

/// Processes recorded meetings through: preprocessing → transcription → diarization → speaker assignment → output.
/// Jobs are processed sequentially (one at a time) to avoid ANE contention.
/// Failed stages retry up to 3 times with exponential backoff (5s, 30s, 5min).
@MainActor
final class PipelineProcessor: ObservableObject {
    @Published private(set) var isProcessing = false

    private let queueStore: PipelineQueueStore
    private let speakerStore: SpeakerStore
    private let settingsStore: SettingsStore
    private let modelCatalog: ModelCatalog
    private let onNamingRequired: @MainActor ([NamingCandidate]) -> Void

    /// In-memory preprocessed tracks for the current job (not persisted).
    private var appTrack: PreprocessedTrack?
    private var micTrack: PreprocessedTrack?

    /// Retry backoff intervals in seconds.
    private static let retryDelays: [TimeInterval] = [5, 30, 300]
    private static let maxRetries = 3

    init(
        queueStore: PipelineQueueStore,
        speakerStore: SpeakerStore,
        settingsStore: SettingsStore,
        modelCatalog: ModelCatalog,
        onNamingRequired: @escaping @MainActor ([NamingCandidate]) -> Void
    ) {
        self.queueStore = queueStore
        self.speakerStore = speakerStore
        self.settingsStore = settingsStore
        self.modelCatalog = modelCatalog
        self.onNamingRequired = onNamingRequired
    }

    func enqueueFinishedRecording(_ session: RecordingSession, endedAt: Date) {
        let job = PipelineJob(
            id: UUID(),
            meetingTitle: session.title,
            startTime: session.startTime,
            endTime: endedAt,
            appAudioPath: session.appAudioPath,
            micAudioPath: session.micAudioPath,
            transcriptPath: nil,
            stage: .queued,
            stageStartTime: nil,
            error: nil,
            retryCount: 0
        )
        queueStore.enqueue(job)
        runNextIfNeeded()
    }

    func retryFailedJob(_ job: PipelineJob) {
        var retry = job
        retry.stage = .queued
        retry.error = nil
        queueStore.update(retry)
        runNextIfNeeded()
    }

    func runNextIfNeeded() {
        guard !isProcessing else { return }
        guard let next = queueStore.jobs.first(where: { $0.stage == .queued }) else { return }
        isProcessing = true
        Task {
            await processWithRetry(next)
            await MainActor.run {
                self.isProcessing = false
                self.appTrack = nil
                self.micTrack = nil
                self.runNextIfNeeded()
            }
        }
    }

    // MARK: - Retry Logic

    private func processWithRetry(_ job: PipelineJob) async {
        var working = job
        for attempt in 0..<Self.maxRetries {
            do {
                try await process(&working)
                return // Success
            } catch is CancellationError {
                return
            } catch {
                working.error = error.localizedDescription
                working.retryCount = attempt + 1
                queueStore.update(working)

                if attempt < Self.maxRetries - 1 {
                    let delay = Self.retryDelays[min(attempt, Self.retryDelays.count - 1)]
                    NSLog("MeetingTranscriber: Pipeline stage \(working.stage.rawValue) failed (attempt \(attempt + 1)), retrying in \(Int(delay))s: \(error)")
                    try? await Task.sleep(for: .seconds(delay))
                } else {
                    NSLog("MeetingTranscriber: Pipeline exhausted retries for job \(working.id): \(error)")
                    working.stage = .failed
                    queueStore.update(working)
                }
            }
        }
    }

    // MARK: - Pipeline Stages

    private func process(_ job: inout PipelineJob) async throws {

        // Stage 1: Preprocessing — load WAV, downmix, resample to 16kHz, VAD trim
        if job.stage == .queued || job.stage == .preprocessing {
            try await advanceTo(&job, stage: .preprocessing)
            try await runPreprocessing(job)
        }

        // Stage 2: Transcription — run Parakeet TDT on both tracks
        if job.stage == .preprocessing || job.stage == .transcribing {
            try await advanceTo(&job, stage: .transcribing)
            try await runTranscription(job)
        }

        // Stage 3: Diarization — run LS-EEND + WeSpeaker on both tracks
        if job.stage == .transcribing || job.stage == .diarizing {
            try await advanceTo(&job, stage: .diarizing)
            try await runDiarization(job)
        }

        // Stage 4: Speaker Assignment — merge transcription + diarization
        if job.stage == .diarizing || job.stage == .assigning {
            try await advanceTo(&job, stage: .assigning)
            let transcript = try await runSpeakerAssignment(job)

            // Stage 5: Output
            let outputDirectory = URL(
                fileURLWithPath: settingsStore.settings.outputDirectory,
                isDirectory: true
            )
            let outputURL = try TranscriptWriter.write(
                document: transcript,
                outputDirectory: outputDirectory
            )
            job.transcriptPath = outputURL
            job.stage = .complete
            job.stageStartTime = nil
            job.error = nil
            queueStore.update(job)

            // Prompt for unmatched speakers
            let unmatched = transcript.participants.filter { $0.hasPrefix("Speaker ") }
            if !unmatched.isEmpty {
                onNamingRequired(unmatched.map {
                    NamingCandidate(id: UUID(), temporaryName: $0, suggestedName: nil)
                })
            }
        }
    }

    private func advanceTo(_ job: inout PipelineJob, stage: PipelineStage) async throws {
        job.stage = stage
        job.stageStartTime = Date()
        job.error = nil
        queueStore.update(job)
    }

    // MARK: - Stage 1: Preprocessing

    private func runPreprocessing(_ job: PipelineJob) async throws {
        // Preprocess app track (stereo → mono → 16kHz → VAD)
        let appExists = FileManager.default.fileExists(atPath: job.appAudioPath.path)
        if appExists {
            appTrack = try await Task.detached(priority: .userInitiated) {
                try await AudioPreprocessor.preprocess(wavURL: job.appAudioPath, isStereo: true)
            }.value
        }

        // Preprocess mic track (mono → 16kHz → VAD)
        let micExists = FileManager.default.fileExists(atPath: job.micAudioPath.path)
        if micExists {
            micTrack = try await Task.detached(priority: .userInitiated) {
                try await AudioPreprocessor.preprocess(wavURL: job.micAudioPath, isStereo: false)
            }.value
        }

        guard appTrack != nil || micTrack != nil else {
            throw PipelineError.noAudioFiles
        }
    }

    // MARK: - Stage 2: Transcription (CoreML seam)

    private func runTranscription(_ job: PipelineJob) async throws {
        // TODO: Load Parakeet TDT V2 CoreML model and transcribe both tracks.
        // For now, generate placeholder segments from the preprocessed audio duration.
        // When real model is integrated:
        //   1. Load model from ~/Library/Application Support/MeetingTranscriber/Models/parakeet-tdt-0.6b-v2/
        //   2. Run inference on appTrack.samples and micTrack.samples
        //   3. Remap timestamps through vadMap.toOriginalTime()
        //   4. Store results for speaker assignment stage

        // Placeholder: sleep briefly to simulate processing time
        try await Task.sleep(for: .milliseconds(100))
    }

    // MARK: - Stage 3: Diarization (CoreML seam)

    private func runDiarization(_ job: PipelineJob) async throws {
        // TODO: Load LS-EEND + WeSpeaker CoreML models and diarize both tracks.
        // When real models are integrated:
        //   1. Run LS-EEND on appTrack for speaker segmentation
        //   2. Run LS-EEND on micTrack (expect 1 speaker = local user)
        //   3. Extract WeSpeaker embeddings for each detected speaker
        //   4. Remap timestamps through vadMap.toOriginalTime()
        //   5. Prefix app speakers with R_, mic speakers with M_
        //   6. Merge into unified timeline

        try await Task.sleep(for: .milliseconds(100))
    }

    // MARK: - Stage 4: Speaker Assignment

    private func runSpeakerAssignment(_ job: PipelineJob) async throws -> TranscriptDocument {
        // TODO: Match transcription segments to diarization segments by temporal overlap.
        // When real pipeline is complete:
        //   1. For each transcript segment, find diarization segment with max overlap
        //   2. Assign speaker label from matched diarization segment
        //   3. Look up speaker in speaker database by embedding cosine distance
        //   4. Merge consecutive segments from same speaker
        //   5. Apply mic delay offset for alignment

        // Placeholder: generate sample transcript from preprocessed data
        let me = settingsStore.settings.userName.isEmpty ? "Me" : settingsStore.settings.userName
        let remote = speakerStore.speakers.first?.name ?? "Speaker 1"

        let appDuration = appTrack?.duration ?? 0
        let micDuration = micTrack?.duration ?? 0
        let totalDuration = max(appDuration, micDuration)

        // Generate segments spaced across the recording duration
        var segments: [TranscriptSegment] = []
        if totalDuration > 0 {
            let interval = max(totalDuration / 6, 5)
            var t: TimeInterval = 0
            var speakerToggle = true
            while t < totalDuration {
                let speaker = speakerToggle ? me : remote
                segments.append(TranscriptSegment(
                    speaker: speaker,
                    startTime: t,
                    endTime: min(t + interval, totalDuration),
                    text: "[Transcription pending — CoreML model integration required]"
                ))
                t += interval
                speakerToggle.toggle()
            }
        } else {
            // No audio was preprocessed — use static placeholder
            segments = [
                TranscriptSegment(speaker: me, startTime: 0, endTime: 4, text: "[No audio captured for this meeting]"),
            ]
        }

        return TranscriptDocument(
            title: job.meetingTitle.isEmpty ? "Meeting" : job.meetingTitle,
            startTime: job.startTime,
            endTime: job.endTime,
            participants: Array(Set(segments.map(\.speaker))).sorted(),
            segments: segments
        )
    }
}

enum PipelineError: LocalizedError {
    case noAudioFiles

    var errorDescription: String? {
        switch self {
        case .noAudioFiles: return "No audio files found for this recording"
        }
    }
}
