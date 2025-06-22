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
                        MediaItemView(asset: asset)
                            .padding(3)
                            .background(selectedAssetIDs.contains(asset.id) ? Theme.accentColor : Color.clear)
                            .cornerRadius(8)
                            .onTapGesture {
                                // Toggle selection
                                if selectedAssetIDs.contains(asset.id) {
                                    selectedAssetIDs.remove(asset.id)
                                } else {
                                    selectedAssetIDs.insert(asset.id)
                                }
                            }
                    }
                }
                .padding(12)
            }
        }
        .background(Theme.secondaryBackgroundColor)
        .cornerRadius(12)
        .clipped()
    }
} 