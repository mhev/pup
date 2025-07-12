import Foundation
import SwiftUI
import Combine
import CoreLocation

@MainActor
class AddVisitViewModel: ObservableObject {
    @Published var clientName = ""
    @Published var petName = ""
    @Published var address = ""
    @Published var startTime = Date()
    @Published var endTime = Date().addingTimeInterval(3600) // 1 hour later
    @Published var duration: Double = 30 // minutes
    @Published var serviceType: ServiceType = .dropIn // Changed default to Drop-in
    @Published var notes = ""
    @Published var selectedSavedClient: SavedClient?
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isFormValid = false
    
    private let locationService = LocationService()
    @Published var savedClientsService = SavedClientsService()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupValidation()
        roundTimeToNearestFiveMinutes()
    }
    
    private func setupValidation() {
        Publishers.CombineLatest4(
            $clientName,
            $petName,
            $address,
            $duration
        )
        .map { clientName, petName, address, duration in
            !clientName.isEmpty && 
            !petName.isEmpty && 
            !address.isEmpty && 
            duration >= 10 // Changed minimum to 10 minutes
        }
        .assign(to: \.isFormValid, on: self)
        .store(in: &cancellables)
        
        // Automatically adjust end time when start time changes
        $startTime
            .sink { [weak self] newStartTime in
                guard let self = self else { return }
                // Round to nearest 5 minutes
                let roundedStartTime = self.roundToNearestFiveMinutes(newStartTime)
                if roundedStartTime != newStartTime {
                    self.startTime = roundedStartTime
                    return
                }
                // Keep the same duration when start time changes
                self.endTime = roundedStartTime.addingTimeInterval(self.duration * 60)
            }
            .store(in: &cancellables)
        
        // Automatically adjust end time when duration changes
        $duration
            .sink { [weak self] newDuration in
                guard let self = self else { return }
                self.endTime = self.startTime.addingTimeInterval(newDuration * 60)
            }
            .store(in: &cancellables)
        
        // Round end time to nearest 5 minutes when it changes
        $endTime
            .sink { [weak self] newEndTime in
                guard let self = self else { return }
                let roundedEndTime = self.roundToNearestFiveMinutes(newEndTime)
                if roundedEndTime != newEndTime {
                    self.endTime = roundedEndTime
                }
            }
            .store(in: &cancellables)
    }
    
    func selectSavedClient(_ client: SavedClient) {
        selectedSavedClient = client
        clientName = client.clientName
        petName = client.petName
        address = client.address
    }
    
    func clearSelectedClient() {
        selectedSavedClient = nil
        clientName = ""
        petName = ""
        address = ""
    }
    
    private func roundTimeToNearestFiveMinutes() {
        startTime = roundToNearestFiveMinutes(startTime)
        endTime = roundToNearestFiveMinutes(endTime)
    }
    
    private func roundToNearestFiveMinutes(_ date: Date) -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        
        guard let minute = components.minute else { return date }
        
        let roundedMinute = (minute / 5) * 5
        
        var newComponents = components
        newComponents.minute = roundedMinute
        newComponents.second = 0
        
        return calendar.date(from: newComponents) ?? date
    }
    
    func createVisit() async throws -> Visit {
        guard isFormValid else {
            throw AddVisitError.invalidForm
        }
        
        isLoading = true
        errorMessage = nil
        
        defer {
            isLoading = false
        }
        
        do {
            let coordinate: Coordinate
            
            // Use coordinate from saved client if available, otherwise geocode
            if let savedClient = selectedSavedClient,
               savedClient.address == address.trimmingCharacters(in: .whitespacesAndNewlines) {
                coordinate = savedClient.coordinate
            } else {
                coordinate = try await locationService.geocodeAddress(address)
            }
            
            let visit = Visit(
                clientName: clientName.trimmingCharacters(in: .whitespacesAndNewlines),
                petName: petName.trimmingCharacters(in: .whitespacesAndNewlines),
                address: address.trimmingCharacters(in: .whitespacesAndNewlines),
                coordinate: coordinate,
                startTime: startTime,
                endTime: endTime,
                duration: duration,
                serviceType: serviceType,
                notes: notes.isEmpty ? nil : notes.trimmingCharacters(in: .whitespacesAndNewlines),
                isCompleted: false
            )
            
            // Save client for future use
            savedClientsService.saveClientFromVisit(visit)
            
            return visit
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    func resetForm() {
        selectedSavedClient = nil
        clientName = ""
        petName = ""
        address = ""
        startTime = Date()
        endTime = Date().addingTimeInterval(3600)
        duration = 30
        serviceType = .dropIn // Changed default to Drop-in
        notes = ""
        errorMessage = nil
        roundTimeToNearestFiveMinutes()
    }
    
    func setDefaultDate(_ date: Date) {
        // Set the start time to the selected date with a default hour (9 AM)
        let calendar = Calendar.current
        if let defaultStartTime = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: date) {
            startTime = roundToNearestFiveMinutes(defaultStartTime)
            endTime = startTime.addingTimeInterval(duration * 60)
        }
    }
    
    var timeWindowDuration: TimeInterval {
        endTime.timeIntervalSince(startTime)
    }
    
    var isTimeWindowValid: Bool {
        timeWindowDuration >= duration * 60
    }
    
    var formattedDuration: String {
        let hours = Int(duration) / 60
        let minutes = Int(duration.truncatingRemainder(dividingBy: 60))
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

enum AddVisitError: Error, LocalizedError {
    case invalidForm
    case geocodingFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidForm:
            return "Please fill in all required fields"
        case .geocodingFailed:
            return "Unable to find the specified address"
        }
    }
} 