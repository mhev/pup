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
    
    @Published var homeBaseViewModel = HomeBaseViewModel()
    @Published var savedClientsService = SavedClientsService()
    
    private let routeOptimizationService = GeminiRouteOptimizationService()
    private let locationService = LocationService()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Persistence
    private let userDefaults = UserDefaults.standard
    private let visitsKey = "SavedVisits"
    
    init() {
        setupBindings()
        loadPersistedVisits()
    }
    
    private func setupBindings() {
        routeOptimizationService.$isOptimizing
            .assign(to: \.isLoading, on: self)
            .store(in: &cancellables)
        
        // Clear optimized route when home base or date changes
        homeBaseViewModel.$homeBase
            .sink { [weak self] _ in
                self?.clearOptimizedRoute()
            }
            .store(in: &cancellables)
        
        // Clear optimized route when selected date changes
        $selectedDate
            .sink { [weak self] _ in
                self?.clearOptimizedRoute()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Visit Management
    func addVisit(_ visit: Visit) {
        visits.append(visit)
        clearOptimizedRoute()
        persistVisits()
    }
    
    func removeVisit(_ visit: Visit) {
        visits.removeAll { $0.id == visit.id }
        clearOptimizedRoute()
        persistVisits()
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
            persistVisits()
        }
    }
    
    func deleteAllSchedules() {
        visits.removeAll()
        clearOptimizedRoute()
        persistVisits()
    }
    
    // MARK: - Persistence Methods
    private func persistVisits() {
        do {
            let data = try JSONEncoder().encode(visits)
            userDefaults.set(data, forKey: visitsKey)
        } catch {
            print("Failed to save visits: \(error)")
        }
    }
    
    private func loadPersistedVisits() {
        guard let data = userDefaults.data(forKey: visitsKey) else {
            // No persisted data - start with empty visits
            visits = []
            return
        }
        
        do {
            visits = try JSONDecoder().decode([Visit].self, from: data)
        } catch {
            print("Failed to load visits: \(error)")
            // Failed to decode - start with empty visits
            visits = []
        }
    }
    
    func optimizeCurrentRoute() {
        let todaysVisits = visits.filter { Calendar.current.isDate($0.startTime, inSameDayAs: selectedDate) && !$0.isCompleted }
        
        guard !todaysVisits.isEmpty else {
            optimizedRoute = nil
            return
        }
        
        Task {
            do {
                // Use home base if set, otherwise fall back to current location
                let startCoordinate: Coordinate? = if homeBaseViewModel.homeBase.isReady {
                    homeBaseViewModel.homeBase.coordinate
                } else if let currentLocation = locationService.currentLocation {
                    Coordinate(latitude: currentLocation.coordinate.latitude, longitude: currentLocation.coordinate.longitude)
                } else {
                    nil
                }
                
                let route = try await routeOptimizationService.optimizeRoute(
                    visits: todaysVisits,
                    homeBase: homeBaseViewModel.homeBase.isReady ? homeBaseViewModel.homeBase : nil
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
    
    func clearOptimizedRoute() {
        optimizedRoute = nil
    }
    
    func requestLocationPermission() {
        locationService.requestLocationPermission()
    }
    
    // MARK: - Date Navigation
    func goToPreviousDay() {
        selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
    }
    
    func goToNextDay() {
        selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
    }
    
    func goToToday() {
        selectedDate = Date()
    }
    
    func goToDate(_ date: Date) {
        selectedDate = date
    }
    
    var isToday: Bool {
        Calendar.current.isDate(selectedDate, inSameDayAs: Date())
    }
    
    var isTomorrow: Bool {
        guard let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) else { return false }
        return Calendar.current.isDate(selectedDate, inSameDayAs: tomorrow)
    }
    
    var selectedDateTitle: String {
        let formatter = DateFormatter()
        
        if isToday {
            return "Today's Schedule"
        } else if isTomorrow {
            return "Tomorrow's Schedule"
        } else {
            formatter.dateFormat = "EEEE, MMM d"
            return formatter.string(from: selectedDate)
        }
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
}

 