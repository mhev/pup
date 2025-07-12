import Foundation
import CoreLocation
import SwiftUI
import Combine

struct MileageEntry: Identifiable, Codable {
    let id = UUID()
    let date: Date
    let startLocation: Coordinate
    let endLocation: Coordinate
    let distance: Double // in miles
    let duration: TimeInterval // in seconds
    let visitId: UUID?
    let purpose: MileagePurpose
    let isManual: Bool
    
    var formattedDistance: String {
        return String(format: "%.1f mi", distance)
    }
    
    var formattedDuration: String {
        let minutes = Int(duration / 60)
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        
        if hours > 0 {
            return "\(hours)h \(remainingMinutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    var estimatedDeduction: Double {
        // 2024 IRS mileage rate: $0.67 per mile
        return distance * 0.67
    }
}

enum MileagePurpose: String, CaseIterable, Codable {
    case business = "Business"
    case personal = "Personal"
    case commute = "Commute"
    
    var deductionRate: Double {
        switch self {
        case .business:
            return 0.67 // Full IRS rate
        case .personal:
            return 0.0 // Not deductible
        case .commute:
            return 0.0 // Not deductible
        }
    }
}

struct DailyMileageSummary: Identifiable {
    let id = UUID()
    let date: Date
    let totalDistance: Double
    let totalDuration: TimeInterval
    let businessDistance: Double
    let estimatedDeduction: Double
    let entryCount: Int
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    var formattedTotalDistance: String {
        return String(format: "%.1f mi", totalDistance)
    }
    
    var formattedBusinessDistance: String {
        return String(format: "%.1f mi", businessDistance)
    }
    
    var formattedDeduction: String {
        return String(format: "$%.2f", estimatedDeduction)
    }
}

@MainActor
class MileageTrackingService: NSObject, ObservableObject {
    @Published var mileageEntries: [MileageEntry] = []
    @Published var isTracking: Bool = false
    @Published var todaysMileage: Double = 0.0
    @Published var currentTripDistance: Double = 0.0
    @Published var currentTripStartTime: Date?
    @Published var currentTripStartLocation: CLLocation?
    
    private let locationManager = CLLocationManager()
    private var trackingLocations: [CLLocation] = []
    private var currentVisitId: UUID?
    private let userDefaults = UserDefaults.standard
    private let mileageEntriesKey = "SavedMileageEntries"
    
    // Location tracking parameters
    private let minimumDistance: CLLocationDistance = 10.0 // meters
    private let minimumSpeed: CLLocationSpeed = 2.0 // m/s (~4.5 mph)
    private let maximumSpeed: CLLocationSpeed = 35.0 // m/s (~78 mph)
    
    static let shared = MileageTrackingService()
    
    private override init() {
        super.init()
        setupLocationManager()
        loadMileageEntries()
        updateTodaysMileage()
    }
    
    // MARK: - Location Manager Setup
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = minimumDistance
        locationManager.pausesLocationUpdatesAutomatically = false
    }
    
    // MARK: - Tracking Control
    
    func startTracking(for visitId: UUID? = nil) {
        guard !isTracking else { return }
        
        // Check location permission
        guard locationManager.authorizationStatus == .authorizedAlways ||
              locationManager.authorizationStatus == .authorizedWhenInUse else {
            locationManager.requestAlwaysAuthorization()
            return
        }
        
        currentVisitId = visitId
        currentTripStartTime = Date()
        currentTripStartLocation = nil
        currentTripDistance = 0.0
        trackingLocations.removeAll()
        
        // Only enable background location updates if we have always authorization
        if locationManager.authorizationStatus == .authorizedAlways {
            locationManager.allowsBackgroundLocationUpdates = true
        }
        
        locationManager.startUpdatingLocation()
        isTracking = true
        
        print("🚗 Started mileage tracking for visit: \(visitId?.uuidString ?? "manual")")
    }
    
    func stopTracking() {
        guard isTracking else { return }
        
        locationManager.stopUpdatingLocation()
        
        // Disable background location updates when stopping tracking
        if locationManager.authorizationStatus == .authorizedAlways {
            locationManager.allowsBackgroundLocationUpdates = false
        }
        
        isTracking = false
        
        // Save the trip if it has meaningful distance
        if currentTripDistance > 0.1 { // At least 0.1 miles
            saveMileageEntry()
        }
        
        // Reset tracking state
        currentVisitId = nil
        currentTripStartTime = nil
        currentTripStartLocation = nil
        currentTripDistance = 0.0
        trackingLocations.removeAll()
        
        print("🛑 Stopped mileage tracking")
    }
    
    // MARK: - Manual Entry
    
    func addManualEntry(startAddress: String, endAddress: String, distance: Double, purpose: MileagePurpose) async {
        // Geocode addresses to get coordinates
        let geocoder = CLGeocoder()
        
        do {
            let startPlacemarks = try await geocoder.geocodeAddressString(startAddress)
            let endPlacemarks = try await geocoder.geocodeAddressString(endAddress)
            
            guard let startCoordinate = startPlacemarks.first?.location?.coordinate,
                  let endCoordinate = endPlacemarks.first?.location?.coordinate else {
                print("❌ Failed to geocode addresses")
                return
            }
            
            let entry = MileageEntry(
                date: Date(),
                startLocation: Coordinate(latitude: startCoordinate.latitude, longitude: startCoordinate.longitude),
                endLocation: Coordinate(latitude: endCoordinate.latitude, longitude: endCoordinate.longitude),
                distance: distance,
                duration: 0, // Manual entries don't have duration
                visitId: nil,
                purpose: purpose,
                isManual: true
            )
            
            mileageEntries.append(entry)
            saveMileageEntries()
            updateTodaysMileage()
            
        } catch {
            print("❌ Error geocoding addresses: \(error)")
        }
    }
    
    // MARK: - Data Management
    
    private func saveMileageEntry() {
        guard let startLocation = currentTripStartLocation,
              let startTime = currentTripStartTime else { return }
        
        let endLocation = trackingLocations.last ?? startLocation
        let duration = Date().timeIntervalSince(startTime)
        
        let entry = MileageEntry(
            date: Date(),
            startLocation: Coordinate(latitude: startLocation.coordinate.latitude, longitude: startLocation.coordinate.longitude),
            endLocation: Coordinate(latitude: endLocation.coordinate.latitude, longitude: endLocation.coordinate.longitude),
            distance: currentTripDistance,
            duration: duration,
            visitId: currentVisitId,
            purpose: .business, // Default for visit-based trips
            isManual: false
        )
        
        mileageEntries.append(entry)
        saveMileageEntries()
        updateTodaysMileage()
        
        print("💾 Saved mileage entry: \(entry.formattedDistance) in \(entry.formattedDuration)")
    }
    
    private func saveMileageEntries() {
        if let encoded = try? JSONEncoder().encode(mileageEntries) {
            userDefaults.set(encoded, forKey: mileageEntriesKey)
        }
    }
    
    private func loadMileageEntries() {
        if let data = userDefaults.data(forKey: mileageEntriesKey),
           let decoded = try? JSONDecoder().decode([MileageEntry].self, from: data) {
            mileageEntries = decoded
        }
    }
    
    // MARK: - Analytics
    
    private func updateTodaysMileage() {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        
        todaysMileage = mileageEntries
            .filter { $0.date >= today && $0.date < tomorrow }
            .reduce(0) { $0 + $1.distance }
    }
    
    func getDailyMileageSummaries(for period: DateInterval) -> [DailyMileageSummary] {
        let calendar = Calendar.current
        var summaries: [DailyMileageSummary] = []
        
        var currentDate = calendar.startOfDay(for: period.start)
        
        while currentDate <= period.end {
            let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
            
            let dayEntries = mileageEntries.filter { entry in
                entry.date >= currentDate && entry.date < nextDate
            }
            
            let totalDistance = dayEntries.reduce(0) { $0 + $1.distance }
            let totalDuration = dayEntries.reduce(0) { $0 + $1.duration }
            let businessDistance = dayEntries.filter { $0.purpose == .business }.reduce(0) { $0 + $1.distance }
            let estimatedDeduction = businessDistance * 0.67
            
            if totalDistance > 0 {
                summaries.append(DailyMileageSummary(
                    date: currentDate,
                    totalDistance: totalDistance,
                    totalDuration: totalDuration,
                    businessDistance: businessDistance,
                    estimatedDeduction: estimatedDeduction,
                    entryCount: dayEntries.count
                ))
            }
            
            currentDate = nextDate
        }
        
        return summaries.sorted { $0.date > $1.date }
    }
    
    func getWeeklyMileage() -> Double {
        let calendar = Calendar.current
        let now = Date()
        guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start else { return 0.0 }
        
        return mileageEntries
            .filter { $0.date >= weekStart }
            .reduce(0) { $0 + $1.distance }
    }
    
    func getMonthlyMileage() -> Double {
        let calendar = Calendar.current
        let now = Date()
        guard let monthStart = calendar.dateInterval(of: .month, for: now)?.start else { return 0.0 }
        
        return mileageEntries
            .filter { $0.date >= monthStart }
            .reduce(0) { $0 + $1.distance }
    }
    
    func getYearlyMileage() -> Double {
        let calendar = Calendar.current
        let now = Date()
        guard let yearStart = calendar.dateInterval(of: .year, for: now)?.start else { return 0.0 }
        
        return mileageEntries
            .filter { $0.date >= yearStart }
            .reduce(0) { $0 + $1.distance }
    }
    
    func getTotalBusinessMileage() -> Double {
        return mileageEntries
            .filter { $0.purpose == .business }
            .reduce(0) { $0 + $1.distance }
    }
    
    func getTotalEstimatedDeduction() -> Double {
        return mileageEntries
            .filter { $0.purpose == .business }
            .reduce(0) { $0 + $1.estimatedDeduction }
    }
    
    // MARK: - Export
    
    func exportMileageData() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        
        var csvContent = "Date,Start Location,End Location,Distance (mi),Duration,Purpose,Deduction\n"
        
        for entry in mileageEntries.sorted(by: { $0.date > $1.date }) {
            let dateString = formatter.string(from: entry.date)
            let startLoc = "\(entry.startLocation.latitude),\(entry.startLocation.longitude)"
            let endLoc = "\(entry.endLocation.latitude),\(entry.endLocation.longitude)"
            let distance = String(format: "%.2f", entry.distance)
            let duration = entry.formattedDuration
            let purpose = entry.purpose.rawValue
            let deduction = String(format: "%.2f", entry.estimatedDeduction)
            
            csvContent += "\(dateString),\(startLoc),\(endLoc),\(distance),\(duration),\(purpose),\(deduction)\n"
        }
        
        return csvContent
    }
}

// MARK: - CLLocationManagerDelegate

extension MileageTrackingService: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard isTracking else { return }
        
        for location in locations {
            // Filter out inaccurate locations
            guard location.horizontalAccuracy < 50 else { continue }
            
            // Filter out locations that are too slow or too fast
            guard location.speed >= minimumSpeed && location.speed <= maximumSpeed else { continue }
            
            if let previousLocation = trackingLocations.last {
                let distance = location.distance(from: previousLocation)
                let distanceInMiles = distance * 0.000621371 // Convert meters to miles
                
                // Only add distance if it's meaningful
                if distanceInMiles > 0.01 { // At least 0.01 miles
                    currentTripDistance += distanceInMiles
                    trackingLocations.append(location)
                }
            } else {
                // First location
                currentTripStartLocation = location
                trackingLocations.append(location)
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("❌ Location manager error: \(error)")
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            print("✅ Location permission granted")
        case .denied, .restricted:
            print("❌ Location permission denied")
            isTracking = false
        case .notDetermined:
            manager.requestAlwaysAuthorization()
        @unknown default:
            break
        }
    }
} 