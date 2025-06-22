import SwiftUI

struct MediaItemView: View {
    let asset: MediaAsset

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            // Thumbnail
            ZStack(alignment: .bottomTrailing) {
                // Placeholder for the thumbnail image
                Rectangle()
                    .fill(Color.gray.opacity(0.4))
                    .aspectRatio(4/3, contentMode: .fit)
                
                // Display duration for videos
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
            }
            .cornerRadius(6)

            // Title
            Text(asset.title)
                .font(.caption)
                .foregroundColor(Theme.secondaryTextColor)
                .lineLimit(1)
                .truncationMode(.middle)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
} 