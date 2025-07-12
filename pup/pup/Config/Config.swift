import Foundation
import SwiftUI

struct Config {
    // MARK: - API Configuration
    
    /// Google Gemini API key loaded from secure configuration
    /// Get your free API key at: https://makersuite.google.com/app/apikey
    static let geminiAPIKey: String = {
        // First try to load from a secure config file
        if let path = Bundle.main.path(forResource: "APIKeys", ofType: "plist"),
           let plist = NSDictionary(contentsOfFile: path),
           let apiKey = plist["GeminiAPIKey"] as? String,
           !apiKey.isEmpty {
            print("✅ Successfully loaded Gemini API key from APIKeys.plist")
            return apiKey
        }
        
        // Fallback to environment variable (useful for CI/CD)
        if let apiKey = ProcessInfo.processInfo.environment["GEMINI_API_KEY"],
           !apiKey.isEmpty {
            print("✅ Successfully loaded Gemini API key from environment variable")
            return apiKey
        }
        
        // If neither works, return empty string and the app will handle the error
        print("⚠️ Warning: No Gemini API key found. Please add your API key to APIKeys.plist")
        print("📝 Instructions: Copy APIKeys.plist.template to APIKeys.plist and add your key")
        return ""
    }()
    
    /// Validate that the API key is properly configured
    static func validateAPIKey() -> Bool {
        let isValid = !geminiAPIKey.isEmpty && geminiAPIKey != "YOUR_GEMINI_API_KEY_HERE"
        if isValid {
            print("✅ API key validation passed")
        } else {
            print("❌ API key validation failed - please check your APIKeys.plist configuration")
        }
        return isValid
    }
    
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
    
    // Translucent header colors
    static let headerBackgroundColor = Color(hex: "CDE3D3").opacity(0.85) // Translucent mint
    static let headerBlurColor = Color(hex: "CDE3D3").opacity(0.95)
    
    // Context colors
    static let mileageColor = Color(hex: "FF6B35") // Orange for mileage 🚗
    static let tipsColor = Color(hex: "FFD700") // Gold for tips 💰
    static let visitsColor = Color(hex: "4A90E2") // Blue for visits 🐾
    static let incomeColor = Color(hex: "32CD32") // Green for income
    
    // Context colors structure
    static let contextColors = (
        mileage: mileageColor,
        tips: tipsColor,
        visits: visitsColor,
        income: incomeColor
    )
    
    // MARK: - Design Tokens
    
    // Typography
    static let bodyFontSize: CGFloat = 15
    static let bodyLargeFontSize: CGFloat = 16
    static let headingFontSize: CGFloat = 20
    static let largeTitleFontSize: CGFloat = 24
    static let largeFontSize: CGFloat = 32
    static let captionFontSize: CGFloat = 12
    
    // Spacing
    static let cardPadding: CGFloat = 12 // Reduced from 16 for more compact design
    static let sectionSpacing: CGFloat = 8
    static let smallSpacing: CGFloat = 4
    static let itemSpacing: CGFloat = 6
    static let largeSpacing: CGFloat = 16
    
    // Corner Radius
    static let cardCornerRadius: CGFloat = 12
    static let buttonCornerRadius: CGFloat = 8
    static let chipCornerRadius: CGFloat = 6
    static let smallCornerRadius: CGFloat = 4
    
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
    
    func translucentHeader() -> some View {
        self
            .background(
                ZStack {
                    // Blur background
                    RoundedRectangle(cornerRadius: Config.cardCornerRadius)
                        .fill(Config.headerBlurColor)
                        .background(.ultraThinMaterial)
                    
                    // Subtle shadow for depth
                    RoundedRectangle(cornerRadius: Config.cardCornerRadius)
                        .fill(Config.shadowColor)
                        .offset(y: 1)
                }
            )
    }
    
    func contextIcon(_ emoji: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Text(emoji)
                .font(.system(size: 14))
            self
                .foregroundColor(color)
        }
        .font(.system(size: Config.captionFontSize, weight: .medium))
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: Config.chipCornerRadius)
                .fill(color.opacity(0.1))
        )
    }
} 

// MARK: - Context Icons Helper
struct ContextIcons {
    static let mileage = "🚗"
    static let tips = "💰"
    static let visits = "🐾"
    static let income = "💵"
    static let reminders = "⏰"
    static let analytics = "📊"
    static let route = "🗺️"
    static let ai = "🤖"
}
