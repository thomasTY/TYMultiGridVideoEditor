import SwiftUI

struct MediaItemView: View {
    let asset: MediaAsset
    let isSelected: Bool
    var onDelete: (() -> Void)? = nil
    var onRename: (() -> Void)? = nil
    var onDuplicate: (() -> Void)? = nil
    
    @State private var isHovering = false

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            // Thumbnail
            ZStack(alignment: .bottomTrailing) {
                // Placeholder for the thumbnail image
                Rectangle()
                    .fill(Color.gray.opacity(0.4))
                    .aspectRatio(4/3, contentMode: .fit)
                
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
                
                // Display duration for videos
                if asset.type == .video, let duration = asset.duration, !isHovering {
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
            Button("重命名", systemImage: "pencil", action: { onRename?() })
            Button("创建副本", systemImage: "plus.square.on.square", action: { onDuplicate?() })
            Divider()
            Button("删除", systemImage: "trash", role: .destructive, action: { onDelete?() })
        }
    }
} 