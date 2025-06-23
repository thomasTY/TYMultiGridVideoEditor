import Foundation

struct Draft: Identifiable {
    let id = UUID()
    var title: String
    var coverImageName: String? = nil // 可选首帧图字段，后续可扩展为图片路径或缩略图数据
} 