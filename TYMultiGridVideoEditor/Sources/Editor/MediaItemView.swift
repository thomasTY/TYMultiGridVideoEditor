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
    var onDelete: (() -> Void)? = nil
    var onRename: (() -> Void)? = nil
    var onDuplicate: (() -> Void)? = nil
    var onReplace: (() -> Void)? = nil
    
    @State private var isHovering = false

    // 主要内容视图（缩略图），用于正常显示
    private var thumbnailContent: some View {
        Group {
            if let thumbnail = asset.thumbnail {
                Image(nsImage: thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipShape(Rectangle())
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.4))
            }
        }
        .aspectRatio(4/3, contentMode: .fit)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            ZStack {
                thumbnailContent
                // 已添加标签，左上角
                if isAddedToCanvas {
                    VStack {
                        HStack {
                            Text("已添加")
                                .font(.caption2)
                                .fontWeight(.medium)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(Theme.accentColor)
                                .foregroundColor(.white)
                                .cornerRadius(4)
                                .padding(5)
                            Spacer()
                        }
                        Spacer()
                    }
                }
                // 视频素材显示时长，左下角
                VStack {
                    Spacer()
                    HStack {
                        if asset.type == .video, let duration = asset.duration {
                            Text(String(format: "%.1fs", duration))
                                .font(.caption2)
                                .fontWeight(.medium)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(Color.black.opacity(0.6))
                                .foregroundColor(.white)
                                .cornerRadius(4)
                                .padding(5)
                        }
                        Spacer()
                    }
                }
                if isHovering {
                    // "Add to canvas" button on bottom right
                    Button(action: { print("Add \(asset.title) to canvas") }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.white, Theme.accentColor)
                    }
                    .buttonStyle(.plain)
                    .padding(5)
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
                    .padding(5)
                }
            }
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(isSelected ? Theme.accentColor : Color.clear, lineWidth: 2.5)
            )
            // Title
            Text(asset.title)
                .font(.caption)
                .foregroundColor(Theme.secondaryTextColor)
                .lineLimit(1)
                .truncationMode(.middle)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .onHover { hovering in
            isHovering = hovering
        }
        .contextMenu {
            Button("替换素材", systemImage: "arrow.triangle.2.circlepath") {
                onReplace?()
            }
        }
        .onDrag {
            NSItemProvider(object: asset.id.uuidString as NSString)
        } preview: {
            Group {
                if let thumbnail = asset.thumbnail {
                    Image(nsImage: thumbnail)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.4))
                }
            }
            .frame(width: 100, height: 75)
            .cornerRadius(6)
            .clipped()
        }
    }
} 