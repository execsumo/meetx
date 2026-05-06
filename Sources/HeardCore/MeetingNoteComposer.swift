import AppKit
import SwiftUI

/// Floating composer for in-meeting notes. Hotkey opens the panel; the panel
/// becomes key immediately so the first keystroke goes into the field. Esc
/// cancels, Cmd+Return submits.
@MainActor
public final class MeetingNoteComposer {
    public static let shared = MeetingNoteComposer()

    private var panel: KeyablePanel?
    /// Captured at the instant the panel is shown so a slow typer's note still
    /// anchors to when they reacted to what was being said, not when they hit
    /// Cmd+Return.
    private var openedAt: Date?
    private var onSubmit: ((Date, String) -> Void)?
    private var onCancel: (() -> Void)?

    public func present(
        meetingTitle: String,
        recordingStart: Date,
        onSubmit: @escaping (Date, String) -> Void,
        onCancel: @escaping () -> Void = {}
    ) {
        // If already showing, bring it forward rather than stacking.
        if let existing = panel, existing.isVisible {
            existing.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let now = Date()
        self.openedAt = now
        self.onSubmit = onSubmit
        self.onCancel = onCancel

        let view = MeetingNoteComposerView(
            meetingTitle: meetingTitle,
            offsetSecondsAtOpen: max(0, now.timeIntervalSince(recordingStart)),
            onSubmit: { [weak self] text in self?.submit(text: text) },
            onCancel: { [weak self] in self?.cancel() }
        )

        let host = NSHostingView(rootView: view)
        let size = NSSize(width: 420, height: 200)
        host.frame = NSRect(origin: .zero, size: size)

        let p = KeyablePanel(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.titled, .closable, .utilityWindow, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        p.title = "Meeting Note"
        p.level = .floating
        p.isReleasedWhenClosed = false
        p.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        p.contentView = host
        p.center()
        p.delegate = panelDelegate

        // Activate the app briefly so the panel can take key — without this,
        // a backgrounded menu-bar app's panels won't accept keystrokes.
        NSApp.activate(ignoringOtherApps: true)
        p.makeKeyAndOrderFront(nil)

        panel = p
    }

    /// Programmatically dismiss the composer (e.g. on app teardown).
    public func dismiss() {
        panel?.orderOut(nil)
        panel = nil
        openedAt = nil
        onSubmit = nil
        onCancel = nil
    }

    private func submit(text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty, let openedAt {
            onSubmit?(openedAt, trimmed)
        }
        teardown()
    }

    private func cancel() {
        onCancel?()
        teardown()
    }

    private func teardown() {
        panel?.orderOut(nil)
        panel = nil
        openedAt = nil
        onSubmit = nil
        onCancel = nil
    }

    // The panel delegate is held by the composer (NSPanel.delegate is weak).
    private lazy var panelDelegate: ComposerPanelDelegate = {
        ComposerPanelDelegate { [weak self] in self?.cancel() }
    }()
}

/// NSPanel that can become key — required for text input. The default NSPanel
/// with `.nonactivatingPanel` won't accept keystrokes; overriding canBecomeKey
/// is the standard fix.
private final class KeyablePanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

private final class ComposerPanelDelegate: NSObject, NSWindowDelegate {
    let onClose: () -> Void
    init(onClose: @escaping () -> Void) { self.onClose = onClose }

    func windowWillClose(_ notification: Notification) {
        onClose()
    }
}

// MARK: - Composer view

private struct MeetingNoteComposerView: View {
    let meetingTitle: String
    let offsetSecondsAtOpen: TimeInterval
    let onSubmit: (String) -> Void
    let onCancel: () -> Void

    @State private var text: String = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text(headerTitle)
                    .font(.headline)
                Spacer()
                Text("[\(offsetSecondsAtOpen.timestampString)]")
                    .font(.system(.callout, design: .monospaced))
                    .foregroundStyle(.secondary)
            }

            TextEditor(text: $text)
                .font(.body)
                .focused($isFocused)
                .frame(minHeight: 96)
                .padding(6)
                .background(Color(nsColor: .textBackgroundColor))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.secondary.opacity(0.3))
                )

            HStack(spacing: 8) {
                Text("⌘↩ to save, Esc to cancel")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                Spacer()
                Button("Cancel") { onCancel() }
                    .keyboardShortcut(.cancelAction)
                Button("Save Note") { onSubmit(text) }
                    .keyboardShortcut(.return, modifiers: [.command])
                    .buttonStyle(.borderedProminent)
                    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(16)
        .frame(width: 420, height: 200, alignment: .topLeading)
        .onAppear {
            // Defer one runloop tick so the panel is fully key before claiming
            // first responder — without the delay the focus sometimes lands
            // outside the editor on first present.
            DispatchQueue.main.async { isFocused = true }
        }
    }

    private var headerTitle: String {
        let trimmed = meetingTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Note" : "Note · \(trimmed)"
    }
}
