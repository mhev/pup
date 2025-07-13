import SwiftUI

// MARK: - Modern Empty State

struct ModernEmptyState: View {
    let selectedDate: Date
    let isToday: Bool
    let onAddVisit: () -> Void
    
    var body: some View {
        VStack(spacing: Config.largeSpacing) {
            // Illustration and content removed for clean empty state
            
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
        .padding(.vertical, Config.largeSpacing)
    }
    
    // emptyTitle and emptyMessage properties removed - no longer needed
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