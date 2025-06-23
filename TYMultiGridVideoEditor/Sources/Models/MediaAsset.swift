import Foundation
import AppKit
import AVFoundation

enum AssetType {
    case video
    case image
}

struct MediaAsset: Identifiable, Hashable {
    let id = UUID()
    var title: String
    var type: AssetType
    var duration: TimeInterval? // nil for images
    var url: URL?  // 文件路径
    
    // 获取缩略图
    var thumbnail: NSImage? {
        guard let url = url else { return nil }
        
        if type == .image {
            return NSImage(contentsOf: url)
        } else {
            let asset = AVAsset(url: url)
            let imageGenerator = AVAssetImageGenerator(asset: asset)
            imageGenerator.appliesPreferredTrackTransform = true
            
            do {
                let cgImage = try imageGenerator.copyCGImage(at: .zero, actualTime: nil)
                return NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
            } catch {
                print("Error generating thumbnail: \(error)")
                return nil
            }
        }
    }
    
    init(title: String, type: AssetType, duration: TimeInterval? = nil, url: URL? = nil) {
        self.title = title
        self.type = type
        self.duration = duration
        self.url = url
    }

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
    
    // Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: MediaAsset, rhs: MediaAsset) -> Bool {
        lhs.id == rhs.id
    }
} 