import SwiftUI

struct DraftItemView: View {
    let draft: Draft
    var onRename: () -> Void
    var onDuplicate: () -> Void
    var onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let cover = draft.coverImageName, !cover.isEmpty, let img = NSImage(named: cover) {
                Image(nsImage: img)
                    .resizable()
                    .aspectRatio(16/9, contentMode: .fit)
                    .cornerRadius(8)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .aspectRatio(16/9, contentMode: .fit)
                    .cornerRadius(8)
                    .overlay(Image(systemName: "film").font(.largeTitle).foregroundColor(.white))
            }

            Text(draft.title)
                .font(.headline)
                .foregroundColor(Theme.primaryTextColor)
                .lineLimit(1)
                .truncationMode(.middle)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(10)
        .background(Theme.secondaryBackgroundColor)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 2)
        .contextMenu {
            Button("重命名", systemImage: "pencil") { onRename() }
            Button("创建副本", systemImage: "plus.square.on.square") { onDuplicate() }
            Divider()
            Button("删除", systemImage: "trash", role: .destructive) { onDelete() }
        }
    }
} 