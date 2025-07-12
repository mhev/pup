import SwiftUI

struct AnalyticsCard: View {
    @StateObject private var mileageService = MileageTrackingService.shared
    @StateObject private var subscriptionService = SubscriptionService.shared
    @EnvironmentObject var scheduleViewModel: ScheduleViewModel
    
    @State private var selectedPeriod: AnalyticsPeriod = .today
    @State private var showingSubscriptionPaywall = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: Config.sectionSpacing) {
            // Header
            HStack {
                Text("Analytics")
                    .contextIcon(ContextIcons.analytics, color: Config.visitsColor)
                    .font(.system(size: Config.headingFontSize, weight: .semibold))
                
                Spacer()
                
                // Period selector
                Menu {
                    ForEach(AnalyticsPeriod.allCases, id: \.self) { period in
                        Button(period.displayName) {
                            selectedPeriod = period
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(selectedPeriod.displayName)
                            .font(.system(size: Config.captionFontSize, weight: .medium))
                        Image(systemName: "chevron.down")
                            .font(.system(size: Config.captionFontSize))
                    }
                    .foregroundColor(Config.evergreenColor)
                }
            }
            
            if subscriptionService.isPremium {
                // Premium analytics content
                premiumAnalyticsContent
            } else {
                // Free tier with upgrade prompt
                freeAnalyticsContent
            }
        }
        .cardStyle()
        .sheet(isPresented: $showingSubscriptionPaywall) {
            SubscriptionPaywallView(isPresented: $showingSubscriptionPaywall)
        }
    }
    
    private var premiumAnalyticsContent: some View {
        VStack(spacing: Config.sectionSpacing) {
            // Primary metrics row
            HStack(spacing: Config.sectionSpacing) {
                AnalyticsMetric(
                    icon: ContextIcons.visits,
                    value: "\(completedVisitsCount)",
                    label: "Visits",
                    color: Config.visitsColor
                )
                
                AnalyticsMetric(
                    icon: ContextIcons.mileage,
                    value: formattedMileage,
                    label: "Miles",
                    color: Config.mileageColor
                )
                
                AnalyticsMetric(
                    icon: "💰",
                    value: formattedDeduction,
                    label: "Deduction",
                    color: Config.incomeColor
                )
            }
            
            // Secondary metrics
            HStack(spacing: Config.sectionSpacing) {
                AnalyticsMetric(
                    icon: "⏱️",
                    value: formattedTime,
                    label: "Time",
                    color: Config.evergreenColor,
                    isSecondary: true
                )
                
                AnalyticsMetric(
                    icon: "📈",
                    value: efficiencyScore,
                    label: "Efficiency",
                    color: Config.aiInsightColor,
                    isSecondary: true
                )
                
                AnalyticsMetric(
                    icon: "💵",
                    value: formattedAvgPerVisit,
                    label: "Per Visit",
                    color: Config.tipsColor,
                    isSecondary: true
                )
            }
            
            // Trend indicators
            if selectedPeriod != .today {
                trendIndicators
            }
        }
    }
    
    private var freeAnalyticsContent: some View {
        VStack(spacing: Config.sectionSpacing) {
            // Limited free metrics
            HStack(spacing: Config.sectionSpacing) {
                AnalyticsMetric(
                    icon: ContextIcons.visits,
                    value: "\(completedVisitsCount)",
                    label: "Visits",
                    color: Config.visitsColor
                )
                
                // Locked metrics
                LockedAnalyticsMetric(
                    icon: ContextIcons.mileage,
                    label: "Miles",
                    color: Config.mileageColor
                )
                
                LockedAnalyticsMetric(
                    icon: "💰",
                    label: "Deduction",
                    color: Config.incomeColor
                )
            }
            
            // Upgrade prompt
            Button(action: {
                showingSubscriptionPaywall = true
            }) {
                HStack {
                    Image(systemName: "crown.fill")
                        .font(.system(size: Config.captionFontSize))
                    Text("Upgrade for Full Analytics")
                        .font(.system(size: Config.captionFontSize, weight: .medium))
                }
                .foregroundColor(Config.evergreenColor)
                .padding(.horizontal, Config.sectionSpacing)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: Config.chipCornerRadius)
                        .fill(Config.evergreenColor.opacity(0.1))
                )
            }
        }
    }
    
    private var trendIndicators: some View {
        HStack(spacing: Config.largeSpacing) {
            TrendIndicator(
                title: "vs Previous",
                value: Double(visitsTrend),
                isPositive: visitsTrend >= 0,
                icon: ContextIcons.visits
            )
            
            TrendIndicator(
                title: "Miles Trend",
                value: mileageTrend,
                isPositive: true, // More miles is generally good for business
                icon: ContextIcons.mileage
            )
            
            Spacer()
        }
    }
    
    // MARK: - Computed Properties
    
    private var completedVisitsCount: Int {
        let visits = getVisitsForPeriod()
        return visits.filter { $0.isCompleted }.count
    }
    
    private var formattedMileage: String {
        let mileage = getMileageForPeriod()
        return String(format: "%.1f", mileage)
    }
    
    private var formattedDeduction: String {
        let deduction = getDeductionForPeriod()
        return String(format: "$%.0f", deduction)
    }
    
    private var formattedTime: String {
        let totalMinutes = getTotalTimeForPeriod()
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        return hours > 0 ? "\(hours)h \(minutes)m" : "\(minutes)m"
    }
    
    private var efficiencyScore: String {
        let score = getEfficiencyScore()
        return String(format: "%.0f%%", score * 100)
    }
    
    private var formattedAvgPerVisit: String {
        let visits = completedVisitsCount
        let deduction = getDeductionForPeriod()
        if visits > 0 {
            return String(format: "$%.0f", deduction / Double(visits))
        }
        return "$0"
    }
    
    private var visitsTrend: Int {
        let current = completedVisitsCount
        let previous = getPreviousPeriodVisits()
        return current - previous
    }
    
    private var mileageTrend: Double {
        let current = getMileageForPeriod()
        let previous = getPreviousPeriodMileage()
        return current - previous
    }
    
    // MARK: - Data Helpers
    
    private func getVisitsForPeriod() -> [Visit] {
        let dateRange = selectedPeriod.dateRange
        return scheduleViewModel.visits.filter { visit in
            visit.startTime >= dateRange.start && visit.startTime <= dateRange.end
        }
    }
    
    private func getMileageForPeriod() -> Double {
        switch selectedPeriod {
        case .today:
            return mileageService.todaysMileage
        case .week:
            return mileageService.getWeeklyMileage()
        case .month:
            return mileageService.getMonthlyMileage()
        case .year:
            return mileageService.getYearlyMileage()
        }
    }
    
    private func getDeductionForPeriod() -> Double {
        let dateRange = selectedPeriod.dateRange
        return mileageService.mileageEntries
            .filter { $0.date >= dateRange.start && $0.date <= dateRange.end }
            .filter { $0.purpose == .business }
            .reduce(0) { $0 + $1.estimatedDeduction }
    }
    
    private func getTotalTimeForPeriod() -> Int {
        let visits = getVisitsForPeriod().filter { $0.isCompleted }
        return visits.reduce(0) { total, visit in
            total + Int(visit.duration)
        }
    }
    
    private func getEfficiencyScore() -> Double {
        // Calculate efficiency based on route optimization
        if let route = scheduleViewModel.optimizedRoute {
            return route.efficiency
        }
        
        // Fallback calculation based on completed visits
        let visits = getVisitsForPeriod()
        let completedCount = visits.filter { $0.isCompleted }.count
        let totalCount = visits.count
        
        return totalCount > 0 ? Double(completedCount) / Double(totalCount) : 0.0
    }
    
    private func getPreviousPeriodVisits() -> Int {
        let previousRange = selectedPeriod.previousPeriodRange
        return scheduleViewModel.visits.filter { visit in
            visit.startTime >= previousRange.start && visit.startTime <= previousRange.end && visit.isCompleted
        }.count
    }
    
    private func getPreviousPeriodMileage() -> Double {
        let previousRange = selectedPeriod.previousPeriodRange
        return mileageService.mileageEntries
            .filter { $0.date >= previousRange.start && $0.date <= previousRange.end }
            .reduce(0) { $0 + $1.distance }
    }
}

// MARK: - Supporting Views

struct AnalyticsMetric: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    var isSecondary: Bool = false
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Text(icon)
                    .font(.system(size: isSecondary ? 12 : 14))
                Text(value)
                    .font(.system(size: isSecondary ? Config.bodyFontSize : Config.headingFontSize, weight: .semibold))
                    .foregroundColor(color)
            }
            
            Text(label)
                .font(.system(size: Config.captionFontSize))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct LockedAnalyticsMetric: View {
    let icon: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Text(icon)
                    .font(.system(size: 14))
                    .opacity(0.3)
                Image(systemName: "lock.fill")
                    .font(.system(size: Config.captionFontSize))
                    .foregroundColor(.secondary)
            }
            
            Text(label)
                .font(.system(size: Config.captionFontSize))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct TrendIndicator: View {
    let title: String
    let value: Double
    let isPositive: Bool
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: Config.captionFontSize))
                .foregroundColor(.secondary)
            
            HStack(spacing: 4) {
                Text(icon)
                    .font(.system(size: 10))
                
                Image(systemName: value > 0 ? "arrow.up.right" : value < 0 ? "arrow.down.right" : "minus")
                    .font(.system(size: Config.captionFontSize))
                    .foregroundColor(value > 0 ? .green : value < 0 ? .red : .secondary)
                
                Text(String(format: "%.1f", abs(value)))
                    .font(.system(size: Config.captionFontSize, weight: .medium))
                    .foregroundColor(.primary)
            }
        }
    }
}

// MARK: - Analytics Period Enum

enum AnalyticsPeriod: CaseIterable {
    case today
    case week
    case month
    case year
    
    var displayName: String {
        switch self {
        case .today: return "Today"
        case .week: return "This Week"
        case .month: return "This Month"
        case .year: return "This Year"
        }
    }
    
    var dateRange: DateInterval {
        let calendar = Calendar.current
        let now = Date()
        
        switch self {
        case .today:
            let start = calendar.startOfDay(for: now)
            let end = calendar.date(byAdding: .day, value: 1, to: start)!
            return DateInterval(start: start, end: end)
        case .week:
            let start = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
            let end = calendar.date(byAdding: .weekOfYear, value: 1, to: start)!
            return DateInterval(start: start, end: end)
        case .month:
            let start = calendar.dateInterval(of: .month, for: now)?.start ?? now
            let end = calendar.date(byAdding: .month, value: 1, to: start)!
            return DateInterval(start: start, end: end)
        case .year:
            let start = calendar.dateInterval(of: .year, for: now)?.start ?? now
            let end = calendar.date(byAdding: .year, value: 1, to: start)!
            return DateInterval(start: start, end: end)
        }
    }
    
    var previousPeriodRange: DateInterval {
        let calendar = Calendar.current
        let current = dateRange
        
        switch self {
        case .today:
            let start = calendar.date(byAdding: .day, value: -1, to: current.start)!
            let end = current.start
            return DateInterval(start: start, end: end)
        case .week:
            let start = calendar.date(byAdding: .weekOfYear, value: -1, to: current.start)!
            let end = current.start
            return DateInterval(start: start, end: end)
        case .month:
            let start = calendar.date(byAdding: .month, value: -1, to: current.start)!
            let end = current.start
            return DateInterval(start: start, end: end)
        case .year:
            let start = calendar.date(byAdding: .year, value: -1, to: current.start)!
            let end = current.start
            return DateInterval(start: start, end: end)
        }
    }
}

#Preview {
    AnalyticsCard()
        .environmentObject(ScheduleViewModel())
        .padding()
} 