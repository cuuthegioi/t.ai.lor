import Cocoa
import Carbon

protocol HotkeyManagerDelegate: AnyObject {
    func hotkeyPressed()
}

class HotkeyManager {
    weak var delegate: HotkeyManagerDelegate?
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    
    func registerHotkey() {
        // Register for key events
        let eventMask = CGEventMask(1 << CGEventType.keyDown.rawValue)
        
        eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: eventMask,
            callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                let manager = Unmanaged<HotkeyManager>.fromOpaque(refcon!).takeUnretainedValue()
                return manager.handleKeyEvent(proxy: proxy, type: type, event: event)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        )
        
        if let eventTap = eventTap {
            runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
            CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
            CGEvent.tapEnable(tap: eventTap, enable: true)
        }
    }
    
    private func handleKeyEvent(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        let flags = event.flags
        
        // Check for Cmd + Option + Z (keyCode 6 for Z)
        if keyCode == 6 && flags.contains(.maskCommand) && flags.contains(.maskAlternate) {
            DispatchQueue.main.async {
                self.delegate?.hotkeyPressed()
            }
            return nil // Consume the event
        }
        
        return Unmanaged.passRetained(event)
    }
    
    deinit {
        if let eventTap = eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
        }
        if let runLoopSource = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        }
    }
} 