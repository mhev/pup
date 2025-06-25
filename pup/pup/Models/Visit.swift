import Foundation
import CoreLocation

struct Visit: Identifiable, Codable, Equatable {
    let id = UUID()
    let clientName: String
    let petName: String
    let address: String
    let coordinate: Coordinate
    let startTime: Date
    let endTime: Date
    let duration: TimeInterval // in minutes
    let serviceType: ServiceType
    let notes: String?
    let isCompleted: Bool
    
    var timeWindow: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return "\(formatter.string(from: startTime)) - \(formatter.string(from: endTime))"
    }
    
    var isFlexible: Bool {
        return endTime.timeIntervalSince(startTime) > duration * 60
    }
}

struct Coordinate: Codable, Equatable {
    let latitude: Double
    let longitude: Double
    
    var clLocation: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

enum ServiceType: String, CaseIterable, Codable {
    case walk = "Dog Walk"
    case sitting = "Pet Sitting"
    case dropIn = "Drop-in Visit"
    case overnight = "Overnight"
    
    var icon: String {
        switch self {
        case .walk: return "figure.walk"
        case .sitting: return "house.fill"
        case .dropIn: return "clock"
        case .overnight: return "moon.fill"
        }
    }
    
    var color: String {
        switch self {
        case .walk: return "blue"
        case .sitting: return "green"
        case .dropIn: return "orange"
        case .overnight: return "purple"
        }
    }
} 