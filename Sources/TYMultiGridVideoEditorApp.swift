import SwiftUI

@main
struct TYMultiGridVideoEditorApp: App {
    var body: some Scene {
        WindowGroup {
            WelcomeView()
                .frame(minWidth: 800, minHeight: 600)
                .background(Color(NSColor.windowBackgroundColor).ignoresSafeArea())
        }
        .windowStyle(HiddenTitleBarWindowStyle())
    }
} 