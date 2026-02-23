import AppKit

/// Hotkey: ⌘ + ⌥ + Z (Command+Option+Z)
private let keyCodeZ: UInt16 = 6  // kVK_ANSI_Z

/// Retain the global monitor so it stays active
private var hotkeyMonitor: Any?

/// Optional loading panel shown while waiting for Gemini
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
        let apiKey = getConfig("GEMINI_API_KEY")
        Task {
            do {
                let result = try await tailorWithGemini(text: text, apiKey: apiKey)
                await MainActor.run {
                    hideLoadingPanel()
                    showModal(title: "Tailored", body: result)
                }
            } catch {
                await MainActor.run {
                    hideLoadingPanel()
                    let message: String
                    if let gemini = error as? GeminiError {
                        switch gemini {
                        case .missingApiKey:
                            message = "Set GEMINI_API_KEY in your environment (e.g. in ~/.zshrc or when running: GEMINI_API_KEY=your_key swift run Tailor)."
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
