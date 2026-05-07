import AVFoundation
import SwiftUI

// MARK: - Color helpers

private extension Color {
    init(hex: String) {
        let v = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var n: UInt64 = 0
        Scanner(string: v).scanHexInt64(&n)
        self.init(
            red:   Double((n >> 16) & 0xFF) / 255,
            green: Double((n >>  8) & 0xFF) / 255,
            blue:  Double( n        & 0xFF) / 255
        )
    }
}

// MARK: - Theme

enum HeardTheme {
    enum Paper {
        static let bg           = Color(hex: "F5EFE4")
        static let surface      = Color(hex: "FBF7EF")
        static let surfaceAlt   = Color(hex: "EFE7D7")
        static let sidebar      = Color(hex: "EBE2CE")
        static let border       = Color(hex: "D9CFB9")
        static let borderSoft   = Color(hex: "E5DCC8")
        static let ink          = Color(hex: "1C2024")
        static let ink2         = Color(hex: "3A3F47")
        static let mute         = Color(hex: "7B7264")
        static let muteSoft     = Color(hex: "C9BBA5")
        static let accent       = Color(hex: "3F5C8C")
        static let accentInk    = Color(hex: "2F4570")
        static let accentSoft   = Color(hex: "E5EAF3")
        static let good         = Color(hex: "3D7A4F")
        static let goodSoft     = Color(hex: "E1EEDF")
        static let warn         = Color(hex: "A66A1F")
        static let warnSoft     = Color(hex: "F4E6CE")
        static let bad          = Color(hex: "A6452B")
        static let badSoft      = Color(hex: "F2DCD2")
        static let recordingBg  = Color(hex: "2E3338")
        static let recordingInk = Color(hex: "F5EFE4")
    }

    static var accent: Color { Paper.accent }

    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 20
        static let xl: CGFloat = 28
    }

    enum Radius {
        static let inline: CGFloat = 6
        static let card: CGFloat = 10
        static let hero: CGFloat = 14
    }
}

// MARK: - HeardMark

struct HeardMark: View {
    var size: CGFloat = 26

    var body: some View {
        Canvas { ctx, sz in
            let s = sz.width / 64
            // Squircle background gradient
            let bgPath = RoundedRectangle(cornerRadius: 14 * s)
                .path(in: CGRect(origin: .zero, size: sz))
            ctx.fill(bgPath, with: .linearGradient(
                Gradient(colors: [Color(hex: "E8DFD2"), Color(hex: "C9BBA5")]),
                startPoint: CGPoint(x: sz.width / 2, y: 0),
                endPoint: CGPoint(x: sz.width / 2, y: sz.height)
            ))
            // Bubble shape
            var bubble = Path()
            bubble.move(to: CGPoint(x: 16*s, y: 22*s))
            bubble.addCurve(to: CGPoint(x: 22*s, y: 16*s),
                            control1: CGPoint(x: 16*s, y: 18.7*s),
                            control2: CGPoint(x: 19.4*s, y: 16*s))
            bubble.addLine(to: CGPoint(x: 42*s, y: 16*s))
            bubble.addCurve(to: CGPoint(x: 48*s, y: 22*s),
                            control1: CGPoint(x: 45.3*s, y: 16*s),
                            control2: CGPoint(x: 48*s, y: 18.7*s))
            bubble.addLine(to: CGPoint(x: 48*s, y: 36*s))
            bubble.addCurve(to: CGPoint(x: 42*s, y: 42*s),
                            control1: CGPoint(x: 48*s, y: 39.3*s),
                            control2: CGPoint(x: 45.3*s, y: 42*s))
            bubble.addLine(to: CGPoint(x: 35*s, y: 42*s))
            bubble.addLine(to: CGPoint(x: 28*s, y: 48*s))
            bubble.addLine(to: CGPoint(x: 28*s, y: 42*s))
            bubble.addLine(to: CGPoint(x: 22*s, y: 42*s))
            bubble.addCurve(to: CGPoint(x: 16*s, y: 36*s),
                            control1: CGPoint(x: 18.7*s, y: 42*s),
                            control2: CGPoint(x: 16*s, y: 39.3*s))
            bubble.closeSubpath()
            ctx.fill(bubble, with: .linearGradient(
                Gradient(colors: [Color(hex: "2E3338"), Color(hex: "1C2024")]),
                startPoint: CGPoint(x: sz.width / 2, y: 0),
                endPoint: CGPoint(x: sz.width / 2, y: sz.height)
            ))
            // Three dots (cx 24/32/40, cy 29, r 2.4/3.2/2.4)
            let dot = Color(hex: "E8DFD2")
            ctx.fill(Path(ellipseIn: CGRect(x: (24-2.4)*s, y: (29-2.4)*s, width: 4.8*s, height: 4.8*s)),
                     with: .color(dot.opacity(0.65)))
            ctx.fill(Path(ellipseIn: CGRect(x: (32-3.2)*s, y: (29-3.2)*s, width: 6.4*s, height: 6.4*s)),
                     with: .color(dot))
            ctx.fill(Path(ellipseIn: CGRect(x: (40-2.4)*s, y: (29-2.4)*s, width: 4.8*s, height: 4.8*s)),
                     with: .color(dot.opacity(0.65)))
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Toggle Style

private struct HeardToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        ZStack(alignment: configuration.isOn ? .trailing : .leading) {
            Capsule()
                .fill(configuration.isOn ? HeardTheme.Paper.accent : HeardTheme.Paper.muteSoft)
                .frame(width: 30, height: 18)
            Circle()
                .fill(Color.white)
                .shadow(color: .black.opacity(0.15), radius: 1, x: 0, y: 0.5)
                .frame(width: 14, height: 14)
                .padding(2)
        }
        .animation(.easeInOut(duration: 0.14), value: configuration.isOn)
        .onTapGesture { configuration.isOn.toggle() }
    }
}

// MARK: - Shared card components

private struct SectionLabel: View {
    let text: String
    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 10.5, weight: .bold))
            .kerning(0.7)
            .foregroundStyle(HeardTheme.Paper.mute)
    }
}

private struct SettingsCard<Content: View>: View {
    @ViewBuilder let content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(HeardTheme.Paper.surface)
        .clipShape(RoundedRectangle(cornerRadius: HeardTheme.Radius.card))
        .overlay(
            RoundedRectangle(cornerRadius: HeardTheme.Radius.card)
                .stroke(HeardTheme.Paper.border, lineWidth: 0.5)
        )
        .shadow(color: Color(red: 60/255, green: 45/255, blue: 20/255).opacity(0.06),
                radius: 1, x: 0, y: 1)
    }
}

private struct CardRow<Content: View>: View {
    var isLast: Bool = false
    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: 0) {
            content
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
            if !isLast {
                HeardTheme.Paper.borderSoft
                    .frame(height: 0.5)
                    .padding(.leading, 12)
            }
        }
    }
}

private struct ToggleRow: View {
    let title: String
    var subtitle: String? = nil
    var isLast: Bool = false
    let isOn: Binding<Bool>

    var body: some View {
        CardRow(isLast: isLast) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(HeardTheme.Paper.ink)
                    if let sub = subtitle {
                        Text(sub)
                            .font(.system(size: 11))
                            .foregroundStyle(HeardTheme.Paper.mute)
                    }
                }
                Spacer()
                Toggle("", isOn: isOn)
                    .toggleStyle(HeardToggleStyle())
                    .labelsHidden()
            }
        }
    }
}

private struct StatusPill: View {
    let text: String
    let fg: Color
    let bg: Color

    var body: some View {
        Text(text)
            .font(.system(size: 10.5, weight: .semibold))
            .foregroundStyle(fg)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(bg, in: Capsule())
    }
}

// Used inside the dark hero card in the Models tab
private struct HeroButtonStyle: ButtonStyle {
    var isDanger: Bool = false
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(isDanger ? Color(hex: "F2DCD2") : HeardTheme.Paper.recordingInk)
            .padding(.vertical, 4)
            .padding(.horizontal, 10)
            .background(
                isDanger ? Color(hex: "A6452B").opacity(0.4) : Color.white.opacity(0.15),
                in: RoundedRectangle(cornerRadius: 5)
            )
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

// MARK: - Menu Bar Dropdown

public struct MenuBarView: View {
    @ObservedObject public var model: AppModel
    @Environment(\.openWindow) private var openWindow

    public init(model: AppModel) { self.model = model }

    public var body: some View {
        VStack(spacing: 0) {
            if let errorMessage = model.errorMessage {
                errorBanner(errorMessage)
            }
            if model.dictationAXLost {
                axLostBanner
            }

            statusHeader
                .padding(.horizontal, 10)
                .padding(.top, 10)
                .padding(.bottom, 8)

            HeardTheme.Paper.borderSoft.frame(height: 0.5)

            VStack(spacing: 1) {
                if model.settingsStore.settings.developerMode {
                    if model.recordingManager.activeSession == nil {
                        MenuBarRow(title: "Simulate Meeting", icon: "bolt.circle") {
                            model.simulateMeeting()
                        }
                    } else {
                        MenuBarRow(title: "End Simulation", icon: "stop.circle") {
                            model.endSimulatedMeeting()
                        }
                    }
                }

                if !model.namingCandidates.isEmpty {
                    MenuBarRow(title: "Name Speakers…", icon: "person.badge.plus", accent: true) {
                        openWindow(id: "speaker-naming")
                        NSApp.activate(ignoringOtherApps: true)
                    }
                }

                if model.settingsStore.settings.dictationEnabled && !model.isDictating {
                    MenuBarRow(title: "Start Dictation", icon: "mic.badge.plus") {
                        model.toggleDictation()
                    }
                }

                MenuBarRow(title: "Open Transcripts", icon: "folder") {
                    model.openOutputDirectory()
                }
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 4)

            if !model.queueStore.recentJobs.isEmpty {
                HeardTheme.Paper.borderSoft.frame(height: 0.5)

                VStack(alignment: .leading, spacing: 1) {
                    Text("Recent Meetings")
                        .font(.system(size: 10, weight: .bold))
                        .kerning(0.5)
                        .foregroundStyle(HeardTheme.Paper.mute)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 4)

                    ForEach(model.queueStore.recentJobs) { job in
                        JobRow(job: job, model: model)
                    }
                }
                .padding(.horizontal, 6)
                .padding(.bottom, 4)
            }

            HeardTheme.Paper.borderSoft.frame(height: 0.5)

            VStack(spacing: 1) {
                MenuBarRow(title: "Settings…", icon: "gearshape") {
                    openWindow(id: "settings")
                    NSApp.activate(ignoringOtherApps: true)
                }
                MenuBarRow(title: "Quit Heard", icon: "power") {
                    NSApplication.shared.terminate(nil)
                }
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
        }
        .frame(width: 268)
        .background(HeardTheme.Paper.bg)
        .preferredColorScheme(.light)
        .onChange(of: model.showNamingPrompt) { _, show in
            NSLog("Heard: MenuBarView observed showNamingPrompt=\(show)")
            if show {
                openWindow(id: "speaker-naming")
                NSApp.activate(ignoringOtherApps: true)
            }
        }
        .onChange(of: model.namingCandidates.isEmpty) { wasEmpty, isEmpty in
            if wasEmpty && !isEmpty {
                NSLog("Heard: MenuBarView observed namingCandidates became non-empty (\(model.namingCandidates.count))")
                openWindow(id: "speaker-naming")
                NSApp.activate(ignoringOtherApps: true)
            }
        }
    }

    // MARK: Status Header

    @ViewBuilder
    private var statusHeader: some View {
        if let session = model.recordingManager.activeSession {
            let tapFailed = model.recordingManager.appAudioTapFailed
            StatusHeaderCard(
                dotColor: HeardTheme.Paper.bad,
                pulsing: true,
                title: tapFailed ? "Recording (mic only)" : "Recording",
                subtitle: tapFailed
                    ? "No system audio — check Screen Recording"
                    : (session.title.isEmpty ? "Meeting" : session.title),
                dark: true,
                trailing: AnyView(
                    RecordingTimerView(startTime: session.startTime)
                        .monospacedDigit()
                        .font(.system(.callout, design: .monospaced))
                        .foregroundStyle(HeardTheme.Paper.recordingInk.opacity(0.7))
                )
            )
        } else if let job = model.queueStore.processingJob {
            StatusHeaderCard(
                dotColor: HeardTheme.Paper.warn,
                pulsing: true,
                title: "Processing",
                subtitle: processingSubtitle(for: job),
                dark: false,
                trailing: nil
            )
        } else if model.phase == .processing {
            StatusHeaderCard(
                dotColor: HeardTheme.Paper.warn,
                pulsing: true,
                title: "Processing",
                subtitle: "Preparing transcription…",
                dark: false,
                trailing: nil
            )
        } else if model.isDictating {
            StatusHeaderCard(
                dotColor: HeardTheme.Paper.bad,
                pulsing: true,
                title: "Dictating",
                subtitle: model.partialTranscript.isEmpty ? "Listening…" : String(model.partialTranscript.suffix(60)),
                dark: true,
                trailing: nil
            )
        } else {
            Button { model.toggleWatching() } label: {
                StatusHeaderCard(
                    dotColor: model.meetingDetector.isWatching ? HeardTheme.Paper.good : HeardTheme.Paper.warn,
                    pulsing: false,
                    title: model.meetingDetector.isWatching ? "Watching" : "Paused",
                    subtitle: model.meetingDetector.isWatching ? "Waiting for Teams meeting" : "Click to resume",
                    dark: false,
                    trailing: nil
                )
            }
            .buttonStyle(.plain)
        }
    }

    private func processingSubtitle(for job: PipelineJob) -> String {
        switch job.stage {
        case .queued:        return "Queued — preparing to transcribe"
        case .preprocessing: return "Preprocessing audio"
        case .transcribing:
            if let p = model.pipelineProcessor.transcriptionProgress {
                return "Transcribing — \(Int(p * 100))%"
            }
            return "Transcribing"
        case .diarizing:     return "Identifying speakers"
        case .assigning:     return "Matching speakers"
        case .complete, .failed: return job.stage.displayName
        }
    }

    private func errorBanner(_ message: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(HeardTheme.Paper.bad)
                .font(.caption)
            Text(message)
                .font(.caption)
                .foregroundStyle(HeardTheme.Paper.ink)
                .lineLimit(2)
            Spacer(minLength: 4)
            Button("Dismiss") { model.acknowledgeError() }
                .buttonStyle(.plain)
                .font(.caption.weight(.medium))
                .foregroundStyle(HeardTheme.Paper.accent)
        }
        .padding(10)
        .background(HeardTheme.Paper.badSoft, in: RoundedRectangle(cornerRadius: HeardTheme.Radius.inline))
        .padding(.horizontal, 10)
        .padding(.top, 10)
    }

    private var axLostBanner: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(HeardTheme.Paper.warn)
                .font(.caption)
            VStack(alignment: .leading, spacing: 4) {
                Text("Accessibility access was revoked. Dictation text injection stopped.")
                    .font(.caption)
                    .foregroundStyle(HeardTheme.Paper.ink)
                    .lineLimit(3)
                Button("Re-grant Access…") {
                    TextInjector.ensureAccessibility()
                    model.acknowledgeAXLost()
                }
                .buttonStyle(.plain)
                .font(.caption.weight(.medium))
                .foregroundStyle(HeardTheme.Paper.accent)
            }
            Spacer(minLength: 4)
            Button("Dismiss") { model.acknowledgeAXLost() }
                .buttonStyle(.plain)
                .font(.caption.weight(.medium))
                .foregroundStyle(HeardTheme.Paper.mute)
        }
        .padding(10)
        .background(HeardTheme.Paper.warnSoft, in: RoundedRectangle(cornerRadius: HeardTheme.Radius.inline))
        .padding(.horizontal, 10)
        .padding(.top, 10)
    }
}

// MARK: - Menu Bar Components

private struct StatusHeaderCard: View {
    let dotColor: Color
    let pulsing: Bool
    let title: String
    let subtitle: String
    var dark: Bool = false
    let trailing: AnyView?

    var body: some View {
        HStack(spacing: 10) {
            StatusDot(color: dotColor, pulsing: pulsing)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(dark ? HeardTheme.Paper.recordingInk : HeardTheme.Paper.ink)
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(dark ? HeardTheme.Paper.recordingInk.opacity(0.65) : HeardTheme.Paper.mute)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            Spacer(minLength: 4)
            if let trailing { trailing }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: HeardTheme.Radius.card)
                .fill(dark ? HeardTheme.Paper.recordingBg : HeardTheme.Paper.surfaceAlt)
        )
        .contentShape(RoundedRectangle(cornerRadius: HeardTheme.Radius.card))
    }
}

private struct StatusDot: View {
    let color: Color
    let pulsing: Bool
    @State private var pulse = false

    var body: some View {
        ZStack {
            if pulsing {
                Circle()
                    .fill(color.opacity(pulse ? 0.22 : 0))
                    .frame(width: 13, height: 13)
                    .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: pulse)
            }
            Circle()
                .fill(color)
                .frame(width: 7, height: 7)
        }
        .frame(width: 13, height: 13)
        .onAppear { if pulsing { pulse = true } }
    }
}

private struct MenuBarRow: View {
    let title: String
    let icon: String
    var accent: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 9) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundStyle(accent ? HeardTheme.Paper.accent : HeardTheme.Paper.ink2)
                    .frame(width: 18, alignment: .center)
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(accent ? HeardTheme.Paper.accent : HeardTheme.Paper.ink)
                Spacer()
            }
            .contentShape(Rectangle())
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
        }
        .buttonStyle(MenuBarRowStyle())
    }
}

private struct MenuBarRowStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                configuration.isPressed ? HeardTheme.Paper.surfaceAlt : Color.clear,
                in: RoundedRectangle(cornerRadius: 5)
            )
    }
}

private struct JobRow: View {
    let job: PipelineJob
    @ObservedObject var model: AppModel

    var body: some View {
        Button(action: {
            if job.stage == .complete { model.openTranscript(job) }
        }) {
            HStack(spacing: 9) {
                Image(systemName: iconName)
                    .font(.system(size: 12))
                    .foregroundStyle(iconColor)
                    .frame(width: 18, alignment: .center)
                VStack(alignment: .leading, spacing: 1) {
                    Text(job.meetingTitle.isEmpty ? "Meeting" : job.meetingTitle)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(HeardTheme.Paper.ink)
                        .lineLimit(1)
                    Text(job.startTime.formatted(date: .omitted, time: .shortened))
                        .font(.system(size: 11))
                        .foregroundStyle(HeardTheme.Paper.mute)
                }
                Spacer()
            }
            .contentShape(Rectangle())
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
        }
        .buttonStyle(MenuBarRowStyle())
        .contextMenu {
            if job.stage == .complete {
                Button("Reveal in Finder") {
                    if let url = job.transcriptPath {
                        NSWorkspace.shared.activateFileViewerSelecting([url])
                    }
                }
            } else if job.stage == .failed {
                Button("Retry") { model.retry(job) }
            }
            Button("Dismiss") { model.dismissJob(job) }
        }
    }

    private var iconName: String {
        switch job.stage {
        case .complete: return "doc.text.fill"
        case .failed:   return "exclamationmark.triangle.fill"
        default:        return "arrow.triangle.2.circlepath"
        }
    }

    private var iconColor: Color {
        switch job.stage {
        case .complete: return HeardTheme.Paper.mute
        case .failed:   return HeardTheme.Paper.bad
        default:        return HeardTheme.Paper.warn
        }
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
            .onReceive(timer) { _ in elapsed = Date().timeIntervalSince(startTime) }
            .onAppear { elapsed = Date().timeIntervalSince(startTime) }
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let total = Int(seconds)
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        if h > 0 { return String(format: "%d:%02d:%02d", h, m, s) }
        return String(format: "%02d:%02d", m, s)
    }
}

/// Kept for public API compatibility.
public struct PulsingDot: View {
    var size: CGFloat = 8
    public init(size: CGFloat = 8) { self.size = size }
    public var body: some View {
        StatusDot(color: HeardTheme.Paper.bad, pulsing: true)
            .frame(width: size, height: size)
    }
}

// MARK: - Settings Window

public struct SettingsView: View {
    @ObservedObject public var model: AppModel
    @ObservedObject private var permissionCenter: PermissionCenter
    @State private var isRecordingHotkey = false
    @State private var isRecordingNoteHotkey = false
    @State private var commandSpokenDraft = ""
    @State private var commandWrittenDraft = ""
    @StateObject private var clipPlayer = SpeakerClipController()

    public init(model: AppModel) {
        self.model = model
        self.permissionCenter = model.permissionCenter
    }

    public var body: some View {
        HStack(spacing: 0) {
            sidebar
            detailPane
        }
        .frame(minWidth: 880, minHeight: 600)
        .preferredColorScheme(.light)
        .sheet(isPresented: $isRecordingHotkey) {
            HotkeyRecorderView(
                onCommit: { combo in
                    model.updateDictationHotkey(combo)
                    isRecordingHotkey = false
                },
                onCancel: { isRecordingHotkey = false }
            )
            .preferredColorScheme(.light)
        }
        .sheet(isPresented: $isRecordingNoteHotkey) {
            HotkeyRecorderView(
                onCommit: { combo in
                    model.updateMeetingNoteHotkey(combo)
                    isRecordingNoteHotkey = false
                },
                onCancel: { isRecordingNoteHotkey = false }
            )
        }
    }

    // MARK: Sidebar

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                HeardMark(size: 26)
                VStack(alignment: .leading, spacing: 1) {
                    Text("Heard")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(HeardTheme.Paper.ink)
                    Text("0.1.0")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(HeardTheme.Paper.mute)
                }
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.top, 16)
            .padding(.bottom, 12)

            HeardTheme.Paper.border.frame(height: 0.5)

            VStack(spacing: 2) {
                ForEach(SettingsTab.allCases) { tab in
                    sidebarItem(tab)
                }
            }
            .padding(.horizontal, 6)
            .padding(.top, 8)

            Spacer()
        }
        .frame(width: 188)
        .background(HeardTheme.Paper.sidebar)
        .overlay(alignment: .trailing) {
            HeardTheme.Paper.border.frame(width: 0.5)
        }
    }

    private func sidebarItem(_ tab: SettingsTab) -> some View {
        let isSelected = model.selectedSettingsTab == tab
        return Button {
            model.selectedSettingsTab = tab
        } label: {
            HStack(spacing: 9) {
                Image(systemName: tab.icon)
                    .font(.system(size: 13))
                    .foregroundStyle(isSelected ? HeardTheme.Paper.accent : HeardTheme.Paper.ink2)
                    .frame(width: 18, alignment: .center)
                Text(tab.label)
                    .font(.system(size: 12.5, weight: isSelected ? .semibold : .medium))
                    .foregroundStyle(isSelected ? HeardTheme.Paper.ink : HeardTheme.Paper.ink2)
                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: 7)
                        .fill(HeardTheme.Paper.surface)
                        .shadow(color: Color(red: 60/255, green: 45/255, blue: 20/255).opacity(0.06),
                                radius: 1, x: 0, y: 1)
                        .overlay(
                            RoundedRectangle(cornerRadius: 7)
                                .stroke(HeardTheme.Paper.border, lineWidth: 0.5)
                        )
                }
            }
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 6)
    }

    // MARK: Detail pane

    private var detailPane: some View {
        Group {
            switch model.selectedSettingsTab {
            case .general:       generalSection
            case .transcription: transcriptionSection
            case .dictation:     dictationSection
            case .speakers:      speakersSection
            case .advanced:      advancedSection
            case .about:         aboutSection
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: General

    private var generalSection: some View {
        paneScroll {
            sectionGroup("Profile") {
                SettingsCard {
                    CardRow(isLast: true) {
                        HStack(spacing: HeardTheme.Spacing.sm) {
                            Text("Your Name")
                                .font(.system(size: 12))
                                .foregroundStyle(HeardTheme.Paper.mute)
                            TextField("Used as speaker label in transcripts", text: settingsBinding(\.userName))
                                .textFieldStyle(.roundedBorder)
                                .frame(maxWidth: 280)
                            Spacer()
                        }
                    }
                }
            }

            sectionGroup("Behavior") {
                SettingsCard {
                    ToggleRow(
                        title: "Launch at Login",
                        isOn: Binding(
                            get: { model.settingsStore.settings.launchAtLogin },
                            set: { model.setLaunchAtLogin($0) }
                        )
                    )
                    ToggleRow(title: "Auto-Watch on Launch", isLast: true, isOn: settingsBinding(\.autoWatch))
                }
            }

            sectionGroup("Output Folder") {
                SettingsCard {
                    CardRow {
                        Text(model.settingsStore.settings.outputDirectory)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(HeardTheme.Paper.mute)
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    CardRow {
                        HStack(spacing: 8) {
                            Button("Choose…") { model.chooseOutputDirectory() }
                            Button("Reset") { model.chooseDefaultOutputDirectory() }
                            Button("Open in Finder") { model.openOutputDirectory() }
                            Spacer()
                        }
                    }
                    CardRow(isLast: true) {
                        HStack {
                            Text("Filename Format")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(HeardTheme.Paper.ink)
                            Spacer()
                            Picker("", selection: settingsBinding(\.filenameFormat)) {
                                ForEach(FilenameFormat.allCases) { format in
                                    Text(format.displayName).tag(format)
                                }
                            }
                            .labelsHidden()
                            .frame(maxWidth: 200)
                        }
                    }
                }
            }

            sectionGroup("Permissions") {
                SettingsCard {
                    let perms = model.permissionCenter.statuses
                    ForEach(Array(perms.enumerated()), id: \.offset) { index, perm in
                        CardRow(isLast: index == perms.count - 1) {
                            PermissionRow(permission: perm, model: model)
                        }
                    }
                }
            }
        }
    }

    // MARK: Transcription

    private var transcriptionSection: some View {
        paneScroll {
            sectionGroup("Language Support") {
                SettingsCard {
                    ForEach(Array(TranscriptionModel.allCases.enumerated()), id: \.offset) { index, version in
                        CardRow(isLast: index == TranscriptionModel.allCases.count - 1) {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(version.displayName)
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundStyle(HeardTheme.Paper.ink)
                                }
                                Spacer()
                                if model.settingsStore.settings.transcriptionModel == version {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundStyle(HeardTheme.Paper.accent)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture { model.setTranscriptionModel(version) }
                        }
                    }
                }
            }

            sectionGroup("Custom Vocabulary") {
                SettingsCard {
                    CardRow {
                        HStack(spacing: 8) {
                            TextField("Term or phrase (e.g. AI, flip phone)", text: $model.vocabularyDraft)
                                .textFieldStyle(.roundedBorder)
                                .onSubmit { model.addVocabularyTerm() }
                            Button("Add") { model.addVocabularyTerm() }
                                .disabled(model.vocabularyDraft.trimmingCharacters(in: .whitespacesAndNewlines).count < 2)
                        }
                    }
                    if !model.settingsStore.settings.customVocabulary.isEmpty {
                        CardRow {
                            FlowLayout(model.settingsStore.settings.customVocabulary, id: \.self) { term in
                                HStack(spacing: 5) {
                                    Text(term).font(.system(size: 12))
                                        .foregroundStyle(HeardTheme.Paper.ink)
                                    Button {
                                        model.removeVocabularyTerm(term)
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.caption)
                                            .foregroundStyle(HeardTheme.Paper.mute)
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(HeardTheme.Paper.surfaceAlt, in: Capsule())
                            }
                        }
                    }
                    CardRow(isLast: true) {
                        Text("\(model.settingsStore.settings.customVocabulary.count) / 50 entries")
                            .font(.system(size: 11))
                            .foregroundStyle(HeardTheme.Paper.mute)
                    }
                }
            }

            sectionGroup("Meeting Notes") {
                SettingsCard {
                    CardRow(isLast: true) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("In-Meeting Note Hotkey")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(HeardTheme.Paper.ink)
                                Text("Press during a meeting to type a note inserted into the transcript, marked as supplemental.")
                                    .font(.system(size: 11))
                                    .foregroundStyle(HeardTheme.Paper.mute)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            Spacer()
                            Text(model.settingsStore.settings.meetingNoteHotkey.displayString)
                                .font(.system(size: 11, design: .monospaced).weight(.medium))
                                .foregroundStyle(HeardTheme.Paper.ink)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(HeardTheme.Paper.surfaceAlt,
                                            in: RoundedRectangle(cornerRadius: 5))
                            Button("Record…") { isRecordingNoteHotkey = true }
                        }
                    }
                }
            }
        }
    }

    // MARK: Dictation

    private var dictationSection: some View {
        paneScroll {
            sectionGroup("Dictation") {
                SettingsCard {
                    ToggleRow(
                        title: "Enable Dictation",
                        subtitle: "Press the hotkey to start/stop dictating into any text field.",
                        isLast: true,
                        isOn: Binding(
                            get: { model.settingsStore.settings.dictationEnabled },
                            set: { model.setDictationEnabled($0) }
                        )
                    )
                }
            }

            sectionGroup("Hotkey") {
                SettingsCard {
                    ToggleRow(
                        title: "Push to Talk",
                        subtitle: "Hold the hotkey to dictate, release to stop.",
                        isOn: Binding(
                            get: { model.settingsStore.settings.pushToTalk },
                            set: { model.setPushToTalk($0) }
                        )
                    )
                    .disabled(!model.settingsStore.settings.dictationEnabled)

                    CardRow(isLast: permissionCenter.isAccessibilityGranted) {
                        HStack {
                            Text(model.settingsStore.settings.pushToTalk ? "Hold to dictate" : "Toggle dictation")
                                .font(.system(size: 12))
                                .foregroundStyle(HeardTheme.Paper.mute)
                            Spacer()
                            Text(model.settingsStore.settings.dictationHotkey.displayString)
                                .font(.system(size: 11, design: .monospaced).weight(.medium))
                                .foregroundStyle(HeardTheme.Paper.ink)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(HeardTheme.Paper.surfaceAlt,
                                            in: RoundedRectangle(cornerRadius: 5))
                            Button("Record…") { isRecordingHotkey = true }
                                .disabled(!model.settingsStore.settings.dictationEnabled)
                        }
                    }

                    if !permissionCenter.isAccessibilityGranted {
                        CardRow(isLast: true) {
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(HeardTheme.Paper.warn)
                                    .font(.system(size: 11))
                                VStack(alignment: .leading, spacing: 5) {
                                    Text("Accessibility permission is required for text injection into other apps.")
                                        .font(.system(size: 11))
                                        .foregroundStyle(HeardTheme.Paper.mute)
                                    Button("Grant Accessibility Access…") {
                                        TextInjector.ensureAccessibility()
                                    }
                                    .controlSize(.small)
                                }
                            }
                        }
                    }
                }
            }

            sectionGroup("Overlay") {
                SettingsCard {
                    ToggleRow(
                        title: "Show Dictation Indicator",
                        subtitle: "A floating pill appears on screen when dictation is active.",
                        isLast: true,
                        isOn: settingsBinding(\.showDictationHUD)
                    )
                    .disabled(!model.settingsStore.settings.dictationEnabled)
                }
            }

            sectionGroup("Custom Formatting Commands") {
                SettingsCard {
                    let cmds = model.settingsStore.settings.formattingCommands
                    if cmds.isEmpty {
                        CardRow {
                            Text("No custom formatting commands.")
                                .font(.system(size: 12))
                                .foregroundStyle(HeardTheme.Paper.mute)
                        }
                    } else {
                        ForEach(cmds) { cmd in
                            CardRow(isLast: false) {
                                HStack {
                                    Text(cmd.spoken)
                                        .font(.system(size: 11, design: .monospaced))
                                        .foregroundStyle(HeardTheme.Paper.ink)
                                    Image(systemName: "arrow.right")
                                        .font(.system(size: 10))
                                        .foregroundStyle(HeardTheme.Paper.mute)
                                    Text(cmd.written.replacingOccurrences(of: "\n", with: "\\n"))
                                        .font(.system(size: 11, design: .monospaced))
                                        .foregroundStyle(HeardTheme.Paper.mute)
                                    Spacer()
                                    Button {
                                        model.removeFormattingCommand(id: cmd.id)
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundStyle(HeardTheme.Paper.mute)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    CardRow(isLast: true) {
                        HStack(spacing: 8) {
                            TextField("Spoken (e.g. 'new paragraph')", text: $commandSpokenDraft)
                                .textFieldStyle(.roundedBorder)
                            TextField("Written (e.g. '\\n\\n')", text: $commandWrittenDraft)
                                .textFieldStyle(.roundedBorder)
                            Button("Add") {
                                let written = commandWrittenDraft.replacingOccurrences(of: "\\n", with: "\n")
                                model.addFormattingCommand(spoken: commandSpokenDraft, written: written)
                                commandSpokenDraft = ""
                                commandWrittenDraft = ""
                            }
                            .disabled(
                                commandSpokenDraft.trimmingCharacters(in: .whitespaces).isEmpty ||
                                commandWrittenDraft.trimmingCharacters(in: .whitespaces).isEmpty
                            )
                        }
                    }
                }
            }

            if model.isDictating {
                sectionGroup("Status") {
                    SettingsCard {
                        CardRow(isLast: model.partialTranscript.isEmpty) {
                            HStack(spacing: 8) {
                                StatusDot(color: HeardTheme.Paper.bad, pulsing: true)
                                Text("Dictating…")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(HeardTheme.Paper.ink)
                            }
                        }
                        if !model.partialTranscript.isEmpty {
                            CardRow(isLast: true) {
                                Text(model.partialTranscript)
                                    .font(.system(size: 11))
                                    .foregroundStyle(HeardTheme.Paper.mute)
                                    .lineLimit(3)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }
                }
            }

            if let error = model.dictationError {
                sectionGroup("Error") {
                    SettingsCard {
                        CardRow(isLast: true) {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .foregroundStyle(HeardTheme.Paper.bad)
                                Text(error)
                                    .font(.system(size: 11))
                                    .foregroundStyle(HeardTheme.Paper.mute)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: Speakers

    private var speakersSection: some View {
        VStack(spacing: 0) {
            VStack(spacing: HeardTheme.Spacing.md) {
                if !model.namingCandidates.isEmpty {
                    HStack(spacing: 8) {
                        Image(systemName: "person.badge.plus")
                            .foregroundStyle(HeardTheme.Paper.warn)
                            .font(.system(size: 12))
                        Text("New speakers detected — open the speaker naming window to identify them")
                            .font(.system(size: 12))
                            .foregroundStyle(HeardTheme.Paper.warn)
                        Spacer()
                    }
                    .padding(12)
                    .background(HeardTheme.Paper.warnSoft,
                                in: RoundedRectangle(cornerRadius: HeardTheme.Radius.inline))
                }

                HStack(spacing: HeardTheme.Spacing.sm) {
                    HStack(spacing: 6) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(HeardTheme.Paper.mute)
                            .font(.system(size: 12))
                        TextField("Search speakers", text: $model.speakerFilter)
                            .textFieldStyle(.plain)
                            .font(.system(size: 12))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(HeardTheme.Paper.surfaceAlt,
                                in: RoundedRectangle(cornerRadius: HeardTheme.Radius.inline))
                    .frame(maxWidth: 260)

                    Picker("Sort", selection: $model.speakerSortMode) {
                        ForEach(SpeakerSortMode.allCases) { sortMode in
                            Text(sortMode.displayName).tag(sortMode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .frame(maxWidth: 240)

                    Spacer()

                    Button("Merge Selected") { model.mergeSelectedSpeakers() }
                        .disabled(model.mergeSelection.count != 2)
                }
            }
            .padding(HeardTheme.Spacing.lg)
            .background(HeardTheme.Paper.bg)

            HeardTheme.Paper.border.frame(height: 0.5)

            Table(model.filteredSpeakers, selection: $model.mergeSelection) {
                TableColumn("Voice") { speaker in
                    SpeakerVoiceCell(speaker: speaker, controller: clipPlayer)
                }
                .width(min: 80, ideal: 100, max: 130)
                TableColumn("Name") { speaker in
                    InlineEditableText(value: speaker.name) { newValue in
                        model.renameSpeaker(id: speaker.id, to: newValue)
                    }
                }
                TableColumn("Meetings") { speaker in
                    Text("\(speaker.meetingCount)").monospacedDigit()
                }
                .width(min: 60, ideal: 70, max: 90)
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
                        clipPlayer.stop()
                        model.speakerStore.delete(id: id)
                    }
                }
            }
        }
        .background(HeardTheme.Paper.bg)
    }

    // MARK: Advanced

    private var advancedSection: some View {
        paneScroll {
            // Hero card (dark gradient)
            let readyCount = model.modelCatalog.statuses.filter { $0.availability == .ready }.count
            let totalCount = model.modelCatalog.statuses.count

            HStack(alignment: .center, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(readyCount) of \(totalCount) models ready")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(HeardTheme.Paper.recordingInk)
                    Text(model.downloadManager.allBatchModelsReady
                         ? "Ready to transcribe"
                         : "Some models need downloading")
                        .font(.system(size: 11))
                        .foregroundStyle(HeardTheme.Paper.recordingInk.opacity(0.65))
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 6) {
                    if !model.downloadManager.allBatchModelsReady {
                        Button("Download Missing") {
                            model.downloadManager.downloadAllModels()
                        }
                        .buttonStyle(HeroButtonStyle())
                    }
                    Button("Unload All") {
                        model.pipelineProcessor.unloadPipelineModels()
                        model.dictationManager.unloadModels()
                    }
                    .buttonStyle(HeroButtonStyle(isDanger: true))
                    .disabled(model.pipelineProcessor.isProcessing || model.isDictating)
                }
            }
            .padding(14)
            .background(
                LinearGradient(
                    colors: [Color(hex: "2E3338"), Color(hex: "1C2024")],
                    startPoint: .top, endPoint: .bottom
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: HeardTheme.Radius.card))
            .overlay(
                RoundedRectangle(cornerRadius: HeardTheme.Radius.card)
                    .stroke(Color(hex: "3A3F47"), lineWidth: 0.5)
            )

            sectionGroup("Models on Disk") {
                SettingsCard {
                    ForEach(Array(model.modelCatalog.statuses.enumerated()), id: \.offset) { index, item in
                        CardRow(isLast: index == model.modelCatalog.statuses.count - 1) {
                            ModelStatusRow(item: item, downloadManager: model.downloadManager)
                        }
                    }
                }
            }

            sectionGroup("Meeting Transcription Keep-Alive") {
                SettingsCard {
                    CardRow {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Keep transcription models loaded for **\(keepAliveLabel(model.settingsStore.settings.pipelineKeepAlive))** after processing.")
                                .font(.system(size: 12))
                                .foregroundStyle(HeardTheme.Paper.ink)
                            Slider(
                                value: Binding<Double>(
                                    get: { Double(model.settingsStore.settings.pipelineKeepAlive) },
                                    set: { model.settingsStore.settings.pipelineKeepAlive = Int($0) }
                                ),
                                in: 0...99, step: 1
                            )
                            HStack {
                                Text("Unload immediately")
                                    .font(.system(size: 10))
                                    .foregroundStyle(HeardTheme.Paper.mute)
                                Spacer()
                                Text("99 minutes")
                                    .font(.system(size: 10))
                                    .foregroundStyle(HeardTheme.Paper.mute)
                            }
                        }
                    }
                    CardRow(isLast: true) {
                        Text("Keeping models loaded speeds up back-to-back meetings but uses ~800 MB RAM.")
                            .font(.system(size: 11))
                            .foregroundStyle(HeardTheme.Paper.mute)
                    }
                }
            }

            sectionGroup("Dictation Keep-Alive") {
                SettingsCard {
                    CardRow {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Keep dictation model loaded for **\(keepAliveLabel(model.settingsStore.settings.dictationKeepAlive))** after stopping.")
                                .font(.system(size: 12))
                                .foregroundStyle(HeardTheme.Paper.ink)
                            Slider(
                                value: Binding<Double>(
                                    get: { Double(model.settingsStore.settings.dictationKeepAlive) },
                                    set: { model.settingsStore.settings.dictationKeepAlive = Int($0) }
                                ),
                                in: 0...99, step: 1
                            )
                            HStack {
                                Text("Unload immediately")
                                    .font(.system(size: 10))
                                    .foregroundStyle(HeardTheme.Paper.mute)
                                Spacer()
                                Text("99 minutes")
                                    .font(.system(size: 10))
                                    .foregroundStyle(HeardTheme.Paper.mute)
                            }
                        }
                    }
                    CardRow(isLast: true) {
                        HStack {
                            Text("~800 MB RAM while loaded")
                                .font(.system(size: 11))
                                .foregroundStyle(HeardTheme.Paper.mute)
                            Spacer()
                            Button("Unload Now") { model.dictationManager.unloadModels() }
                                .disabled(model.isDictating)
                        }
                    }
                }
            }

            sectionGroup("Debugging") {
                SettingsCard {
                    ToggleRow(
                        title: "Developer Mode",
                        subtitle: "Shows simulate meeting buttons for testing",
                        isLast: true,
                        isOn: settingsBinding(\.developerMode)
                    )
                }
            }
        }
    }

    // MARK: About

    private var aboutSection: some View {
        VStack(spacing: 0) {
            LinearGradient(
                colors: [Color(hex: "F0E7D5"), Color(hex: "E8DEC8")],
                startPoint: .top, endPoint: .bottom
            )
            .frame(height: 38)
            .overlay(alignment: .bottom) {
                HeardTheme.Paper.border.frame(height: 0.5)
            }

            ScrollView {
                VStack(spacing: 0) {
                    Spacer().frame(height: 40)
                    HeardMark(size: 72)
                    VStack(spacing: 4) {
                        Text("Heard")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(HeardTheme.Paper.ink)
                        Text("Version 0.1.0")
                            .font(.system(size: 11.5, design: .monospaced))
                            .foregroundStyle(HeardTheme.Paper.mute)
                    }
                    .padding(.top, 20)

                    Text("Automatic meeting detection, dual-track recording,\non-device transcription and speaker diarization.")
                        .multilineTextAlignment(.center)
                        .foregroundStyle(HeardTheme.Paper.ink2)
                        .font(.system(size: 12))
                        .padding(.top, 12)

                    HStack(spacing: HeardTheme.Spacing.sm) {
                        AboutBadge(icon: "lock.shield", text: "On-device")
                        AboutBadge(icon: "icloud.slash", text: "No cloud")
                        AboutBadge(icon: "brain.head.profile", text: "No LLM")
                    }
                    .padding(.top, 16)

                    Text("Powered by FluidAudio · Parakeet TDT · Silero VAD · WeSpeaker")
                        .font(.system(size: 11))
                        .foregroundStyle(HeardTheme.Paper.mute)
                        .padding(.top, 12)

                    Spacer().frame(height: 40)
                }
                .frame(maxWidth: .infinity)
            }
            .background(HeardTheme.Paper.bg)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(HeardTheme.Paper.bg)
    }

    // MARK: Pane helpers

    private func paneScroll<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                content()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
        }
        .background(HeardTheme.Paper.bg)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func sectionGroup<Content: View>(
        _ label: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionLabel(text: label)
            content()
        }
    }

    private func settingsBinding<Value>(_ keyPath: WritableKeyPath<AppSettings, Value>) -> Binding<Value> {
        Binding(
            get: { model.settingsStore.settings[keyPath: keyPath] },
            set: { model.settingsStore.settings[keyPath: keyPath] = $0 }
        )
    }

    private func keepAliveLabel(_ minutes: Int) -> String {
        if minutes == 0 { return "0 minutes (unload immediately)" }
        return minutes == 1 ? "1 minute" : "\(minutes) minutes"
    }
}

// MARK: - Model Status Row

private struct ModelStatusRow: View {
    let item: ModelStatusItem
    @ObservedObject var downloadManager: ModelDownloadManager

    var body: some View {
        HStack(spacing: HeardTheme.Spacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(statusBg)
                    .frame(width: 28, height: 28)
                Image(systemName: statusIcon)
                    .font(.system(size: 13))
                    .foregroundStyle(statusColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(item.modelKind.displayName(for: downloadManager.transcriptionModel))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(HeardTheme.Paper.ink)

                if let progress = downloadManager.downloadProgress[item.modelKind] {
                    ProgressView(value: progress)
                    Text("\(Int(progress * 100))%")
                        .font(.system(size: 10))
                        .foregroundStyle(HeardTheme.Paper.mute)
                        .monospacedDigit()
                } else if let error = downloadManager.errors[item.modelKind] {
                    Text(error)
                        .font(.system(size: 11))
                        .foregroundStyle(HeardTheme.Paper.bad)
                        .lineLimit(1)
                } else {
                    Text(item.detail)
                        .font(.system(size: 11))
                        .foregroundStyle(item.availability == .ready ? HeardTheme.Paper.good : HeardTheme.Paper.mute)
                }
            }

            Spacer()

            if item.availability == .notDownloaded && downloadManager.downloadProgress[item.modelKind] == nil {
                Button("Download") { downloadManager.download(item.modelKind) }
                    .controlSize(.small)
            }
        }
        .padding(.vertical, 2)
    }

    private var statusIcon: String {
        if downloadManager.downloadProgress[item.modelKind] != nil { return "arrow.down.circle" }
        if downloadManager.errors[item.modelKind] != nil { return "exclamationmark.triangle" }
        switch item.availability {
        case .ready:         return "checkmark.circle.fill"
        case .downloading:   return "arrow.down.circle"
        case .notDownloaded: return "arrow.down.to.line"
        }
    }

    private var statusColor: Color {
        if downloadManager.downloadProgress[item.modelKind] != nil { return HeardTheme.Paper.accent }
        if downloadManager.errors[item.modelKind] != nil { return HeardTheme.Paper.bad }
        switch item.availability {
        case .ready:         return HeardTheme.Paper.good
        case .downloading:   return HeardTheme.Paper.accent
        case .notDownloaded: return HeardTheme.Paper.mute
        }
    }

    private var statusBg: Color {
        if downloadManager.errors[item.modelKind] != nil { return HeardTheme.Paper.badSoft }
        switch item.availability {
        case .ready:         return HeardTheme.Paper.goodSoft
        case .downloading:   return HeardTheme.Paper.accentSoft
        case .notDownloaded: return HeardTheme.Paper.surfaceAlt
        }
    }
}

// MARK: - Permission Row

private struct PermissionRow: View {
    let permission: PermissionStatus
    @ObservedObject var model: AppModel

    var body: some View {
        HStack(spacing: HeardTheme.Spacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: 7)
                    .fill(iconBg)
                    .frame(width: 28, height: 28)
                Image(systemName: iconName)
                    .font(.system(size: 14))
                    .foregroundStyle(iconTint)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(permission.title)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(HeardTheme.Paper.ink)
                    if permission.id == "microphone" || permission.id == "screenCapture" {
                        StatusPill(text: "Required",
                                   fg: HeardTheme.Paper.bad,
                                   bg: HeardTheme.Paper.badSoft)
                    }
                }
                Text(permission.purpose)
                    .font(.system(size: 11))
                    .foregroundStyle(HeardTheme.Paper.mute)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                StatusPill(text: permission.state.badge, fg: pillFg, bg: pillBg)
                if permission.state != .granted {
                    Button("Grant…") {
                        switch permission.id {
                        case "microphone":    model.permissionCenter.requestMicrophone()
                        case "audioCapture":  model.permissionCenter.requestAudioCapture()
                        case "screenCapture": model.permissionCenter.openScreenCaptureSettings()
                        case "accessibility": model.permissionCenter.openAccessibilitySettings()
                        default: break
                        }
                    }
                    .controlSize(.small)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var iconName: String {
        switch permission.id {
        case "microphone":    return "mic.fill"
        case "audioCapture":  return "speaker.wave.2.fill"
        case "screenCapture": return "rectangle.dashed.badge.record"
        case "accessibility": return "figure.stand"
        default:              return "lock.fill"
        }
    }

    private var iconTint: Color {
        permission.state == .granted ? HeardTheme.Paper.good : HeardTheme.Paper.accent
    }

    private var iconBg: Color {
        permission.state == .granted ? HeardTheme.Paper.goodSoft : HeardTheme.Paper.accentSoft
    }

    private var pillFg: Color {
        switch permission.state {
        case .granted:     return HeardTheme.Paper.good
        case .recommended: return HeardTheme.Paper.warn
        case .unknown:     return HeardTheme.Paper.bad
        }
    }

    private var pillBg: Color {
        switch permission.state {
        case .granted:     return HeardTheme.Paper.goodSoft
        case .recommended: return HeardTheme.Paper.warnSoft
        case .unknown:     return HeardTheme.Paper.badSoft
        }
    }
}

// MARK: - About Badge

private struct AboutBadge: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: icon).font(.caption2)
            Text(text).font(.system(size: 11))
        }
        .foregroundStyle(HeardTheme.Paper.mute)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(HeardTheme.Paper.surfaceAlt, in: Capsule())
    }
}

// MARK: - Hotkey Recorder

private struct HotkeyRecorderView: View {
    let onCommit: (HotkeyCombo) -> Void
    let onCancel: () -> Void

    @State private var captured: HotkeyCombo? = nil
    @State private var monitorToken: Any? = nil

    private enum ValidationKind { case noModifier, forbidden, singleModifier }

    var body: some View {
        VStack(spacing: HeardTheme.Spacing.lg) {
            Image(systemName: "keyboard")
                .font(.system(size: 36))
                .foregroundStyle(HeardTheme.Paper.accent)

            Text("Record Shortcut")
                .font(.title2.weight(.semibold))
                .foregroundStyle(HeardTheme.Paper.ink)

            Text("Press the key combination you want to use for dictation.")
                .font(.callout)
                .foregroundStyle(HeardTheme.Paper.mute)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 280)

            Group {
                if let combo = captured {
                    Text(combo.displayString)
                        .font(.system(.title3, design: .monospaced).weight(.semibold))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(HeardTheme.Paper.accentSoft,
                                    in: RoundedRectangle(cornerRadius: HeardTheme.Radius.inline))
                        .foregroundStyle(HeardTheme.Paper.accent)
                } else {
                    Text("Waiting for input…")
                        .font(.callout)
                        .foregroundStyle(HeardTheme.Paper.mute)
                        .padding(.vertical, 8)
                }
            }
            .frame(height: 44)

            if let validation = captured.flatMap({ validate($0) }) {
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: validation == .singleModifier
                          ? "exclamationmark.triangle.fill"
                          : "xmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(validation == .singleModifier ? HeardTheme.Paper.warn : HeardTheme.Paper.bad)
                    Text(validationMessage(validation))
                        .font(.caption)
                        .foregroundStyle(validation == .singleModifier ? HeardTheme.Paper.warn : HeardTheme.Paper.bad)
                        .multilineTextAlignment(.leading)
                }
                .frame(maxWidth: 280, alignment: .leading)
            }

            HStack(spacing: HeardTheme.Spacing.md) {
                Button("Cancel") {
                    stopMonitoring()
                    onCancel()
                }
                .keyboardShortcut(.cancelAction)

                Button("Save") {
                    stopMonitoring()
                    if let combo = captured { onCommit(combo) }
                }
                .keyboardShortcut(.defaultAction)
                .disabled(captured == nil || isBlocked(captured))
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(HeardTheme.Spacing.xl)
        .frame(width: 360)
        .background(HeardTheme.Paper.bg)
        .onAppear { startMonitoring() }
        .onDisappear { stopMonitoring() }
    }

    private func isBlocked(_ combo: HotkeyCombo?) -> Bool {
        guard let combo else { return false }
        let v = validate(combo)
        return v == .noModifier || v == .forbidden
    }

    private func isFunctionKeyCode(_ code: UInt16) -> Bool {
        let functionKeyCodes: Set<UInt16> = [
            122, 120, 99, 118, 96, 97, 98, 100, 101, 109, 103, 111,
            105, 107, 113, 106, 64, 79, 80, 90,
        ]
        return functionKeyCodes.contains(code)
    }

    private func validate(_ combo: HotkeyCombo) -> ValidationKind? {
        let flags = combo.modifierFlags
        let modifiers: [NSEvent.ModifierFlags] = [.command, .control, .option, .shift]
        let modCount = modifiers.filter { flags.contains($0) }.count
        if modCount == 0 && !isFunctionKeyCode(combo.keyCode) { return .noModifier }
        if isForbiddenCombo(combo) { return .forbidden }
        if modCount == 1 && !isFunctionKeyCode(combo.keyCode) { return .singleModifier }
        return nil
    }

    private func validationMessage(_ kind: ValidationKind) -> String {
        switch kind {
        case .noModifier:     return "A modifier key (⌘, ⌃, ⌥, or ⇧) is required."
        case .forbidden:      return "This shortcut is reserved by macOS. Please choose another."
        case .singleModifier: return "Single-modifier shortcuts may conflict with app shortcuts."
        }
    }

    private func isForbiddenCombo(_ combo: HotkeyCombo) -> Bool {
        let blocked: [(UInt16, NSEvent.ModifierFlags)] = [
            (48, .command), (49, .command), (49, [.command, .option]),
            (49, .control), (12, .command), (4, .command), (46, .command),
            (13, .command), (43, .command), (50, .command),
            (20, [.command, .shift]), (21, [.command, .shift]), (22, [.command, .shift]),
        ]
        return blocked.contains { keyCode, mods in
            combo.keyCode == keyCode && combo.modifierFlags == mods
        }
    }

    private func startMonitoring() {
        monitorToken = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            guard !isModifierOnlyKeyCode(event.keyCode) else { return event }
            let combo = HotkeyCombo(
                keyCode: event.keyCode,
                modifiers: event.modifierFlags.intersection([.command, .option, .control, .shift])
            )
            captured = combo
            return nil
        }
    }

    private func stopMonitoring() {
        if let token = monitorToken {
            NSEvent.removeMonitor(token)
            monitorToken = nil
        }
    }

    private func isModifierOnlyKeyCode(_ code: UInt16) -> Bool {
        Set<UInt16>([54, 55, 56, 57, 58, 59, 60, 61, 62, 63]).contains(code)
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
        HStack(spacing: HeardTheme.Spacing.sm) {
            Text(candidate.temporaryName)
                .font(.callout.weight(.medium))
                .foregroundStyle(HeardTheme.Paper.ink2)
                .frame(width: 140, alignment: .leading)
            TextField("Enter speaker name", text: $draft)
                .textFieldStyle(.roundedBorder)
                .onSubmit { save() }
            Button("Save") { save() }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }

    private func save() {
        guard !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        onSave(draft)
    }
}

// MARK: - Speaker Naming Prompt Window

public struct SpeakerNamingView: View {
    @ObservedObject var model: AppModel
    @State private var drafts: [UUID: String] = [:]
    @State private var playingCandidateID: UUID?
    @State private var playingClipIndex: Int?
    @State private var audioPlayer: AVAudioPlayer?
    @State private var countdownSeconds = 120
    @State private var countdownTask: Task<Void, Never>?
    @Environment(\.dismissWindow) private var dismissWindow

    public init(model: AppModel) { self.model = model }

    public var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: HeardTheme.Spacing.sm) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(HeardTheme.Paper.accentSoft)
                        .frame(width: 44, height: 44)
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 22))
                        .foregroundStyle(HeardTheme.Paper.accent)
                }

                Text("New Speakers Detected")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(HeardTheme.Paper.ink)

                Text("Listen to each voice clip and enter their name. Unnamed speakers will be saved with generic labels.")
                    .font(.system(size: 12))
                    .foregroundStyle(HeardTheme.Paper.mute)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 420)

                Text("Auto-saving in \(countdownSeconds)s")
                    .font(.system(size: 11))
                    .foregroundStyle(HeardTheme.Paper.warn)
                    .monospacedDigit()
            }
            .padding(.top, HeardTheme.Spacing.lg)
            .padding(.bottom, HeardTheme.Spacing.md)

            HeardTheme.Paper.borderSoft.frame(height: 0.5)

            ScrollView {
                VStack(spacing: HeardTheme.Spacing.sm) {
                    ForEach(model.namingCandidates) { candidate in
                        speakerRow(candidate)
                    }
                }
                .padding(HeardTheme.Spacing.lg)
            }
            .background(HeardTheme.Paper.bg)

            HeardTheme.Paper.borderSoft.frame(height: 0.5)

            HStack {
                Button("Skip All") {
                    stopAudio()
                    model.skipNaming()
                    dismissWindow(id: "speaker-naming")
                }
                .keyboardShortcut(.cancelAction)
                .foregroundStyle(HeardTheme.Paper.ink2)

                Spacer()

                Button("Save & Close") {
                    stopAudio()
                    saveAll()
                    dismissWindow(id: "speaker-naming")
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
            }
            .padding(HeardTheme.Spacing.lg)
            .background(HeardTheme.Paper.surface)
        }
        .frame(width: 560)
        .background(HeardTheme.Paper.bg)
        .preferredColorScheme(.light)
        .onAppear { startCountdown() }
        .onDisappear {
            stopAudio()
            countdownTask?.cancel()
        }
        .onChange(of: model.namingCandidates) { _, candidates in
            if candidates.isEmpty {
                stopAudio()
                countdownTask?.cancel()
                dismissWindow(id: "speaker-naming")
            }
        }
    }

    private func speakerRow(_ candidate: NamingCandidate) -> some View {
        HStack(spacing: HeardTheme.Spacing.md) {
            clipButtons(for: candidate)

            VStack(alignment: .leading, spacing: HeardTheme.Spacing.xs) {
                HStack(spacing: 6) {
                    Text(candidate.temporaryName)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(HeardTheme.Paper.mute)
                    if let suggested = candidate.suggestedName {
                        Text("maybe \(suggested)?")
                            .font(.system(size: 11))
                            .foregroundStyle(HeardTheme.Paper.warn)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(HeardTheme.Paper.warnSoft, in: Capsule())
                    }
                }
                TextField(
                    candidate.suggestedName ?? "Enter speaker name",
                    text: binding(for: candidate)
                )
                .textFieldStyle(.roundedBorder)
                .onSubmit { saveSingle(candidate) }
            }

            Button("Save") { saveSingle(candidate) }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .disabled(draftText(for: candidate).isEmpty)
        }
        .padding(HeardTheme.Spacing.md)
        .background(HeardTheme.Paper.surface)
        .clipShape(RoundedRectangle(cornerRadius: HeardTheme.Radius.card))
        .overlay(
            RoundedRectangle(cornerRadius: HeardTheme.Radius.card)
                .stroke(HeardTheme.Paper.border, lineWidth: 0.5)
        )
    }

    @ViewBuilder
    private func clipButtons(for candidate: NamingCandidate) -> some View {
        if candidate.audioClipURLs.isEmpty {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(HeardTheme.Paper.surfaceAlt)
                    .frame(width: 38, height: 38)
                Image(systemName: "play.slash")
                    .font(.system(size: 15))
                    .foregroundStyle(HeardTheme.Paper.mute)
            }
            .help("No audio clip available")
        } else {
            VStack(alignment: .leading, spacing: 4) {
                Text("Samples")
                    .font(.system(size: 10, weight: .bold))
                    .kerning(0.5)
                    .foregroundStyle(HeardTheme.Paper.mute)
                HStack(spacing: 4) {
                    ForEach(Array(candidate.audioClipURLs.enumerated()), id: \.offset) { index, url in
                        clipButton(candidateID: candidate.id, index: index, url: url)
                    }
                }
            }
        }
    }

    private func clipButton(candidateID: UUID, index: Int, url: URL) -> some View {
        let isPlaying = playingCandidateID == candidateID && playingClipIndex == index
        let tint = isPlaying ? HeardTheme.Paper.bad : HeardTheme.Paper.accent
        return Button {
            togglePlayback(candidateID: candidateID, index: index, url: url)
        } label: {
            HStack(spacing: 3) {
                Image(systemName: isPlaying ? "stop.fill" : "play.fill")
                    .font(.system(size: 9, weight: .semibold))
                Text("\(index + 1)")
                    .font(.system(size: 11, weight: .semibold))
                    .monospacedDigit()
            }
            .foregroundStyle(tint)
            .padding(.horizontal, 7)
            .padding(.vertical, 5)
            .background(tint.opacity(0.14), in: RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
        .help("Play sample \(index + 1)")
    }

    // MARK: Playback

    private func togglePlayback(candidateID: UUID, index: Int, url: URL) {
        if playingCandidateID == candidateID && playingClipIndex == index {
            stopAudio(); return
        }
        stopAudio()
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.play()
            audioPlayer = player
            playingCandidateID = candidateID
            playingClipIndex = index
            Task {
                try? await Task.sleep(for: .seconds(player.duration + 0.1))
                if playingCandidateID == candidateID && playingClipIndex == index {
                    playingCandidateID = nil
                    playingClipIndex = nil
                }
            }
        } catch {
            NSLog("Heard: Failed to play audio clip: \(error)")
        }
    }

    private func stopAudio() {
        audioPlayer?.stop()
        audioPlayer = nil
        playingCandidateID = nil
        playingClipIndex = nil
    }

    // MARK: Drafts

    private func binding(for candidate: NamingCandidate) -> Binding<String> {
        Binding(
            get: { drafts[candidate.id] ?? candidate.suggestedName ?? "" },
            set: { newValue in
                drafts[candidate.id] = newValue
                // Any text edit resets the dormancy timer so an active user isn't interrupted.
                model.resetNamingAutoDismiss()
                startCountdown()
            }
        )
    }

    private func draftText(for candidate: NamingCandidate) -> String {
        (drafts[candidate.id] ?? candidate.suggestedName ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func saveSingle(_ candidate: NamingCandidate) {
        let name = draftText(for: candidate)
        guard !name.isEmpty else { return }
        model.saveSpeakerName(candidate: candidate, name: name)
        drafts.removeValue(forKey: candidate.id)
    }

    private func saveAll() {
        for candidate in model.namingCandidates {
            let name = draftText(for: candidate)
            if !name.isEmpty { model.saveSpeakerName(candidate: candidate, name: name) }
        }
        if !model.namingCandidates.isEmpty { model.skipNaming() }
    }

    // MARK: Countdown

    private func startCountdown() {
        countdownSeconds = 120
        countdownTask?.cancel()
        countdownTask = Task {
            while !Task.isCancelled && countdownSeconds > 0 {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { return }
                countdownSeconds -= 1
            }
        }
    }
}

// MARK: - Speaker Voice Cell (Speakers tab playback)

@MainActor
final class SpeakerClipController: ObservableObject {
    @Published private(set) var playingSpeakerID: UUID?
    @Published private(set) var playingClipIndex: Int?
    private var player: AVAudioPlayer?
    private var stopTask: Task<Void, Never>?

    func toggle(speakerID: UUID, clipIndex: Int, clipURL: URL) {
        if playingSpeakerID == speakerID && playingClipIndex == clipIndex {
            stop(); return
        }
        stop()
        guard FileManager.default.fileExists(atPath: clipURL.path) else { return }
        do {
            let p = try AVAudioPlayer(contentsOf: clipURL)
            p.play()
            player = p
            playingSpeakerID = speakerID
            playingClipIndex = clipIndex
            let duration = p.duration
            stopTask = Task { [weak self] in
                try? await Task.sleep(for: .seconds(duration + 0.1))
                guard let self, !Task.isCancelled else { return }
                if self.playingSpeakerID == speakerID && self.playingClipIndex == clipIndex {
                    self.stop()
                }
            }
        } catch {
            NSLog("Heard: Failed to play speaker clip: \(error)")
        }
    }

    func stop() {
        player?.stop()
        player = nil
        stopTask?.cancel()
        stopTask = nil
        playingSpeakerID = nil
        playingClipIndex = nil
    }
}

struct SpeakerVoiceCell: View {
    let speaker: SpeakerProfile
    @ObservedObject var controller: SpeakerClipController

    private var availableClips: [(index: Int, url: URL)] {
        speaker.audioClipURLs.enumerated().compactMap { index, url in
            FileManager.default.fileExists(atPath: url.path) ? (index, url) : nil
        }
    }

    var body: some View {
        let clips = availableClips
        if clips.isEmpty {
            Image(systemName: "play.slash")
                .font(.system(size: 11))
                .foregroundStyle(HeardTheme.Paper.mute)
                .frame(width: 22, height: 20)
                .help("No voice sample saved")
        } else {
            HStack(spacing: 3) {
                ForEach(clips, id: \.index) { clip in
                    clipButton(index: clip.index, url: clip.url)
                }
            }
        }
    }

    private func clipButton(index: Int, url: URL) -> some View {
        let isPlaying = controller.playingSpeakerID == speaker.id && controller.playingClipIndex == index
        let tint = isPlaying ? HeardTheme.Paper.bad : HeardTheme.Paper.accent
        return Button {
            controller.toggle(speakerID: speaker.id, clipIndex: index, clipURL: url)
        } label: {
            HStack(spacing: 2) {
                Image(systemName: isPlaying ? "stop.fill" : "play.fill")
                    .font(.system(size: 8, weight: .semibold))
                Text("\(index + 1)")
                    .font(.system(size: 10, weight: .semibold))
                    .monospacedDigit()
            }
            .foregroundStyle(tint)
            .padding(.horizontal, 5)
            .padding(.vertical, 3)
            .background(tint.opacity(0.14), in: RoundedRectangle(cornerRadius: 5))
        }
        .buttonStyle(.plain)
        .help("Play sample \(index + 1)")
    }
}

// MARK: - Flow Layout

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
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), alignment: .leading)],
                  alignment: .leading, spacing: 8) {
            ForEach(data, id: id, content: content)
        }
    }
}
