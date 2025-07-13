import Foundation

struct GeminiService {
    private let apiKey: String
    private let baseURL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent"
    
    init() {
        self.apiKey = Config.geminiAPIKey
    }
    
    func optimizeRoute(visits: [Visit], homeBase: HomeBase? = nil) async throws -> String {
        print("🔍 DEBUG: Starting Gemini API call")
        print("🔍 DEBUG: API Key exists: \(!apiKey.isEmpty)")
        print("🔍 DEBUG: API Key prefix: \(String(apiKey.prefix(10)))...")
        print("🔍 DEBUG: Base URL: \(baseURL)")
        
        guard !apiKey.isEmpty else {
            print("❌ DEBUG: API Key is missing")
            throw GeminiError.missingAPIKey
        }
        
        let prompt = buildRouteOptimizationPrompt(visits: visits, homeBase: homeBase)
        print("🔍 DEBUG: Prompt length: \(prompt.count) characters")
        print("📤 SENDING TO GEMINI:")
        print("======================")
        print(prompt)
        print("======================END PROMPT======================\n")
        
        // Add API key as URL parameter (correct format for Gemini API)
        let urlWithKey = "\(baseURL)?key=\(apiKey)"
        
        guard let url = URL(string: urlWithKey) else {
            print("❌ DEBUG: Invalid URL: \(urlWithKey)")
            throw GeminiError.invalidURL
        }
        
        print("🔍 DEBUG: Final URL: \(url)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        // Remove Bearer token - Gemini API uses key in URL
        
        print("🔍 DEBUG: Request headers set")
        
        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        [
                            "text": prompt
                        ]
                    ]
                ]
            ],
            "generationConfig": [
                "temperature": 0.1,
                "maxOutputTokens": 2048
            ]
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
            print("🔍 DEBUG: Request body serialized successfully")
        } catch {
            print("❌ DEBUG: Failed to serialize request body: \(error)")
            throw GeminiError.jsonParsingError(error)
        }
        
        print("🔍 DEBUG: Making API request...")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("🔍 DEBUG: HTTP Status Code: \(httpResponse.statusCode)")
                print("🔍 DEBUG: Response Headers: \(httpResponse.allHeaderFields)")
            }
            
            print("🔍 DEBUG: Response data length: \(data.count) bytes")
            
            if let responseString = String(data: data, encoding: .utf8) {
                print("🔍 DEBUG: Response body: \(responseString)")
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ DEBUG: Not an HTTP response")
                throw GeminiError.invalidResponse
            }
            
            guard httpResponse.statusCode == 200 else {
                print("❌ DEBUG: HTTP Error - Status: \(httpResponse.statusCode)")
                if let responseString = String(data: data, encoding: .utf8) {
                    print("❌ DEBUG: Error response body: \(responseString)")
                }
                throw GeminiError.invalidResponse
            }
            
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            print("🔍 DEBUG: JSON parsed successfully")
            
            if let candidates = json?["candidates"] as? [[String: Any]],
               let firstCandidate = candidates.first,
               let content = firstCandidate["content"] as? [String: Any],
               let parts = content["parts"] as? [[String: Any]],
               let firstPart = parts.first,
               let text = firstPart["text"] as? String {
                print("✅ DEBUG: Successfully extracted response text")
                print("📥 GEMINI RESPONSE:")
                print("======================")
                print(text)
                print("======================END RESPONSE======================\n")
                return text
            } else {
                print("❌ DEBUG: Failed to parse response structure")
                print("❌ DEBUG: JSON structure: \(json ?? [:])")
                throw GeminiError.invalidResponse
            }
            
        } catch let error as GeminiError {
            print("❌ DEBUG: GeminiError: \(error)")
            throw error
        } catch {
            print("❌ DEBUG: Network error: \(error)")
            throw GeminiError.networkError(error)
        }
    }
    
    private func buildRouteOptimizationPrompt(visits: [Visit], homeBase: HomeBase?) -> String {
        var prompt = """
        You are a professional route optimization assistant for dog walkers and pet sitters. 
        I need you to calculate the most optimal route considering time windows, travel time, and efficiency.
        
        Please analyze the following information and provide the BEST possible route order:
        
        """
        
        // Add home base information with improved handling
        if let homeBase = homeBase, homeBase.isReady {
            prompt += """
            HOME BASE: \(homeBase.displayAddress)
            
            """
        } else {
            prompt += "HOME BASE: Not provided - optimize from first visit location\n\n"
        }
        
        // Add time zone specification
        prompt += """
        TIME_ZONE: America/Chicago
        
        """
        
        // Detect overlapping time windows
        let overlappingWindows = detectOverlappingTimeWindows(visits: visits)
        if !overlappingWindows.isEmpty {
            prompt += "⚠️ IMPORTANT - OVERLAPPING TIME WINDOWS DETECTED:\n"
            for overlap in overlappingWindows {
                let timeFormatter = DateFormatter()
                timeFormatter.dateFormat = "h:mm a"
                let timeWindow = "\(timeFormatter.string(from: overlap.startTime)) - \(timeFormatter.string(from: overlap.endTime))"
                let petNames = overlap.visits.map { $0.petName }.joined(separator: ", ")
                prompt += "- Time window \(timeWindow) has multiple visits: \(petNames)\n"
            }
            prompt += "These visits CANNOT be done simultaneously and must be sequenced within their shared time window.\n\n"
        }
        
        // Add visit information
        prompt += "VISITS TO SCHEDULE:\n"
        for (index, visit) in visits.enumerated() {
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "h:mm a"
            
            prompt += """
            \(index + 1). \(visit.petName) (\(visit.clientName))
               - Address: \(visit.address)
               - Service: \(visit.serviceType.rawValue)
               - Time Window: \(timeFormatter.string(from: visit.startTime)) - \(timeFormatter.string(from: visit.endTime))
               - Duration: \(Int(visit.duration)) minutes
               - Notes: \(visit.notes ?? "None")
            
            """
        }
        
        prompt += """
        
        CRITICAL REQUIREMENTS:
        1. TIME WINDOW FLEXIBILITY: Each visit has a time window (e.g., 7:00-8:00 AM) and a duration (e.g., 30 mins)
           - The visit can START anytime within the window
           - The visit must FINISH before the window closes
           - Example: 7:00-8:00 AM window with 30-min duration = can start between 7:00-7:30 AM
           - This flexibility allows for optimal routing and scheduling
        2. MULTIPLE VISITS with overlapping time windows must be sequenced - they cannot happen simultaneously
        3. Account for realistic travel time between locations. For Austin, TX traffic: locations within 5 miles estimate 10-15 minutes; locations 5-10 miles estimate 15-20 minutes; locations further apart estimate proportionally.
        4. When visits share the same time window, sequence them optimally considering:
           - Travel distance between locations
           - Service duration for each visit
           - Buffer time for travel within the shared window
           - Use the time window flexibility to fit both visits optimally
        5. Minimize total travel distance and time across the entire day
        6. Consider the service duration for each visit
        7. If HOME BASE is provided, start from that location. If HOME BASE is 'Not provided', assume the starting point for optimization is the location of the first scheduled visit in the optimized route.
        8. If it is impossible to create a feasible route that accommodates all visits within their specified time windows, provide an 'optimizedOrder' array that includes only the visits that can be completed. Include a 'feasibleRoute' boolean flag set to 'false' in the JSON output. In the 'reasoning', clearly state which visits could not be fit into the schedule and why.
        
        ROUTE EFFICIENCY RULES:
        ✅ START at home base (if provided) or first visit location
        ✅ Go DIRECTLY from visit to visit for maximum efficiency
        ❌ DO NOT return to home base after each visit
        ✅ When time windows overlap, choose the CLOSEST next visit
        ✅ Only return to home base at the END of the route (or during long breaks)
        ✅ Optimize the path like a delivery driver - minimize backtracking
        ✅ Use time window flexibility to optimize route efficiency
        
        EXAMPLE 1: Single visit flexibility
        - Time window: 7:00-8:00 AM, Duration: 30 minutes
        - Can start anytime between 7:00-7:30 AM (must finish by 8:00 AM)
        - Flexible start times: 7:00 AM, 7:15 AM, 7:30 AM, etc.
        
        EXAMPLE 2: Two 30-minute visits both in 7:00-8:00 AM window:
        - With 10-minute travel time between visits
        - Option A: Visit A 7:00-7:30, Travel 7:30-7:40, Visit B 7:40-8:10 (INVALID - B exceeds window)
        - Option B: Visit A 7:00-7:20, Travel 7:20-7:30, Visit B 7:30-8:00 (VALID - both fit in window)
        - Option C: Recognize if window is too tight, recommend scheduling in different windows
        
        KEY INSIGHT: Use time window flexibility to optimize routes and fit multiple visits efficiently!
        
        Please respond in the following JSON format ONLY (no additional text):
        {
          "optimizedOrder": [1, 3, 2],
          "estimatedTotalDistance": 25.5,
          "estimatedTotalTime": 145,
          "efficiency": 85,
          "feasibleRoute": true,
          "reasoning": "Brief explanation of the optimization logic including how overlapping time windows were handled"
        }
        
        Where:
        - optimizedOrder: Array of visit numbers in the optimal order
        - estimatedTotalDistance: Total driving distance in miles
        - estimatedTotalTime: Total time elapsed from the start of the first visit until the end of the last visit, including both travel time between visits and the duration of each visit (in minutes)
        - efficiency: Efficiency score from 1-100. A score of 100 indicates the most optimal route possible with minimal wasted time/distance and successful accommodation of all visits within their time windows. Lower scores indicate more travel or difficulty fitting visits.
        - feasibleRoute: Boolean indicating if all visits can be accommodated within their time windows (true) or if some visits had to be excluded (false)
        - reasoning: Brief explanation of why this order is optimal, especially how overlapping windows were sequenced. If feasibleRoute is false, clearly state which visits could not be fit and why.
        """
        
        return prompt
    }
    
    private func detectOverlappingTimeWindows(visits: [Visit]) -> [OverlappingTimeWindow] {
        var overlappingWindows: [OverlappingTimeWindow] = []
        
        // Group visits by their time windows
        let groupedByTimeWindow = Dictionary(grouping: visits) { visit in
            TimeWindowKey(startTime: visit.startTime, endTime: visit.endTime)
            }
            
        // Find groups with more than one visit
        for (timeWindow, visitsInWindow) in groupedByTimeWindow {
            if visitsInWindow.count > 1 {
                overlappingWindows.append(OverlappingTimeWindow(
                    startTime: timeWindow.startTime,
                    endTime: timeWindow.endTime,
                    visits: visitsInWindow
                ))
            }
        }
        
        return overlappingWindows
    }
}

// MARK: - Request/Response Models

struct GeminiRequest: Codable {
    let contents: [GeminiContent]
}

struct GeminiContent: Codable {
    let parts: [GeminiPart]
}

struct GeminiPart: Codable {
    let text: String
}

struct GeminiAPIResponse: Codable {
    let candidates: [GeminiCandidate]
}

struct GeminiCandidate: Codable {
    let content: GeminiContent
}

struct GeminiRouteResponse: Codable {
    let optimizedOrder: [Int]
    let estimatedTotalDistance: Double
    let estimatedTotalTime: Double
    let efficiency: Double
    let feasibleRoute: Bool?
    let reasoning: String
}

// MARK: - Helper Types for Overlapping Time Windows

struct TimeWindowKey: Hashable {
    let startTime: Date
    let endTime: Date
}

struct OverlappingTimeWindow {
    let startTime: Date
    let endTime: Date
    let visits: [Visit]
}

// MARK: - Travel Times Support (Future Implementation)

struct TravelTimes {
    let travelTimes: [String: Int] // "visitName1-visitName2": travelTimeInMinutes
}

// MARK: - Error Types

enum GeminiError: Error, LocalizedError {
    case missingAPIKey
    case invalidURL
    case networkError(Error)
    case invalidResponse
    case jsonParsingError(Error)
    
    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "Gemini API key is missing. Please check your configuration."
        case .invalidURL:
            return "Invalid URL for Gemini API"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from Gemini API"
        case .jsonParsingError(let error):
            return "Error parsing JSON response: \(error.localizedDescription)"
        }
    }
} 