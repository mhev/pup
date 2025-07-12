import Foundation
import EventKit
import CoreLocation
import SwiftUI

@MainActor
class CalendarImportService: ObservableObject {
    @Published var isImporting = false
    @Published var importProgress: Double = 0.0
    @Published var errorMessage: String?
    @Published var importedEvents: [EKEvent] = []
    
    private let eventStore = EKEventStore()
    private let locationService = LocationService()
    
    // MARK: - Authorization
    
    func requestCalendarAccess() async -> Bool {
        switch EKEventStore.authorizationStatus(for: .event) {
        case .authorized:
            return true
        case .notDetermined:
            do {
                return try await eventStore.requestAccess(to: .event)
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to request calendar access: \(error.localizedDescription)"
                }
                return false
            }
        case .denied, .restricted:
            await MainActor.run {
                errorMessage = "Calendar access denied. Please enable in Settings > Privacy & Security > Calendars"
            }
            return false
        @unknown default:
            return false
        }
    }
    
    // MARK: - Import Events
    
    func importEventsFromCalendar(dateRange: DateInterval) async -> [Visit] {
        guard await requestCalendarAccess() else {
            return []
        }
        
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
            // Get all calendars
            let calendars = eventStore.calendars(for: .event)
            
            await MainActor.run {
                importProgress = 0.2
            }
            
            // Create predicate for date range
            let predicate = eventStore.predicateForEvents(
                withStart: dateRange.start,
                end: dateRange.end,
                calendars: calendars
            )
            
            await MainActor.run {
                importProgress = 0.4
            }
            
            // Fetch events
            let events = eventStore.events(matching: predicate)
            
            await MainActor.run {
                importedEvents = events
                importProgress = 0.6
            }
            
            // Filter and convert relevant events to visits
            let visits = await convertEventsToVisits(events)
            
            await MainActor.run {
                importProgress = 1.0
            }
            
            return visits
            
        } catch {
            await MainActor.run {
                errorMessage = "Failed to import calendar events: \(error.localizedDescription)"
            }
            return []
        }
    }
    
    // MARK: - Event Conversion
    
    private func convertEventsToVisits(_ events: [EKEvent]) async -> [Visit] {
        var visits: [Visit] = []
        let totalEvents = events.count
        
        for (index, event) in events.enumerated() {
            await MainActor.run {
                importProgress = 0.6 + (Double(index) / Double(totalEvents)) * 0.4
            }
            
            // Only process events that might be pet-related
            if isPetRelatedEvent(event) {
                if let visit = await convertEventToVisit(event) {
                    visits.append(visit)
                }
            }
        }
        
        return visits
    }
    
    private func isPetRelatedEvent(_ event: EKEvent) -> Bool {
        let title = event.title?.lowercased() ?? ""
        let notes = event.notes?.lowercased() ?? ""
        let location = event.location?.lowercased() ?? ""
        
        let petKeywords = [
            "dog", "walk", "pet", "sitting", "rover", "wag", "puppy", "pup",
            "cat", "kitten", "visit", "drop-in", "overnight", "boarding",
            "doggy", "petsitting", "pet sitting", "dog walking", "dogwalking"
        ]
        
        return petKeywords.contains { keyword in
            title.contains(keyword) || notes.contains(keyword) || location.contains(keyword)
        }
    }
    
    private func convertEventToVisit(_ event: EKEvent) async -> Visit? {
        // Extract client and pet names from event title
        let (clientName, petName) = extractNamesFromTitle(event.title ?? "")
        
        // Use event location or try to extract from notes
        let address = event.location ?? extractAddressFromNotes(event.notes ?? "")
        
        guard !address.isEmpty else {
            print("⚠️ Skipping event '\(event.title ?? "Unknown")' - no address found")
            return nil
        }
        
        // Get coordinate for address
        guard let coordinate = await geocodeAddress(address) else {
            print("⚠️ Skipping event '\(event.title ?? "Unknown")' - failed to geocode address")
            return nil
        }
        
        // Determine service type from event details
        let serviceType = determineServiceType(from: event)
        
        // Calculate duration
        let duration = event.endDate.timeIntervalSince(event.startDate) / 60 // Convert to minutes
        
        return Visit(
            clientName: clientName,
            petName: petName,
            address: address,
            coordinate: coordinate,
            startTime: event.startDate,
            endTime: event.endDate,
            duration: max(15, duration), // Minimum 15 minutes
            serviceType: serviceType,
            notes: event.notes,
            isCompleted: event.endDate < Date()
        )
    }
    
    private func extractNamesFromTitle(_ title: String) -> (clientName: String, petName: String) {
        // Try to parse formats like "Walk Max (Johnson)" or "Pet Sitting - Bella & Charlie"
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Look for parentheses indicating client name
        if let range = cleanTitle.range(of: "\\(([^)]+)\\)", options: .regularExpression),
           let clientMatch = cleanTitle.range(of: "\\(([^)]+)\\)", options: .regularExpression) {
            let clientName = String(cleanTitle[clientMatch]).trimmingCharacters(in: CharacterSet(charactersIn: "()"))
            let petName = cleanTitle.replacingCharacters(in: range, with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: "Walk ", with: "")
                .replacingOccurrences(of: "Pet Sitting - ", with: "")
                .replacingOccurrences(of: "Drop-in - ", with: "")
            return (clientName, petName.isEmpty ? "Pet" : petName)
        }
        
        // Try to extract from dash-separated format
        if cleanTitle.contains(" - ") {
            let components = cleanTitle.components(separatedBy: " - ")
            if components.count >= 2 {
                let petName = components[1].trimmingCharacters(in: .whitespacesAndNewlines)
                return ("Client", petName.isEmpty ? "Pet" : petName)
            }
        }
        
        // Default extraction
        let words = cleanTitle.components(separatedBy: " ")
        if words.count >= 2 {
            let petName = words.last ?? "Pet"
            return ("Client", petName)
        }
        
        return ("Client", "Pet")
    }
    
    private func extractAddressFromNotes(_ notes: String) -> String {
        // Look for address patterns in notes
        let addressPattern = "([0-9]+\\s+[A-Za-z0-9\\s,]+(?:Street|St|Avenue|Ave|Road|Rd|Boulevard|Blvd|Drive|Dr|Lane|Ln|Circle|Cir|Court|Ct|Way))"
        
        if let range = notes.range(of: addressPattern, options: .regularExpression) {
            return String(notes[range]).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        return ""
    }
    
    private func determineServiceType(from event: EKEvent) -> ServiceType {
        let title = event.title?.lowercased() ?? ""
        let notes = event.notes?.lowercased() ?? ""
        let content = "\(title) \(notes)"
        
        if content.contains("walk") || content.contains("walking") {
            return .walk
        } else if content.contains("overnight") || content.contains("boarding") {
            return .overnight
        } else if content.contains("sitting") || content.contains("pet sitting") {
            return .sitting
        } else {
            return .dropIn
        }
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
    
    // MARK: - Utility Methods
    
    func getRecommendedDateRange() -> DateInterval {
        let calendar = Calendar.current
        let now = Date()
        
        // Default to next 30 days
        let startDate = calendar.startOfDay(for: now)
        let endDate = calendar.date(byAdding: .day, value: 30, to: startDate) ?? now
        
        return DateInterval(start: startDate, end: endDate)
    }
    
    func previewImportableEvents(dateRange: DateInterval) async -> [EKEvent] {
        guard await requestCalendarAccess() else {
            return []
        }
        
        let calendars = eventStore.calendars(for: .event)
        let predicate = eventStore.predicateForEvents(
            withStart: dateRange.start,
            end: dateRange.end,
            calendars: calendars
        )
        
        let events = eventStore.events(matching: predicate)
        return events.filter { isPetRelatedEvent($0) }
    }
} 