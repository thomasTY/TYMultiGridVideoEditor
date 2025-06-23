import SwiftUI
import AppKit
import AVFoundation

struct MediaListView: View {
    @ObservedObject private var appState = AppState.shared
    @State private var mediaAssets: [MediaAsset] = MediaAsset.placeholderAssets()
    @State private var selectedAssetIDs = Set<MediaAsset.ID>()
    @State private var itemFrames: [MediaAsset.ID: CGRect] = [:]
    @State private var scrollOffset: CGFloat = 0

    // 用于收集每个单元格frame的PreferenceKey
    struct ItemFramePreferenceKey: PreferenceKey {
        static var defaultValue: [MediaAsset.ID: CGRect] = [:]
        static func reduce(value: inout [MediaAsset.ID: CGRect], nextValue: () -> [MediaAsset.ID: CGRect]) {
            value.merge(nextValue(), uniquingKeysWith: { $1 })
        }
    }

    struct ScrollOffsetPreferenceKey: PreferenceKey {
        static var defaultValue: CGFloat = 0
        static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
            value = nextValue()
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // 顶部工具栏
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
            .background(Theme.headerBackgroundColor)
            // 工具栏和内容区之间加分割线
            Divider().opacity(0.7)

            // 内容区（仅内容区可选区）
            GeometryReader { geo in
                ZStack {
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 110), spacing: 15)], spacing: 15) {
                            ForEach(mediaAssets) { asset in
                                MediaItemView(
                                    asset: asset,
                                    isSelected: selectedAssetIDs.contains(asset.id),
                                    isAddedToCanvas: appState.isAssetInCanvas(asset.id),
                                    selectedAssetIDs: selectedAssetIDs,
                                    onDelete: {
                                        if selectedAssetIDs.contains(asset.id) && selectedAssetIDs.count > 1 {
                                            handleDeleteSelectedAssets()
                                        } else {
                                            deleteAsset(asset)
                                            appState.removeAssetFromCanvas(asset.id)
                                        }
                                    },
                                    onRename: { renameAsset(asset) },
                                    onDuplicate: { duplicateAsset(asset) },
                                    onReplace: { replaceAsset(asset) },
                                    onAddToCanvas: { handleAddToCanvas(asset) }
                                )
                                .onTapGesture { event in
                                    handleSelection(for: asset, with: event)
                                }
                                .background(
                                    GeometryReader { geoItem in
                                        Color.clear
                                            .preference(key: ItemFramePreferenceKey.self, value: [asset.id: geoItem.frame(in: .named("mediaListArea"))])
                                    }
                                )
                            }
                        }
                        .padding(12)
                        // .background(Color(NSColor.windowBackgroundColor).opacity(0.97))
                        .background(
                            GeometryReader { geo in
                                Color.clear
                                    .preference(key: ScrollOffsetPreferenceKey.self, value: geo.frame(in: .named("mediaListArea")).minY)
                            }
                        )
                    }
                    .coordinateSpace(name: "mediaListArea")
                    .onPreferenceChange(ItemFramePreferenceKey.self) { value in
                        itemFrames = value
                    }
                    .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                        scrollOffset = value
                    }
                    .onTapGesture {
                        // Click on empty space to deselect all
                        selectedAssetIDs.removeAll()
                    }
                }
            }
        }
        .background(Theme.secondaryBackgroundColor)
        .cornerRadius(12)
        .clipped()
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.willUpdateNotification)) { _ in
            if let event = NSApp.currentEvent, event.type == .keyDown, event.keyCode == 51 { // 51为Delete键
                handleDeleteSelectedAssets()
            }
        }
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
                    return MediaAsset(title: name, type: .image, url: url)
                } else if ["mp4", "mov", "m4v", "avi", "mkv"].contains(ext) {
                    // 获取视频时长
                    let asset = AVAsset(url: url)
                    let duration = asset.duration.seconds
                    return MediaAsset(title: name, type: .video, duration: duration, url: url)
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
                let oldId = mediaAssets[idx].id
                mediaAssets[idx] = newAsset
                // 同步替换画布中的引用
                appState.replaceAssetInCanvas(oldId: oldId, newId: newAsset.id)
            }
        }
    }
    
    private func handleAddToCanvas(_ asset: MediaAsset) {
        let idsToAdd: [UUID]
        if selectedAssetIDs.contains(asset.id) && selectedAssetIDs.count > 1 {
            idsToAdd = Array(selectedAssetIDs)
        } else {
            idsToAdd = [asset.id]
        }
        for id in idsToAdd {
            appState.addAssetToCanvas(id)
        }
    }
    
    private func handleDeleteSelectedAssets() {
        let idsToDelete = Array(selectedAssetIDs)
        for id in idsToDelete {
            if let asset = mediaAssets.first(where: { $0.id == id }) {
                deleteAsset(asset)
                appState.removeAssetFromCanvas(asset.id)
            }
        }
        selectedAssetIDs.removeAll()
    }
} 
