import SwiftUI

struct InspectorView: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
            Text("属性编辑区")
                .font(.title2)
                .foregroundColor(.secondary)
        }
    }
} 