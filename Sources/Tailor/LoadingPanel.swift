import AppKit

enum LoadingPanel {
    private static var panel: NSPanel?

    static func show() {
        hide()
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 280, height: 80),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        panel.title = "Tailor"
        panel.isReleasedWhenClosed = false
        panel.level = .floating
        let label = NSTextField(labelWithString: "Tailoring your text…")
        label.frame = NSRect(x: 20, y: 42, width: 240, height: 20)
        label.alignment = .center
        panel.contentView?.addSubview(label)
        let spinner = NSProgressIndicator()
        spinner.style = .spinning
        spinner.frame = NSRect(x: 130, y: 12, width: 20, height: 20)
        spinner.startAnimation(nil)
        panel.contentView?.addSubview(spinner)
        panel.center()
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
        self.panel = panel
    }

    static func hide() {
        panel?.orderOut(nil)
        panel = nil
    }
}
