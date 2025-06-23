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
            .environmentObject(appState)
            .frame(minWidth: 1200, minHeight: 800)
            .background(Theme.primaryBackgroundColor.ignoresSafeArea())
        }
        .windowStyle(HiddenTitleBarWindowStyle())
    }
} 