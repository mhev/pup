import SwiftUI

struct TipRemindersView: View {
    @ObservedObject var incomeService: IncomeService
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingAddTip = false
    @State private var selectedReminder: TipReminder?
    @State private var tipAmount: String = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                Config.primaryColor
                    .ignoresSafeArea()
                
                if incomeService.pendingTipReminders.isEmpty {
                    emptyStateView
                } else {
                    ScrollView {
                        VStack(spacing: Config.sectionSpacing) {
                            // Header
                            headerSection
                            
                            // Pending reminders
                            ForEach(incomeService.pendingTipReminders) { reminder in
                                TipReminderCard(
                                    reminder: reminder,
                                    onAddTip: { 
                                        selectedReminder = reminder
                                        showingAddTip = true
                                    },
                                    onDismiss: { 
                                        incomeService.dismissTipReminder(reminder)
                                    }
                                )
                            }
                            
                            Spacer(minLength: 50)
                        }
                        .padding(.horizontal, Config.largeSpacing)
                    }
                }
            }
            .navigationTitle("Tip Reminders")
            .navigationBarTitleDisplayMode(.inline)
            .translucentHeader()
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Config.evergreenColor)
                }
            }
        }
        .sheet(isPresented: $showingAddTip) {
            AddTipView(
                reminder: selectedReminder,
                tipAmount: $tipAmount,
                onSave: { reminder, tip in
                    incomeService.completeTipReminder(reminder, tip: tip)
                    showingAddTip = false
                    selectedReminder = nil
                    tipAmount = ""
                }
            )
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: Config.sectionSpacing) {
            Text("💡")
                .font(.system(size: Config.largeFontSize))
            
            Text("Don't forget to record your tips!")
                .font(.system(size: Config.bodyFontSize))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            if incomeService.pendingTipReminders.count > 0 {
                Text("\(incomeService.pendingTipReminders.count) pending reminders")
                    .font(.system(size: Config.captionFontSize, weight: .medium))
                    .foregroundColor(Config.contextColors.tips)
            }
        }
        .padding(.top, Config.sectionSpacing)
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: Config.largeSpacing) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: Config.largeFontSize))
                .foregroundColor(Config.evergreenColor)
            
            Text("All caught up!")
                .font(.system(size: Config.bodyFontSize, weight: .semibold))
                .foregroundColor(.primary)
            
            Text("You have no pending tip reminders")
                .font(.system(size: Config.captionFontSize))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(Config.largeSpacing)
    }
}

struct TipReminderCard: View {
    let reminder: TipReminder
    let onAddTip: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: Config.sectionSpacing) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: Config.smallSpacing) {
                    Text("\(reminder.clientName) - \(reminder.petName)")
                        .font(.system(size: Config.bodyFontSize, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text(reminder.serviceType.rawValue)
                        .font(.system(size: Config.captionFontSize))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text(ContextIcons.visits)
                    .font(.system(size: Config.bodyFontSize))
            }
            
            // Visit details
            VStack(alignment: .leading, spacing: Config.smallSpacing) {
                HStack {
                    Text("Visit Date:")
                        .font(.system(size: Config.captionFontSize))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(DateFormatter.shortDate.string(from: reminder.visitDate))
                        .font(.system(size: Config.captionFontSize, weight: .medium))
                        .foregroundColor(.primary)
                }
                
                HStack {
                    Text("Reminder:")
                        .font(.system(size: Config.captionFontSize))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(timeAgo(from: reminder.reminderDate))
                        .font(.system(size: Config.captionFontSize, weight: .medium))
                        .foregroundColor(Config.contextColors.tips)
                }
            }
            .padding(.vertical, Config.smallSpacing)
            .padding(.horizontal, Config.sectionSpacing)
            .background(Config.contextColors.tips.opacity(0.1))
            .cornerRadius(Config.smallCornerRadius)
            
            // Actions
            HStack(spacing: Config.sectionSpacing) {
                Button(action: onAddTip) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: Config.captionFontSize))
                        
                        Text("Add Tip")
                            .font(.system(size: Config.captionFontSize, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Config.smallSpacing)
                    .background(Config.contextColors.tips)
                    .cornerRadius(Config.smallCornerRadius)
                }
                
                Button(action: onDismiss) {
                    HStack {
                        Image(systemName: "xmark.circle")
                            .font(.system(size: Config.captionFontSize))
                        
                        Text("Dismiss")
                            .font(.system(size: Config.captionFontSize, weight: .medium))
                    }
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Config.smallSpacing)
                    .background(Color.clear)
                    .cornerRadius(Config.smallCornerRadius)
                    .overlay(
                        RoundedRectangle(cornerRadius: Config.smallCornerRadius)
                            .stroke(Color.secondary, lineWidth: 1)
                    )
                }
            }
        }
        .padding(Config.sectionSpacing)
        .background(Color.white)
        .cornerRadius(Config.cardCornerRadius)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    private func timeAgo(from date: Date) -> String {
        let now = Date()
        let interval = now.timeIntervalSince(date)
        
        if interval < 60 {
            return "Just now"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes) min ago"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours) hr ago"
        } else {
            let days = Int(interval / 86400)
            return "\(days) day\(days == 1 ? "" : "s") ago"
        }
    }
}

struct AddTipView: View {
    let reminder: TipReminder?
    @Binding var tipAmount: String
    let onSave: (TipReminder, Double) -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var isValid = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            ZStack {
                Config.primaryColor
                    .ignoresSafeArea()
                
                VStack(spacing: Config.largeSpacing) {
                    // Header
                    VStack(spacing: Config.sectionSpacing) {
                        Text("💰")
                            .font(.system(size: Config.largeFontSize))
                        
                        if let reminder = reminder {
                            Text("Add tip for \(reminder.clientName)")
                                .font(.system(size: Config.bodyFontSize, weight: .semibold))
                                .foregroundColor(.primary)
                            
                            Text("\(reminder.petName) • \(reminder.serviceType.rawValue)")
                                .font(.system(size: Config.captionFontSize))
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.top, Config.sectionSpacing)
                    
                    // Tip amount input
                    VStack(alignment: .leading, spacing: Config.sectionSpacing) {
                        Text("Tip Amount")
                            .font(.system(size: Config.bodyFontSize, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        TextField("$0.00", text: $tipAmount)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .font(.system(size: Config.bodyFontSize))
                            .onChange(of: tipAmount) { newValue in
                                // Format as currency
                                let filtered = newValue.filter { $0.isNumber || $0 == "." }
                                if filtered != newValue {
                                    tipAmount = filtered
                                }
                                validateForm()
                            }
                        
                        // Quick tip buttons
                        VStack(spacing: Config.sectionSpacing) {
                            Text("Quick Select")
                                .font(.system(size: Config.captionFontSize, weight: .medium))
                                .foregroundColor(.secondary)
                            
                            HStack(spacing: Config.sectionSpacing) {
                                ForEach(["5", "10", "15", "20"], id: \.self) { amount in
                                    Button(action: { tipAmount = amount }) {
                                        Text("$\(amount)")
                                            .font(.system(size: Config.captionFontSize, weight: .medium))
                                            .foregroundColor(.primary)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, Config.smallSpacing)
                                            .background(Color.white)
                                            .cornerRadius(Config.smallCornerRadius)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: Config.smallCornerRadius)
                                                    .stroke(Config.contextColors.tips, lineWidth: 1)
                                            )
                                    }
                                }
                            }
                        }
                        .padding(.top, Config.sectionSpacing)
                    }
                    .padding(Config.sectionSpacing)
                    .background(Color.white)
                    .cornerRadius(Config.cardCornerRadius)
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                    
                    // Error message
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .font(.system(size: Config.captionFontSize))
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(Config.smallCornerRadius)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, Config.largeSpacing)
            }
            .navigationTitle("Add Tip")
            .navigationBarTitleDisplayMode(.inline)
            .translucentHeader()
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Config.evergreenColor)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveTip()
                    }
                    .foregroundColor(isValid ? Config.evergreenColor : .gray)
                    .disabled(!isValid)
                }
            }
        }
        .onAppear {
            validateForm()
        }
    }
    
    private func validateForm() {
        let amount = Double(tipAmount) ?? 0
        isValid = amount >= 0 // Allow $0 tips
        
        if amount < 0 {
            errorMessage = "Tip amount cannot be negative"
        } else {
            errorMessage = nil
        }
    }
    
    private func saveTip() {
        guard let reminder = reminder, isValid else { return }
        
        let amount = Double(tipAmount) ?? 0
        onSave(reminder, amount)
    }
}

#Preview {
    TipRemindersView(incomeService: IncomeService())
} 