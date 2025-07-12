import Foundation
import MapKit
import Combine

class AddressAutocompleteService: NSObject, ObservableObject {
    @Published var suggestions: [MKLocalSearchCompletion] = []
    @Published var isSearching = false
    
    private let searchCompleter = MKLocalSearchCompleter()
    private var cancellables = Set<AnyCancellable>()
    
    override init() {
        super.init()
        searchCompleter.delegate = self
        searchCompleter.resultTypes = .address
        searchCompleter.pointOfInterestFilter = .excludingAll
    }
    
    func search(for query: String) {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            suggestions = []
            isSearching = false
            return
        }
        
        isSearching = true
        searchCompleter.queryFragment = query
    }
    
    func clearSuggestions() {
        suggestions = []
        isSearching = false
        searchCompleter.cancel()
    }
    
    func formatCompletion(_ completion: MKLocalSearchCompletion) -> String {
        if completion.subtitle.isEmpty {
            return completion.title
        } else {
            return "\(completion.title), \(completion.subtitle)"
        }
    }
}

extension AddressAutocompleteService: MKLocalSearchCompleterDelegate {
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        DispatchQueue.main.async {
            self.suggestions = completer.results
            self.isSearching = false
        }
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.suggestions = []
            self.isSearching = false
        }
    }
} 