import SwiftUI
import MapKit

struct AddressAutocompleteField: View {
    let title: String
    @Binding var text: String
    let axis: Axis
    let lineLimit: ClosedRange<Int>
    
    @StateObject private var autocompleteService = AddressAutocompleteService()
    @State private var showingSuggestions = false
    @FocusState private var isTextFieldFocused: Bool
    
    init(
        _ title: String,
        text: Binding<String>,
        axis: Axis = .horizontal,
        lineLimit: ClosedRange<Int> = 1...1
    ) {
        self.title = title
        self._text = text
        self.axis = axis
        self.lineLimit = lineLimit
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            TextField(title, text: $text, axis: axis)
                .textContentType(.fullStreetAddress)
                .lineLimit(lineLimit)
                .focused($isTextFieldFocused)
                .onChange(of: text) { newValue in
                    autocompleteService.search(for: newValue)
                    showingSuggestions = !newValue.isEmpty && isTextFieldFocused
                }
                .onChange(of: isTextFieldFocused) { focused in
                    if focused {
                        showingSuggestions = !text.isEmpty
                        if !text.isEmpty {
                            autocompleteService.search(for: text)
                        }
                    } else {
                        showingSuggestions = false
                        autocompleteService.clearSuggestions()
                    }
                }
            
            if showingSuggestions && !autocompleteService.suggestions.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(autocompleteService.suggestions.prefix(5), id: \.self) { suggestion in
                        Button(action: {
                            text = autocompleteService.formatCompletion(suggestion)
                            showingSuggestions = false
                            isTextFieldFocused = false
                            autocompleteService.clearSuggestions()
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(suggestion.title)
                                        .font(.subheadline)
                                        .foregroundColor(.primary)
                                        .multilineTextAlignment(.leading)
                                    
                                    if !suggestion.subtitle.isEmpty {
                                        Text(suggestion.subtitle)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .multilineTextAlignment(.leading)
                                    }
                                }
                                
                                Spacer()
                                
                                Image(systemName: "location")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color(.systemGray6))
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        if suggestion != autocompleteService.suggestions.prefix(5).last {
                            Divider()
                                .padding(.leading, 12)
                        }
                    }
                }
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .padding(.top, 4)
            }
        }
    }
}

#Preview {
    Form {
        Section("Address") {
            AddressAutocompleteField("Enter address", text: .constant(""))
        }
    }
} 