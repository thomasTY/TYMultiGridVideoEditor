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
        let appState = AppState.shared
        if appState.isEditing {
            appState.isEditing = false
            DispatchQueue.main.async {
                NSApp.activate(ignoringOtherApps: true)
                sender.makeKeyAndOrderFront(nil)
            }
            return false
        }

        let alert = NSAlert()
        alert.messageText = "将退出 TY Multi Grid Video Editor"
        alert.informativeText = "您确定要退出应用程序吗？（5秒后自动退出）"
        alert.addButton(withTitle: "确定")
        alert.addButton(withTitle: "取消")
        alert.alertStyle = .warning

        var didRespond = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            if !didRespond {
                NSApp.terminate(nil)
            }
        }
        alert.beginSheetModal(for: sender) { response in
            didRespond = true
            if response == .alertFirstButtonReturn {
                NSApp.terminate(nil)
            }
            // 取消则什么都不做
        }
        return false
    }
} 