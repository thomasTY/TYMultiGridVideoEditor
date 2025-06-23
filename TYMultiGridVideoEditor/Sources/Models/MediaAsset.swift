import Foundation

enum AssetType {
    case video
    case image
}

struct MediaAsset: Identifiable, Hashable {
    let id = UUID()
    var title: String
    var type: AssetType
    var duration: TimeInterval? // nil for images

    static func placeholderAssets() -> [MediaAsset] {
        [
            MediaAsset(title: "seaside_waves.mp4", type: .video, duration: 15.3),
            MediaAsset(title: "mountain_peak.jpg", type: .image),
            MediaAsset(title: "forest_stream.mp4", type: .video, duration: 32.8),
            MediaAsset(title: "city_skyline.jpg", type: .image),
            MediaAsset(title: "sunset_lapse.mp4", type: .video, duration: 25.0),
            MediaAsset(title: "cat_on_sofa.jpg", type: .image),
            MediaAsset(title: "drone_shot.mp4", type: .video, duration: 59.1),
        ]
    }
} 