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
    
    private init() {} // Private initializer to ensure singleton usage
    
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
} 