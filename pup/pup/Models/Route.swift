import Foundation
import MapKit

struct Route: Identifiable {
    let id = UUID()
    let visits: [Visit]
    let totalDistance: Double // in miles
    let totalTravelTime: TimeInterval // in seconds
    let efficiency: Double // percentage score
    let createdAt: Date
    let aiReasoning: String? // Gemini's explanation of the optimization
    let feasibleRoute: Bool // Whether all visits could be accommodated
    
    var formattedDistance: String {
        return String(format: "%.1f mi", totalDistance)
    }
    
    var formattedTravelTime: String {
        let hours = Int(totalTravelTime) / 3600
        let minutes = Int(totalTravelTime.truncatingRemainder(dividingBy: 3600)) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    var efficiencyColor: String {
        switch efficiency {
        case 0.8...1.0: return "green"
        case 0.6..<0.8: return "yellow"
        default: return "red"
        }
    }
    
    var feasibilityColor: String {
        return feasibleRoute ? "green" : "red"
    }
    
    var feasibilityText: String {
        return feasibleRoute ? "All visits scheduled" : "Some visits excluded"
    }
}

struct RouteStep {
    let from: Visit?
    let to: Visit
    let distance: Double
    let travelTime: TimeInterval
    let polyline: MKPolyline?
} 