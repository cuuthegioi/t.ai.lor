import AppKit

// MARK: - App state

private let keyCodeGrave: UInt16 = 50  // ⌘ + ` (Command+backtick)
private var hotkeyMonitor: Any?
private var statusItem: NSStatusItem?

// MARK: - Entry

func main() {
    let app = NSApplication.shared
    app.setActivationPolicy(.accessory)

    statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    hotkeyMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
        let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        if event.keyCode == keyCodeGrave && modifiers.contains(.command) {
            handleHotkey()
        }
    }
    if let item = statusItem {
        MenuBar.setup(statusItem: item, hotkeyRegistered: hotkeyMonitor != nil)
    }
    if hotkeyMonitor == nil {
        print("Tailor: Global hotkey requires Accessibility permission (System Settings → Privacy & Security → Accessibility).")
    }

    app.run()
}

// MARK: - Hotkey handler

func handleHotkey() {
    DispatchQueue.main.async {
        let content = NSPasteboard.general.string(forType: .string)
        guard let text = content, !text.isEmpty else {
            showAlert(title: "Clipboard", body: "(empty)")
            return
        }
        LoadingPanel.show()
        let apiKey = Preferences.resolvedAPIKey()
        let provider = Preferences.currentProvider()
        let systemPrompt = Preferences.effectiveTailorPrompt()
        Task {
            do {
                let result: String
                if provider == Preferences.providerGemini {
                    result = try await tailorWithGemini(text: text, apiKey: apiKey, systemPrompt: systemPrompt)
                } else {
                    result = try await tailorWithGPT(text: text, apiKey: apiKey, systemPrompt: systemPrompt)
                }
                await MainActor.run {
                    LoadingPanel.hide()
                    ResultPanel.present(text: result)
                }
            } catch {
                await MainActor.run {
                    LoadingPanel.hide()
                    let message = errorMessage(for: error)
                    showAlert(title: "Error", body: message)
                }
            }
        }
    }
}

private func errorMessage(for error: Error) -> String {
    if let gpt = error as? GPTError {
        switch gpt {
        case .missingApiKey:
            return "Set your API key via the menu bar: Tailor → Set API Key…"
        case .invalidResponse:
            return "Invalid response from OpenAI."
        case .networkError(let e):
            return e.localizedDescription
        }
    }
    if let gemini = error as? GeminiError {
        switch gemini {
        case .missingApiKey:
            return "Set your API key via the menu bar: Tailor → Set API Key…"
        case .invalidResponse:
            return "Invalid response from Gemini."
        case .networkError(let e):
            return e.localizedDescription
        }
    }
    return (error as NSError).localizedDescription
}

// MARK: - Alerts

func showAlert(title: String, body: String) {
    NSApp.activate(ignoringOtherApps: true)
    let alert = NSAlert()
    alert.messageText = title
    alert.informativeText = body
    alert.alertStyle = title == "Error" ? .warning : .informational
    alert.addButton(withTitle: "OK")
    alert.runModal()
}

main()
