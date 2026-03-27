import SwiftUI

// MARK: - Theme

private enum LurkTheme {
    static let accent = Color.indigo
    static let cardBackground = Color(.windowBackgroundColor).opacity(0.5)
    static let cardBorder = Color.primary.opacity(0.06)
    static let sectionSpacing: CGFloat = 12
    static let cornerRadius: CGFloat = 10
}

// MARK: - Menu Bar Dropdown

public struct MenuBarView: View {
    @ObservedObject public var model: AppModel
    @Environment(\.openWindow) private var openWindow

    public init(model: AppModel) { self.model = model }

    public var body: some View {
        VStack(spacing: 0) {
            statusHeader
                .padding(.horizontal, 14)
                .padding(.top, 12)
                .padding(.bottom, 8)

            Divider().padding(.horizontal, 10)

            actionsSection
                .padding(.horizontal, 6)
                .padding(.vertical, 4)

            Divider().padding(.horizontal, 10)

            bottomBar
                .padding(.horizontal, 6)
                .padding(.vertical, 4)
        }
        .frame(width: 260)
    }

    // MARK: Status Header

    private var statusHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                statusIcon
                VStack(alignment: .leading, spacing: 2) {
                    Text(model.phase.title)
                        .font(.system(.headline, design: .rounded))
                    statusSubtitle
                }
                Spacer()
            }

            if let errorMessage = model.errorMessage {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                        .font(.caption)
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .lineLimit(2)
                    Spacer()
                    Button("Dismiss") { model.acknowledgeError() }
                        .buttonStyle(.plain)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(LurkTheme.accent)
                }
                .padding(8)
                .background(.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
            }
        }
    }

    @ViewBuilder
    private var statusIcon: some View {
        switch model.phase {
        case .recording:
            ZStack {
                Circle()
                    .fill(.red.opacity(0.15))
                    .frame(width: 32, height: 32)
                PulsingDot(size: 10)
            }
        case .processing:
            ZStack {
                Circle()
                    .fill(.orange.opacity(0.15))
                    .frame(width: 32, height: 32)
                Image(systemName: "waveform")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.orange)
            }
        case .error:
            ZStack {
                Circle()
                    .fill(.red.opacity(0.15))
                    .frame(width: 32, height: 32)
                Image(systemName: "exclamationmark.circle.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(.red)
            }
        case .userAction:
            ZStack {
                Circle()
                    .fill(.yellow.opacity(0.15))
                    .frame(width: 32, height: 32)
                Image(systemName: "person.crop.circle.badge.questionmark")
                    .font(.system(size: 14))
                    .foregroundStyle(.yellow)
            }
        case .dormant:
            ZStack {
                Circle()
                    .fill(.green.opacity(0.12))
                    .frame(width: 32, height: 32)
                Circle()
                    .fill(.green)
                    .frame(width: 8, height: 8)
            }
        }
    }

    @ViewBuilder
    private var statusSubtitle: some View {
        if let session = model.recordingManager.activeSession {
            HStack(spacing: 4) {
                Text(session.title.isEmpty ? "Meeting" : session.title)
                    .lineLimit(1)
                Text("·")
                RecordingTimerView(startTime: session.startTime)
                    .monospacedDigit()
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        } else if let job = model.queueStore.activeJob, job.stage != .complete && job.stage != .failed {
            HStack(spacing: 4) {
                Text(job.meetingTitle)
                    .lineLimit(1)
                Text("·")
                Text(job.stage.displayName)
                    .foregroundStyle(.orange)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        } else {
            Text(model.meetingDetector.isWatching ? "Listening for Teams meetings" : "Idle — not watching")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
    }

    // MARK: Actions

    private var actionsSection: some View {
        VStack(spacing: 2) {
            MenuBarButton(
                title: model.meetingDetector.isWatching ? "Stop Watching" : "Start Watching",
                icon: model.meetingDetector.isWatching ? "pause.circle" : "play.circle",
                tint: model.meetingDetector.isWatching ? .orange : .green
            ) {
                model.toggleWatching()
            }

            if model.settingsStore.settings.developerMode {
                if model.recordingManager.activeSession == nil {
                    MenuBarButton(title: "Simulate Meeting", icon: "bolt.circle", tint: .purple) {
                        model.simulateMeeting()
                    }
                } else {
                    MenuBarButton(title: "End Simulation", icon: "stop.circle", tint: .red) {
                        model.endSimulatedMeeting()
                    }
                }
            }

            if !model.namingCandidates.isEmpty {
                MenuBarButton(title: "Name Speakers…", icon: "person.badge.plus", tint: .yellow) {
                    model.selectedSettingsTab = .speakers
                    openWindow(id: "settings")
                    NSApp.activate(ignoringOtherApps: true)
                }
            }

            MenuBarButton(title: "Open Transcripts", icon: "folder", tint: .blue) {
                model.openOutputDirectory()
            }
        }
    }

    // MARK: Bottom Bar

    private var bottomBar: some View {
        HStack(spacing: 2) {
            MenuBarButton(title: "Settings", icon: "gearshape", tint: .secondary) {
                openWindow(id: "settings")
                NSApp.activate(ignoringOtherApps: true)
            }
            Spacer()
            MenuBarButton(title: "Quit", icon: "power", tint: .secondary) {
                NSApplication.shared.terminate(nil)
            }
        }
    }
}

// MARK: - Menu Bar Button

private struct MenuBarButton: View {
    let title: String
    let icon: String
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 13))
                    .foregroundStyle(tint)
                    .frame(width: 20)
                Text(title)
                    .font(.system(.body, design: .default))
                Spacer()
            }
            .contentShape(Rectangle())
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
        }
        .buttonStyle(MenuBarButtonStyle())
    }
}

private struct MenuBarButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                configuration.isPressed
                    ? Color.primary.opacity(0.08)
                    : Color.clear,
                in: RoundedRectangle(cornerRadius: 6)
            )
    }
}

// MARK: - Job Row

private struct JobRow: View {
    let job: PipelineJob
    @ObservedObject var model: AppModel

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: job.stage == .complete ? "checkmark.circle.fill" : job.stage == .failed ? "xmark.circle.fill" : "clock.fill")
                .font(.caption)
                .foregroundStyle(job.stage == .complete ? .green : job.stage == .failed ? .red : .orange)

            Text(job.meetingTitle)
                .font(.caption)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            if job.transcriptPath != nil {
                Button { model.openTranscript(job) } label: {
                    Image(systemName: "doc.text")
                        .font(.caption2)
                        .foregroundStyle(LurkTheme.accent)
                }
                .buttonStyle(.plain)
                .help("Open transcript")
            }

            if job.stage == .failed {
                Button { model.retry(job) } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }
                .buttonStyle(.plain)
                .help("Retry")
            }

            Button { model.dismissJob(job) } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
            .buttonStyle(.plain)
            .help("Remove")
        }
        .padding(.vertical, 3)
    }
}

// MARK: - Recording Timer

public struct RecordingTimerView: View {
    public let startTime: Date
    @State private var elapsed: TimeInterval = 0
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    public init(startTime: Date) { self.startTime = startTime }

    public var body: some View {
        Text(formatDuration(elapsed))
            .onReceive(timer) { _ in
                elapsed = Date().timeIntervalSince(startTime)
            }
            .onAppear {
                elapsed = Date().timeIntervalSince(startTime)
            }
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let total = Int(seconds)
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        }
        return String(format: "%02d:%02d", m, s)
    }
}

// MARK: - Pulsing Recording Dot

public struct PulsingDot: View {
    var size: CGFloat = 8
    @State private var isPulsing = false

    public init(size: CGFloat = 8) { self.size = size }

    public var body: some View {
        Circle()
            .fill(.red)
            .frame(width: size, height: size)
            .opacity(isPulsing ? 0.3 : 1.0)
            .animation(
                .easeInOut(duration: 0.4).repeatForever(autoreverses: true),
                value: isPulsing
            )
            .onAppear { isPulsing = true }
    }
}

// MARK: - Settings Window

public struct SettingsView: View {
    @ObservedObject public var model: AppModel

    public init(model: AppModel) { self.model = model }

    public var body: some View {
        TabView(selection: $model.selectedSettingsTab) {
            generalTab
                .tabItem { Label("General", systemImage: "gearshape") }
                .tag(SettingsTab.general)

            transcriptionTab
                .tabItem { Label("Transcription", systemImage: "waveform") }
                .tag(SettingsTab.transcription)

            dictationTab
                .tabItem { Label("Dictation", systemImage: "mic.badge.plus") }
                .tag(SettingsTab.dictation)

            speakersTab
                .tabItem { Label("Speakers", systemImage: "person.3") }
                .tag(SettingsTab.speakers)

            permissionsTab
                .tabItem { Label("Permissions", systemImage: "lock.shield") }
                .tag(SettingsTab.permissions)

            aboutTab
                .tabItem { Label("About", systemImage: "info.circle") }
                .tag(SettingsTab.about)
        }
        .padding(20)
    }

    // MARK: General Tab

    private var generalTab: some View {
        Form {
            TextField("Your Name", text: settingsBinding(\.userName))
                .help("Used as the local speaker label in transcripts")

            Toggle("Launch at Login", isOn: Binding(
                get: { model.settingsStore.settings.launchAtLogin },
                set: { model.setLaunchAtLogin($0) }
            ))

            Toggle("Auto-Watch on Launch", isOn: settingsBinding(\.autoWatch))

            Toggle("Developer Mode", isOn: settingsBinding(\.developerMode))
                .help("Shows simulate meeting buttons in the menu bar for testing")

            VStack(alignment: .leading, spacing: 8) {
                Text("Output Folder")
                    .font(.headline)

                HStack {
                    Text(model.settingsStore.settings.outputDirectory)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(6)
                        .background(.quaternary, in: RoundedRectangle(cornerRadius: 6))

                    Button("Choose…") { model.chooseOutputDirectory() }
                    Button("Reset") { model.chooseDefaultOutputDirectory() }
                    Button("Open") { model.openOutputDirectory() }
                }
            }
        }
        .formStyle(.grouped)
    }

    // MARK: Transcription Tab

    private var transcriptionTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Custom Vocabulary
                VStack(alignment: .leading, spacing: 10) {
                    Label("Custom Vocabulary", systemImage: "textformat.abc")
                        .font(.headline)

                    HStack {
                        TextField("Add a term (min 3 chars)", text: $model.vocabularyDraft)
                            .textFieldStyle(.roundedBorder)
                            .onSubmit { model.addVocabularyTerm() }
                        Button("Add") { model.addVocabularyTerm() }
                            .disabled(model.vocabularyDraft.trimmingCharacters(in: .whitespacesAndNewlines).count < 3)
                    }

                    if model.settingsStore.settings.customVocabulary.isEmpty {
                        Text("No custom terms. Add domain-specific words to improve recognition.")
                            .foregroundStyle(.tertiary)
                            .font(.caption)
                    } else {
                        FlowLayout(model.settingsStore.settings.customVocabulary, id: \.self) { term in
                            HStack(spacing: 5) {
                                Text(term)
                                    .font(.callout)
                                Button {
                                    model.removeVocabularyTerm(term)
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(LurkTheme.accent.opacity(0.1), in: Capsule())
                        }
                    }

                    Text("\(model.settingsStore.settings.customVocabulary.count)/50 terms")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }

                Divider()

                // Model Status
                VStack(alignment: .leading, spacing: 12) {
                    Label("Model Status", systemImage: "cpu")
                        .font(.headline)

                    ForEach(model.modelCatalog.statuses) { item in
                        ModelStatusCard(item: item, downloadManager: model.downloadManager)
                    }

                    if !model.downloadManager.allModelsReady {
                        Button {
                            model.downloadManager.downloadAllModels()
                        } label: {
                            HStack {
                                Image(systemName: "arrow.down.circle.fill")
                                Text("Download All Models")
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(LurkTheme.accent)

                        Text("Models download automatically on first meeting, but you can pre-download here.")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            .padding(4)
        }
    }

    // MARK: Dictation Tab

    private var dictationTab: some View {
        VStack(spacing: 16) {
            Image(systemName: "mic.badge.plus")
                .font(.system(size: 48))
                .foregroundStyle(LurkTheme.accent.opacity(0.3))
            Text("Coming in v2")
                .font(.title3.weight(.semibold))
            Text("Live dictation with streaming transcription.\nThe mic publisher and model catalog are ready for this.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .font(.callout)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: Speakers Tab

    private var speakersTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            if !model.namingCandidates.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Label("New speakers detected — name them:", systemImage: "person.badge.plus")
                        .font(.headline)
                        .foregroundStyle(.orange)
                    ForEach(model.namingCandidates) { candidate in
                        NamingCandidateRow(candidate: candidate) { name in
                            model.saveSpeakerName(candidate: candidate, name: name)
                        }
                    }
                }
                .padding(12)
                .background(.orange.opacity(0.06), in: RoundedRectangle(cornerRadius: LurkTheme.cornerRadius))
                Divider()
            }

            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.tertiary)
                    TextField("Search speakers", text: $model.speakerFilter)
                        .textFieldStyle(.plain)
                }
                .padding(6)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 6))

                Picker("Sort", selection: $model.speakerSortMode) {
                    ForEach(SpeakerSortMode.allCases) { sortMode in
                        Text(sortMode.displayName).tag(sortMode)
                    }
                }
                .pickerStyle(.segmented)

                Button("Merge Selected") {
                    model.mergeSelectedSpeakers()
                }
                .disabled(model.mergeSelection.count != 2)
            }

            Table(model.filteredSpeakers, selection: $model.mergeSelection) {
                TableColumn("Name") { speaker in
                    InlineEditableText(value: speaker.name) { newValue in
                        model.speakerStore.rename(id: speaker.id, to: newValue)
                    }
                }
                TableColumn("Meetings") { speaker in
                    Text("\(speaker.meetingCount)")
                        .monospacedDigit()
                }
                TableColumn("First Seen") { speaker in
                    Text(speaker.firstSeen.formatted(date: .abbreviated, time: .omitted))
                }
                TableColumn("Last Seen") { speaker in
                    Text(speaker.lastSeen.formatted(date: .abbreviated, time: .omitted))
                }
            }
            .contextMenu(forSelectionType: UUID.self) { ids in
                if ids.count == 1, let id = ids.first {
                    Button("Delete Speaker", role: .destructive) {
                        model.speakerStore.delete(id: id)
                    }
                }
            }
        }
    }

    // MARK: Permissions Tab

    private var permissionsTab: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(model.permissionCenter.statuses) { permission in
                PermissionCard(permission: permission, model: model)
            }
            Spacer()
        }
        .padding(4)
    }

    // MARK: About Tab

    private var aboutTab: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 16) {
                // App icon placeholder
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                colors: [LurkTheme.accent, LurkTheme.accent.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)
                    Image(systemName: "waveform.and.mic")
                        .font(.system(size: 36, weight: .medium))
                        .foregroundStyle(.white)
                }

                VStack(spacing: 4) {
                    Text("Lurk")
                        .font(.system(.title, design: .rounded).weight(.bold))
                    Text("Version 0.1.0")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }

                Text("Automatic meeting detection, dual-track recording,\non-device transcription and speaker diarization.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .font(.callout)

                HStack(spacing: 16) {
                    AboutBadge(icon: "lock.shield.fill", text: "On-Device")
                    AboutBadge(icon: "icloud.slash.fill", text: "No Cloud")
                    AboutBadge(icon: "brain.head.profile.fill", text: "No LLM")
                }

                Text("Powered by FluidAudio · Parakeet TDT · Silero VAD · WeSpeaker")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            Divider()

            Text("Direct Download Distribution")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Helpers

    private func settingsBinding<Value>(_ keyPath: WritableKeyPath<AppSettings, Value>) -> Binding<Value> {
        Binding(
            get: { model.settingsStore.settings[keyPath: keyPath] },
            set: { model.settingsStore.settings[keyPath: keyPath] = $0 }
        )
    }
}

// MARK: - Model Status Card

private struct ModelStatusCard: View {
    let item: ModelStatusItem
    @ObservedObject var downloadManager: ModelDownloadManager

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: statusIcon)
                .font(.system(size: 16))
                .foregroundStyle(statusColor)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.modelKind.displayName)
                    .font(.callout.weight(.medium))

                if let progress = downloadManager.downloadProgress[item.modelKind] {
                    ProgressView(value: progress)
                        .tint(LurkTheme.accent)
                    Text("\(Int(progress * 100))%")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                } else if let error = downloadManager.errors[item.modelKind] {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .lineLimit(1)
                } else {
                    Text(item.detail)
                        .font(.caption)
                        .foregroundStyle(item.availability == .ready ? .green : .secondary)
                }
            }

            Spacer()
        }
        .padding(10)
        .background(Color.primary.opacity(0.03), in: RoundedRectangle(cornerRadius: 8))
    }

    private var statusIcon: String {
        if downloadManager.downloadProgress[item.modelKind] != nil { return "arrow.down.circle" }
        if downloadManager.errors[item.modelKind] != nil { return "exclamationmark.triangle" }
        switch item.availability {
        case .ready: return "checkmark.circle.fill"
        case .downloading: return "arrow.down.circle"
        case .notDownloaded: return "arrow.down.to.line"
        }
    }

    private var statusColor: Color {
        if downloadManager.downloadProgress[item.modelKind] != nil { return LurkTheme.accent }
        if downloadManager.errors[item.modelKind] != nil { return .red }
        switch item.availability {
        case .ready: return .green
        case .downloading: return LurkTheme.accent
        case .notDownloaded: return .secondary
        }
    }
}

// MARK: - Permission Card

private struct PermissionCard: View {
    let permission: PermissionStatus
    @ObservedObject var model: AppModel

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(iconColor.opacity(0.12))
                    .frame(width: 36, height: 36)
                Image(systemName: iconName)
                    .font(.system(size: 16))
                    .foregroundStyle(iconColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(permission.title)
                        .font(.callout.weight(.medium))
                    if permission.id == "microphone" {
                        Text("Required")
                            .font(.system(size: 9, weight: .semibold))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(.red.opacity(0.12), in: Capsule())
                            .foregroundStyle(.red)
                    }
                }
                Text(permission.purpose)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(permission.state.badge)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(permission.state == .granted ? .green : .orange)

                if permission.state != .granted {
                    Button("Grant…") {
                        switch permission.id {
                        case "microphone": model.permissionCenter.requestMicrophone()
                        case "screen": model.permissionCenter.openScreenRecordingSettings()
                        case "accessibility": model.permissionCenter.openAccessibilitySettings()
                        default: break
                        }
                    }
                    .font(.caption)
                    .buttonStyle(.borderedProminent)
                    .tint(LurkTheme.accent)
                    .controlSize(.small)
                }
            }
        }
        .padding(12)
        .background(Color.primary.opacity(0.03), in: RoundedRectangle(cornerRadius: LurkTheme.cornerRadius))
    }

    private var iconName: String {
        switch permission.id {
        case "microphone": return "mic.fill"
        case "screen": return "rectangle.inset.filled.and.person.filled"
        case "accessibility": return "figure.stand"
        default: return "lock.fill"
        }
    }

    private var iconColor: Color {
        permission.state == .granted ? .green : LurkTheme.accent
    }
}

// MARK: - About Badge

private struct AboutBadge: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
            Text(text)
                .font(.caption)
        }
        .foregroundStyle(.secondary)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Color.primary.opacity(0.04), in: Capsule())
    }
}

// MARK: - Reusable Components

struct InlineEditableText: View {
    let value: String
    let onCommit: (String) -> Void

    @State private var draft = ""
    @State private var isEditing = false

    var body: some View {
        if isEditing {
            TextField("Name", text: $draft, onCommit: commit)
                .textFieldStyle(.roundedBorder)
        } else {
            Text(value)
                .onTapGesture {
                    draft = value
                    isEditing = true
                }
        }
    }

    private func commit() {
        isEditing = false
        guard !draft.isEmpty else { return }
        onCommit(draft)
    }
}

struct NamingCandidateRow: View {
    let candidate: NamingCandidate
    let onSave: (String) -> Void

    @State private var draft = ""

    var body: some View {
        HStack {
            Text(candidate.temporaryName)
                .font(.callout.weight(.medium))
                .frame(width: 140, alignment: .leading)
            TextField("Enter speaker name", text: $draft)
                .textFieldStyle(.roundedBorder)
                .onSubmit { save() }
            Button("Save") { save() }
                .buttonStyle(.borderedProminent)
                .tint(LurkTheme.accent)
                .controlSize(.small)
                .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }

    private func save() {
        guard !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        onSave(draft)
    }
}

struct FlowLayout<Data: RandomAccessCollection, ID: Hashable, Content: View>: View {
    private let data: [Data.Element]
    private let id: KeyPath<Data.Element, ID>
    private let content: (Data.Element) -> Content

    init(_ data: Data, id: KeyPath<Data.Element, ID>, @ViewBuilder content: @escaping (Data.Element) -> Content) {
        self.data = Array(data)
        self.id = id
        self.content = content
    }

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), alignment: .leading)], alignment: .leading, spacing: 8) {
            ForEach(data, id: id, content: content)
        }
    }
}
