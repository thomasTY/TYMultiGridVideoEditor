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
    @ObservedObject private var appState = AppState.shared
    @State private var isTargeted = false
    
    var body: some View {
        VStack {
            if appState.canvasAssets.isEmpty {
                PlaceholderView(title: isTargeted ? "拖拽到此处！" : "画布区", color: Theme.playerBackgroundColor)
            } else {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 10)], spacing: 10) {
                        ForEach(appState.canvasAssets, id: \.self) { assetId in
                            ZStack(alignment: .topTrailing) {
                                Rectangle()
                                    .fill(Theme.playerBackgroundColor)
                                    .aspectRatio(4/3, contentMode: .fit)
                                    .cornerRadius(6)
                                
                                // 删除按钮
                                Button(action: { removeAsset(assetId) }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.title3)
                                        .symbolRenderingMode(.palette)
                                        .foregroundStyle(.white, Theme.accentColor)
                                }
                                .buttonStyle(.plain)
                                .padding(5)
                            }
                        }
                    }
                    .padding(10)
                }
            }
        }
        .onDrop(of: [UTType.text], isTargeted: $isTargeted) { providers in
            if let provider = providers.first {
                _ = provider.loadObject(ofClass: NSString.self) { object, _ in
                    if let idStr = object as? String {
                        let ids = idStr.split(separator: ",").compactMap { UUID(uuidString: String($0)) }
                        for assetId in ids {
                            addAsset(assetId)
                        }
                    }
                }
                return true
            }
            return false
        }
    }
    
    private func addAsset(_ assetId: UUID) {
        if !appState.canvasAssets.contains(assetId) {
            appState.canvasAssets.append(assetId)
            appState.addAssetToCanvas(assetId)
        }
    }
    
    private func removeAsset(_ assetId: UUID) {
        appState.canvasAssets.removeAll { $0 == assetId }
        appState.removeAssetFromCanvas(assetId)
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