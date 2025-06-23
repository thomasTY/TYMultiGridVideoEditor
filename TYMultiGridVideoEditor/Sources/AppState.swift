import SwiftUI
import Combine

class AppState: ObservableObject {
    static let shared = AppState()
    
    @Published var isEditing = false
    
    private init() {} // Private initializer to ensure singleton usage
} 