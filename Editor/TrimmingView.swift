import SwiftUI

struct TrimmingView: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
            Text("裁剪区")
                .font(.title2)
                .foregroundColor(.secondary)
        }
    }
} 