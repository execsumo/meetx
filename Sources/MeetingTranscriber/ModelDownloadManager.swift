import FluidAudio
import Foundation

/// Manages pre-downloading CoreML models so they're ready when a meeting ends.
/// FluidAudio auto-downloads models on first use, but pre-downloading avoids delays
/// after the first meeting.
@MainActor
final class ModelDownloadManager: ObservableObject {

    @Published private(set) var downloadProgress: [ModelKind: Double] = [:]
    @Published private(set) var errors: [ModelKind: String] = [:]

    private let modelsDirectory: URL
    private var activeTasks: [ModelKind: Task<Void, Never>] = [:]
    private let catalog: ModelCatalog

    init(catalog: ModelCatalog) {
        self.catalog = catalog
        self.modelsDirectory = FileManager.default.meetingTranscriberAppSupportDirectory
            .appendingPathComponent("Models", isDirectory: true)
        refreshStatuses()
    }

    /// Check which models are already cached.
    func refreshStatuses() {
        // Check if ASR models are downloaded by looking for the model directory
        let asrDir = modelsDirectory.appendingPathComponent("parakeet-tdt-v2", isDirectory: true)
        if FileManager.default.fileExists(atPath: asrDir.path) {
            catalog.markReady(.batchParakeet)
        }

        let vadDir = modelsDirectory.appendingPathComponent("silero-vad", isDirectory: true)
        if FileManager.default.fileExists(atPath: vadDir.path) {
            catalog.markReady(.batchVad)
        }

        let diarDir = modelsDirectory.appendingPathComponent("diarizer", isDirectory: true)
        if FileManager.default.fileExists(atPath: diarDir.path) {
            catalog.markReady(.diarization)
        }
    }

    var allModelsReady: Bool {
        let statuses = catalog.statuses
        return statuses.filter { $0.modelKind != .streamingPlaceholder }
            .allSatisfy { $0.availability == .ready }
    }

    /// Pre-download all models via FluidAudio's built-in download system.
    func downloadAllModels() {
        download(.batchVad)
        download(.batchParakeet)
        download(.diarization)
    }

    func download(_ kind: ModelKind) {
        guard activeTasks[kind] == nil else { return }
        errors[kind] = nil
        catalog.markDownloading(kind)
        downloadProgress[kind] = 0

        activeTasks[kind] = Task { [weak self] in
            guard let self else { return }
            do {
                switch kind {
                case .batchVad:
                    // VadManager auto-downloads on init
                    let _ = try await VadManager { [weak self] progress in
                        Task { @MainActor [weak self] in
                            self?.downloadProgress[.batchVad] = progress.fractionCompleted
                        }
                    }
                    catalog.markReady(.batchVad)

                case .batchParakeet:
                    // AsrModels.load auto-downloads
                    let _ = try await AsrModels.load(from: modelsDirectory, version: .v2) { [weak self] progress in
                        Task { @MainActor [weak self] in
                            self?.downloadProgress[.batchParakeet] = progress.fractionCompleted
                        }
                    }
                    catalog.markReady(.batchParakeet)

                case .diarization:
                    // OfflineDiarizerManager.prepareModels auto-downloads
                    let diarizer = OfflineDiarizerManager()
                    try await diarizer.prepareModels()
                    catalog.markReady(.diarization)

                case .streamingPlaceholder:
                    break
                }
                downloadProgress[kind] = 1.0
            } catch {
                errors[kind] = error.localizedDescription
                downloadProgress[kind] = nil
                NSLog("MeetingTranscriber: Model download failed for \(kind): \(error)")
            }
            activeTasks[kind] = nil
        }
    }

    func cancel(_ kind: ModelKind) {
        activeTasks[kind]?.cancel()
        activeTasks[kind] = nil
        downloadProgress[kind] = nil
    }
}
