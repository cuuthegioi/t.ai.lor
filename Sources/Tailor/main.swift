import AppKit

/// Hotkey: ⌘ + ⌥ + Z (Command+Option+Z)
private let keyCodeZ: UInt16 = 6  // kVK_ANSI_Z

/// Retain the global monitor so it stays active
private var hotkeyMonitor: Any?

/// Optional loading panel shown while waiting for AI
private var loadingPanel: NSPanel?

/// Menu bar status item (retain so it stays visible)
private var statusItem: NSStatusItem?

private let providerKey = "TailorAIProvider"
private let providerGPT = "gpt"
private let providerGemini = "gemini"

func main() {
    let app = NSApplication.shared
    app.setActivationPolicy(.accessory)

    setupMenuBar()

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

private func setupMenuBar() {
    statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    guard let button = statusItem?.button else { return }

    if let image = NSImage(systemSymbolName: "scissors", accessibilityDescription: "Tailor") {
        image.isTemplate = true
        button.image = image
    } else {
        button.title = "Tailor"
    }

    let menu = NSMenu()
    menu.delegate = MenuBarTarget.shared

    let tailorItem = NSMenuItem(title: "Tailor clipboard (⌘⌥Z)", action: #selector(MenuBarTarget.tailorClipboard), keyEquivalent: "")
    tailorItem.target = MenuBarTarget.shared
    menu.addItem(tailorItem)
    menu.addItem(NSMenuItem.separator())

    let chatGPTItem = NSMenuItem(title: "ChatGPT", action: #selector(MenuBarTarget.selectProvider(_:)), keyEquivalent: "")
    chatGPTItem.target = MenuBarTarget.shared
    chatGPTItem.tag = 1
    menu.addItem(chatGPTItem)
    let geminiItem = NSMenuItem(title: "Gemini", action: #selector(MenuBarTarget.selectProvider(_:)), keyEquivalent: "")
    geminiItem.target = MenuBarTarget.shared
    geminiItem.tag = 2
    menu.addItem(geminiItem)
    menu.addItem(NSMenuItem.separator())

    let setKeyItem = NSMenuItem(title: "Set API Key…", action: #selector(MenuBarTarget.showSetAPIKeyModal), keyEquivalent: "")
    setKeyItem.target = MenuBarTarget.shared
    menu.addItem(setKeyItem)
    menu.addItem(NSMenuItem.separator())

    let quitItem = NSMenuItem(title: "Quit", action: #selector(MenuBarTarget.quit), keyEquivalent: "q")
    quitItem.target = MenuBarTarget.shared
    menu.addItem(quitItem)

    statusItem?.menu = menu
}

private func currentProvider() -> String {
    UserDefaults.standard.string(forKey: providerKey) ?? providerGPT
}

private func saveProvider(_ value: String) {
    UserDefaults.standard.set(value, forKey: providerKey)
}

/// API key: Keychain first (from "Set API Key"), then Config.xcconfig / environment.
private func resolvedAPIKey() -> String? {
    KeychainStorage.loadAPIKey() ?? getConfig("API_KEY")
}

private class MenuBarTarget: NSObject, NSMenuDelegate {
    static let shared = MenuBarTarget()

    @objc func tailorClipboard() {
        handleHotkey()
    }

    @objc func selectProvider(_ sender: NSMenuItem) {
        if sender.tag == 1 { saveProvider(providerGPT) }
        else if sender.tag == 2 { saveProvider(providerGemini) }
    }

    @objc func showSetAPIKeyModal() {
        showAPIKeyPanel()
    }

    @objc func quit() {
        NSApp.terminate(nil)
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        let provider = currentProvider()
        for item in menu.items {
            if item.tag == 1 { item.state = provider == providerGPT ? .on : .off }
            if item.tag == 2 { item.state = provider == providerGemini ? .on : .off }
        }
    }
}

private func showAPIKeyPanel() {
    NSApp.activate(ignoringOtherApps: true)
    let panelWidth: CGFloat = 400
    let panelHeight: CGFloat = 200
    let margin: CGFloat = 20
    let textAreaWidth = panelWidth - 2 * margin
    let textAreaHeight: CGFloat = 100
    let buttonHeight: CGFloat = 28
    let buttonWidth: CGFloat = 88

    let panel = NSPanel(
        contentRect: NSRect(x: 0, y: 0, width: panelWidth, height: panelHeight),
        styleMask: [.titled, .closable],
        backing: .buffered,
        defer: false
    )
    panel.title = "Set API Key"
    panel.isReleasedWhenClosed = false
    panel.level = .floating
    panel.standardWindowButton(.documentIconButton)?.isHidden = true

    guard let contentView = panel.contentView else { return }

    let label = NSTextField(labelWithString: "API Key (stored in Keychain):")
    label.frame = NSRect(x: margin, y: panelHeight - margin - 18, width: textAreaWidth, height: 18)
    label.font = NSFont.systemFont(ofSize: NSFont.smallSystemFontSize)
    contentView.addSubview(label)

    let scrollView = NSScrollView(frame: NSRect(x: margin, y: panelHeight - margin - 18 - textAreaHeight - 8, width: textAreaWidth, height: textAreaHeight))
    scrollView.hasVerticalScroller = true
    scrollView.hasHorizontalScroller = false
    scrollView.borderType = .bezelBorder
    scrollView.autohidesScrollers = true

    let textView = NSTextView(frame: scrollView.bounds)
    textView.string = KeychainStorage.loadAPIKey() ?? ""
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

    let cancelButton = NSButton(title: "Cancel", target: nil, action: #selector(APIKeyPanelHolder.cancelTapped))
    cancelButton.frame = NSRect(x: margin, y: margin, width: buttonWidth, height: buttonHeight)
    cancelButton.bezelStyle = .rounded
    let saveButton = NSButton(title: "Save", target: nil, action: #selector(APIKeyPanelHolder.saveTapped))
    saveButton.frame = NSRect(x: panelWidth - margin - buttonWidth, y: margin, width: buttonWidth, height: buttonHeight)
    saveButton.bezelStyle = .rounded
    saveButton.keyEquivalent = "\r"

    let holder = APIKeyPanelHolder(panel: panel, textView: textView)
    cancelButton.target = holder
    saveButton.target = holder
    contentView.addSubview(cancelButton)
    contentView.addSubview(saveButton)

    panel.center()
    panel.makeKeyAndOrderFront(nil)
    panel.makeFirstResponder(textView)
    NSApp.runModal(for: panel)
    panel.close()
}

private class APIKeyPanelHolder: NSObject {
    let panel: NSPanel
    let textView: NSTextView

    init(panel: NSPanel, textView: NSTextView) {
        self.panel = panel
        self.textView = textView
    }

    @objc func cancelTapped() {
        NSApp.stopModal()
    }

    @objc func saveTapped() {
        let key = textView.string.trimmingCharacters(in: .whitespacesAndNewlines)
        if KeychainStorage.saveAPIKey(key) {
            NSApp.stopModal()
        } else {
            let alert = NSAlert()
            alert.messageText = "Could not save to Keychain."
            alert.runModal()
        }
    }
}

private func handleHotkey() {
    DispatchQueue.main.async {
        let content = NSPasteboard.general.string(forType: .string)
        guard let text = content, !text.isEmpty else {
            showModal(title: "Clipboard", body: "(empty)")
            return
        }
        showLoadingPanel()
        let apiKey = resolvedAPIKey()
        let provider = currentProvider()
        Task {
            do {
                let result: String
                if provider == providerGemini {
                    result = try await tailorWithGemini(text: text, apiKey: apiKey)
                } else {
                    result = try await tailorWithGPT(text: text, apiKey: apiKey)
                }
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
                            message = "Set your API key via the menu bar: Tailor → Set API Key… (or use Config.xcconfig)."
                        case .invalidResponse:
                            message = "Invalid response from OpenAI."
                        case .networkError(let e):
                            message = e.localizedDescription
                        }
                    } else if let gemini = error as? GeminiError {
                        switch gemini {
                        case .missingApiKey:
                            message = "Set your API key via the menu bar: Tailor → Set API Key… (or use Config.xcconfig)."
                        case .invalidResponse:
                            message = "Invalid response from Gemini."
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
