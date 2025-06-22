import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Access the main window.
        guard let window = NSApp.windows.first else {
            print("Main window not found.")
            return
        }
        
        // Make the window draggable by its background.
        window.isMovableByWindowBackground = true
        
        // Standard title bar appearance settings.
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        
        // Add the custom view for edge cursor tracking.
        if let contentView = window.contentView {
            let trackingView = EdgeTrackingView(frame: contentView.bounds)
            trackingView.autoresizingMask = [.width, .height]
            contentView.addSubview(trackingView, positioned: .above, relativeTo: nil)
        }
    }
} 