import AppKit

enum MetaPromptPanel {
    private static let panelWidth: CGFloat = 480
    private static let panelHeight: CGFloat = 320
    private static let margin: CGFloat = 20
    private static let textAreaHeight: CGFloat = 200
    private static let buttonHeight: CGFloat = 28
    private static let buttonWidth: CGFloat = 88

    static func present() {
        NSApp.activate(ignoringOtherApps: true)
        let textAreaWidth = panelWidth - 2 * margin

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: panelWidth, height: panelHeight),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        panel.title = "Set meta prompt"
        panel.isReleasedWhenClosed = false
        panel.level = .floating
        panel.standardWindowButton(.documentIconButton)?.isHidden = true

        guard let contentView = panel.contentView else { return }

        let label = NSTextField(labelWithString: "Instructions for the AI (leave empty to use default):")
        label.frame = NSRect(x: margin, y: panelHeight - margin - 18, width: textAreaWidth, height: 18)
        label.font = NSFont.systemFont(ofSize: NSFont.smallSystemFontSize)
        contentView.addSubview(label)

        let scrollView = NSScrollView(frame: NSRect(x: margin, y: panelHeight - margin - 18 - textAreaHeight - 8, width: textAreaWidth, height: textAreaHeight))
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.borderType = .bezelBorder
        scrollView.autohidesScrollers = true

        let textView = NSTextView(frame: scrollView.bounds)
        textView.string = Preferences.effectiveTailorPrompt()
        textView.isEditable = true
        textView.isSelectable = true
        textView.font = NSFont.systemFont(ofSize: NSFont.systemFontSize)
        textView.textContainer?.containerSize = NSSize(width: scrollView.contentSize.width, height: .greatestFiniteMagnitude)
        textView.textContainer?.widthTracksTextView = true
        textView.minSize = NSSize(width: 0, height: 0)
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = .width
        scrollView.documentView = textView
        contentView.addSubview(scrollView)

        let holder = Holder(textView: textView)
        let cancelButton = NSButton(title: "Cancel", target: holder, action: #selector(Holder.cancelTapped))
        cancelButton.frame = NSRect(x: margin, y: margin, width: buttonWidth, height: buttonHeight)
        cancelButton.bezelStyle = .rounded
        let saveButton = NSButton(title: "Save", target: holder, action: #selector(Holder.saveTapped))
        saveButton.frame = NSRect(x: panelWidth - margin - buttonWidth, y: margin, width: buttonWidth, height: buttonHeight)
        saveButton.bezelStyle = .rounded
        saveButton.keyEquivalent = "\r"
        contentView.addSubview(cancelButton)
        contentView.addSubview(saveButton)

        panel.center()
        panel.makeKeyAndOrderFront(nil)
        panel.makeFirstResponder(textView)
        NSApp.runModal(for: panel)
        panel.close()
    }

    private class Holder: NSObject {
        let textView: NSTextView

        init(textView: NSTextView) {
            self.textView = textView
        }

        @objc func cancelTapped() {
            NSApp.stopModal()
        }

        @objc func saveTapped() {
            Preferences.saveMetaPrompt(textView.string)
            NSApp.stopModal()
        }
    }
}
