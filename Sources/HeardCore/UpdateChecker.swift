import Foundation

@MainActor
public final class UpdateChecker: ObservableObject {
    @Published public var availableVersion: String? = nil
    @Published public var releaseURL: URL? = nil
    @Published public var isChecking = false

    private static let lastCheckKey = "updateChecker.lastCheck"
    private static let checkInterval: TimeInterval = 24 * 60 * 60

    public let currentVersion: String

    public init() {
        currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.1.0"
    }

    public func checkIfNeeded() {
        let lastCheck = UserDefaults.standard.double(forKey: Self.lastCheckKey)
        let elapsed = Date().timeIntervalSince1970 - lastCheck
        guard elapsed >= Self.checkInterval else { return }
        Task { await check() }
    }

    public func check() async {
        guard !isChecking else { return }
        isChecking = true
        defer { isChecking = false }

        guard let url = URL(string: "https://api.github.com/repos/execsumo/Heard/releases/latest") else { return }
        var request = URLRequest(url: url)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")
        request.timeoutInterval = 10

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else { return }
            let release = try JSONDecoder().decode(GitHubRelease.self, from: data)
            UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: Self.lastCheckKey)

            let tag = release.tagName
            let latest = tag.hasPrefix("v") ? String(tag.dropFirst()) : tag
            if isNewer(latest, than: currentVersion) {
                availableVersion = latest
                releaseURL = URL(string: release.htmlURL)
            } else {
                availableVersion = nil
                releaseURL = nil
            }
        } catch {
            // Silent — network failure should not interrupt the user
        }
    }

    private func isNewer(_ candidate: String, than current: String) -> Bool {
        let parse: (String) -> [Int] = { v in v.split(separator: ".").compactMap { Int($0) } }
        let a = parse(candidate)
        let b = parse(current)
        for i in 0..<max(a.count, b.count) {
            let ai = i < a.count ? a[i] : 0
            let bi = i < b.count ? b[i] : 0
            if ai != bi { return ai > bi }
        }
        return false
    }
}

private struct GitHubRelease: Decodable {
    let tagName: String
    let htmlURL: String

    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case htmlURL = "html_url"
    }
}
