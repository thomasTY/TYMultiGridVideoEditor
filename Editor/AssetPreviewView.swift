import SwiftUI

struct AssetPreviewView: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
            Text("单素材预览区")
                .font(.title2)
                .foregroundColor(.secondary)
        }
    }
} 