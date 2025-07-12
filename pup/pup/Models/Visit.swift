import Foundation
import CoreLocation
import SwiftUI

struct Visit: Identifiable, Codable, Equatable {
    var id = UUID()
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

struct Coordinate: Codable, Equatable, Hashable {
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
    
    var color: Color {
        switch self {
        case .walk: return .blue
        case .sitting: return Config.evergreenColor
        case .dropIn: return .orange
        case .overnight: return Config.aiInsightColor
        }
    }
}

// MARK: - Saved Client Data for Reuse

struct SavedClient: Identifiable, Codable {
    var id = UUID()
    let clientName: String
    let petName: String
    let address: String
    let coordinate: Coordinate
    let lastUsed: Date
    
    init(clientName: String, petName: String, address: String, coordinate: Coordinate) {
        self.clientName = clientName
        self.petName = petName
        self.address = address
        self.coordinate = coordinate
        self.lastUsed = Date()
    }
    
    // Create from a Visit
    init(from visit: Visit) {
        self.clientName = visit.clientName
        self.petName = visit.petName
        self.address = visit.address
        self.coordinate = visit.coordinate
        self.lastUsed = Date()
    }
}

class SavedClientsService: ObservableObject {
    @Published var savedClients: [SavedClient] = []
    
    private let userDefaults = UserDefaults.standard
    private let savedClientsKey = "SavedClients"
    
    init() {
        loadSavedClients()
    }
    
    func saveClient(_ client: SavedClient) {
        // Remove existing client with same name/pet combination
        savedClients.removeAll { $0.clientName == client.clientName && $0.petName == client.petName }
        
        // Add new/updated client
        savedClients.append(client)
        
        // Sort by most recently used
        savedClients.sort { $0.lastUsed > $1.lastUsed }
        
        // Keep only the most recent 50 clients
        if savedClients.count > 50 {
            savedClients = Array(savedClients.prefix(50))
        }
        
        persistSavedClients()
    }
    
    func saveClientFromVisit(_ visit: Visit) {
        let savedClient = SavedClient(from: visit)
        saveClient(savedClient)
    }
    
    func deleteClient(_ client: SavedClient) {
        savedClients.removeAll { $0.id == client.id }
        persistSavedClients()
    }
    
    func deleteAllClients() {
        savedClients.removeAll()
        persistSavedClients()
    }
    
    private func loadSavedClients() {
        guard let data = userDefaults.data(forKey: savedClientsKey) else { return }
        
        do {
            savedClients = try JSONDecoder().decode([SavedClient].self, from: data)
        } catch {
            print("Failed to load saved clients: \(error)")
            savedClients = []
        }
    }
    
    private func persistSavedClients() {
        do {
            let data = try JSONEncoder().encode(savedClients)
            userDefaults.set(data, forKey: savedClientsKey)
        } catch {
            print("Failed to save clients: \(error)")
        }
    }
} 