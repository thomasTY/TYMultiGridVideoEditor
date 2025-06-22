import SwiftUI

struct PlaceholderView: View {
    let title: String
    let color: Color

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12).fill(color)
            Text(title).font(.title2).foregroundColor(.secondary)
        }
    }
}

struct CanvasView: View {
    var body: some View { PlaceholderView(title: "画布区", color: .init(nsColor: .darkGray)) }
}

struct InspectorView: View {
    var body: some View { PlaceholderView(title: "属性编辑区", color: .init(nsColor: .controlBackgroundColor)) }
}

struct AssetPreviewView: View {
    var body: some View { PlaceholderView(title: "单素材预览区", color: .init(nsColor: .controlBackgroundColor)) }
}

struct TrimmingView: View {
    var body: some View { PlaceholderView(title: "裁剪区", color: .init(nsColor: .controlBackgroundColor)) }
} 