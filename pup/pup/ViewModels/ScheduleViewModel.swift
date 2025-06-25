import Foundation
import SwiftUI
import Combine
import CoreLocation

@MainActor
class ScheduleViewModel: ObservableObject {
    @Published var visits: [Visit] = []
    @Published var optimizedRoute: Route?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedDate = Date()
    
    private let routeOptimizationService = RouteOptimizationService()
    private let locationService = LocationService()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupBindings()
        loadSampleData() // For demo purposes
    }
    
    private func setupBindings() {
        routeOptimizationService.$isOptimizing
            .assign(to: \.isLoading, on: self)
            .store(in: &cancellables)
    }
    
    func addVisit(_ visit: Visit) {
        visits.append(visit)
        optimizeCurrentRoute()
    }
    
    func removeVisit(_ visit: Visit) {
        visits.removeAll { $0.id == visit.id }
        optimizeCurrentRoute()
    }
    
    func markVisitCompleted(_ visit: Visit) {
        if let index = visits.firstIndex(where: { $0.id == visit.id }) {
            let updatedVisit = Visit(
                clientName: visit.clientName,
                petName: visit.petName,
                address: visit.address,
                coordinate: visit.coordinate,
                startTime: visit.startTime,
                endTime: visit.endTime,
                duration: visit.duration,
                serviceType: visit.serviceType,
                notes: visit.notes,
                isCompleted: true
            )
            visits[index] = updatedVisit
        }
    }
    
    func optimizeCurrentRoute() {
        let todaysVisits = visits.filter { Calendar.current.isDate($0.startTime, inSameDayAs: selectedDate) }
        
        guard !todaysVisits.isEmpty else {
            optimizedRoute = nil
            return
        }
        
        Task {
            do {
                let startCoordinate: Coordinate? = if let currentLocation = locationService.currentLocation {
                    Coordinate(latitude: currentLocation.coordinate.latitude, longitude: currentLocation.coordinate.longitude)
                } else {
                    nil
                }
                
                let route = try await routeOptimizationService.optimizeRoute(
                    visits: todaysVisits,
                    startLocation: startCoordinate
                )
                await MainActor.run {
                    self.optimizedRoute = route
                    self.errorMessage = nil
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.optimizedRoute = nil
                }
            }
        }
    }
    
    func requestLocationPermission() {
        locationService.requestLocationPermission()
    }
    
    var todaysVisits: [Visit] {
        visits.filter { Calendar.current.isDate($0.startTime, inSameDayAs: selectedDate) }
    }
    
    var upcomingVisits: [Visit] {
        todaysVisits
            .filter { !$0.isCompleted }
            .sorted { $0.startTime < $1.startTime }
    }
    
    var completedVisits: [Visit] {
        todaysVisits.filter { $0.isCompleted }
    }
    
    // MARK: - Sample Data (for demo)
    private func loadSampleData() {
        let calendar = Calendar.current
        let today = Date()
        
        let sampleVisits = [
            Visit(
                clientName: "Sarah Johnson",
                petName: "Max",
                address: "123 Downtown Austin, TX",
                coordinate: Coordinate(latitude: 30.2672, longitude: -97.7431),
                startTime: calendar.date(bySettingHour: 13, minute: 0, second: 0, of: today)!,
                endTime: calendar.date(bySettingHour: 15, minute: 0, second: 0, of: today)!,
                duration: 30,
                serviceType: .walk,
                notes: "Friendly golden retriever, loves treats",
                isCompleted: false
            ),
            Visit(
                clientName: "Mike Chen",
                petName: "Luna",
                address: "456 North Austin, TX",
                coordinate: Coordinate(latitude: 30.3077, longitude: -97.7555),
                startTime: calendar.date(bySettingHour: 16, minute: 30, second: 0, of: today)!,
                endTime: calendar.date(bySettingHour: 17, minute: 30, second: 0, of: today)!,
                duration: 45,
                serviceType: .sitting,
                notes: "Shy cat, needs medication at 5pm",
                isCompleted: false
            ),
            Visit(
                clientName: "Emily Rodriguez",
                petName: "Buddy",
                address: "789 South Austin, TX",
                coordinate: Coordinate(latitude: 30.2500, longitude: -97.7500),
                startTime: calendar.date(bySettingHour: 11, minute: 0, second: 0, of: today)!,
                endTime: calendar.date(bySettingHour: 12, minute: 0, second: 0, of: today)!,
                duration: 20,
                serviceType: .dropIn,
                notes: "Quick check-in and feed",
                isCompleted: false
            )
        ]
        
        visits = sampleVisits
        optimizeCurrentRoute()
    }
}

 