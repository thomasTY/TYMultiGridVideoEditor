import SwiftUI

@main
struct MultiGridVideoEditorApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            Group {
                if appState.isEditing {
                    EditorView()
                } else {
                    WelcomeView()
                }
            }
            .environmentObject(appState)
            .frame(minWidth: 1200, minHeight: 800)
        }
        .windowStyle(HiddenTitleBarWindowStyle())
    }
} 