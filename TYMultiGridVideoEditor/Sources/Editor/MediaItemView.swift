import SwiftUI

struct MediaItemView: View {
    let asset: MediaAsset
    let isSelected: Bool
    let isAddedToCanvas: Bool
    var onDelete: (() -> Void)? = nil
    var onRename: (() -> Void)? = nil
    var onDuplicate: (() -> Void)? = nil
    var onReplace: (() -> Void)? = nil
    
    @State private var isHovering = false

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            // Thumbnail
            ZStack {
                Rectangle()
                    .fill(Color.gray.opacity(0.4))
                    .aspectRatio(4/3, contentMode: .fit)
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
        }
    }
} 