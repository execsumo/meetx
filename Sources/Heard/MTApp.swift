import AppKit
import HeardCore
import SwiftUI

private struct MenuBarIcon: View {
    @ObservedObject var model: AppModel

    private static let templateImage: NSImage = {
        guard let url = Bundle.main.url(forResource: "MenuBarIconTemplate", withExtension: "svg"),
              let img = NSImage(contentsOf: url) else {
            return NSImage()
        }
        img.size = NSSize(width: 18, height: 18)
        img.isTemplate = true
        return img
    }()

    var body: some View {
        Image(nsImage: Self.templateImage)
            .renderingMode(.template)
            .foregroundStyle(iconTint)
            .opacity(iconOpacity)
            .overlay(alignment: .topTrailing) {
                badge
            }
    }

    /// Accent when actively capturing audio; primary otherwise.
    private var iconTint: AnyShapeStyle {
        (model.isDictating || model.phase == .recording)
            ? AnyShapeStyle(.tint)
            : AnyShapeStyle(.primary)
    }

    /// Dimmed when the app is idle and watching is off (paused); full otherwise.
    private var iconOpacity: Double {
        let paused = model.phase == .dormant
            && !model.isDictating
            && !model.meetingDetector.isWatching
        return paused ? 0.5 : 1.0
    }

    @ViewBuilder
    private var badge: some View {
        switch model.phase {
        case .error:
            Circle().fill(.red).frame(width: 5, height: 5)
                .offset(x: 1, y: -1)
        case .userAction:
            Circle().fill(.orange).frame(width: 5, height: 5)
                .offset(x: 1, y: -1)
        default:
            EmptyView()
        }
    }
}

@main
struct HeardApp: App {
    @StateObject private var appModel = AppModel.bootstrap()

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(model: appModel)
        } label: {
            MenuBarIcon(model: appModel)
        }
        .menuBarExtraStyle(.window)

        Window("Heard Settings", id: "settings") {
            SettingsView(model: appModel)
                .frame(minWidth: 760, minHeight: 520)
                .onAppear { WindowActivationCoordinator.begin("settings") }
                .onDisappear { WindowActivationCoordinator.end("settings") }
        }
        .defaultSize(width: 760, height: 520)
        .windowResizability(.contentSize)

        Window("Name Speakers", id: "speaker-naming") {
            SpeakerNamingView(model: appModel)
                .onAppear { WindowActivationCoordinator.begin("speaker-naming") }
                .onDisappear {
                    WindowActivationCoordinator.end("speaker-naming")
                    // If user closes window without naming, skip naming
                    if !appModel.namingCandidates.isEmpty {
                        appModel.skipNaming()
                    }
                }
        }
        .defaultSize(width: 520, height: 420)
        .windowResizability(.contentSize)
    }
}
