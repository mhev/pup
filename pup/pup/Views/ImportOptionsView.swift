import SwiftUI
import UniformTypeIdentifiers

struct ImportOptionsView: View {
    @ObservedObject var incomeService: IncomeService
    @StateObject private var calendarService = CalendarImportService()
    @StateObject private var csvService = CSVImportService()
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedImportType: ImportType = .calendar
    @State private var showingFilePicker = false
    @State private var showingScheduleImport = false
    @State private var showingIncomeImport = false
    @State private var importedData: Data?
    @State private var previewVisits: [Visit] = []
    @State private var previewIncome: [IncomeEntry] = []
    
    enum ImportType {
        case calendar, csv
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Config.primaryColor
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: Config.largeSpacing) {
                        // Header
                        headerSection
                        
                        // Import type selector
                        importTypeSelector
                        
                        // Import content
                        if selectedImportType == .calendar {
                            calendarImportSection
                        } else {
                            csvImportSection
                        }
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, Config.largeSpacing)
                }
                .navigationTitle("Import Data")
                .navigationBarTitleDisplayMode(.inline)
                .translucentHeader()
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            dismiss()
                        }
                        .foregroundColor(Config.evergreenColor)
                    }
                }
            }
        }
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [UTType.commaSeparatedText],
            allowsMultipleSelection: false
        ) { result in
            handleFileImport(result: result)
        }
        .sheet(isPresented: $showingScheduleImport) {
            ScheduleImportPreview(visits: previewVisits, onImport: importSchedule)
        }
        .sheet(isPresented: $showingIncomeImport) {
            IncomeImportPreview(incomeEntries: previewIncome, onImport: importIncome)
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: Config.sectionSpacing) {
            Text("📊")
                .font(.system(size: Config.largeFontSize))
            
            Text("Import your existing data")
                .font(.system(size: Config.bodyFontSize))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, Config.sectionSpacing)
    }
    
    // MARK: - Import Type Selector
    
    private var importTypeSelector: some View {
        VStack(alignment: .leading, spacing: Config.sectionSpacing) {
            Text("Import Source")
                .font(.system(size: Config.bodyFontSize, weight: .semibold))
                .foregroundColor(.primary)
            
            HStack(spacing: Config.sectionSpacing) {
                ImportTypeButton(
                    icon: "calendar",
                    title: "Calendar",
                    subtitle: "Import from iPhone Calendar",
                    isSelected: selectedImportType == .calendar,
                    action: { selectedImportType = .calendar }
                )
                
                ImportTypeButton(
                    icon: "doc.text",
                    title: "CSV File",
                    subtitle: "Import from Rover, Wag, etc.",
                    isSelected: selectedImportType == .csv,
                    action: { selectedImportType = .csv }
                )
            }
        }
        .padding(Config.sectionSpacing)
        .background(Color.white)
        .cornerRadius(Config.cardCornerRadius)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Calendar Import Section
    
    private var calendarImportSection: some View {
        VStack(alignment: .leading, spacing: Config.sectionSpacing) {
            Text("Calendar Import")
                .font(.system(size: Config.bodyFontSize, weight: .semibold))
                .foregroundColor(.primary)
            
            VStack(spacing: Config.sectionSpacing) {
                InfoRow(
                    icon: "info.circle",
                    title: "What we'll import",
                    description: "Pet-related events from your iPhone calendar"
                )
                
                InfoRow(
                    icon: "calendar.badge.clock",
                    title: "Date Range",
                    description: "Next 30 days of calendar events"
                )
                
                InfoRow(
                    icon: "checkmark.shield",
                    title: "Privacy",
                    description: "Data stays on your device, requires calendar permission"
                )
                
                if calendarService.errorMessage != nil {
                    Text(calendarService.errorMessage!)
                        .font(.system(size: Config.captionFontSize))
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(Config.smallCornerRadius)
                }
                
                Button(action: importFromCalendar) {
                    HStack {
                        if calendarService.isImporting {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "calendar")
                        }
                        
                        Text(calendarService.isImporting ? "Importing..." : "Import from Calendar")
                    }
                    .font(.system(size: Config.bodyFontSize, weight: .medium))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Config.sectionSpacing)
                    .background(Config.evergreenColor)
                    .cornerRadius(Config.buttonCornerRadius)
                }
                .disabled(calendarService.isImporting)
            }
        }
        .padding(Config.sectionSpacing)
        .background(Color.white)
        .cornerRadius(Config.cardCornerRadius)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - CSV Import Section
    
    private var csvImportSection: some View {
        VStack(alignment: .leading, spacing: Config.sectionSpacing) {
            Text("CSV Import")
                .font(.system(size: Config.bodyFontSize, weight: .semibold))
                .foregroundColor(.primary)
            
            VStack(spacing: Config.sectionSpacing) {
                InfoRow(
                    icon: "doc.text",
                    title: "Supported Formats",
                    description: "Rover, Wag, or any CSV with visit/income data"
                )
                
                InfoRow(
                    icon: "square.and.arrow.up",
                    title: "How to get CSV",
                    description: "Download from your platform's earnings or booking section"
                )
                
                InfoRow(
                    icon: "eye",
                    title: "Preview First",
                    description: "Review data before importing to your app"
                )
                
                if csvService.errorMessage != nil {
                    Text(csvService.errorMessage!)
                        .font(.system(size: Config.captionFontSize))
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(Config.smallCornerRadius)
                }
                
                VStack(spacing: Config.sectionSpacing) {
                    Button(action: { showingFilePicker = true }) {
                        HStack {
                            if csvService.isImporting {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "doc.badge.plus")
                            }
                            
                            Text(csvService.isImporting ? "Processing..." : "Choose CSV File")
                        }
                        .font(.system(size: Config.bodyFontSize, weight: .medium))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Config.sectionSpacing)
                        .background(Config.evergreenColor)
                        .cornerRadius(Config.buttonCornerRadius)
                    }
                    .disabled(csvService.isImporting)
                    
                    Text("Supported file types: .csv")
                        .font(.system(size: Config.captionFontSize))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(Config.sectionSpacing)
        .background(Color.white)
        .cornerRadius(Config.cardCornerRadius)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Actions
    
    private func importFromCalendar() {
        Task {
            let dateRange = calendarService.getRecommendedDateRange()
            let visits = await calendarService.importEventsFromCalendar(dateRange: dateRange)
            
            await MainActor.run {
                if !visits.isEmpty {
                    previewVisits = visits
                    showingScheduleImport = true
                }
            }
        }
    }
    
    private func handleFileImport(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            
            do {
                let data = try Data(contentsOf: url)
                importedData = data
                
                Task {
                    // Try to import as both schedule and income data
                    let visits = await csvService.importScheduleFromCSV(data: data)
                    let income = await csvService.importIncomeFromCSV(data: data)
                    
                    await MainActor.run {
                        if !visits.isEmpty {
                            previewVisits = visits
                            showingScheduleImport = true
                        } else if !income.isEmpty {
                            previewIncome = income
                            showingIncomeImport = true
                        }
                    }
                }
                
            } catch {
                csvService.errorMessage = "Failed to read file: \(error.localizedDescription)"
            }
            
        case .failure(let error):
            csvService.errorMessage = "Failed to import file: \(error.localizedDescription)"
        }
    }
    
    private func importSchedule(_ visits: [Visit]) {
        // Import to schedule view model
        // This would need to be connected to the main app's schedule service
        dismiss()
    }
    
    private func importIncome(_ incomeEntries: [IncomeEntry]) {
        incomeService.importIncomeEntries(incomeEntries)
        dismiss()
    }
}

// MARK: - Supporting Views

struct ImportTypeButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: Config.smallSpacing) {
                Image(systemName: icon)
                    .font(.system(size: Config.bodyFontSize))
                    .foregroundColor(isSelected ? .white : Config.evergreenColor)
                
                Text(title)
                    .font(.system(size: Config.bodyFontSize, weight: .medium))
                    .foregroundColor(isSelected ? .white : .primary)
                
                Text(subtitle)
                    .font(.system(size: Config.captionFontSize))
                    .foregroundColor(isSelected ? .white : .secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Config.sectionSpacing)
            .background(isSelected ? Config.evergreenColor : Color.clear)
            .cornerRadius(Config.smallCornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: Config.smallCornerRadius)
                    .stroke(Config.evergreenColor, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct InfoRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: Config.sectionSpacing) {
            Image(systemName: icon)
                .font(.system(size: Config.bodyFontSize))
                .foregroundColor(Config.evergreenColor)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: Config.smallSpacing) {
                Text(title)
                    .font(.system(size: Config.bodyFontSize, weight: .medium))
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.system(size: Config.captionFontSize))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

struct ScheduleImportPreview: View {
    let visits: [Visit]
    let onImport: ([Visit]) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: Config.largeSpacing) {
                Text("Found \(visits.count) visits to import")
                    .font(.system(size: Config.bodyFontSize, weight: .semibold))
                    .foregroundColor(.primary)
                
                List(visits.prefix(10)) { visit in
                    VStack(alignment: .leading, spacing: Config.smallSpacing) {
                        Text("\(visit.clientName) - \(visit.petName)")
                            .font(.system(size: Config.bodyFontSize, weight: .medium))
                        
                        Text(visit.timeWindow)
                            .font(.system(size: Config.captionFontSize))
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, Config.smallSpacing)
                }
                
                Button(action: {
                    onImport(visits)
                    dismiss()
                }) {
                    Text("Import \(visits.count) Visits")
                        .font(.system(size: Config.bodyFontSize, weight: .medium))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Config.sectionSpacing)
                        .background(Config.evergreenColor)
                        .cornerRadius(Config.buttonCornerRadius)
                }
                .padding(.horizontal, Config.largeSpacing)
            }
            .navigationTitle("Preview Import")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct IncomeImportPreview: View {
    let incomeEntries: [IncomeEntry]
    let onImport: ([IncomeEntry]) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: Config.largeSpacing) {
                Text("Found \(incomeEntries.count) income entries to import")
                    .font(.system(size: Config.bodyFontSize, weight: .semibold))
                    .foregroundColor(.primary)
                
                List(incomeEntries.prefix(10)) { entry in
                    VStack(alignment: .leading, spacing: Config.smallSpacing) {
                        Text("\(entry.clientName) - \(entry.petName)")
                            .font(.system(size: Config.bodyFontSize, weight: .medium))
                        
                        HStack {
                            Text(entry.formattedTotal)
                                .font(.system(size: Config.captionFontSize))
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text(DateFormatter.shortDate.string(from: entry.date))
                                .font(.system(size: Config.captionFontSize))
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, Config.smallSpacing)
                }
                
                Button(action: {
                    onImport(incomeEntries)
                    dismiss()
                }) {
                    Text("Import \(incomeEntries.count) Entries")
                        .font(.system(size: Config.bodyFontSize, weight: .medium))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Config.sectionSpacing)
                        .background(Config.evergreenColor)
                        .cornerRadius(Config.buttonCornerRadius)
                }
                .padding(.horizontal, Config.largeSpacing)
            }
            .navigationTitle("Preview Import")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    ImportOptionsView(incomeService: IncomeService())
} 