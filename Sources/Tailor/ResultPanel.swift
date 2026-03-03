import AppKit

enum ResultPanel {
    private static let panelWidth: CGFloat = 440
    private static let panelHeight: CGFloat = 340
    private static let margin: CGFloat = 16
    private static let buttonHeight: CGFloat = 28
    private static let buttonWidth: CGFloat = 88

    static func present(text: String) {
        NSApp.activate(ignoringOtherApps: true)
        let textHeight = panelHeight - 2 * margin - buttonHeight - 12

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: panelWidth, height: panelHeight),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        panel.title = "Tailored"
        panel.isReleasedWhenClosed = false
        panel.level = .floating
        panel.standardWindowButton(.documentIconButton)?.isHidden = true

        guard let contentView = panel.contentView else { return }
        contentView.wantsLayer = true

        let scrollView = NSScrollView(frame: NSRect(x: margin, y: margin + buttonHeight + 12, width: panelWidth - 2 * margin, height: textHeight))
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.borderType = .bezelBorder
        scrollView.autoresizingMask = [.width, .height]

        let textView = NSTextView(frame: scrollView.bounds)
        textView.string = text
        textView.isSelectable = true
        textView.isEditable = true
        textView.font = NSFont.systemFont(ofSize: NSFont.systemFontSize)
        textView.textContainer?.containerSize = NSSize(width: scrollView.contentSize.width, height: .greatestFiniteMagnitude)
        textView.textContainer?.widthTracksTextView = true
        textView.minSize = NSSize(width: 0, height: 0)
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = .width
        textView.sizeToFit()
        scrollView.documentView = textView
        contentView.addSubview(scrollView)

        let holder = Holder(textView: textView)
        let copyButton = NSButton(title: "Copy", target: holder, action: #selector(Holder.copyTapped))
        copyButton.frame = NSRect(x: margin, y: margin, width: buttonWidth, height: buttonHeight)
        copyButton.bezelStyle = .rounded
        let okButton = NSButton(title: "OK", target: holder, action: #selector(Holder.okTapped))
        okButton.frame = NSRect(x: panelWidth - margin - buttonWidth, y: margin, width: buttonWidth, height: buttonHeight)
        okButton.bezelStyle = .rounded
        okButton.keyEquivalent = "\r"
        contentView.addSubview(copyButton)
        contentView.addSubview(okButton)

        panel.center()
        NSApp.runModal(for: panel)
        panel.close()
    }

    private class Holder: NSObject {
        weak var textView: NSTextView?

        init(textView: NSTextView) {
            self.textView = textView
        }

        @objc func copyTapped() {
            guard let content = textView?.string else { return }
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(content, forType: .string)
        }

        @objc func okTapped() {
            guard let content = textView?.string else { return }
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(content, forType: .string)
            NSApp.stopModal()
        }
    }
}
