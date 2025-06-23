import SwiftUI
import UniformTypeIdentifiers

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
    @State private var isTargeted = false
    var body: some View {
        PlaceholderView(title: isTargeted ? "拖拽到此处！" : "画布区", color: Theme.playerBackgroundColor)
            .onDrop(of: [UTType.text], isTargeted: $isTargeted) { providers in
                if let provider = providers.first {
                    _ = provider.loadObject(ofClass: NSString.self) { object, _ in
                        if let idStr = object as? String {
                            print("[Canvas] 接收到拖拽素材ID: \(idStr)")
                        }
                    }
                    return true
                }
                return false
            }
    }
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