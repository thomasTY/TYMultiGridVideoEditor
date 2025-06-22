import SwiftUI

struct MediaListView: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
            Text("素材列表区")
                .font(.title2)
                .foregroundColor(.secondary)
        }
    }
} 