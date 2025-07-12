import Foundation
import SwiftUI
import CoreLocation
import UniformTypeIdentifiers

@MainActor
class CSVImportService: ObservableObject {
    @Published var isImporting = false
    @Published var importProgress: Double = 0.0
    @Published var errorMessage: String?
    @Published var previewData: [CSVPreviewRow] = []
    
    private let locationService = LocationService()
    
    // MARK: - Import Methods
    
    func importScheduleFromCSV(data: Data) async -> [Visit] {
        await MainActor.run {
            isImporting = true
            importProgress = 0.0
            errorMessage = nil
        }
        
        defer {
            Task { @MainActor in
                isImporting = false
                importProgress = 0.0
            }
        }
        
        do {
            let csvString = String(data: data, encoding: .utf8) ?? ""
            
            await MainActor.run {
                importProgress = 0.2
            }
            
            // Parse CSV content
            let rows = parseCSVString(csvString)
            
            await MainActor.run {
                importProgress = 0.4
            }
            
            // Detect CSV format (Rover, Wag, etc.)
            let format = detectCSVFormat(rows: rows)
            
            await MainActor.run {
                importProgress = 0.6
            }
            
            // Convert to visits based on format
            let visits = await convertRowsToVisits(rows: rows, format: format)
            
            await MainActor.run {
                importProgress = 1.0
            }
            
            return visits
            
        } catch {
            await MainActor.run {
                errorMessage = "Failed to import CSV: \(error.localizedDescription)"
            }
            return []
        }
    }
    
    func importIncomeFromCSV(data: Data) async -> [IncomeEntry] {
        await MainActor.run {
            isImporting = true
            importProgress = 0.0
            errorMessage = nil
        }
        
        defer {
            Task { @MainActor in
                isImporting = false
                importProgress = 0.0
            }
        }
        
        do {
            let csvString = String(data: data, encoding: .utf8) ?? ""
            
            await MainActor.run {
                importProgress = 0.2
            }
            
            // Parse CSV content
            let rows = parseCSVString(csvString)
            
            await MainActor.run {
                importProgress = 0.4
            }
            
            // Detect CSV format
            let format = detectCSVFormat(rows: rows)
            
            await MainActor.run {
                importProgress = 0.6
            }
            
            // Convert to income entries
            let incomeEntries = await convertRowsToIncomeEntries(rows: rows, format: format)
            
            await MainActor.run {
                importProgress = 1.0
            }
            
            return incomeEntries
            
        } catch {
            await MainActor.run {
                errorMessage = "Failed to import income CSV: \(error.localizedDescription)"
            }
            return []
        }
    }
    
    // MARK: - CSV Parsing
    
    private func parseCSVString(_ csvString: String) -> [[String]] {
        var rows: [[String]] = []
        let lines = csvString.components(separatedBy: .newlines)
        
        for line in lines {
            if !line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                let columns = parseCSVLine(line)
                rows.append(columns)
            }
        }
        
        return rows
    }
    
    private func parseCSVLine(_ line: String) -> [String] {
        var columns: [String] = []
        var currentColumn = ""
        var insideQuotes = false
        var i = line.startIndex
        
        while i < line.endIndex {
            let char = line[i]
            
            if char == "\"" {
                insideQuotes.toggle()
            } else if char == "," && !insideQuotes {
                columns.append(currentColumn.trimmingCharacters(in: .whitespacesAndNewlines))
                currentColumn = ""
            } else {
                currentColumn.append(char)
            }
            
            i = line.index(after: i)
        }
        
        // Add the last column
        columns.append(currentColumn.trimmingCharacters(in: .whitespacesAndNewlines))
        
        return columns
    }
    
    // MARK: - Format Detection
    
    private func detectCSVFormat(rows: [[String]]) -> CSVFormat {
        guard let header = rows.first else { return .unknown }
        
        let headerString = header.joined(separator: "|").lowercased()
        
        // Rover format detection
        if headerString.contains("sitter") && headerString.contains("owner") && headerString.contains("service") {
            return .rover
        }
        
        // Wag format detection
        if headerString.contains("dog walker") || headerString.contains("walk date") {
            return .wag
        }
        
        // Generic pet care format
        if headerString.contains("pet") || headerString.contains("client") || headerString.contains("visit") {
            return .generic
        }
        
        return .unknown
    }
    
    // MARK: - Data Conversion
    
    private func convertRowsToVisits(rows: [[String]], format: CSVFormat) async -> [Visit] {
        guard rows.count > 1 else { return [] }
        
        let header = rows[0]
        let dataRows = Array(rows.dropFirst())
        var visits: [Visit] = []
        
        for (index, row) in dataRows.enumerated() {
            await MainActor.run {
                importProgress = 0.6 + (Double(index) / Double(dataRows.count)) * 0.4
            }
            
            if let visit = await convertRowToVisit(row: row, header: header, format: format) {
                visits.append(visit)
            }
        }
        
        return visits
    }
    
    private func convertRowToVisit(row: [String], header: [String], format: CSVFormat) async -> Visit? {
        let data = createDataDictionary(row: row, header: header)
        
        switch format {
        case .rover:
            return await convertRoverRowToVisit(data: data)
        case .wag:
            return await convertWagRowToVisit(data: data)
        case .generic:
            return await convertGenericRowToVisit(data: data)
        case .unknown:
            return nil
        }
    }
    
    private func convertRoverRowToVisit(data: [String: String]) async -> Visit? {
        // Rover CSV format: Owner, Pet, Service, Date, Start Time, End Time, Address, etc.
        
        guard let clientName = data["owner"] ?? data["client"],
              let petName = data["pet"] ?? data["dog"],
              let serviceString = data["service"] ?? data["service type"],
              let dateString = data["date"] ?? data["visit date"],
              let address = data["address"] ?? data["location"],
              !clientName.isEmpty,
              !petName.isEmpty,
              !address.isEmpty else {
            return nil
        }
        
        // Parse date and time
        let startTime = parseDateTime(dateString: dateString, timeString: data["start time"])
        let endTime = parseDateTime(dateString: dateString, timeString: data["end time"]) ?? startTime.addingTimeInterval(3600)
        
        // Get coordinate
        guard let coordinate = await geocodeAddress(address) else {
            return nil
        }
        
        // Determine service type
        let serviceType = parseServiceType(serviceString)
        
        // Calculate duration
        let duration = endTime.timeIntervalSince(startTime) / 60 // Convert to minutes
        
        return Visit(
            clientName: clientName,
            petName: petName,
            address: address,
            coordinate: coordinate,
            startTime: startTime,
            endTime: endTime,
            duration: max(15, duration),
            serviceType: serviceType,
            notes: data["notes"] ?? data["special instructions"],
            isCompleted: endTime < Date()
        )
    }
    
    private func convertWagRowToVisit(data: [String: String]) async -> Visit? {
        // Wag CSV format: similar to Rover but with different column names
        
        guard let clientName = data["owner name"] ?? data["client"],
              let petName = data["dog name"] ?? data["pet name"],
              let dateString = data["walk date"] ?? data["date"],
              let address = data["address"] ?? data["pickup location"],
              !clientName.isEmpty,
              !petName.isEmpty,
              !address.isEmpty else {
            return nil
        }
        
        let startTime = parseDateTime(dateString: dateString, timeString: data["start time"])
        let endTime = parseDateTime(dateString: dateString, timeString: data["end time"]) ?? startTime.addingTimeInterval(1800) // 30 min default
        
        guard let coordinate = await geocodeAddress(address) else {
            return nil
        }
        
        let serviceType = parseServiceType(data["service"] ?? "walk")
        let duration = endTime.timeIntervalSince(startTime) / 60
        
        return Visit(
            clientName: clientName,
            petName: petName,
            address: address,
            coordinate: coordinate,
            startTime: startTime,
            endTime: endTime,
            duration: max(15, duration),
            serviceType: serviceType,
            notes: data["notes"],
            isCompleted: endTime < Date()
        )
    }
    
    private func convertGenericRowToVisit(data: [String: String]) async -> Visit? {
        // Generic format - try to find common column names
        
        let clientName = data["client"] ?? data["owner"] ?? data["customer"] ?? "Client"
        let petName = data["pet"] ?? data["dog"] ?? data["animal"] ?? "Pet"
        let address = data["address"] ?? data["location"] ?? ""
        let dateString = data["date"] ?? data["visit date"] ?? ""
        
        guard !address.isEmpty, !dateString.isEmpty else {
            return nil
        }
        
        let startTime = parseDateTime(dateString: dateString, timeString: data["time"] ?? data["start time"])
        let endTime = parseDateTime(dateString: dateString, timeString: data["end time"]) ?? startTime.addingTimeInterval(3600)
        
        guard let coordinate = await geocodeAddress(address) else {
            return nil
        }
        
        let serviceType = parseServiceType(data["service"] ?? data["type"] ?? "visit")
        let duration = endTime.timeIntervalSince(startTime) / 60
        
        return Visit(
            clientName: clientName,
            petName: petName,
            address: address,
            coordinate: coordinate,
            startTime: startTime,
            endTime: endTime,
            duration: max(15, duration),
            serviceType: serviceType,
            notes: data["notes"],
            isCompleted: endTime < Date()
        )
    }
    
    private func convertRowsToIncomeEntries(rows: [[String]], format: CSVFormat) async -> [IncomeEntry] {
        guard rows.count > 1 else { return [] }
        
        let header = rows[0]
        let dataRows = Array(rows.dropFirst())
        var incomeEntries: [IncomeEntry] = []
        
        for (index, row) in dataRows.enumerated() {
            await MainActor.run {
                importProgress = 0.6 + (Double(index) / Double(dataRows.count)) * 0.4
            }
            
            if let entry = convertRowToIncomeEntry(row: row, header: header, format: format) {
                incomeEntries.append(entry)
            }
        }
        
        return incomeEntries
    }
    
    private func convertRowToIncomeEntry(row: [String], header: [String], format: CSVFormat) -> IncomeEntry? {
        let data = createDataDictionary(row: row, header: header)
        
        // Common fields across platforms
        let amountString = data["amount"] ?? data["payout"] ?? data["earnings"] ?? data["total"] ?? ""
        let tipString = data["tip"] ?? data["gratuity"] ?? data["bonus"] ?? ""
        let dateString = data["date"] ?? data["payout date"] ?? data["service date"] ?? ""
        let serviceString = data["service"] ?? data["type"] ?? ""
        let clientName = data["client"] ?? data["owner"] ?? data["customer"] ?? ""
        let petName = data["pet"] ?? data["dog"] ?? ""
        
        // Parse amount
        let amount = parseAmount(amountString)
        guard amount > 0 else { return nil }
        
        // Parse tip
        let tip = parseAmount(tipString)
        
        // Parse date
        let date = parseDate(dateString) ?? Date()
        
        // Determine service type
        let serviceType = parseServiceType(serviceString)
        
        return IncomeEntry(
            date: date,
            amount: amount,
            tip: tip,
            serviceType: serviceType,
            clientName: clientName,
            petName: petName,
            platform: format.platformName,
            notes: data["notes"] ?? data["description"]
        )
    }
    
    // MARK: - Utility Methods
    
    private func createDataDictionary(row: [String], header: [String]) -> [String: String] {
        var data: [String: String] = [:]
        
        for (index, value) in row.enumerated() {
            if index < header.count {
                let key = header[index].lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
                data[key] = value.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        
        return data
    }
    
    private func parseDateTime(dateString: String, timeString: String?) -> Date {
        let formatter = DateFormatter()
        
        // Try different date formats
        let dateFormats = [
            "yyyy-MM-dd",
            "MM/dd/yyyy",
            "dd/MM/yyyy",
            "yyyy-MM-dd HH:mm:ss",
            "MM/dd/yyyy HH:mm:ss",
            "yyyy-MM-dd HH:mm",
            "MM/dd/yyyy HH:mm"
        ]
        
        // If we have separate date and time strings
        if let timeString = timeString, !timeString.isEmpty {
            let combinedString = "\(dateString) \(timeString)"
            
            for format in dateFormats {
                formatter.dateFormat = format
                if let date = formatter.date(from: combinedString) {
                    return date
                }
            }
        }
        
        // Try parsing the date string alone
        for format in dateFormats {
            formatter.dateFormat = format
            if let date = formatter.date(from: dateString) {
                return date
            }
        }
        
        return Date()
    }
    
    private func parseDate(_ dateString: String) -> Date? {
        let formatter = DateFormatter()
        
        let dateFormats = [
            "yyyy-MM-dd",
            "MM/dd/yyyy",
            "dd/MM/yyyy",
            "yyyy-MM-dd HH:mm:ss",
            "MM/dd/yyyy HH:mm:ss"
        ]
        
        for format in dateFormats {
            formatter.dateFormat = format
            if let date = formatter.date(from: dateString) {
                return date
            }
        }
        
        return nil
    }
    
    private func parseServiceType(_ serviceString: String) -> ServiceType {
        let service = serviceString.lowercased()
        
        if service.contains("walk") {
            return .walk
        } else if service.contains("overnight") || service.contains("boarding") {
            return .overnight
        } else if service.contains("sitting") {
            return .sitting
        } else {
            return .dropIn
        }
    }
    
    private func parseAmount(_ amountString: String) -> Double {
        let cleanAmount = amountString.replacingOccurrences(of: "$", with: "")
            .replacingOccurrences(of: ",", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        return Double(cleanAmount) ?? 0.0
    }
    
    private func geocodeAddress(_ address: String) async -> Coordinate? {
        let geocoder = CLGeocoder()
        
        do {
            let placemarks = try await geocoder.geocodeAddressString(address)
            if let location = placemarks.first?.location {
                return Coordinate(
                    latitude: location.coordinate.latitude,
                    longitude: location.coordinate.longitude
                )
            }
        } catch {
            print("❌ Geocoding failed for address '\(address)': \(error)")
        }
        
        return nil
    }
    
    // MARK: - Preview Methods
    
    func previewCSV(data: Data) async -> [CSVPreviewRow] {
        let csvString = String(data: data, encoding: .utf8) ?? ""
        let rows = parseCSVString(csvString)
        
        guard rows.count > 1 else { return [] }
        
        let header = rows[0]
        let dataRows = Array(rows.dropFirst().prefix(10)) // Preview first 10 rows
        let format = detectCSVFormat(rows: rows)
        
        return dataRows.map { row in
            CSVPreviewRow(
                data: createDataDictionary(row: row, header: header),
                format: format
            )
        }
    }
}

// MARK: - Supporting Types

enum CSVFormat {
    case rover
    case wag
    case generic
    case unknown
    
    var platformName: String {
        switch self {
        case .rover: return "Rover"
        case .wag: return "Wag"
        case .generic: return "Generic"
        case .unknown: return "Unknown"
        }
    }
}

struct CSVPreviewRow: Identifiable {
    let id = UUID()
    let data: [String: String]
    let format: CSVFormat
}

// MARK: - Income Entry Model (Forward Declaration)

struct IncomeEntry: Identifiable, Codable {
    let id = UUID()
    let date: Date
    let amount: Double
    let tip: Double
    let serviceType: ServiceType
    let clientName: String
    let petName: String
    let platform: String
    let notes: String?
    
    var total: Double {
        return amount + tip
    }
    
    var formattedAmount: String {
        return String(format: "$%.2f", amount)
    }
    
    var formattedTip: String {
        return String(format: "$%.2f", tip)
    }
    
    var formattedTotal: String {
        return String(format: "$%.2f", total)
    }
} 