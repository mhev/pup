import SwiftUI

// MARK: - Modern Empty State

struct ModernEmptyState: View {
    let selectedDate: Date
    let isToday: Bool
    let onAddVisit: () -> Void
    
    var body: some View {
        VStack(spacing: Config.largeSpacing) {
            // Illustration
            ZStack {
                // Background circles for depth
                Circle()
                    .fill(Config.evergreenColor.opacity(0.1))
                    .frame(width: 120, height: 120)
                    .offset(x: -10, y: -10)
                
                Circle()
                    .fill(Config.aiInsightColor.opacity(0.1))
                    .frame(width: 100, height: 100)
                    .offset(x: 10, y: 10)
                
                // Main icon
                Image(systemName: "calendar.badge.plus")
                    .font(.system(size: 48, weight: .light))
                    .foregroundColor(Config.evergreenColor.opacity(0.3))
                    .symbolEffect(.pulse.wholeSymbol, options: .repeating)
            }
            
            // Content
            VStack(spacing: Config.sectionSpacing) {
                Text(emptyTitle)
                    .font(.system(size: Config.headingFontSize, weight: .semibold))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                
                Text(emptyMessage)
                    .font(.system(size: Config.bodyFontSize))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
            }
            
            // Action button
            Button(action: {
                // Haptic feedback
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred()
                
                onAddVisit()
            }) {
                HStack(spacing: Config.sectionSpacing) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: Config.bodyFontSize))
                    
                    Text("Add Your First Visit")
                        .font(.system(size: Config.bodyFontSize, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, Config.largeSpacing)
                .padding(.vertical, Config.sectionSpacing)
                .background(
                    RoundedRectangle(cornerRadius: Config.buttonCornerRadius)
                        .fill(Config.evergreenColor)
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, Config.largeSpacing * 2)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            // Subtle pattern background
            GeometryReader { geometry in
                Path { path in
                    let size = geometry.size
                    let step: CGFloat = 40
                    
                    for x in stride(from: 0, through: size.width, by: step) {
                        for y in stride(from: 0, through: size.height, by: step) {
                            let rect = CGRect(x: x, y: y, width: 2, height: 2)
                            path.addEllipse(in: rect)
                        }
                    }
                }
                .fill(Config.evergreenColor.opacity(0.03))
            }
        )
    }
    
    private var emptyTitle: String {
        if isToday {
            return "Ready to start your day?"
        } else {
            return "No visits planned yet"
        }
    }
    
    private var emptyMessage: String {
        if isToday {
            return "Add your first visit to get started with AI-powered route optimization and make your pet care schedule more efficient."
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE, MMM d"
            return "No visits are scheduled for \(formatter.string(from: selectedDate)). Add a visit to start planning your route."
        }
    }
}

// MARK: - Compact Empty State

struct CompactEmptyState: View {
    let message: String
    let actionTitle: String
    let onAction: () -> Void
    
    var body: some View {
        VStack(spacing: Config.sectionSpacing) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 32, weight: .light))
                .foregroundColor(Config.evergreenColor.opacity(0.4))
            
            Text(message)
                .font(.system(size: Config.bodyFontSize))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: onAction) {
                Text(actionTitle)
                    .font(.system(size: Config.bodyFontSize, weight: .medium))
                    .foregroundColor(Config.evergreenColor)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(Config.largeSpacing)
    }
}

// MARK: - Loading State

struct LoadingState: View {
    let message: String
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: Config.largeSpacing) {
            ZStack {
                Circle()
                    .stroke(Config.evergreenColor.opacity(0.2), lineWidth: 3)
                    .frame(width: 40, height: 40)
                
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(Config.evergreenColor, lineWidth: 3)
                    .frame(width: 40, height: 40)
                    .rotationEffect(.degrees(isAnimating ? 360 : 0))
                    .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: isAnimating)
            }
            
            Text(message)
                .font(.system(size: Config.bodyFontSize))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(Config.largeSpacing)
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Error State

struct ErrorState: View {
    let title: String
    let message: String
    let actionTitle: String
    let onAction: () -> Void
    
    var body: some View {
        VStack(spacing: Config.largeSpacing) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40, weight: .light))
                .foregroundColor(.orange.opacity(0.8))
            
            VStack(spacing: Config.sectionSpacing) {
                Text(title)
                    .font(.system(size: Config.headingFontSize, weight: .semibold))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                
                Text(message)
                    .font(.system(size: Config.bodyFontSize))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
            }
            
            Button(action: onAction) {
                Text(actionTitle)
                    .font(.system(size: Config.bodyFontSize, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, Config.largeSpacing)
                    .padding(.vertical, Config.sectionSpacing)
                    .background(
                        RoundedRectangle(cornerRadius: Config.buttonCornerRadius)
                            .fill(Config.evergreenColor)
                    )
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, Config.largeSpacing * 2)
    }
} 