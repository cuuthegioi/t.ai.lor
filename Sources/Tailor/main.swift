import AppKit

/// Hotkey: ⌘ + ⌥ + Z (Command+Option+Z)
private let keyCodeZ: UInt16 = 6  // kVK_ANSI_Z

/// Retain the global monitor so it stays active
private var hotkeyMonitor: Any?

/// Optional loading panel shown while waiting for AI
private var loadingPanel: NSPanel?

func main() {
    let app = NSApplication.shared
    app.setActivationPolicy(.accessory)

    hotkeyMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
        let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        if event.keyCode == keyCodeZ && modifiers.contains(.command) && modifiers.contains(.option) {
            handleHotkey()
        }
    }

    if hotkeyMonitor == nil {
        print("Tailor: Global hotkey requires Accessibility permission (System Settings → Privacy & Security → Accessibility).")
    }

    app.run()
}

private func handleHotkey() {
    DispatchQueue.main.async {
        let content = NSPasteboard.general.string(forType: .string)
        guard let text = content, !text.isEmpty else {
            showModal(title: "Clipboard", body: "(empty)")
            return
        }
        showLoadingPanel()
        let apiKey = getConfig("API_KEY")
        Task {
            do {
                let result = try await tailorWithGPT(text: text, apiKey: apiKey)
                await MainActor.run {
                    hideLoadingPanel()
                    showResultPanel(text: result)
                }
            } catch {
                await MainActor.run {
                    hideLoadingPanel()
                    let message: String
                    if let gpt = error as? GPTError {
                        switch gpt {
                        case .missingApiKey:
                            message = "Set API_KEY in Config.xcconfig or in your environment (e.g. API_KEY=your_key swift run Tailor)."
                        case .invalidResponse:
                            message = "Invalid response from OpenAI."
                        case .networkError(let e):
                            message = e.localizedDescription
                        }
                    } else {
                        message = (error as NSError).localizedDescription
                    }
                    showModal(title: "Error", body: message)
                }
            }
        }
    }
}

private func showLoadingPanel() {
    hideLoadingPanel()
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
    loadingPanel = panel
}

private func hideLoadingPanel() {
    loadingPanel?.orderOut(nil)
    loadingPanel = nil
}

private func showResultPanel(text: String) {
    NSApp.activate(ignoringOtherApps: true)

    let panelWidth: CGFloat = 440
    let panelHeight: CGFloat = 340
    let margin: CGFloat = 16
    let buttonHeight: CGFloat = 28
    let buttonWidth: CGFloat = 88
    let textHeight = panelHeight - 2 * margin - buttonHeight - 12  // text area above buttons

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

    // Scroll view + text view (selectable, copyable) — above buttons
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

    let holder = ResultPanelHolder(panel: panel, textView: textView)

    // Copy button (bottom left)
    let copyButton = NSButton(title: "Copy", target: holder, action: #selector(ResultPanelHolder.copyTapped))
    copyButton.frame = NSRect(x: margin, y: margin, width: buttonWidth, height: buttonHeight)
    copyButton.bezelStyle = .rounded
    contentView.addSubview(copyButton)

    // OK button (bottom right)
    let okButton = NSButton(title: "OK", target: holder, action: #selector(ResultPanelHolder.okTapped))
    okButton.frame = NSRect(x: panelWidth - margin - buttonWidth, y: margin, width: buttonWidth, height: buttonHeight)
    okButton.bezelStyle = .rounded
    okButton.keyEquivalent = "\r"
    contentView.addSubview(okButton)

    panel.center()
    NSApp.runModal(for: panel)
    panel.close()
}

private class ResultPanelHolder: NSObject {
    let panel: NSPanel
    weak var textView: NSTextView?

    init(panel: NSPanel, textView: NSTextView) {
        self.panel = panel
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

private func showModal(title: String, body: String) {
    NSApp.activate(ignoringOtherApps: true)
    let alert = NSAlert()
    alert.messageText = title
    alert.informativeText = body
    alert.alertStyle = title == "Error" ? .warning : .informational
    alert.addButton(withTitle: "OK")
    alert.runModal()
}

main()
