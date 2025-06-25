import Foundation
import MapKit
import Combine

class RouteOptimizationService: ObservableObject {
    @Published var isOptimizing = false
    @Published var optimizationProgress: Double = 0.0
    
    func optimizeRoute(visits: [Visit], startLocation: Coordinate? = nil) async throws -> Route {
        isOptimizing = true
        optimizationProgress = 0.0
        
        defer {
            isOptimizing = false
            optimizationProgress = 0.0
        }
        
        guard !visits.isEmpty else {
            throw RouteOptimizationError.noVisits
        }
        
        // For single visit, return as-is
        if visits.count == 1 {
            optimizationProgress = 1.0
            return Route(
                visits: visits,
                totalDistance: 0,
                totalTravelTime: 0,
                efficiency: 1.0,
                createdAt: Date()
            )
        }
        
        optimizationProgress = 0.3
        
        // Simple greedy optimization based on time windows
        let optimizedOrder = optimizeVisitOrder(visits: visits)
        
        optimizationProgress = 0.7
        
        // Calculate metrics for the optimized route
        let (totalDistance, totalTravelTime) = await calculateRouteMetrics(visits: optimizedOrder)
        
        optimizationProgress = 0.9
        
        // Calculate efficiency score
        let efficiency = calculateEfficiency(visits: optimizedOrder, totalDistance: totalDistance)
        
        optimizationProgress = 1.0
        
        return Route(
            visits: optimizedOrder,
            totalDistance: totalDistance,
            totalTravelTime: totalTravelTime,
            efficiency: efficiency,
            createdAt: Date()
        )
    }
    
    private func optimizeVisitOrder(visits: [Visit]) -> [Visit] {
        // Sort visits by their earliest start time to respect time constraints
        var sortedVisits = visits.sorted { visit1, visit2 in
            // Primary sort: start time
            if visit1.startTime != visit2.startTime {
                return visit1.startTime < visit2.startTime
            }
            // Secondary sort: flexibility (less flexible visits first)
            return !visit1.isFlexible && visit2.isFlexible
        }
        
        // For now, return the time-sorted order
        // In a production app, you could implement more sophisticated algorithms here
        return sortedVisits
    }
    
    private func calculateRouteMetrics(visits: [Visit]) async -> (Double, TimeInterval) {
        guard visits.count > 1 else { return (0, 0) }
        
        var totalDistance: Double = 0
        var totalTravelTime: TimeInterval = 0
        
        // Calculate distance and travel time between consecutive visits
        for i in 0..<visits.count - 1 {
            let fromCoordinate = visits[i].coordinate
            let toCoordinate = visits[i + 1].coordinate
            
            do {
                let metrics = try await calculateDirectRoute(from: fromCoordinate, to: toCoordinate)
                totalDistance += metrics.distance
                totalTravelTime += metrics.travelTime
            } catch {
                // If route calculation fails, use estimated values
                let estimatedDistance = estimateDistance(from: fromCoordinate, to: toCoordinate)
                totalDistance += estimatedDistance
                totalTravelTime += estimatedDistance * 120 // Rough estimate: 30 mph average
            }
        }
        
        return (totalDistance, totalTravelTime)
    }
    
    private func calculateDirectRoute(from: Coordinate, to: Coordinate) async throws -> RouteMetrics {
        return try await withCheckedThrowingContinuation { continuation in
            let request = MKDirections.Request()
            request.source = MKMapItem(placemark: MKPlacemark(coordinate: from.clLocation))
            request.destination = MKMapItem(placemark: MKPlacemark(coordinate: to.clLocation))
            request.transportType = .automobile
            
            let directions = MKDirections(request: request)
            directions.calculate { response, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let route = response?.routes.first else {
                    continuation.resume(throwing: RouteOptimizationError.routeCalculationFailed)
                    return
                }
                
                let metrics = RouteMetrics(
                    distance: route.distance * 0.000621371, // Convert meters to miles
                    travelTime: route.expectedTravelTime
                )
                continuation.resume(returning: metrics)
            }
        }
    }
    
    private func estimateDistance(from: Coordinate, to: Coordinate) -> Double {
        let earthRadius = 3959.0 // Earth's radius in miles
        
        let lat1Rad = from.latitude * .pi / 180
        let lat2Rad = to.latitude * .pi / 180
        let deltaLatRad = (to.latitude - from.latitude) * .pi / 180
        let deltaLonRad = (to.longitude - from.longitude) * .pi / 180
        
        let a = sin(deltaLatRad / 2) * sin(deltaLatRad / 2) +
                cos(lat1Rad) * cos(lat2Rad) *
                sin(deltaLonRad / 2) * sin(deltaLonRad / 2)
        
        let c = 2 * atan2(sqrt(a), sqrt(1 - a))
        
        return earthRadius * c
    }
    
    private func calculateEfficiency(visits: [Visit], totalDistance: Double) -> Double {
        // Simple efficiency calculation based on distance per visit
        guard !visits.isEmpty && totalDistance > 0 else { return 1.0 }
        
        let avgDistancePerVisit = totalDistance / Double(visits.count - 1)
        let baselineDistance = 10.0 // Assume 10 miles per visit as baseline
        
        return max(0.0, min(1.0, baselineDistance / avgDistancePerVisit))
    }
}

struct RouteMetrics {
    let distance: Double // in miles
    let travelTime: TimeInterval // in seconds
}

enum RouteOptimizationError: Error, LocalizedError {
    case noVisits
    case routeCalculationFailed
    case timeWindowConflict
    
    var errorDescription: String? {
        switch self {
        case .noVisits:
            return "No visits to optimize"
        case .routeCalculationFailed:
            return "Failed to calculate route between locations"
        case .timeWindowConflict:
            return "Visits have conflicting time windows"
        }
    }
} 