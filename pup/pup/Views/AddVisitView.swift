import SwiftUI

struct AddVisitView: View {
    @StateObject private var viewModel = AddVisitViewModel()
    @Environment(\.dismiss) private var dismiss
    
    let defaultDate: Date?
    let onSave: (Visit) -> Void
    
    init(defaultDate: Date? = nil, onSave: @escaping (Visit) -> Void) {
        self.defaultDate = defaultDate
        self.onSave = onSave
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Saved Clients Section
                if !viewModel.savedClientsService.savedClients.isEmpty {
                    Section("Quick Select") {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(viewModel.savedClientsService.savedClients.prefix(10)) { savedClient in
                                    SavedClientCard(
                                        client: savedClient,
                                        isSelected: viewModel.selectedSavedClient?.id == savedClient.id
                                    ) {
                                        if viewModel.selectedSavedClient?.id == savedClient.id {
                                            viewModel.clearSelectedClient()
                                        } else {
                                            viewModel.selectSavedClient(savedClient)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 4)
                        }
                        .listRowInsets(EdgeInsets())
                    }
                }
                
                Section("Client Information") {
                    TextField("Client Name", text: $viewModel.clientName)
                        .textContentType(.name)
                    
                    TextField("Pet Name", text: $viewModel.petName)
                        .textContentType(.name)
                    
                    if viewModel.selectedSavedClient != nil {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(Color(red: 0.0, green: 0.7, blue: 0.0))
                            Text("Using saved client data")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Button("Clear") {
                                viewModel.clearSelectedClient()
                            }
                            .font(.caption)
                            .foregroundColor(.blue)
                        }
                    }
                }
                
                Section("Location") {
                    AddressAutocompleteField("Address", text: $viewModel.address, axis: .vertical, lineLimit: 2...3)
                }
                
                Section("Service Details") {
                    Picker("Service Type", selection: $viewModel.serviceType) {
                        ForEach(ServiceType.allCases, id: \.self) { type in
                            HStack {
                                Image(systemName: type.icon)
                                    .foregroundColor(Color(type.color))
                                Text(type.rawValue)
                            }
                            .tag(type)
                        }
                    }
                    .pickerStyle(.menu)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Duration: \(viewModel.formattedDuration)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Slider(value: $viewModel.duration, in: 10...180, step: 5) {
                            Text("Duration")
                        } minimumValueLabel: {
                            Text("10m")
                                .font(.caption)
                        } maximumValueLabel: {
                            Text("3h")
                                .font(.caption)
                        }
                    }
                }
                
                Section("Time Window") {
                    DatePicker("Start Time", selection: $viewModel.startTime, displayedComponents: [.date, .hourAndMinute])
                    
                    DatePicker("End Time", selection: $viewModel.endTime, displayedComponents: [.date, .hourAndMinute])
                    
                    if !viewModel.isTimeWindowValid {
                        Label("Time window is shorter than service duration", systemImage: "exclamationmark.triangle")
                            .foregroundColor(.orange)
                            .font(.caption)
                    }
                    
                    Text("Times automatically round to nearest 5 minutes")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Section("Notes") {
                    TextField("Additional notes (optional)", text: $viewModel.notes, axis: .vertical)
                        .lineLimit(3...5)
                }
            }
            .navigationTitle("Add Visit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveVisit()
                    }
                    .disabled(!viewModel.isFormValid || !viewModel.isTimeWindowValid)
                    .fontWeight(.semibold)
                }
            }
            .disabled(viewModel.isLoading)
        }
        .onAppear {
            if let defaultDate = defaultDate {
                viewModel.setDefaultDate(defaultDate)
            }
        }
        .overlay {
            if viewModel.isLoading {
                LoadingOverlay(message: "Validating address...")
            }
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            if let error = viewModel.errorMessage {
                Text(error)
            }
        }
    }
    
    private func saveVisit() {
        Task {
            do {
                let visit = try await viewModel.createVisit()
                await MainActor.run {
                    onSave(visit)
                }
            } catch {
                // Error is handled by the view model
            }
        }
    }
}

struct SavedClientCard: View {
    let client: SavedClient
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 4) {
                Text(client.petName)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                
                Text(client.clientName)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                Text(client.address.components(separatedBy: ",").first ?? client.address)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            .frame(width: 120, height: 80)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Config.accentColor.opacity(0.1) : Config.cardBackgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Config.accentColor : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    AddVisitView(defaultDate: Date()) { _ in }
} 
