import SwiftUI

struct AddVisitView: View {
    @StateObject private var viewModel = AddVisitViewModel()
    @Environment(\.dismiss) private var dismiss
    
    let onSave: (Visit) -> Void
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Client Information") {
                    TextField("Client Name", text: $viewModel.clientName)
                        .textContentType(.name)
                    
                    TextField("Pet Name", text: $viewModel.petName)
                        .textContentType(.name)
                }
                
                Section("Location") {
                    TextField("Address", text: $viewModel.address, axis: .vertical)
                        .textContentType(.fullStreetAddress)
                        .lineLimit(2...3)
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
                        
                        Slider(value: $viewModel.duration, in: 15...180, step: 15) {
                            Text("Duration")
                        } minimumValueLabel: {
                            Text("15m")
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

#Preview {
    AddVisitView { _ in }
} 