import SwiftUI
import Combine

class AppState: ObservableObject {
    static let shared = AppState()
    
    @Published var isEditing = false
    @Published var drafts: [Draft] = [
        Draft(title: "6月10日"),
        Draft(title: "6月9日"),
        Draft(title: "6月8日")
    ]
    @Published var currentEditingDraftId: UUID? = nil
    @Published var assetsInCanvas = Set<UUID>()  // 追踪画布中的素材ID
    @Published var canvasAssets: [UUID] = []  // 新增：全局画布素材ID数组
    @Published var mediaAssets: [MediaAsset] = MediaAsset.placeholderAssets() // 新增：全局素材详情数组
    
    private let draftsFileName = "drafts.json"
    private var draftsFileURL: URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return dir.appendingPathComponent(draftsFileName)
    }

    private func saveDrafts() {
        let arr = drafts.map { [
            "title": $0.title,
            "coverImageName": $0.coverImageName ?? "",
            "openCount": $0.openCount
        ] }
        if let data = try? JSONSerialization.data(withJSONObject: arr) {
            try? data.write(to: draftsFileURL)
        }
    }

    private func loadDrafts() {
        guard let data = try? Data(contentsOf: draftsFileURL),
              let arr = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else { return }
        let loaded = arr.compactMap { dict -> Draft? in
            if let title = dict["title"] as? String {
                let cover = dict["coverImageName"] as? String
                let openCount = dict["openCount"] as? Int ?? 0
                return Draft(title: title, coverImageName: cover, openCount: openCount)
            }
            return nil
        }
        if !loaded.isEmpty {
            drafts = loaded
        }
    }

    // 监听drafts变化自动保存
    private var cancellable: AnyCancellable?
    private init() {
        loadDrafts()
        cancellable = $drafts.sink { [weak self] _ in
            self?.saveDrafts()
        }
    }
    
    func deleteDraft(id: UUID) {
        drafts.removeAll { $0.id == id }
    }
    
    func duplicateDraft(id: UUID) {
        guard let original = drafts.first(where: { $0.id == id }) else { return }
        let baseTitle = original.title.replacingOccurrences(of: " 副本", with: "")
        let newTitle = baseTitle + " 副本"
        let newDraft = Draft(title: newTitle)
        if let idx = drafts.firstIndex(where: { $0.id == id }) {
            drafts.insert(newDraft, at: idx + 1)
        } else {
            drafts.append(newDraft)
        }
    }
    
    func renameDraft(id: UUID, newTitle: String) {
        guard let idx = drafts.firstIndex(where: { $0.id == id }) else { return }
        drafts[idx].title = newTitle
    }
    
    func createDraft() -> Draft {
        // 获取当前日期字符串，如"6月10日"
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "zh_CN")
        dateFormatter.dateFormat = "M月d日"
        let baseTitle = dateFormatter.string(from: Date())
        
        // 查找已有同名草稿，统计编号
        let sameDayDrafts = drafts.filter { $0.title == baseTitle || $0.title.hasPrefix(baseTitle + "-") }
        var newTitle = baseTitle
        if !sameDayDrafts.isEmpty {
            // 找最大编号
            let numbers = sameDayDrafts.compactMap { draft -> Int? in
                let parts = draft.title.components(separatedBy: "-")
                if parts.count == 2, let num = Int(parts[1]) { return num }
                return nil
            }
            let nextNum = (numbers.max() ?? 0) + 1
            newTitle = "\(baseTitle)-\(nextNum)"
        }
        let draft = Draft(title: newTitle)
        drafts.insert(draft, at: 0)
        currentEditingDraftId = draft.id
        return draft
    }
    
    func importDraftFromJSON(url: URL) -> Draft? {
        do {
            let data = try Data(contentsOf: url)
            if let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let title = dict["title"] as? String {
                let draft = Draft(title: title)
                drafts.insert(draft, at: 0)
                currentEditingDraftId = draft.id
                return draft
            }
        } catch {
            print("导入草稿失败: \(error)")
        }
        return nil
    }
    
    func incrementDraftOpenCount(id: UUID) {
        guard let idx = drafts.firstIndex(where: { $0.id == id }) else { return }
        drafts[idx].openCount += 1
        // 更新标题编号
        let baseTitle = drafts[idx].title.components(separatedBy: "(").first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? drafts[idx].title
        if drafts[idx].openCount > 0 {
            drafts[idx].title = "\(baseTitle)(\(drafts[idx].openCount))"
        } else {
            drafts[idx].title = baseTitle
        }
        saveDrafts()
    }
    
    func addAssetToCanvas(_ assetId: UUID) {
        assetsInCanvas.insert(assetId)
    }
    
    func removeAssetFromCanvas(_ assetId: UUID) {
        assetsInCanvas.remove(assetId)
    }
    
    func isAssetInCanvas(_ assetId: UUID) -> Bool {
        return assetsInCanvas.contains(assetId)
    }
    
    func replaceAssetInCanvas(oldId: UUID, newId: UUID) {
        for i in 0..<canvasAssets.count {
            if canvasAssets[i] == oldId {
                canvasAssets[i] = newId
            }
        }
    }
} 