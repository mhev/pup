import SwiftUI

struct AddIncomeView: View {
    @ObservedObject var incomeService: IncomeService
    @Environment(\.dismiss) private var dismiss
    
    @State private var amount: String = ""
    @State private var tip: String = ""
    @State private var serviceType: ServiceType = .dropIn
    @State private var clientName: String = ""
    @State private var petName: String = ""
    @State private var platform: String = "Manual"
    @State private var date: Date = Date()
    @State private var notes: String = ""
    
    @State private var isValid = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            ZStack {
                Config.primaryColor
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: Config.largeSpacing) {
                        // Header
                        headerSection
                        
                        // Amount section
                        amountSection
                        
                        // Service details
                        serviceDetailsSection
                        
                        // Client information
                        clientInformationSection
                        
                        // Date and platform
                        dateAndPlatformSection
                        
                        // Notes
                        notesSection
                        
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
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, Config.largeSpacing)
                }
                .navigationTitle("Add Income")
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
                            saveIncomeEntry()
                        }
                        .foregroundColor(isValid ? Config.evergreenColor : .gray)
                        .disabled(!isValid)
                    }
                }
            }
        }
        .onChange(of: amount) { _ in validateForm() }
        .onChange(of: clientName) { _ in validateForm() }
        .onChange(of: petName) { _ in validateForm() }
        .onAppear {
            validateForm()
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: Config.sectionSpacing) {
            Text("💰")
                .font(.system(size: Config.largeFontSize))
            
            Text("Record your earnings and tips")
                .font(.system(size: Config.bodyFontSize))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, Config.sectionSpacing)
    }
    
    // MARK: - Amount Section
    
    private var amountSection: some View {
        VStack(alignment: .leading, spacing: Config.sectionSpacing) {
            Text("Earnings")
                .font(.system(size: Config.bodyFontSize, weight: .semibold))
                .foregroundColor(.primary)
            
            VStack(spacing: Config.sectionSpacing) {
                // Base amount
                HStack {
                    Text("Base Pay")
                        .font(.system(size: Config.bodyFontSize))
                        .foregroundColor(.primary)
                        .frame(width: 80, alignment: .leading)
                    
                    TextField("$0.00", text: $amount)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onChange(of: amount) { newValue in
                            // Format as currency
                            let filtered = newValue.filter { $0.isNumber || $0 == "." }
                            if filtered != newValue {
                                amount = filtered
                            }
                        }
                }
                
                // Tip amount
                HStack {
                    Text("Tip")
                        .font(.system(size: Config.bodyFontSize))
                        .foregroundColor(.primary)
                        .frame(width: 80, alignment: .leading)
                    
                    TextField("$0.00", text: $tip)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onChange(of: tip) { newValue in
                            // Format as currency
                            let filtered = newValue.filter { $0.isNumber || $0 == "." }
                            if filtered != newValue {
                                tip = filtered
                            }
                        }
                }
                
                // Total display
                if let amountValue = Double(amount), let tipValue = Double(tip) {
                    HStack {
                        Text("Total")
                            .font(.system(size: Config.bodyFontSize, weight: .semibold))
                            .foregroundColor(.primary)
                            .frame(width: 80, alignment: .leading)
                        
                        Spacer()
                        
                        Text(String(format: "$%.2f", amountValue + tipValue))
                            .font(.system(size: Config.bodyFontSize, weight: .bold))
                            .foregroundColor(Config.evergreenColor)
                    }
                    .padding(.horizontal, Config.sectionSpacing)
                    .padding(.vertical, Config.smallSpacing)
                    .background(Config.evergreenColor.opacity(0.1))
                    .cornerRadius(Config.smallCornerRadius)
                }
            }
        }
        .padding(Config.sectionSpacing)
        .background(Color.white)
        .cornerRadius(Config.cardCornerRadius)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Service Details Section
    
    private var serviceDetailsSection: some View {
        VStack(alignment: .leading, spacing: Config.sectionSpacing) {
            Text("Service Type")
                .font(.system(size: Config.bodyFontSize, weight: .semibold))
                .foregroundColor(.primary)
            
            HStack {
                ForEach(ServiceType.allCases, id: \.self) { type in
                    Button(action: { serviceType = type }) {
                        VStack(spacing: Config.smallSpacing) {
                            Image(systemName: type.icon)
                                .font(.system(size: Config.bodyFontSize))
                                .foregroundColor(serviceType == type ? .white : type.color)
                            
                            Text(type.rawValue)
                                .font(.system(size: Config.captionFontSize, weight: .medium))
                                .foregroundColor(serviceType == type ? .white : .primary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Config.sectionSpacing)
                        .background(serviceType == type ? type.color : Color.clear)
                        .cornerRadius(Config.smallCornerRadius)
                        .overlay(
                            RoundedRectangle(cornerRadius: Config.smallCornerRadius)
                                .stroke(type.color, lineWidth: 1)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding(Config.sectionSpacing)
        .background(Color.white)
        .cornerRadius(Config.cardCornerRadius)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Client Information Section
    
    private var clientInformationSection: some View {
        VStack(alignment: .leading, spacing: Config.sectionSpacing) {
            Text("Client Information")
                .font(.system(size: Config.bodyFontSize, weight: .semibold))
                .foregroundColor(.primary)
            
            VStack(spacing: Config.sectionSpacing) {
                TextField("Client Name", text: $clientName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.words)
                
                TextField("Pet Name", text: $petName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.words)
            }
        }
        .padding(Config.sectionSpacing)
        .background(Color.white)
        .cornerRadius(Config.cardCornerRadius)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Date and Platform Section
    
    private var dateAndPlatformSection: some View {
        VStack(alignment: .leading, spacing: Config.sectionSpacing) {
            Text("Details")
                .font(.system(size: Config.bodyFontSize, weight: .semibold))
                .foregroundColor(.primary)
            
            VStack(spacing: Config.sectionSpacing) {
                // Date picker
                DatePicker("Date", selection: $date, displayedComponents: .date)
                    .datePickerStyle(CompactDatePickerStyle())
                
                // Platform selection
                HStack {
                    Text("Platform")
                        .font(.system(size: Config.bodyFontSize))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Menu {
                        Button("Manual") { platform = "Manual" }
                        Button("Rover") { platform = "Rover" }
                        Button("Wag") { platform = "Wag" }
                        Button("Other") { platform = "Other" }
                    } label: {
                        HStack {
                            Text(platform)
                                .font(.system(size: Config.bodyFontSize))
                                .foregroundColor(.primary)
                            
                            Image(systemName: "chevron.down")
                                .font(.system(size: Config.captionFontSize))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .padding(Config.sectionSpacing)
        .background(Color.white)
        .cornerRadius(Config.cardCornerRadius)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Notes Section
    
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: Config.sectionSpacing) {
            Text("Notes (Optional)")
                .font(.system(size: Config.bodyFontSize, weight: .semibold))
                .foregroundColor(.primary)
            
            TextField("Add any additional notes...", text: $notes, axis: .vertical)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .lineLimit(3...6)
        }
        .padding(Config.sectionSpacing)
        .background(Color.white)
        .cornerRadius(Config.cardCornerRadius)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Validation
    
    private func validateForm() {
        let amountValue = Double(amount) ?? 0
        let hasValidAmount = amountValue > 0
        let hasClientName = !clientName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasPetName = !petName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        
        isValid = hasValidAmount && hasClientName && hasPetName
        
        if !hasValidAmount {
            errorMessage = "Please enter a valid amount"
        } else if !hasClientName {
            errorMessage = "Please enter a client name"
        } else if !hasPetName {
            errorMessage = "Please enter a pet name"
        } else {
            errorMessage = nil
        }
    }
    
    // MARK: - Save Action
    
    private func saveIncomeEntry() {
        guard isValid else { return }
        
        let amountValue = Double(amount) ?? 0
        let tipValue = Double(tip) ?? 0
        
        let entry = IncomeEntry(
            date: date,
            amount: amountValue,
            tip: tipValue,
            serviceType: serviceType,
            clientName: clientName.trimmingCharacters(in: .whitespacesAndNewlines),
            petName: petName.trimmingCharacters(in: .whitespacesAndNewlines),
            platform: platform,
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : notes
        )
        
        incomeService.addIncomeEntry(entry)
        dismiss()
    }
}

#Preview {
    AddIncomeView(incomeService: IncomeService())
} 