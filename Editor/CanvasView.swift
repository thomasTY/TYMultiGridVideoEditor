import SwiftUI

struct CanvasView: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.darkGray))
            Text("画布区")
                .font(.title)
                .foregroundColor(.white.opacity(0.8))
        }
    }
} 