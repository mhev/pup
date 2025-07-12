import SwiftUI

struct MileageHeaderView: View {
    @StateObject private var mileageService = MileageTrackingService.shared
    @StateObject private var subscriptionService = SubscriptionService.shared
    @State private var showingSubscriptionPaywall = false
    
    var body: some View {
        HStack(spacing: Config.sectionSpacing) {
            // Mileage info
            VStack(alignment: .leading, spacing: 4) {
                Text("Today's Mileage")
                    .contextIcon(ContextIcons.mileage, color: Config.mileageColor)
                    .font(.system(size: Config.bodyFontSize, weight: .semibold))
                    .foregroundColor(.primary)
                
                if subscriptionService.isPremium {
                    HStack(spacing: 4) {
                        Text(formattedMileage)
                            .font(.system(size: Config.headingFontSize, weight: .bold))
                            .foregroundColor(Config.mileageColor)
                        
                        Text("miles")
                            .font(.system(size: Config.captionFontSize))
                            .foregroundColor(.secondary)
                    }
                    
                    if let deduction = estimatedDeduction {
                        Text(deduction)
                            .font(.system(size: Config.captionFontSize))
                            .foregroundColor(.secondary)
                    }
                } else {
                    HStack(spacing: 4) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: Config.captionFontSize))
                            .foregroundColor(.secondary)
                        
                        Text("Premium Feature")
                            .font(.system(size: Config.captionFontSize))
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // Tracking status or upgrade button
            if subscriptionService.isPremium {
                trackingStatusView
            } else {
                upgradeButton
            }
        }
        .translucentHeader()
        .sheet(isPresented: $showingSubscriptionPaywall) {
            SubscriptionPaywallView(isPresented: $showingSubscriptionPaywall)
        }
    }
    
    private var trackingStatusView: some View {
        VStack(spacing: 4) {
            if mileageService.isTracking {
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                        .scaleEffect(mileageService.isTracking ? 1.2 : 1.0)
                        .animation(.easeInOut(duration: 0.5).repeatForever(), value: mileageService.isTracking)
                    
                    Text("Tracking")
                        .font(.system(size: Config.captionFontSize, weight: .medium))
                        .foregroundColor(.green)
                }
                
                Text("\(String(format: "%.1f", mileageService.currentTripDistance)) mi")
                    .font(.system(size: Config.captionFontSize))
                    .foregroundColor(.secondary)
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
        }
    }
    
    private var upgradeButton: some View {
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
    
    // MARK: - Computed Properties
    
    private var formattedMileage: String {
        return String(format: "%.1f", mileageService.todaysMileage)
    }
    
    private var estimatedDeduction: String? {
        let deduction = mileageService.todaysMileage * 0.67
        return deduction > 0 ? "Est. $\(String(format: "%.2f", deduction)) deduction" : nil
    }
}

#Preview {
    MileageHeaderView()
        .padding()
} 