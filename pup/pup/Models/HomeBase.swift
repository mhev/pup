import Foundation
import CoreLocation

struct HomeBase: Codable, Equatable {
    let id = UUID()
    var name: String
    var address: String?
    var coordinate: Coordinate?
    var useCurrentLocation: Bool
    var isSet: Bool
    
    init(name: String = "Home Base", useCurrentLocation: Bool = false) {
        self.name = name
        self.useCurrentLocation = useCurrentLocation
        self.address = nil
        self.coordinate = nil
        self.isSet = false
    }
    
    init(name: String, address: String, coordinate: Coordinate) {
        self.name = name
        self.address = address
        self.coordinate = coordinate
        self.useCurrentLocation = false
        self.isSet = true
    }
    
    var displayAddress: String {
        if useCurrentLocation {
            return "Using current location"
        } else if let address = address {
            return address
        } else {
            return "No address set"
        }
    }
    
    var isReady: Bool {
        return isSet && coordinate != nil
    }
} 