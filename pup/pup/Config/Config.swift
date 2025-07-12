import Foundation
import SwiftUI

struct Config {
    // MARK: - API Configuration
    
    /// Add your Google Gemini API key here
    /// Get your free API key at: https://makersuite.google.com/app/apikey
    static let geminiAPIKey = "AIzaSyBjgqsPWquP8d159a9NOEwm69zGJ9MFFmU"
    
    // MARK: - App Settings
    static let appName = "Martina"
    static let appVersion = "1.0.0"
    
    // MARK: - Color Scheme (Redesigned)
    static let primaryColor = Color(hex: "CDE3D3") // Mint-green background
    static let evergreenColor = Color(hex: "2E674E") // Primary action buttons
    static let cardBackgroundColor = Color(hex: "FDFDFD") // Off-white cards
    static let accentColor = Color(hex: "2E674E") // Keep consistent with evergreen
    static let buttonTextColor = Color.white
    
    // Accent colors for specific purposes
    static let aiInsightColor = Color.purple
    static let navigationColor = Color.blue
    static let shadowColor = Color.black.opacity(0.08)
    
    // MARK: - Design Tokens
    
    // Typography
    static let bodyFontSize: CGFloat = 15
    static let bodyLargeFontSize: CGFloat = 16
    static let headingFontSize: CGFloat = 20
    static let largeTitleFontSize: CGFloat = 24
    static let captionFontSize: CGFloat = 12
    
    // Spacing
    static let cardPadding: CGFloat = 12 // Reduced from 16 for more compact design
    static let sectionSpacing: CGFloat = 8
    static let itemSpacing: CGFloat = 6
    static let largeSpacing: CGFloat = 16
    
    // Corner Radius
    static let cardCornerRadius: CGFloat = 12
    static let buttonCornerRadius: CGFloat = 8
    static let chipCornerRadius: CGFloat = 6
    
    // Shadows
    static let cardShadowRadius: CGFloat = 4 // Soft 4dp shadow
    static let cardShadowOffset = CGSize(width: 0, height: 2)
    
    // MARK: - Route Optimization Settings
    static let defaultEfficiencyThreshold = 0.8
    static let maxOptimizationRetries = 3
    static let fallbackToBasicOptimization = true
}

// Color extension to support hex colors
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
            (a, r, g, b) = (1, 1, 1, 0)
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

// MARK: - Design System Extensions

extension View {
    func cardStyle() -> some View {
        self
            .padding(Config.cardPadding)
            .background(
                RoundedRectangle(cornerRadius: Config.cardCornerRadius)
                    .fill(Config.cardBackgroundColor)
                    .shadow(
                        color: Config.shadowColor,
                        radius: Config.cardShadowRadius,
                        x: Config.cardShadowOffset.width,
                        y: Config.cardShadowOffset.height
                    )
            )
    }
    
    func primaryButton() -> some View {
        self
            .foregroundColor(Config.buttonTextColor)
            .padding(.horizontal, Config.largeSpacing)
            .padding(.vertical, Config.sectionSpacing)
            .background(
                RoundedRectangle(cornerRadius: Config.buttonCornerRadius)
                    .fill(Config.evergreenColor)
            )
    }
    
    func iconChip(color: Color = Config.evergreenColor) -> some View {
        self
            .font(.system(size: Config.captionFontSize, weight: .medium))
            .foregroundColor(color)
            .padding(.horizontal, Config.sectionSpacing)
            .padding(.vertical, Config.itemSpacing)
            .background(
                RoundedRectangle(cornerRadius: Config.chipCornerRadius)
                    .fill(color.opacity(0.1))
            )
    }
} 
