import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {

    func applicationDidFinishLaunching(_ notification: Notification) {
        guard let window = NSApp.windows.first else { return }
        window.delegate = self
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
    }
    
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        print("[Log] windowShouldClose called.")
        let appState = AppState.shared
        
        print("[Log] Current state: isEditing = \(appState.isEditing)")
        
        if appState.isEditing {
            print("[Log] Switching from Editor to Welcome view.")
            appState.isEditing = false
            print("[Log] New state: isEditing = \(appState.isEditing)")
            
            DispatchQueue.main.async {
                print("[Log] Activating window in next event cycle.")
                NSApp.activate(ignoringOtherApps: true)
                sender.makeKeyAndOrderFront(nil)
            }
            
            print("[Log] Preventing window from closing.")
            return false
        }
        
        print("[Log] On Welcome view. Allowing window to close.")
        return true
    }
} 