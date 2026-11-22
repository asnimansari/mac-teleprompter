import SwiftUI

struct EditorView: View {
    @ObservedObject var settings: Settings

    private var words: Int { settings.script.split(whereSeparator: \.isWhitespace).count }

    var body: some View {
        VStack(spacing: 0) {
            TextEditor(text: $settings.script)
                .font(.system(size: 15))
                .scrollContentBackground(.hidden)
                .padding(10)
            Divider()
            HStack {
                Text("\(words) words · ~\(duration) at \(settings.wpm) wpm")
                Spacer()
                Text("⌃⌥Space play/pause · ⌃⌥↑↓ speed · ⌃⌥R restart · ⌃⌥H hide")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 12).padding(.vertical, 6)
        }
        .frame(minWidth: 480, minHeight: 320)
    }

    private var duration: String {
        let seconds = Int((Double(words) / Double(settings.wpm) * 60).rounded())
        return String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
}

@MainActor
final class EditorWindowController {
    private var window: NSWindow?

    func show(settings: Settings) {
        if window == nil {
            let w = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 620, height: 480),
                             styleMask: [.titled, .closable, .resizable, .miniaturizable],
                             backing: .buffered, defer: false)
            w.title = "Mac Teleprompter Script"
            w.isReleasedWhenClosed = false
            w.contentViewController = NSHostingController(rootView: EditorView(settings: settings))
            w.center()
            window = w
        }
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
    }
}
