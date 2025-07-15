import Foundation
import SwiftUI
import Combine

@MainActor
class IncomeService: ObservableObject {
    @Published var incomeEntries: [IncomeEntry] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Analytics properties
    @Published var totalEarnings: Double = 0
    @Published var totalTips: Double = 0
    @Published var averagePerVisit: Double = 0
    @Published var thisWeekEarnings: Double = 0
    @Published var thisMonthEarnings: Double = 0
    
    // Tip reminder properties
    @Published var pendingTipReminders: [TipReminder] = []
    
    private let userDefaults = UserDefaults.standard
    private let incomeKey = "SavedIncomeEntries"
    private let tipRemindersKey = "PendingTipReminders"
    
    // Timer for tip reminders
    private var tipReminderTimer: Timer?
    
    init() {
        loadPersistedData()
        calculateAnalytics()
        startTipReminderTimer()
    }
    
    deinit {
        tipReminderTimer?.invalidate()
    }
    
    // MARK: - Data Management
    
    func addIncomeEntry(_ entry: IncomeEntry) {
        incomeEntries.append(entry)
        persistData()
        calculateAnalytics()
    }
    
    func updateIncomeEntry(_ entry: IncomeEntry) {
        if let index = incomeEntries.firstIndex(where: { $0.id == entry.id }) {
            incomeEntries[index] = entry
            persistData()
            calculateAnalytics()
        }
    }
    
    func deleteIncomeEntry(_ entry: IncomeEntry) {
        incomeEntries.removeAll { $0.id == entry.id }
        persistData()
        calculateAnalytics()
    }
    
    func importIncomeEntries(_ entries: [IncomeEntry]) {
        // Prevent duplicates based on date, amount, and client
        let existingEntries = Set(incomeEntries.map { "\($0.date.timeIntervalSince1970)_\($0.amount)_\($0.clientName)" })
        
        let newEntries = entries.filter { entry in
            let key = "\(entry.date.timeIntervalSince1970)_\(entry.amount)_\(entry.clientName)"
            return !existingEntries.contains(key)
        }
        
        incomeEntries.append(contentsOf: newEntries)
        persistData()
        calculateAnalytics()
    }
    
    // MARK: - Analytics
    
    func calculateAnalytics() {
        let calendar = Calendar.current
        let now = Date()
        
        // Total earnings and tips
        totalEarnings = incomeEntries.reduce(0) { $0 + $1.amount }
        totalTips = incomeEntries.reduce(0) { $0 + $1.tip }
        
        // Average per visit
        averagePerVisit = incomeEntries.isEmpty ? 0 : (totalEarnings + totalTips) / Double(incomeEntries.count)
        
        // This week earnings
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
        thisWeekEarnings = incomeEntries
            .filter { $0.date >= weekStart }
            .reduce(0) { $0 + $1.total }
        
        // This month earnings
        let monthStart = calendar.dateInterval(of: .month, for: now)?.start ?? now
        thisMonthEarnings = incomeEntries
            .filter { $0.date >= monthStart }
            .reduce(0) { $0 + $1.total }
    }
    
    func getEarningsForPeriod(_ period: EarningsPeriod) -> [IncomeEntry] {
        let calendar = Calendar.current
        let now = Date()
        
        switch period {
        case .today:
            return incomeEntries.filter { calendar.isDate($0.date, inSameDayAs: now) }
        case .thisWeek:
            guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start else { return [] }
            return incomeEntries.filter { $0.date >= weekStart }
        case .thisMonth:
            guard let monthStart = calendar.dateInterval(of: .month, for: now)?.start else { return [] }
            return incomeEntries.filter { $0.date >= monthStart }
        case .thisYear:
            guard let yearStart = calendar.dateInterval(of: .year, for: now)?.start else { return [] }
            return incomeEntries.filter { $0.date >= yearStart }
        case .allTime:
            return incomeEntries
        }
    }
    
    func getEarningsByServiceType() -> [ServiceType: Double] {
        var earnings: [ServiceType: Double] = [:]
        
        for entry in incomeEntries {
            earnings[entry.serviceType, default: 0] += entry.total
        }
        
        return earnings
    }
    
    func getEarningsByPlatform() -> [String: Double] {
        var earnings: [String: Double] = [:]
        
        for entry in incomeEntries {
            earnings[entry.platform, default: 0] += entry.total
        }
        
        return earnings
    }
    
    func getMonthlyEarningsTrend() -> [MonthlyEarnings] {
        let calendar = Calendar.current
        let now = Date()
        
        var monthlyData: [Date: Double] = [:]
        
        print("📊 Income entries count: \(incomeEntries.count)")
        
        for entry in incomeEntries {
            let monthKey = calendar.dateInterval(of: .month, for: entry.date)?.start ?? entry.date
            monthlyData[monthKey, default: 0] += entry.total
            print("📊 Entry: \(entry.clientName) - \(entry.petName), Amount: \(entry.total), Date: \(entry.date), Month: \(monthKey)")
        }
        
        // Always show at least 6 months of data for a proper trend
        let endDate = monthlyData.keys.max() ?? now
        let startDate = calendar.date(byAdding: .month, value: -5, to: endDate) ?? endDate
        
        // Fill in missing months with 0 earnings
        var currentDate = startDate
        while currentDate <= endDate {
            let monthKey = calendar.dateInterval(of: .month, for: currentDate)?.start ?? currentDate
            if monthlyData[monthKey] == nil {
                monthlyData[monthKey] = 0
            }
            currentDate = calendar.date(byAdding: .month, value: 1, to: currentDate) ?? currentDate
        }
        
        let result = monthlyData.map { MonthlyEarnings(month: $0.key, earnings: $0.value) }
            .sorted { $0.month < $1.month }
        
        print("📊 Monthly data result: \(result.count) months")
        for item in result {
            print("📊 Month: \(item.month), Earnings: \(item.earnings)")
        }
        
        return result
    }
    
    // MARK: - Tip Reminders
    
    func createTipReminder(for visit: Visit) {
        let reminder = TipReminder(
            visitId: visit.id,
            clientName: visit.clientName,
            petName: visit.petName,
            serviceType: visit.serviceType,
            visitDate: visit.startTime,
            reminderDate: visit.endTime.addingTimeInterval(30 * 60), // 30 minutes after visit
            isCompleted: false
        )
        
        pendingTipReminders.append(reminder)
        persistData()
    }
    
    func completeTipReminder(_ reminder: TipReminder, tip: Double) {
        // Find corresponding income entry and update it
        if let entryIndex = incomeEntries.firstIndex(where: { 
            Calendar.current.isDate($0.date, inSameDayAs: reminder.visitDate) &&
            $0.clientName == reminder.clientName &&
            $0.petName == reminder.petName
        }) {
            var updatedEntry = incomeEntries[entryIndex]
            updatedEntry = IncomeEntry(
                date: updatedEntry.date,
                amount: updatedEntry.amount,
                tip: tip,
                serviceType: updatedEntry.serviceType,
                clientName: updatedEntry.clientName,
                petName: updatedEntry.petName,
                platform: updatedEntry.platform,
                notes: updatedEntry.notes
            )
            incomeEntries[entryIndex] = updatedEntry
        }
        
        // Remove the reminder
        pendingTipReminders.removeAll { $0.id == reminder.id }
        persistData()
        calculateAnalytics()
    }
    
    func dismissTipReminder(_ reminder: TipReminder) {
        pendingTipReminders.removeAll { $0.id == reminder.id }
        persistData()
    }
    
    private func startTipReminderTimer() {
        tipReminderTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            self.checkForPendingTipReminders()
        }
    }
    
    private func checkForPendingTipReminders() {
        let now = Date()
        let activeReminders = pendingTipReminders.filter { 
            $0.reminderDate <= now && !$0.isCompleted 
        }
        
        // In a real app, you'd send push notifications here
        // For now, we'll just mark them as ready to display
        for reminder in activeReminders {
            print("💡 Tip reminder active for \(reminder.clientName) - \(reminder.petName)")
        }
    }
    
    // MARK: - Persistence
    
    private func persistData() {
        // Save income entries
        if let encoded = try? JSONEncoder().encode(incomeEntries) {
            userDefaults.set(encoded, forKey: incomeKey)
        }
        
        // Save tip reminders
        if let encoded = try? JSONEncoder().encode(pendingTipReminders) {
            userDefaults.set(encoded, forKey: tipRemindersKey)
        }
    }
    
    private func loadPersistedData() {
        // Load income entries
        if let data = userDefaults.data(forKey: incomeKey),
           let decoded = try? JSONDecoder().decode([IncomeEntry].self, from: data) {
            incomeEntries = decoded
        }
        
        // Load tip reminders
        if let data = userDefaults.data(forKey: tipRemindersKey),
           let decoded = try? JSONDecoder().decode([TipReminder].self, from: data) {
            pendingTipReminders = decoded
        }
    }
    
    // MARK: - Export
    
    func exportToCSV() -> String {
        var csv = "Date,Client,Pet,Service,Amount,Tip,Total,Platform,Notes\n"
        
        let sortedEntries = incomeEntries.sorted { $0.date > $1.date }
        
        for entry in sortedEntries {
            let dateString = DateFormatter.shortDate.string(from: entry.date)
            let notes = entry.notes?.replacingOccurrences(of: ",", with: ";") ?? ""
            
            csv += "\(dateString),\(entry.clientName),\(entry.petName),\(entry.serviceType.rawValue),\(entry.formattedAmount),\(entry.formattedTip),\(entry.formattedTotal),\(entry.platform),\(notes)\n"
        }
        
        return csv
    }
    
    // MARK: - Tax Calculations
    
    func calculateTaxDeductions() -> TaxSummary {
        let totalIncome = totalEarnings + totalTips
        let businessExpenses = 0.0 // Could be expanded to track expenses
        let taxableIncome = totalIncome - businessExpenses
        
        return TaxSummary(
            totalIncome: totalIncome,
            businessExpenses: businessExpenses,
            taxableIncome: taxableIncome,
            estimatedTaxes: taxableIncome * 0.25 // Rough estimate
        )
    }
}

// MARK: - Supporting Types

enum EarningsPeriod: String, CaseIterable {
    case today = "Today"
    case thisWeek = "This Week"
    case thisMonth = "This Month"
    case