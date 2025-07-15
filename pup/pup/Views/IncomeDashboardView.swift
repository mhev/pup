import SwiftUI
import Charts

struct IncomeDashboardView: View {
    @StateObject private var incomeService = IncomeService()
    @StateObject private var subscriptionService = SubscriptionService.shared
    @State private var selectedPeriod: EarningsPeriod = .thisMonth
    @State private var showingAddIncome = false
    @State private var showingImportOptions = false
    @State private var showingTipReminders = false
    @State private var showingSubscriptionPaywall = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Config.primaryColor
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: Config.largeSpacing) {
                        // Header with earnings overview
                        earningsOverviewCard
                        
                        // Quick stats
                        quickStatsSection
                        
                        // Period selector
                        periodSelector
                        
                        // Earnings chart (premium)
                        if subscriptionService.isPremium {
                            earningsChart
                        } else {
                            premiumChartPlaceholder
                        }
                        
                        // Recent entries
                        recentEntriesSection
                        
                        // Actions
                        actionsSection
                        
                        Spacer(minLength: 100) // Space for floating action button
                    }
                    .padding(.horizontal, Config.largeSpacing)
                }
                .refreshable {
                    incomeService.calculateAnalytics()
                }
                
                // Floating action button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        FloatingActionButton(
                            action: { showingAddIncome = true }
                        )
                        .padding(.trailing, Config.largeSpacing)
                        .padding(.bottom, Config.largeSpacing)
                    }
                }
            }
            .navigationTitle("💰 Income & Tips")
            .navigationBarTitleDisplayMode(.large)
            .translucentHeader()
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { showingImportOptions = true }) {
                            Label("Import Data", systemImage: "square.and.arrow.down")
                        }
                        
                        Button(action: { showingTipReminders = true }) {
                            Label("Tip Reminders", systemImage: "bell")
                        }
                        
                        Button(action: exportData) {
                            Label("Export CSV", systemImage: "square.and.arrow.up")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(Config.evergreenColor)
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddIncome) {
            AddIncomeView(incomeService: incomeService)
        }
        .sheet(isPresented: $showingImportOptions) {
            ImportOptionsView(incomeService: incomeService)
        }
        .sheet(isPresented: $showingTipReminders) {
            TipRemindersView(incomeService: incomeService)
        }
        .sheet(isPresented: $showingSubscriptionPaywall) {
            SubscriptionPaywallView(isPresented: $showingSubscriptionPaywall)
        }
    }
    
    // MARK: - Earnings Overview Card
    
    private var earningsOverviewCard: some View {
        VStack(alignment: .leading, spacing: Config.sectionSpacing) {
            HStack {
                VStack(alignment: .leading, spacing: Config.smallSpacing) {
                    Text("Total Earnings")
                        .font(.system(size: Config.captionFontSize, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    Text(String(format: "$%.2f", incomeService.totalEarnings + incomeService.totalTips))
                        .font(.system(size: Config.largeTitleFontSize, weight: .bold))
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                Text(ContextIcons.income)
                    .font(.system(size: Config.largeFontSize))
            }
            
            HStack(spacing: Config.largeSpacing) {
                StatBox(
                    title: "Base Pay",
                    value: String(format: "$%.2f", incomeService.totalEarnings),
                    color: Config.evergreenColor
                )
                
                StatBox(
                    title: "Tips",
                    value: String(format: "$%.2f", incomeService.totalTips),
                    color: Config.contextColors.tips
                )
                
                StatBox(
                    title: "Avg/Visit",
                    value: String(format: "$%.2f", incomeService.averagePerVisit),
                    color: Config.aiInsightColor
                )
            }
        }
        .padding(Config.sectionSpacing)
        .background(Color.white)
        .cornerRadius(Config.cardCornerRadius)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Quick Stats Section
    
    private var quickStatsSection: some View {
        HStack(spacing: Config.sectionSpacing) {
            QuickStatCard(
                icon: "calendar.badge.clock",
                title: "This Week",
                value: String(format: "$%.2f", incomeService.thisWeekEarnings),
                color: Config.evergreenColor
            )
            
            QuickStatCard(
                icon: "calendar",
                title: "This Month",
                value: String(format: "$%.2f", incomeService.thisMonthEarnings),
                color: Config.contextColors.tips
            )
        }
    }
    
    // MARK: - Period Selector
    
    private var periodSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Config.sectionSpacing) {
                ForEach(EarningsPeriod.allCases, id: \.self) { period in
                    Button(action: { selectedPeriod = period }) {
                        Text(period.rawValue)
                            .font(.system(size: Config.captionFontSize, weight: .medium))
                            .foregroundColor(selectedPeriod == period ? .white : .primary)
                            .padding(.horizontal, Config.sectionSpacing)
                            .padding(.vertical, Config.smallSpacing)
                            .background(
                                selectedPeriod == period ? Config.evergreenColor : Color.clear
                            )
                            .cornerRadius(Config.smallCornerRadius)
                            .overlay(
                                RoundedRectangle(cornerRadius: Config.smallCornerRadius)
                                    .stroke(Config.evergreenColor, lineWidth: 1)
                            )
                    }
                }
            }
            .padding(.horizontal, Config.largeSpacing)
        }
    }
    
    // MARK: - Earnings Chart
    
    @ViewBuilder
    private var earningsChart: some View {
        if #available(iOS 16.0, *) {
            VStack(alignment: .leading, spacing: Config.sectionSpacing) {
                Text("Earnings Trend")
                    .font(.system(size: Config.bodyFontSize, weight: .semibold))
                    .foregroundColor(.primary)
                
                let monthlyData = incomeService.getMonthlyEarningsTrend()
                
                if monthlyData.isEmpty {
                    // Empty state for chart
                    VStack(spacing: Config.sectionSpacing) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: Config.largeFontSize))
                            .foregroundColor(.gray)
                        
                        Text("No data to display")
                            .font(.system(size: Config.bodyFontSize))
                            .foregroundColor(.secondary)
                        
                        Text("Add some income entries to see your earnings trend")
                            .font(.system(size: Config.captionFontSize))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
                } else {
                    Chart(monthlyData) { item in
                        LineMark(
                            x: .value("Month", item.month),
                            y: .value("Earnings", item.earnings)
                        )
                        .foregroundStyle(Config.evergreenColor)
                        .lineStyle(StrokeStyle(lineWidth: 3))
                        
                        AreaMark(
                            x: .value("Month", item.month),
                            y: .value("Earnings", item.earnings)
                        )
                        .foregroundStyle(Config.evergreenColor.opacity(0.1))
                    }
                .frame(height: 200)
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 6)) { value in
                        if let date = value.as(Date.self) {
                            AxisValueLabel {
                                Text(DateFormatter.chartMonth.string(from: date))
                                    .font(.system(size: Config.captionFontSize))
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        if let earnings = value.as(Double.self) {
                            AxisValueLabel {
                                Text("$\(Int(earnings))")
                                    .font(.system(size: Config.captionFontSize))
                            }
                        }
                    }
                }
                }
            }
            .padding(Config.sectionSpacing)
            .background(Color.white)
            .cornerRadius(Config.cardCornerRadius)
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        } else {
            // Fallback for iOS 15
            simpleEarningsChart
        }
    }
    
    private var simpleEarningsChart: some View {
        VStack(alignment: .leading, spacing: Config.sectionSpacing) {
            Text("Monthly Earnings")
                .font(.system(size: Config.bodyFontSize, weight: .semibold))
                .foregroundColor(.primary)
            
            let monthlyData = incomeService.getMonthlyEarningsTrend()
            
            ForEach(monthlyData.suffix(6)) { item in
                HStack {
                    Text(DateFormatter.monthYear.string(from: item.month))
                        .font(.system(size: Config.captionFontSize))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(String(format: "$%.2f", item.earnings))
                        .font(.system(size: Config.captionFontSize, weight: .medium))
                        .foregroundColor(.primary)
                }
                .padding(.vertical, Config.smallSpacing)
            }
        }
        .padding(Config.sectionSpacing)
        .background(Color.white)
        .cornerRadius(Config.cardCornerRadius)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    private var premiumChartPlaceholder: some View {
        VStack(spacing: Config.sectionSpacing) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: Config.largeFontSize))
                .foregroundColor(.gray)
            
            Text("Earnings Trend Chart")
                .font(.system(size: Config.bodyFontSize, weight: .semibold))
                .foregroundColor(.primary)
            
            Text("Unlock premium to see detailed earnings analytics and trends")
                .font(.system(size: Config.captionFontSize))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: { 
                showingSubscriptionPaywall = true
            }) {
                Text("Upgrade to Premium")
                    .font(.system(size: Config.captionFontSize, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, Config.sectionSpacing)
                    .padding(.vertical, Config.smallSpacing)
                    .background(Config.evergreenColor)
                    .cornerRadius(Config.smallCornerRadius)
            }
        }
        .padding(Config.sectionSpacing)
        .background(Color.white)
        .cornerRadius(Config.cardCornerRadius)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Recent Entries Section
    
    private var recentEntriesSection: some View {
        VStack(alignment: .leading, spacing: Config.sectionSpacing) {
            HStack {
                Text("Recent Entries")
                    .font(.system(size: Config.bodyFontSize, weight: .semibold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: { /* Show all entries */ }) {
                    Text("View All")
                        .font(.system(size: Config.captionFontSize, weight: .medium))
                        .foregroundColor(Config.evergreenColor)
                }
            }
            
            LazyVStack(spacing: Config.smallSpacing) {
                ForEach(incomeService.getEarningsForPeriod(selectedPeriod).prefix(5)) { entry in
                    IncomeEntryRow(entry: entry)
                }
            }
            
            if incomeService.incomeEntries.isEmpty {
                EmptyIncomeState()
            }
        }
        .padding(Config.sectionSpacing)
        .background(Color.white)
        .cornerRadius(Config.cardCornerRadius)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Actions Section
    
    private var actionsSection: some View {
        VStack(spacing: Config.sectionSpacing) {
            ActionButton(
                icon: "plus.circle.fill",
                title: "Add Income Entry",
                subtitle: "Manually record earnings and tips",
                color: Config.evergreenColor,
                action: { showingAddIncome = true }
            )
            
            ActionButton(
                icon: "square.and.arrow.down.fill",
                title: "Import from CSV",
                subtitle: "Import from Rover, Wag, or other platforms",
                color: Config.contextColors.tips,
                action: { showingImportOptions = true }
            )
            
            if !incomeService.pendingTipReminders.isEmpty {
                ActionButton(
                    icon: "bell.fill",
                    title: "Tip Reminders",
                    subtitle: "\(incomeService.pendingTipReminders.count) pending reminders",
                    color: Config.aiInsightColor,
                    action: { showingTipReminders = true }
                )
            }
        }
    }
    
    // MARK: - Actions
    
    private func exportData() {
        let csvData = incomeService.exportToCSV()
        
        // Create activity view controller to share CSV
        let activityVC = UIActivityViewController(
            activityItems: [csvData],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(activityVC, animated: true)
        }
    }
}

// MARK: - Supporting Views

struct StatBox: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: Config.smallSpacing) {
            Text(title)
                .font(.system(size: Config.captionFontSize, weight: .medium))
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.system(size: Config.bodyFontSize, weight: .bold))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct QuickStatCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: Config.smallSpacing) {
            Image(systemName: icon)
                .font(.system(size: Config.bodyFontSize))
                .foregroundColor(color)
            
            Text(title)
                .font(.system(size: Config.captionFontSize, weight: .medium))
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.system(size: Config.bodyFontSize, weight: .bold))
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity)
        .padding(Config.sectionSpacing)
        .background(Color.white)
        .cornerRadius(Config.cardCornerRadius)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct IncomeEntryRow: View {
    let entry: IncomeEntry
    
    var body: some View {
        HStack(spacing: Config.sectionSpacing) {
            VStack(alignment: .leading, spacing: Config.smallSpacing) {
                Text("\(entry.clientName) - \(entry.petName)")
                    .font(.system(size: Config.bodyFontSize, weight: .medium))
                    .foregroundColor(.primary)
                
                HStack {
                    Text(entry.serviceType.rawValue)
                        .font(.system(size: Config.captionFontSize))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(DateFormatter.shortDate.string(from: entry.date))
                        .font(.system(size: Config.captionFontSize))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: Config.smallSpacing) {
                Text(entry.formattedTotal)
                    .font(.system(size: Config.bodyFontSize, weight: .bold))
                    .foregroundColor(.primary)
                
                if entry.tip > 0 {
                    Text("+ \(entry.formattedTip) tip")
                        .font(.system(size: Config.captionFontSize))
                        .foregroundColor(Config.contextColors.tips)
                }
            }
        }
        .padding(.vertical, Config.smallSpacing)
    }
}

struct ActionButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: Config.sectionSpacing) {
                Image(systemName: icon)
                    .font(.system(size: Config.bodyFontSize))
                    .foregroundColor(color)
                    .frame(width: 32, height: 32)
                
                VStack(alignment: .leading, spacing: Config.smallSpacing) {
                    Text(title)
                        .font(.system(size: Config.bodyFontSize, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.system(size: Config.captionFontSize))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: Config.captionFontSize))
                    .foregroundColor(.secondary)
            }
            .padding(Config.sectionSpacing)
            .background(Color.white)
            .cornerRadius(Config.cardCornerRadius)
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct EmptyIncomeState: View {
    var body: some View {
        VStack(spacing: Config.sectionSpacing) {
            Image(systemName: "dollarsign.circle")
                .font(.system(size: Config.largeFontSize))
                .foregroundColor(.gray)
            
            Text("No income entries yet")
                .font(.system(size: Config.bodyFontSize, weight: .medium))
                .foregroundColor(.primary)
            
            Text("Add your first income entry to start tracking earnings")
                .font(.system(size: Config.captionFontSize))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(Config.largeSpacing)
    }
}

#Preview {
    IncomeDashboardView()
} 