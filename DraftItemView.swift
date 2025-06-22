import SwiftUI

struct DraftItemView: View {
    let draft: Draft

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Placeholder for thumbnail
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .aspectRatio(16/9, contentMode: .fit)
                .cornerRadius(8)
                .overlay(
                    Image(systemName: "film")
                        .font(.largeTitle)
                        .foregroundColor(.white)
                )

            Text(draft.title)
                .font(.headline)
                .lineLimit(1)
        }
        .padding(10)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
        .shadow(radius: 2)
        .contextMenu {
            Button(action: {
                // Action to rename
                print("Rename \(draft.title)")
            }) {
                Text("重命名")
                Image(systemName: "pencil")
            }
            Button(action: {
                // Action to create a copy
                print("Create copy of \(draft.title)")
            }) {
                Text("创建副本")
                Image(systemName: "plus.square.on.square")
            }
            Divider()
            Button(action: {
                // Action to delete
                print("Delete \(draft.title)")
            }) {
                Text("删除")
                Image(systemName: "trash")
            }
        }
    }
}

struct DraftItemView_Previews: PreviewProvider {
    static var previews: some View {
        DraftItemView(draft: Draft(title: "6月10日"))
            .frame(width: 200)
    }
} 