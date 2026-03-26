import Foundation

/// Manages downloading CoreML models to ~/Library/Application Support/MeetingTranscriber/Models/.
/// Downloads are idempotent — interrupted downloads resume on next attempt.
@MainActor
final class ModelDownloadManager: ObservableObject {

    struct ModelInfo {
        let kind: ModelKind
        let remoteURL: URL
        /// Relative path under the Models directory (e.g. "parakeet-tdt-0.6b-v2")
        let subdirectory: String
        /// The sentinel file that indicates a complete download
        let sentinelFileName: String
    }

    /// Known model definitions. URLs are placeholders until real hosting is set up.
    static let models: [ModelInfo] = [
        ModelInfo(
            kind: .batchParakeet,
            remoteURL: URL(string: "https://models.example.com/parakeet-tdt-0.6b-v2.mlpackage.zip")!,
            subdirectory: "parakeet-tdt-0.6b-v2",
            sentinelFileName: "model.mlmodelc"
        ),
        ModelInfo(
            kind: .batchVad,
            remoteURL: URL(string: "https://models.example.com/silero-vad-v6.mlpackage.zip")!,
            subdirectory: "silero-vad-v6",
            sentinelFileName: "model.mlmodelc"
        ),
        ModelInfo(
            kind: .diarization,
            remoteURL: URL(string: "https://models.example.com/ls-eend-wespeaker.mlpackage.zip")!,
            subdirectory: "ls-eend",
            sentinelFileName: "model.mlmodelc"
        ),
    ]

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

    /// Check which models are already downloaded and update the catalog.
    func refreshStatuses() {
        for info in Self.models {
            if isDownloaded(info) {
                catalog.markReady(info.kind)
            }
        }
    }

    /// Returns true if the model's sentinel file exists on disk.
    func isDownloaded(_ info: ModelInfo) -> Bool {
        let sentinel = modelsDirectory
            .appendingPathComponent(info.subdirectory, isDirectory: true)
            .appendingPathComponent(info.sentinelFileName)
        return FileManager.default.fileExists(atPath: sentinel.path)
    }

    /// Returns true if all required models (VAD, Parakeet, diarization) are downloaded.
    var allModelsReady: Bool {
        Self.models.allSatisfy { isDownloaded($0) }
    }

    /// Download a specific model. No-op if already downloaded.
    func download(_ kind: ModelKind) {
        guard let info = Self.models.first(where: { $0.kind == kind }) else { return }
        guard !isDownloaded(info) else {
            catalog.markReady(kind)
            return
        }
        guard activeTasks[kind] == nil else { return }

        errors[kind] = nil
        catalog.markDownloading(kind)
        downloadProgress[kind] = 0

        activeTasks[kind] = Task { [weak self] in
            guard let self else { return }
            await self.performDownload(info)
            self.activeTasks[kind] = nil
        }
    }

    /// Download all required models.
    func downloadAllModels() {
        for info in Self.models {
            download(info.kind)
        }
    }

    /// Cancel an in-progress download.
    func cancel(_ kind: ModelKind) {
        activeTasks[kind]?.cancel()
        activeTasks[kind] = nil
        downloadProgress[kind] = nil
    }

    // MARK: - Download Logic

    private func performDownload(_ info: ModelInfo) async {
        let destDir = modelsDirectory.appendingPathComponent(info.subdirectory, isDirectory: true)

        do {
            try FileManager.default.createDirectory(at: destDir, withIntermediateDirectories: true)

            let tempFileURL = try await downloadFile(from: info.remoteURL, kind: info.kind)
            defer { try? FileManager.default.removeItem(at: tempFileURL) }

            // Extract the zip archive
            try await extractZip(at: tempFileURL, to: destDir)

            // Verify sentinel exists after extraction
            let sentinel = destDir.appendingPathComponent(info.sentinelFileName)
            guard FileManager.default.fileExists(atPath: sentinel.path) else {
                throw DownloadError.missingSentinel(info.sentinelFileName)
            }

            downloadProgress[info.kind] = 1.0
            catalog.markReady(info.kind)
        } catch is CancellationError {
            downloadProgress[info.kind] = nil
        } catch {
            errors[info.kind] = error.localizedDescription
            downloadProgress[info.kind] = nil
            NSLog("MeetingTranscriber: Model download failed for \(info.kind): \(error)")
        }
    }

    private func downloadFile(from url: URL, kind: ModelKind) async throws -> URL {
        let (tempURL, response) = try await URLSession.shared.download(from: url, delegate: DownloadProgressDelegate { [weak self] progress in
            Task { @MainActor [weak self] in
                self?.downloadProgress[kind] = progress
            }
        })

        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
            throw DownloadError.httpError(httpResponse.statusCode)
        }

        return tempURL
    }

    private func extractZip(at zipURL: URL, to destDir: URL) async throws {
        try await Task.detached {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/ditto")
            process.arguments = ["-xk", zipURL.path, destDir.path]
            try process.run()
            process.waitUntilExit()
            guard process.terminationStatus == 0 else {
                throw DownloadError.extractionFailed
            }
        }.value
    }
}

// MARK: - Download Progress Delegate

private final class DownloadProgressDelegate: NSObject, URLSessionTaskDelegate {
    private let onProgress: @Sendable (Double) -> Void

    init(onProgress: @escaping @Sendable (Double) -> Void) {
        self.onProgress = onProgress
    }

    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didSendBodyData bytesSent: Int64,
        totalBytesSent: Int64,
        totalBytesExpectedToSend: Int64
    ) {
        // This is for uploads, not downloads — but keeping for protocol conformance
    }

    func urlSession(
        _ session: URLSession,
        didCreateTask task: URLSessionTask
    ) {
        // Observe progress via KVO on the task
        let handler = onProgress
        Task.detached {
            var lastReported = 0.0
            while !task.progress.isFinished && !task.progress.isCancelled {
                try? await Task.sleep(for: .milliseconds(200))
                let fraction = task.progress.fractionCompleted
                if fraction - lastReported > 0.01 {
                    lastReported = fraction
                    handler(fraction)
                }
            }
        }
    }
}

// MARK: - Download Errors

enum DownloadError: LocalizedError {
    case httpError(Int)
    case extractionFailed
    case missingSentinel(String)

    var errorDescription: String? {
        switch self {
        case .httpError(let code): return "Download failed with HTTP \(code)"
        case .extractionFailed: return "Failed to extract model archive"
        case .missingSentinel(let name): return "Model archive missing expected file: \(name)"
        }
    }
}
