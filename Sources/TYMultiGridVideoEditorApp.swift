import SwiftUI

@main
struct TYMultiGridVideoEditorApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @ObservedObject private var appState = AppState.shared

    var body: some Scene {
        WindowGroup {
            Group {
                if appState.isEditing {
                    EditorView()
                } else {
                    WelcomeView()
                }
            }
            .frame(minWidth: 1200, minHeight: 800)
            .background(Color(NSColor.windowBackgroundColor).ignoresSafeArea())
        }
        .windowStyle(HiddenTitleBarWindowStyle())
    }
} 