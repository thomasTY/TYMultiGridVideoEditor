import SwiftUI
import AppKit

struct MediaListView: View {
    @State private var mediaAssets: [MediaAsset] = MediaAsset.placeholderAssets()
    @State private var selectedAssetIDs = Set<MediaAsset.ID>()

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("素材 (\(mediaAssets.count))")
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(Theme.primaryTextColor)
                Spacer()
                
                Button(action: selectAll) {
                    Text("全选")
                        .foregroundColor(Theme.secondaryTextColor)
                }
                .buttonStyle(.plain)

                Button(action: importMediaFiles) {
                    Label("导入", systemImage: "plus")
                        .foregroundColor(Theme.secondaryTextColor)
                }
                .buttonStyle(.plain)
            }
            .padding(12)
            .background(Theme.secondaryBackgroundColor)
            
            Divider().opacity(0.5)

            // Grid of media assets
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 110), spacing: 15)], spacing: 15) {
                    ForEach(mediaAssets) { asset in
                        MediaItemView(
                            asset: asset,
                            isSelected: selectedAssetIDs.contains(asset.id),
                            onDelete: { deleteAsset(asset) },
                            onRename: { renameAsset(asset) },
                            onDuplicate: { duplicateAsset(asset) },
                            onReplace: { replaceAsset(asset) }
                        )
                        .onTapGesture { event in
                            handleSelection(for: asset, with: event)
                        }
                    }
                }
                .padding(12)
            }
            .onTapGesture {
                // Click on empty space to deselect all
                selectedAssetIDs.removeAll()
            }
        }
        .background(Theme.secondaryBackgroundColor)
        .cornerRadius(12)
        .clipped()
    }
    
    private func handleSelection(for asset: MediaAsset, with event: NSEvent) {
        if event.modifierFlags.contains(.command) {
            // Command-click: toggle selection for this item
            if selectedAssetIDs.contains(asset.id) {
                selectedAssetIDs.remove(asset.id)
            } else {
                selectedAssetIDs.insert(asset.id)
            }
        } else {
            // Normal click: select only this item
            selectedAssetIDs = [asset.id]
        }
    }
    
    private func selectAll() {
        selectedAssetIDs = Set(mediaAssets.map { $0.id })
    }
    
    private func importMediaFiles() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.allowedFileTypes = [
            "png", "jpg", "jpeg", "bmp", "gif", "tiff", "heic", "webp", // 图片
            "mp4", "mov", "m4v", "avi", "mkv" // 视频
        ]
        panel.title = "导入素材"
        if panel.runModal() == .OK {
            let newAssets = panel.urls.compactMap { url -> MediaAsset? in
                let ext = url.pathExtension.lowercased()
                let name = url.lastPathComponent
                if ["png", "jpg", "jpeg", "bmp", "gif", "tiff", "heic", "webp"].contains(ext) {
                    return MediaAsset(title: name, type: .image)
                } else if ["mp4", "mov", "m4v", "avi", "mkv"].contains(ext) {
                    return MediaAsset(title: name, type: .video, duration: nil) // 暂不分析时长
                } else {
                    return nil
                }
            }
            mediaAssets.append(contentsOf: newAssets)
        }
    }
    
    private func deleteAsset(_ asset: MediaAsset) {
        mediaAssets.removeAll { $0.id == asset.id }
        selectedAssetIDs.remove(asset.id)
    }
    
    private func renameAsset(_ asset: MediaAsset) {
        // 简单弹窗输入新名字
        let alert = NSAlert()
        alert.messageText = "重命名素材"
        alert.informativeText = "请输入新名称："
        let input = NSTextField(string: asset.title)
        alert.accessoryView = input
        alert.addButton(withTitle: "确定")
        alert.addButton(withTitle: "取消")
        if alert.runModal() == .alertFirstButtonReturn {
            let newName = input.stringValue
            if let idx = mediaAssets.firstIndex(where: { $0.id == asset.id }) {
                mediaAssets[idx].title = newName
            }
        }
    }
    
    private func duplicateAsset(_ asset: MediaAsset) {
        var copy = asset
        copy.title += " 副本"
        // 新副本要有新id
        copy = MediaAsset(title: copy.title, type: copy.type, duration: copy.duration)
        mediaAssets.append(copy)
    }
    
    private func replaceAsset(_ asset: MediaAsset) {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.allowedFileTypes = [
            "png", "jpg", "jpeg", "bmp", "gif", "tiff", "heic", "webp",
            "mp4", "mov", "m4v", "avi", "mkv"
        ]
        panel.title = "选择替换素材"
        if panel.runModal() == .OK, let url = panel.url {
            let ext = url.pathExtension.lowercased()
            let name = url.lastPathComponent
            var newAsset: MediaAsset?
            if ["png", "jpg", "jpeg", "bmp", "gif", "tiff", "heic", "webp"].contains(ext) {
                newAsset = MediaAsset(title: name, type: .image)
            } else if ["mp4", "mov", "m4v", "avi", "mkv"].contains(ext) {
                newAsset = MediaAsset(title: name, type: .video, duration: nil)
            }
            if let newAsset = newAsset, let idx = mediaAssets.firstIndex(where: { $0.id == asset.id }) {
                mediaAssets[idx] = newAsset
                // TODO: 如果画布区有引用该素材，也应同步替换
            }
        }
    }
} 