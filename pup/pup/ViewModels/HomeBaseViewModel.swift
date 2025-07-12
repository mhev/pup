import Foundation
import SwiftUI
import Combine
import CoreLocation

@MainActor
class HomeBaseViewModel: ObservableObject {
    @Published var homeBase: HomeBase = HomeBase()
    @Published var isEditing = false
    @Published var editingName = ""
    @Published var editingAddress = ""
    @Published var editingUseCurrentLocation = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let locationService = LocationService()
    private var cancellables = Set<AnyCancellable>()
    private let homeBaseKey = "SavedHomeBase"
    
    init() {
        loadHomeBase()
        setupBindings()
    }
    
    private func setupBindings() {
        // Listen for location updates when using current location
        locationService.$currentLocation
            .sink { [weak self] location in
                guard let self = self else { return }
                if self.homeBase.useCurrentLocation, let location = location {
                    self.updateHomeBaseWithCurrentLocation(location)
                }
            }
            .store(in: &cancellables)
    }
    
    func startEditing() {
        editingName = homeBase.name
        editingAddress = homeBase.address ?? ""
        editingUseCurrentLocation = homeBase.useCurrentLocation
        isEditing = true
        errorMessage = nil
    }
    
    func cancelEditing() {
        isEditing = false
        editingName = ""
        editingAddress = ""
        editingUseCurrentLocation = false
        errorMessage = nil
    }
    
    func saveHomeBase() {
        guard !editingName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Please enter a name for your home base"
            return
        }
        
        if editingUseCurrentLocation {
            saveWithCurrentLocation()
        } else {
            saveWithManualAddress()
        }
    }
    
    private func saveWithCurrentLocation() {
        guard locationService.authorizationStatus == .authorizedWhenInUse || 
              locationService.authorizationStatus == .authorizedAlways else {
            locationService.requestLocationPermission()
            errorMessage = "Location permission is required to use current location"
            return
        }
        
        if let currentLocation = locationService.currentLocation {
            updateHomeBaseWithCurrentLocation(currentLocation)
            homeBase.name = editingName.trimmingCharacters(in: .whitespacesAndNewlines)
            homeBase.useCurrentLocation = true
            homeBase.isSet = true
            persistHomeBase()
            isEditing = false
        } else {
            locationService.startLocationUpdates()
            errorMessage = "Getting current location..."
        }
    }
    
    private func saveWithManualAddress() {
        guard !editingAddress.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Please enter an address"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let coordinate = try await locationService.geocodeAddress(editingAddress)
                await MainActor.run {
                    self.homeBase = HomeBase(
                        name: self.editingName.trimmingCharacters(in: .whitespacesAndNewlines),
                        address: self.editingAddress.trimmingCharacters(in: .whitespacesAndNewlines),
                        coordinate: coordinate
                    )
                    self.persistHomeBase()
                    self.isEditing = false
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
    
    private func updateHomeBaseWithCurrentLocation(_ location: CLLocation) {
        let coordinate = Coordinate(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude
        )
        
        if homeBase.useCurrentLocation {
            homeBase.coordinate = coordinate
            homeBase.address = "Current Location"
            homeBase.isSet = true
            persistHomeBase()
        }
    }
    
    func requestLocationPermission() {
        locationService.requestLocationPermission()
    }
    
    func clearHomeBase() {
        homeBase = HomeBase()
        persistHomeBase()
    }
    
    // MARK: - Persistence
    private func persistHomeBase() {
        do {
            let data = try JSONEncoder().encode(homeBase)
            UserDefaults.standard.set(data, forKey: homeBaseKey)
        } catch {
            print("Failed to save home base: \(error)")
        }
    }
    
    private func loadHomeBase() {
        guard let data = UserDefaults.standard.data(forKey: homeBaseKey) else {
            return // No saved home base, use default
        }
        
        do {
            homeBase = try JSONDecoder().decode(HomeBase.self, from: data)
        } catch {
            print("Failed to load home base: \(error)")
            // Keep default home base if loading fails
        }
    }
} 