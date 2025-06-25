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
    @Published var serviceType: ServiceType = .walk
    @Published var notes = ""
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isFormValid = false
    
    private let locationService = LocationService()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupValidation()
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
            duration > 0
        }
        .assign(to: \.isFormValid, on: self)
        .store(in: &cancellables)
        
        // Automatically adjust end time when start time changes
        $startTime
            .sink { [weak self] newStartTime in
                guard let self = self else { return }
                // Keep the same duration when start time changes
                self.endTime = newStartTime.addingTimeInterval(self.duration * 60)
            }
            .store(in: &cancellables)
        
        // Automatically adjust end time when duration changes
        $duration
            .sink { [weak self] newDuration in
                guard let self = self else { return }
                self.endTime = self.startTime.addingTimeInterval(newDuration * 60)
            }
            .store(in: &cancellables)
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
            let coordinate = try await locationService.geocodeAddress(address)
            
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
            
            return visit
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    func resetForm() {
        clientName = ""
        petName = ""
        address = ""
        startTime = Date()
        endTime = Date().addingTimeInterval(3600)
        duration = 30
        serviceType = .walk
        notes = ""
        errorMessage = nil
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