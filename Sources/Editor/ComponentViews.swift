import SwiftUI

struct PlaceholderView: View {
    let title: String
    let color: Color

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12).fill(color)
            Text(title).font(.title2).foregroundColor(Theme.secondaryTextColor)
        }
    }
}

struct CanvasView: View {
    var body: some View { PlaceholderView(title: "画布区", color: Theme.playerBackgroundColor) }
}

struct InspectorView: View {
    var body: some View { PlaceholderView(title: "属性编辑区", color: Theme.secondaryBackgroundColor) }
}

struct AssetPreviewView: View {
    var body: some View { PlaceholderView(title: "单素材预览区", color: Theme.secondaryBackgroundColor) }
}

struct TrimmingView: View {
    var body: some View { PlaceholderView(title: "裁剪区", color: Theme.secondaryBackgroundColor) }
} 