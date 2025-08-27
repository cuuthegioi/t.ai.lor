import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var hotkeyManager: HotkeyManager?
    private var settingsWindow: NSWindow?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenuBar()
        setupHotkeyManager()
        setupPopover()
    }
    
    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "scissors", accessibilityDescription: "Tailor")
            button.action = #selector(togglePopover)
            button.target = self
        }
        
        setupMenu()
    }
    
    private func setupMenu() {
        let menu = NSMenu()
        
        let settingsItem = NSMenuItem(title: "Settings", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let quitItem = NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quitItem)
        
        statusItem?.menu = menu
    }
    
    private func setupHotkeyManager() {
        hotkeyManager = HotkeyManager()
        hotkeyManager?.delegate = self
        hotkeyManager?.registerHotkey()
    }
    
    private func setupPopover() {
        popover = NSPopover()
        popover?.contentSize = NSSize(width: 400, height: 300)
        popover?.behavior = .transient
        popover?.contentViewController = NSHostingController(rootView: TailorPopoverView())
    }
    
    @objc private func togglePopover() {
        if let button = statusItem?.button {
            if popover?.isShown == true {
                popover?.performClose(nil)
            } else {
                popover?.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
            }
        }
    }
    
    @objc private func openSettings() {
        if settingsWindow == nil {
            let settingsView = SettingsView()
            settingsWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 500, height: 400),
                styleMask: [.titled, .closable, .miniaturizable, .resizable],
                backing: .buffered,
                defer: false
            )
            settingsWindow?.title = "Tailor Settings"
            settingsWindow?.contentViewController = NSHostingController(rootView: settingsView)
            settingsWindow?.center()
        }
        
        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

extension AppDelegate: HotkeyManagerDelegate {
    func hotkeyPressed() {
        // Get selected text from active application
        if let selectedText = getSelectedText() {
            showTailorPopover(with: selectedText)
        }
    }
    
    private func getSelectedText() -> String? {
        // Simulate getting selected text (in real implementation, this would use Accessibility APIs)
        let pasteboard = NSPasteboard.general
        pasteboard.declareTypes([.string], owner: nil)
        
        // Simulate Cmd+C to copy selected text
        let source = CGEventSource(stateID: .combinedSessionState)
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x08, keyDown: true)
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x08, keyDown: false)
        
        keyDown?.flags = .maskCommand
        keyUp?.flags = .maskCommand
        
        keyDown?.post(tap: .cghidEventTap)
        keyUp?.post(tap: .cghidEventTap)
        
        // Small delay to allow copy to complete
        Thread.sleep(forTimeInterval: 0.1)
        
        return pasteboard.string(forType: .string)
    }
    
    private func showTailorPopover(with text: String) {
        // Create a new popover for the tailored text
        let tailorPopover = NSPopover()
        tailorPopover.contentSize = NSSize(width: 400, height: 300)
        tailorPopover.behavior = .transient
        
        let popoverView = TailorPopoverView(originalText: text)
        tailorPopover.contentViewController = NSHostingController(rootView: popoverView)
        
        // Show popover at mouse location
        if let mouseLocation = NSEvent.mouseLocation {
            let screenFrame = NSScreen.main?.frame ?? NSRect.zero
            let point = NSPoint(x: mouseLocation.x, y: mouseLocation.y - 10)
            
            tailorPopover.show(relativeTo: NSRect(x: point.x, y: point.y, width: 1, height: 1), 
                              of: nil, 
                              preferredEdge: .minY)
        }
    }
} 