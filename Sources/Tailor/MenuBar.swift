import AppKit

enum MenuBar {
    static func setup(statusItem: NSStatusItem) {
        guard let button = statusItem.button else { return }

        if let image = NSImage(systemSymbolName: "scissors", accessibilityDescription: "Tailor") {
            image.isTemplate = true
            button.image = image
        } else {
            button.title = "Tailor"
        }

        let menu = NSMenu()
        menu.delegate = MenuBarTarget.shared

        let tailorItem = NSMenuItem(title: "Tailor clipboard (⌘`)", action: #selector(MenuBarTarget.tailorClipboard), keyEquivalent: "")
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
        let setPromptItem = NSMenuItem(title: "Set meta prompt…", action: #selector(MenuBarTarget.showSetMetaPromptModal), keyEquivalent: "")
        setPromptItem.target = MenuBarTarget.shared
        menu.addItem(setPromptItem)
        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit", action: #selector(MenuBarTarget.quit), keyEquivalent: "q")
        quitItem.target = MenuBarTarget.shared
        menu.addItem(quitItem)

        statusItem.menu = menu
    }
}

final class MenuBarTarget: NSObject, NSMenuDelegate {
    static let shared = MenuBarTarget()

    @objc func tailorClipboard() {
        handleHotkey()
    }

    @objc func selectProvider(_ sender: NSMenuItem) {
        if sender.tag == 1 { Preferences.saveProvider(Preferences.providerGPT) }
        else if sender.tag == 2 { Preferences.saveProvider(Preferences.providerGemini) }
    }

    @objc func showSetAPIKeyModal() {
        APIKeyPanel.present()
    }

    @objc func showSetMetaPromptModal() {
        MetaPromptPanel.present()
    }

    @objc func quit() {
        NSApp.terminate(nil)
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        let provider = Preferences.currentProvider()
        for item in menu.items {
            if item.tag == 1 { item.state = provider == Preferences.providerGPT ? .on : .off }
            if item.tag == 2 { item.state = provider == Preferences.providerGemini ? .on : .off }
        }
    }
}
