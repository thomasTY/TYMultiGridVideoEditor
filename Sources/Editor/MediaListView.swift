import SwiftUI

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

                Button(action: { print("Import button clicked") }) {
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
                        MediaItemView(asset: asset, isSelected: selectedAssetIDs.contains(asset.id))
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
} 