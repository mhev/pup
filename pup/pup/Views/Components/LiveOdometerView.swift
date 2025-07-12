import SwiftUI

struct LiveOdometerView: View {
    @StateObject private var mileageService = MileageTrackingService.shared
    @StateObject private var subscriptionService = SubscriptionService.shared
    @State private var isExpanded = false
    @State private var showingSubscriptionPaywall = false
    
    var body: some View {
        if subscriptionService.isPremium {
            premiumOdometerView
        } else {
            lockedOdometerView
        }
    }
    
    private var premiumOdometerView: some View {
        VStack(spacing: 0) {
            // Main odometer display
            HStack(spacing: Config.itemSpacing) {
                // Tracking indicator
                if mileageService.isTracking {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)
                            .scaleEffect(1.2)
                            .animation(.easeInOut(duration: 0.5).repeatForever(), value: mileageService.isTracking)
                        
                        Text("LIVE")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.green)
                    }
                } else {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.secondary)
                            .frame(width: 8, height: 8)
                        
                        Text("IDLE")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.secondary)
                    }
                }
                
                // Current trip distance
                VStack(alignment: .trailing, spacing: 2) {
                    Text(formattedTripDistance)
                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                        .foregroundColor(mileageService.isTracking ? Config.mileageColor : .primary)
                    
                    Text("Trip")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, Config.cardPadding)
            .padding(.vertical, Config.itemSpacing)
            .background(
                RoundedRectangle(cornerRadius: Config.cardCornerRadius)
                    .fill(Config.cardBackgroundColor.opacity(0.95))
                    .shadow(color: Config.shadowColor, radius: 4, x: 0, y: 2)
            )
            .onTapGesture {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isExpanded.toggle()
                }
            }
            
            // Expanded details
            if isExpanded {
                expandedDetailsView
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .move(edge: .top).combined(with: .opacity)
                    ))
            }
        }
    }
    
    private var expandedDetailsView: some View {
        VStack(spacing: Config.itemSpacing) {
            // Today's total
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Today's Total")
                        .font(.system(size: Config.captionFontSize, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    Text(formattedTodaysMileage)
                        .font(.system(size: Config.bodyFontSize, weight: .semibold, design: .monospaced))
                        .foregroundColor(Config.mileageColor)
                }
                
                Spacer()
                
                // Estimated deduction
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Est. Deduction")
                        .font(.system(size: Config.captionFontSize, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    Text(formattedDeduction)
                        .font(.system(size: Config.bodyFontSize, weight: .semibold, design: .monospaced))
                        .foregroundColor(Config.incomeColor)
                }
            }
            
            // Control buttons
            HStack(spacing: Config.itemSpacing) {
                if mileageService.isTracking {
                    Button(action: {
                        mileageService.stopTracking()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "stop.fill")
                                .font(.system(size: Config.captionFontSize))
                            Text("Stop")
                                .font(.system(size: Config.captionFontSize, weight: .medium))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: Config.chipCornerRadius)
                                .fill(Color.red)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                } else {
                    Button(action: {
                        mileageService.startTracking()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "play.fill")
                                .font(.system(size: Config.captionFontSize))
                            Text("Start")
                                .font(.system(size: Config.captionFontSize, weight: .medium))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: Config.chipCornerRadius)
                                .fill(Config.evergreenColor)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                Spacer()
                
                // Collapse button
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isExpanded = false
                    }
                }) {
                    Image(systemName: "chevron.up")
                        .font(.system(size: Config.captionFontSize))
                        .foregroundColor(.secondary)
                        .padding(6)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, Config.cardPadding)
        .padding(.vertical, Config.itemSpacing)
        .background(
            RoundedRectangle(cornerRadius: Config.cardCornerRadius)
                .fill(Config.cardBackgroundColor.opacity(0.95))
                .shadow(color: Config.shadowColor, radius: 4, x: 0, y: 2)
        )
        .padding(.top, 2)
    }
    
    private var lockedOdometerView: some View {
        HStack(spacing: Config.itemSpacing) {
            Image(systemName: "lock.fill")
                .font(.system(size: Config.captionFontSize))
                .foregroundColor(.secondary)
            
            Text("Odometer")
                .font(.system(size: Config.captionFontSize, weight: .medium))
                .foregroundColor(.secondary)
            
            Spacer()
            
            Button(action: {
                showingSubscriptionPaywall = true
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: Config.captionFontSize))
                    Text("Upgrade")
                        .font(.system(size: Config.captionFontSize, weight: .medium))
                }
                .foregroundColor(Config.evergreenColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: Config.chipCornerRadius)
                        .fill(Config.evergreenColor.opacity(0.1))
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, Config.cardPadding)
        .padding(.vertical, Config.itemSpacing)
        .background(
            RoundedRectangle(cornerRadius: Config.cardCornerRadius)
                .fill(Config.cardBackgroundColor.opacity(0.95))
                .shadow(color: Config.shadowColor, radius: 4, x: 0, y: 2)
        )
        .sheet(isPresented: $showingSubscriptionPaywall) {
            SubscriptionPaywallView(isPresented: $showingSubscriptionPaywall)
        }
    }
    
    // MARK: - Computed Properties
    
    private var formattedTripDistance: String {
        return String(format: "%.1f mi", mileageService.currentTripDistance)
    }
    
    private var formattedTodaysMileage: String {
        return String(format: "%.1f mi", mileageService.todaysMileage)
    }
    
    private var formattedDeduction: String {
        let deduction = mileageService.todaysMileage * 0.67
        return String(format: "$%.2f", deduction)
    }
}

#Preview {
    LiveOdometerView()
        .padding()
} 