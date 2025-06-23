import SwiftUI

extension View {
    func onTapGesture(perform action: @escaping (NSEvent) -> Void) -> some View {
        self.gesture(
            DragGesture(minimumDistance: 0)
                .onEnded { _ in
                    if let event = NSApp.currentEvent {
                        action(event)
                    }
                }
        )
    }
} 