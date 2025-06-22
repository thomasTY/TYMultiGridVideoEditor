import SwiftUI

struct Theme {
    /// The darkest background color, used for the main window background.
    static let primaryBackgroundColor = Color(hex: "#181818")
    
    /// A slightly lighter dark color for panels and components.
    static let secondaryBackgroundColor = Color(hex: "#252525")
    
    /// The color for the canvas/player background.
    static let playerBackgroundColor = Color(hex: "#0E0E0E")
    
    /// The main accent color for selections and highlights.
    static let accentColor = Color(hex: "#00A99D")
    
    /// The gradient for the prominent "Start Creating" button.
    static let creationGradient = LinearGradient(
        colors: [Color(hex: "#00C2B3"), Color(hex: "#007AFF")],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    /// Bright text for titles and headings.
    static let primaryTextColor = Color(hex: "#EAEAEA")
    
    /// Dimmer text for subtitles and body content.
    static let secondaryTextColor = Color(hex: "#A0A0A5")
}

// Helper to allow creating Colors from hex strings.
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
} 