import Foundation
import MapKit
import Combine

class GeminiRouteOptimizationService: ObservableObject {
    @Published var isOptimizing = false
    @Published var optimizationProgress: Double = 0.0
    
    private let geminiService = GeminiService()
    
    func optimizeRoute(visits: [Visit], homeBase: HomeBase? = nil) async throws -> Route {
        await MainActor.run {
            isOptimizing = true
            optimizationProgress = 0.0
        }
        
        defer {
            Task { @MainActor in
                isOptimizing = false
                optimizationProgress = 0.0
            }
        }
        
        guard !visits.isEmpty else {
            throw RouteOptimizationError.noVisits
        }
        
        // For single visit, return as-is
        if visits.count == 1 {
            await MainActor.run {
                optimizationProgress = 1.0
            }
            return Route(
                visits: visits,
                totalDistance: 0,
                totalTravelTime: 0,
                efficiency: 1.0,
                createdAt: Date(),
                aiReasoning: "Single visit - no optimization needed"
            )
        }
        
        await MainActor.run {
            optimizationProgress = 0.2
        }
        
        do {
            // Get optimization from Gemini AI
            let geminiResponseText = try await geminiService.optimizeRoute(visits: visits, homeBase: homeBase)
            
            print("🔍 DEBUG: Gemini response received:")
            print("🔍 DEBUG: Response text: \(geminiResponseText)")
            
            await MainActor.run {
                optimizationProgress = 0.7
            }
            
            // Parse the text response to extract visit order and reasoning
            let parsedResponse = parseGeminiResponse(geminiResponseText, originalVisits: visits)
            
            await MainActor.run {
                optimizationProgress = 0.9
            }
            
            // Create route with parsed information
            let route = Route(
                visits: parsedResponse.visits,
                totalDistance: parsedResponse.estimatedDistance,
                totalTravelTime: parsedResponse.estimatedTravelTime,
                efficiency: parsedResponse.efficiency,
                createdAt: Date(),
                aiReasoning: parsedResponse.reasoning
            )
            
            await MainActor.run {
                optimizationProgress = 1.0
            }
            return route
            
        } catch {
            // If Gemini fails, fall back to basic optimization
            print("❌ DEBUG: Gemini optimization failed: \(error.localizedDescription)")
            return try await fallbackOptimization(visits: visits, homeBase: homeBase)
        }
    }
    
    // MARK: - Response Parsing
    
    private struct GeminiParsedResponse {
        let visits: [Visit]
        let estimatedDistance: Double
        let estimatedTravelTime: TimeInterval
        let efficiency: Double
        let reasoning: String
    }
    
    private func parseGeminiResponse(_ responseText: String, originalVisits: [Visit]) -> GeminiParsedResponse {
        print("🔍 DEBUG: Parsing Gemini response...")
        
        // Try to parse as JSON first (Gemini often returns JSON in markdown code blocks)
        if let jsonResponse = extractAndParseJSON(from: responseText) {
            print("✅ DEBUG: Successfully parsed JSON response")
            
            let optimizedVisits = reorderVisitsFromJSON(jsonResponse: jsonResponse, originalVisits: originalVisits)
            let reasoning = cleanReasoning(jsonResponse["reasoning"] as? String ?? "AI optimization completed")
            
            // Use values from JSON if available, otherwise use defaults
            let estimatedDistance = jsonResponse["estimatedTotalDistance"] as? Double ?? 25.0
            let estimatedTravelTime = TimeInterval((jsonResponse["estimatedTotalTime"] as? Double ?? 90) * 60) // Convert minutes to seconds
            let efficiency = (jsonResponse["efficiency"] as? Double ?? 85.0) / 100.0 // Convert percentage to decimal
            
            return GeminiParsedResponse(
                visits: optimizedVisits,
                estimatedDistance: estimatedDistance,
                estimatedTravelTime: estimatedTravelTime,
                efficiency: efficiency,
                reasoning: reasoning
            )
        }
        
        // Fallback to text parsing if JSON parsing fails
        print("⚠️ DEBUG: JSON parsing failed, falling back to text parsing")
        let optimizedVisits = extractVisitOrder(from: responseText, originalVisits: originalVisits)
        let reasoning = extractReasoning(from: responseText)
        
        return GeminiParsedResponse(
            visits: optimizedVisits,
            estimatedDistance: 25.0,
            estimatedTravelTime: 90 * 60,
            efficiency: 0.85,
            reasoning: reasoning
        )
    }
    
    private func extractAndParseJSON(from text: String) -> [String: Any]? {
        // Look for JSON in markdown code blocks
        let jsonPatterns = [
            "```json\\s*([\\s\\S]*?)\\s*```",  // ```json ... ```
            "```\\s*([\\s\\S]*?)\\s*```",     // ``` ... ```
            "\\{[\\s\\S]*\\}"                 // Direct JSON object
        ]
        
        for pattern in jsonPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []),
               let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) {
                
                let jsonString: String
                if match.numberOfRanges > 1 {
                    // Extract from capture group (markdown code block)
                    let range = Range(match.range(at: 1), in: text)!
                    jsonString = String(text[range])
                } else {
                    // Extract the entire match (direct JSON)
                    let range = Range(match.range, in: text)!
                    jsonString = String(text[range])
                }
                
                // Try to parse the extracted JSON
                if let jsonData = jsonString.data(using: .utf8),
                   let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
                    return json
                }
            }
        }
        
        return nil
    }
    
    private func reorderVisitsFromJSON(jsonResponse: [String: Any], originalVisits: [Visit]) -> [Visit] {
        guard let orderArray = jsonResponse["optimizedOrder"] as? [Int] else {
            print("⚠️ DEBUG: No optimizedOrder found in JSON, using time-based order")
            return originalVisits.sorted { $0.startTime < $1.startTime }
        }
        
        return reorderVisits(visits: originalVisits, order: orderArray)
    }
    
    private func cleanReasoning(_ reasoning: String) -> String {
        // Clean up the reasoning text to make it more user-friendly
        let cleaned = reasoning
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\\n", with: " ")
            .replacingOccurrences(of: "  ", with: " ")
        
        // If reasoning is too long, truncate it nicely
        if cleaned.count > 200 {
            let truncated = String(cleaned.prefix(197))
            if let lastSpace = truncated.lastIndex(of: " ") {
                return String(truncated[..<lastSpace]) + "..."
            } else {
                return truncated + "..."
            }
        }
        
        return cleaned
    }
    
    private func extractVisitOrder(from text: String, originalVisits: [Visit]) -> [Visit] {
        print("🔍 DEBUG: Extracting visit order from response")
        
        // Look for numbered lists or visit names in order
        let lines = text.components(separatedBy: .newlines)
        var orderedVisits: [Visit] = []
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Skip empty lines and common headers
            if trimmedLine.isEmpty || 
               trimmedLine.lowercased().contains("optimal") ||
               trimmedLine.lowercased().contains("route") ||
               trimmedLine.lowercased().contains("schedule") {
                continue
            }
            
            // Look for visit names in the line
            for visit in originalVisits {
                if !orderedVisits.contains(where: { $0.id == visit.id }) && 
                   (trimmedLine.localizedCaseInsensitiveContains(visit.petName) ||
                    trimmedLine.localizedCaseInsensitiveContains(visit.clientName)) {
                    orderedVisits.append(visit)
                    print("🔍 DEBUG: Found visit order: \(visit.petName)")
                    break
                }
            }
        }
        
        // If we couldn't parse the order properly, add any missing visits at the end
        for visit in originalVisits {
            if !orderedVisits.contains(where: { $0.id == visit.id }) {
                orderedVisits.append(visit)
            }
        }
        
        // If parsing failed completely, fall back to time-based ordering
        if orderedVisits.count != originalVisits.count {
            print("⚠️ DEBUG: Order parsing failed, using time-based fallback")
            return originalVisits.sorted { $0.startTime < $1.startTime }
        }
        
        return orderedVisits
    }
    
    private func extractReasoning(from text: String) -> String {
        // Look for reasoning sections in the response
        let lines = text.components(separatedBy: .newlines)
        var reasoningLines: [String] = []
        var inReasoningSection = false
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Check if this line starts a reasoning section
            if trimmedLine.lowercased().contains("reason") ||
               trimmedLine.lowercased().contains("explanation") ||
               trimmedLine.lowercased().contains("analysis") ||
               trimmedLine.lowercased().contains("optimized") {
                inReasoningSection = true
                reasoningLines.append(trimmedLine)
            } else if inReasoningSection {
                reasoningLines.append(trimmedLine)
            }
        }
        
        let reasoning = reasoningLines.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
        
        // If no specific reasoning found, use a summary of the response
        if reasoning.isEmpty {
            return "AI optimized route based on time windows, location proximity, and travel efficiency."
        }
        
        return reasoning
    }
    
    private func reorderVisits(visits: [Visit], order: [Int]) -> [Visit] {
        var reorderedVisits: [Visit] = []
        
        // Gemini returns 1-based indices, convert to 0-based
        for index in order {
            let visitIndex = index - 1
            if visitIndex >= 0 && visitIndex < visits.count {
                reorderedVisits.append(visits[visitIndex])
            }
        }
        
        // If reordering failed, return original order
        if reorderedVisits.count != visits.count {
            print("Warning: Gemini reordering failed, using original order")
            return visits.sorted { $0.startTime < $1.startTime }
        }
        
        return reorderedVisits
    }
    
    private func fallbackOptimization(visits: [Visit], homeBase: HomeBase?) async throws -> Route {
        await MainActor.run {
            optimizationProgress = 0.5
        }
        
        // Simple time-based optimization as fallback
        let sortedVisits = visits.sorted { $0.startTime < $1.startTime }
        
        await MainActor.run {
            optimizationProgress = 0.8
        }
        
        // Calculate basic metrics
        let (totalDistance, totalTravelTime) = await calculateRouteMetrics(visits: sortedVisits)
        let efficiency = calculateEfficiency(visits: sortedVisits, totalDistance: totalDistance)
        
        await MainActor.run {
            optimizationProgress = 1.0
        }
        
        return Route(
            visits: sortedVisits,
            totalDistance: totalDistance,
            totalTravelTime: totalTravelTime,
            efficiency: efficiency,
            createdAt: Date(),
            aiReasoning: "Fallback optimization: Visits ordered by start time"
        )
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