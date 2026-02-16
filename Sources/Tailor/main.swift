import AppKit

/// Hotkey: ⌘ + ⌥ + Z (Command+Option+Z)
private let keyCodeZ: UInt16 = 6  // kVK_ANSI_Z

/// Retain the global monitor so it stays active
private var hotkeyMonitor: Any?

func main() {
    let app = NSApplication.shared
    app.setActivationPolicy(.accessory)  // Background app, no Dock icon

    hotkeyMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
        let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        // Debug: log when Z is pressed with any modifier (remove once working)
        if event.keyCode == keyCodeZ {
            print("Tailor: Z key seen, modifiers raw=\(modifiers.rawValue) cmd=\(modifiers.contains(.command)) opt=\(modifiers.contains(.option))")
        }
        if event.keyCode == keyCodeZ && modifiers.contains(.command) && modifiers.contains(.option) {
            handleHotkey()
        }
    }

    if hotkeyMonitor == nil {
        print("Tailor: Global hotkey requires Accessibility permission.")
        print("Enable it in: System Settings → Privacy & Security → Accessibility")
    } else {
        print("Tailor: Running. Press ⌘⌥Z to show clipboard.")
    }

    app.run()
}

private func handleHotkey() {
    print("Tailor: Hotkey pressed.")
    let pasteboard = NSPasteboard.general
    guard let content = pasteboard.string(forType: .string), !content.isEmpty else {
        DispatchQueue.main.async { showModal(content: nil) }
        return
    }
    DispatchQueue.main.async { showModal(content: content) }
}

private func showModal(content: String?) {
    NSApp.activate(ignoringOtherApps: true)  // Bring app to front so dialog is visible
    let alert = NSAlert()
    alert.messageText = "Clipboard"
    alert.informativeText = content ?? "(empty)"
    alert.alertStyle = .informational
    alert.addButton(withTitle: "OK")
    alert.runModal()
}

main()
