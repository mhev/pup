import SwiftUI

// MARK: - Modern Route Card

struct ModernRouteCard: View {
    let route: Route
    let isCollapsed: Bool
    let onOptimize: () -> Void
    let onToggleCollapse: () -> Void
    
    @State private var isReasoningExpanded = false
    @EnvironmentObject var viewModel: ScheduleViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: Config.sectionSpacing) {
            if isCollapsed {
                // Collapsed 48px banner
                CollapsedRouteBanner(
                    route: route,
                    onExpand: onToggleCollapse
                )
            } else {
                // Full route card
                FullRouteCard(
                    route: route,
                    isReasoningExpanded: $isReasoningExpanded,
                    onOptimize: onOptimize,
                    onCollapse: onToggleCollapse
                )
            }
        }
    }
}

// MARK: - Collapsed Route Banner

struct CollapsedRouteBanner: View {
    let route: Route
    let onExpand: () -> Void
    
    var body: some View {
        Button(action: onExpand) {
            HStack(spacing: Config.sectionSpacing) {
                // Progress ring (smaller)
                CircularProgressRing(
                    progress: route.efficiency,
                    size: 32,
                    lineWidth: 3
                )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Route Optimized")
                        .font(.system(size: Config.bodyFontSize, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text("\(route.visits.count) visits • \(route.formattedDistance)")
                        .font(.system(size: Config.captionFontSize))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.up")
                    .font(.system(size: Config.captionFontSize, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, Config.cardPadding)
            .padding(.vertical, Config.sectionSpacing)
            .background(
                RoundedRectangle(cornerRadius: Config.cardCornerRadius)
                    .fill(Config.cardBackgroundColor.opacity(0.8))
                    .shadow(
                        color: Config.shadowColor,
                        radius: 2,
                        x: 0,
                        y: 1
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Full Route Card

struct FullRouteCard: View {
    let route: Route
    @Binding var isReasoningExpanded: Bool
    let onOptimize: () -> Void
    let onCollapse: () -> Void
    
    @State private var showingAIInsightsPopup = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: Config.sectionSpacing) {
            // Header with title and progress ring
            HStack(spacing: Config.sectionSpacing) {
                Image(systemName: "location.circle.fill")
                    .font(.system(size: Config.headingFontSize))
                    .foregroundColor(Config.navigationColor)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Optimized Route")
                        .font(.system(size: Config.headingFontSize, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text("AI-powered route optimization")
                        .font(.system(size: Config.captionFontSize))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Circular progress ring
                CircularProgressRing(
                    progress: route.efficiency,
                    size: 48,
                    lineWidth: 4
                )
            }
            
            // Stats pills
            HStack(spacing: Config.sectionSpacing) {
                StatsPill(
                    icon: "location.fill",
                    value: route.formattedDistance,
                    label: "Distance"
                )
                
                StatsPill(
                    icon: "clock.fill",
                    value: route.formattedTravelTime,
                    label: "Travel Time"
                )
                
                StatsPill(
                    icon: "mappin.and.ellipse",
                    value: "\(route.visits.count)",
                    label: "Visits"
                )
            }
            
            // AI Insights (if available)
            if let reasoning = route.aiReasoning {
                Divider()
                    .padding(.vertical, Config.itemSpacing)
                
                VStack(alignment: .leading, spacing: Config.itemSpacing) {
                    Button(action: {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.7, blendDuration: 0)) {
                            showingAIInsightsPopup = true
                        }
                    }) {
                        HStack(spacing: Config.itemSpacing) {
                            Image(systemName: "sparkles")
                                .font(.system(size: Config.bodyFontSize))
                                .foregroundColor(.white)
                            
                            Text("AI Insights")
                                .font(.system(size: Config.bodyFontSize, weight: .semibold))
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: Config.captionFontSize))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .padding(.horizontal, Config.sectionSpacing)
                        .padding(.vertical, Config.sectionSpacing)
                        .background(
                            RoundedRectangle(cornerRadius: Config.chipCornerRadius)
                                .fill(Config.aiInsightColor)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            
            // Action buttons
            HStack(spacing: Config.sectionSpacing) {
                Button(action: onOptimize) {
                    HStack(spacing: Config.itemSpacing) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: Config.captionFontSize))
                        
                        Text("Re-optimize")
                            .font(.system(size: Config.captionFontSize, weight: .medium))
                    }
                    .foregroundColor(Config.navigationColor)
                    .padding(.horizontal, Config.sectionSpacing)
                    .padding(.vertical, Config.itemSpacing)
                    .background(
                        RoundedRectangle(cornerRadius: Config.chipCornerRadius)
                            .fill(Config.navigationColor.opacity(0.1))
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                Spacer()
            }
        }
        .cardStyle()
        .overlay(
            // AI Insights Popup
            AIInsightsPopup(
                isPresented: $showingAIInsightsPopup,
                reasoning: route.aiReasoning ?? ""
            )
        )
    }
}

// MARK: - AI Insights Popup

struct AIInsightsPopup: View {
    @Binding var isPresented: Bool
    let reasoning: String
    
    var body: some View {
        if isPresented {
            ZStack {
                // Background overlay
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8, blendDuration: 0)) {
                            isPresented = false
                        }
                    }
                
                // Popup content
                VStack(alignment: .leading, spacing: Config.sectionSpacing) {
                    // Header
                    HStack(spacing: Config.itemSpacing) {
                        Image(systemName: "sparkles")
                            .font(.system(size: Config.bodyLargeFontSize))
                            .foregroundColor(Config.aiInsightColor)
                        
                        Text("AI Insights")
                            .font(.system(size: Config.bodyLargeFontSize, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Button(action: {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.8, blendDuration: 0)) {
                                isPresented = false
                            }
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: Config.bodyLargeFontSize))
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    // Divider
                    Divider()
                    
                    // Full reasoning text
                    ScrollView {
                        Text(reasoning)
                            .font(.system(size: Config.bodyFontSize))
                            .foregroundColor(.primary)
                            .lineSpacing(6)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.bottom, Config.itemSpacing)
                    }
                    .frame(maxHeight: 450)
                    
                    // Dismiss button
                    Button(action: {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8, blendDuration: 0)) {
                            isPresented = false
                        }
                    }) {
                        HStack {
                            Spacer()
                            Text("Got it")
                                .font(.system(size: Config.bodyFontSize, weight: .medium))
                                .foregroundColor(.white)
                            Spacer()
                        }
                        .padding(.vertical, Config.sectionSpacing)
                        .background(Config.aiInsightColor)
                        .cornerRadius(Config.chipCornerRadius)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(Config.largeSpacing)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Config.cardBackgroundColor)
                        .shadow(color: .black.opacity(0.15), radius: 30, x: 0, y: 15)
                        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                )
                .padding(.horizontal, Config.largeSpacing)
                .scaleEffect(isPresented ? 1.0 : 0.7)
                .opacity(isPresented ? 1.0 : 0.0)
                .animation(.spring(response: 0.6, dampingFraction: 0.7, blendDuration: 0), value: isPresented)
            }
            .transition(.asymmetric(
                insertion: .scale(scale: 0.7).combined(with: .opacity),
                removal: .scale(scale: 0.9).combined(with: .opacity)
            ))
        }
    }
}

// MARK: - Circular Progress Ring

struct CircularProgressRing: View {
    let progress: Double
    let size: CGFloat
    let lineWidth: CGFloat
    
    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(Config.evergreenColor.opacity(0.2), lineWidth: lineWidth)
                .frame(width: size, height: size)
            
            // Progress circle
            Circle()
                .trim(from: 0, to: CGFloat(progress))
                .stroke(
                    progressColor,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: progress)
            
            // Percentage text
            Text("\(Int(progress * 100))%")
                .font(.system(size: size * 0.25, weight: .bold))
                .foregroundColor(progressColor)
        }
    }
    
    private var progressColor: Color {
        switch progress {
        case 0.9...1.0:
            return Config.evergreenColor
        case 0.7..<0.9:
            return Config.navigationColor
        case 0.5..<0.7:
            return .orange
        default:
            return .red
        }
    }
}

// MARK: - Stats Pill

struct StatsPill: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        HStack(spacing: Config.itemSpacing) {
            Image(systemName: icon)
                .font(.system(size: Config.captionFontSize))
                .foregroundColor(Config.evergreenColor)
            
            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(.system(size: Config.bodyFontSize, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(label)
                    .font(.system(size: Config.captionFontSize))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, Config.sectionSpacing)
        .padding(.vertical, Config.itemSpacing)
        .background(
            RoundedRectangle(cornerRadius: Config.chipCornerRadius)
                .fill(Config.evergreenColor.opacity(0.1))
        )
    }
}

// MARK: - Modern Optimize Route Button

struct ModernOptimizeRouteButton: View {
    let visitCount: Int
    let isLoading: Bool
    let onOptimize: () -> Void
    
    @State private var isAnimating = false
    
    var body: some View {
        Button(action: {
            // Haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            
            withAnimation(.easeInOut(duration: 0.3)) {
                isAnimating = true
            }
            
            onOptimize()
        }) {
            HStack(spacing: Config.sectionSpacing) {
                ZStack {
                    Circle()
                        .fill(Config.aiInsightColor.opacity(0.2))
                        .frame(width: 44, height: 44)
                    
                    if isLoading {
                        // Animated loading state
                        ZStack {
                            Circle()
                                .stroke(Config.aiInsightColor.opacity(0.3), lineWidth: 2)
                                .frame(width: 24, height: 24)
                            
                            Circle()
                                .trim(from: 0, to: 0.7)
                                .stroke(Config.aiInsightColor, lineWidth: 2)
                                .frame(width: 24, height: 24)
                                .rotationEffect(.degrees(isAnimating ? 360 : 0))
                                .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: isAnimating)
                        }
                    } else {
                        Image(systemName: "brain")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Config.aiInsightColor)
                            .scaleEffect(isAnimating ? 1.1 : 1.0)
                            .animation(.easeInOut(duration: 0.3), value: isAnimating)
                    }
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(isLoading ? "Optimizing Route..." : "Optimize Route")
                        .font(.system(size: Config.bodyLargeFontSize, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    if isLoading {
                        Text("AI is calculating the best route")
                            .font(.system(size: Config.captionFontSize))
                            .foregroundColor(.secondary)
                    } else {
                        Text("Get AI-powered route optimization for \(visitCount) visits")
                            .font(.system(size: Config.captionFontSize))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                if !isLoading {
                    Image(systemName: "chevron.right")
                        .font(.system(size: Config.captionFontSize))
                        .foregroundColor(.secondary)
                }
            }
            .cardStyle()
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isLoading)
        .onChange(of: isLoading) { loading in
            if loading {
                isAnimating = true
            } else {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isAnimating = false
                }
            }
        }
    }
} 