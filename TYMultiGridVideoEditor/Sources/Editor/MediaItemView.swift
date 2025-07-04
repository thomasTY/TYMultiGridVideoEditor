import SwiftUI
import AppKit
import AVFoundation

// 可拖拽的 NSView 包装器
struct DraggableView: NSViewRepresentable {
    let asset: MediaAsset
    
    func makeNSView(context: Context) -> NSView {
        let view = DragSourceView(asset: asset)
        view.wantsLayer = true
        view.layer?.cornerRadius = 6
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {}
}

// 自定义 NSView 处理拖拽
class DragSourceView: NSView, NSDraggingSource {
    let asset: MediaAsset
    
    init(asset: MediaAsset) {
        self.asset = asset
        super.init(frame: .zero)
        registerForDraggedTypes([.string])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func mouseDown(with event: NSEvent) {
        guard let thumbnail = asset.thumbnail else { return }
        
        let dragItem = NSPasteboardItem()
        dragItem.setString(asset.id.uuidString, forType: .string)
        
        // 创建纯图片预览
        let dragImage = NSImage(size: NSSize(width: 100, height: 75))
        dragImage.lockFocus()
        if let cgContext = NSGraphicsContext.current?.cgContext {
            cgContext.setFillColor(NSColor.clear.cgColor)
            cgContext.fill(NSRect(x: 0, y: 0, width: 100, height: 75))
            
            // 绘制图片，保持比例
            let imageRect = AVMakeRect(aspectRatio: thumbnail.size, insideRect: NSRect(x: 0, y: 0, width: 100, height: 75))
            thumbnail.draw(in: imageRect,
                         from: NSRect(x: 0, y: 0, width: thumbnail.size.width, height: thumbnail.size.height),
                         operation: .sourceOver,
                         fraction: 1.0)
        }
        dragImage.unlockFocus()
        
        // 开始拖拽会话
        let draggingItem = NSDraggingItem(pasteboardWriter: dragItem)
        draggingItem.setDraggingFrame(NSRect(origin: .zero, size: dragImage.size), contents: dragImage)
        
        beginDraggingSession(with: [draggingItem], event: event, source: self)
    }
    
    // NSDraggingSource 协议方法（可空实现）
    func draggingSession(_ session: NSDraggingSession, sourceOperationMaskFor context: NSDraggingContext) -> NSDragOperation {
        return .copy
    }
}

struct MediaItemView: View {
    let asset: MediaAsset
    let isSelected: Bool
    let isAddedToCanvas: Bool
    var selectedAssetIDs: Set<MediaAsset.ID> = []
    var onDelete: (() -> Void)? = nil
    var onRename: (() -> Void)? = nil
    var onDuplicate: (() -> Void)? = nil
    var onReplace: (() -> Void)? = nil
    var onAddToCanvas: (() -> Void)? = nil
    
    @State private var isHovering = false

    // 工具函数：将秒数格式化为 mm:ss
    private func formatDuration(_ duration: Double) -> String {
        let totalSeconds = Int(duration)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    // 主要内容视图（缩略图），用于正常显示
    private var thumbnailContent: some View {
        Group {
            if let thumbnail = asset.thumbnail {
                Image(nsImage: thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: .fit)  // 改为.fit以完整显示内容
                    .frame(width: 110, height: 82.5)  // 固定宽高，保持4:3比例
                    .background(Color.black.opacity(0.2))  // 添加背景色以显示空白区域
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.4))
                    .frame(width: 110, height: 82.5)
            }
        }
        .cornerRadius(6)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ZStack(alignment: .center) {
                thumbnailContent
                // 已添加标签，左上角
                if isAddedToCanvas {
                    VStack {
                        HStack {
                            Text("已添加")
                                .font(.caption2)
                                .fontWeight(.medium)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(Theme.accentColor)
                                .foregroundColor(.white)
                                .cornerRadius(3)
                            Spacer()
                        }
                        Spacer()
                    }
                    .padding(4)
                }
                // 视频素材显示时长，左下角
                VStack {
                    Spacer()
                    HStack {
                        if asset.type == .video, let duration = asset.duration {
                            Text(formatDuration(duration))
                                .font(.caption2)
                                .fontWeight(.medium)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(Color.black.opacity(0.6))
                                .foregroundColor(.white)
                                .cornerRadius(3)
                            Spacer()
                        }
                    }
                    .padding(4)
                }
                if isHovering {
                    // "Add to canvas" button on bottom right
                    Button(action: { onAddToCanvas?() }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.white, Theme.accentColor)
                    }
                    .buttonStyle(.plain)
                    .padding(4)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                    // "Delete" button on top right
                    HStack {
                        Spacer()
                        VStack {
                            Button(action: { onDelete?() }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.title3)
                                    .symbolRenderingMode(.palette)
                                    .foregroundStyle(.black.opacity(0.6), Color(NSColor.controlBackgroundColor))
                            }
                            .buttonStyle(.plain)
                            Spacer()
                        }
                    }
                    .padding(4)
                }
            }
            .frame(width: 110, height: 82.5)  // 确保ZStack也是固定大小
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(isSelected ? Theme.accentColor : Color.clear, lineWidth: 2)
            )
            // Title
            Text(asset.title)
                .font(.caption2)  // 使用更小的字体
                .foregroundColor(Theme.secondaryTextColor)
                .lineLimit(1)
                .truncationMode(.middle)
                .frame(width: 110, alignment: .leading)  // 固定宽度，确保文字不会超出
        }
        .frame(width: 110)  // 整个VStack固定宽度
        .onHover { hovering in
            isHovering = hovering
        }
        .contextMenu {
            Button("替换素材", systemImage: "arrow.triangle.2.circlepath") {
                onReplace?()
            }
        }
        .onDrag {
            // 多选拖拽：传递所有选中id，否则只传当前id
            let ids = selectedAssetIDs.isEmpty ? [asset.id] : Array(selectedAssetIDs)
            let idString = ids.map { $0.uuidString }.joined(separator: ",")
            return NSItemProvider(object: idString as NSString)
        } preview: {
            thumbnailContent
        }
    }
} 