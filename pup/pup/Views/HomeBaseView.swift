import SwiftUI

struct HomeBaseView: View {
    @ObservedObject var viewModel: HomeBaseViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            if viewModel.homeBase.isSet {
                SetHomeBaseCard(viewModel: viewModel)
            } else {
                EmptyHomeBaseCard(viewModel: viewModel)
            }
        }
        .sheet(isPresented: $viewModel.isEditing) {
            EditHomeBaseSheet(viewModel: viewModel)
        }
    }
}

struct SetHomeBaseCard: View {
    @ObservedObject var viewModel: HomeBaseViewModel
    @State private var showingRemoveAlert = false
    @State private var isExpanded = false
    
    var body: some View {
        VStack(spacing: 0) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isExpanded.toggle()
                }
            }) {
                HStack(spacing: Config.sectionSpacing) {
                    // House icon in evergreen circle
                    ZStack {
                        Circle()
                            .fill(Config.evergreenColor)
                            .frame(width: 24, height: 24)
                        
                        Image(systemName: "house.fill")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(viewModel.homeBase.name)
                            .font(.system(size: Config.bodyFontSize, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Text(viewModel.homeBase.displayAddress)
                            .font(.system(size: Config.captionFontSize))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                    
                    Spacer()
                    
                    // Chevron hint for expansion
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: Config.captionFontSize, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, Config.cardPadding)
                .padding(.vertical, Config.sectionSpacing)
                .frame(height: 56)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Expanded content
            if isExpanded {
                VStack(spacing: Config.sectionSpacing) {
                    if viewModel.homeBase.useCurrentLocation {
                        HStack {
                            Image(systemName: "location.fill")
                                .foregroundColor(Config.navigationColor)
                                .font(.system(size: Config.captionFontSize))
                            
                            Text("Using current location")
                                .font(.system(size: Config.captionFontSize))
                                .foregroundColor(Config.navigationColor)
                            
                            Spacer()
                        }
                        .padding(.horizontal, Config.cardPadding)
                    }
                    
                    // Action buttons
                    HStack(spacing: Config.sectionSpacing) {
                        Button(action: {
                            viewModel.startEditing()
                        }) {
                            HStack(spacing: Config.itemSpacing) {
                                Image(systemName: "pencil")
                                    .font(.system(size: Config.captionFontSize))
                                
                                Text("Edit")
                                    .font(.system(size: Config.bodyFontSize, weight: .medium))
                            }
                            .foregroundColor(Config.evergreenColor)
                            .padding(.horizontal, Config.largeSpacing)
                            .padding(.vertical, Config.sectionSpacing)
                            .background(
                                RoundedRectangle(cornerRadius: Config.buttonCornerRadius)
                                    .fill(Config.evergreenColor.opacity(0.1))
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Button(action: {
                            showingRemoveAlert = true
                        }) {
                            HStack(spacing: Config.itemSpacing) {
                                Image(systemName: "trash")
                                    .font(.system(size: Config.captionFontSize))
                                
                                Text("Remove")
                                    .font(.system(size: Config.bodyFontSize, weight: .medium))
                            }
                            .foregroundColor(.red)
                            .padding(.horizontal, Config.largeSpacing)
                            .padding(.vertical, Config.sectionSpacing)
                            .background(
                                RoundedRectangle(cornerRadius: Config.buttonCornerRadius)
                                    .fill(Color.red.opacity(0.1))
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.horizontal, Config.cardPadding)
                }
                .padding(.bottom, Config.sectionSpacing)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Config.cardBackgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: Config.cardCornerRadius))
        .shadow(
            color: Color.black.opacity(0.08),
            radius: 4,
            x: 0,
            y: 2
        )
        .overlay(
            // Bottom border divider
            Rectangle()
                .fill(Color(hex: "#E4E9E6"))
                .frame(height: 1)
                .offset(y: isExpanded ? 0 : 28), // Position at bottom of card
            alignment: .bottom
        )
        .contextMenu {
            Button(action: {
                viewModel.startEditing()
            }) {
                Label("Edit", systemImage: "pencil")
            }
            
            Button(action: {
                showingRemoveAlert = true
            }) {
                Label("Remove", systemImage: "trash")
            }
        }
        .alert("Remove Home Base", isPresented: $showingRemoveAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Remove", role: .destructive) {
                viewModel.clearHomeBase()
            }
        } message: {
            Text("Are you sure you want to remove your home base? This will affect route optimization.")
        }
    }
}

struct EmptyHomeBaseCard: View {
    @ObservedObject var viewModel: HomeBaseViewModel
    
    var body: some View {
        VStack(spacing: Config.sectionSpacing) {
            HStack {
                Image(systemName: "house.circle")
                    .foregroundColor(Config.evergreenColor.opacity(0.6))
                    .font(.system(size: Config.headingFontSize))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Set Home Base")
                        .font(.system(size: Config.bodyLargeFontSize, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text("Add your starting location for route optimization")
                        .font(.system(size: Config.bodyFontSize))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            Button("Add Home Base") {
                viewModel.startEditing()
            }
            .font(.system(size: Config.bodyFontSize, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, Config.largeSpacing)
            .padding(.vertical, Config.sectionSpacing)
            .background(
                RoundedRectangle(cornerRadius: Config.buttonCornerRadius)
                    .fill(Config.evergreenColor)
            )
        }
        .padding(Config.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: Config.cardCornerRadius)
                .fill(Config.cardBackgroundColor.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: Config.cardCornerRadius)
                        .stroke(Config.evergreenColor.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [5]))
                )
        )
    }
}

struct EditHomeBaseSheet: View {
    @ObservedObject var viewModel: HomeBaseViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Home Base Details") {
                    TextField("Name (e.g., Home, Office)", text: $viewModel.editingName)
                        .textContentType(.name)
                }
                
                Section("Location") {
                    Toggle("Use Current Location", isOn: $viewModel.editingUseCurrentLocation)
                    
                    if !viewModel.editingUseCurrentLocation {
                        AddressAutocompleteField("Address", text: $viewModel.editingAddress, axis: .vertical, lineLimit: 2...3)
                    } else {
                        HStack {
                            Image(systemName: "location.fill")
                                .foregroundColor(.blue)
                            Text("Will use your device's current location")
                                .foregroundColor(.secondary)
                                .font(.subheadline)
                        }
                    }
                }
                
                if let errorMessage = viewModel.errorMessage {
                    Section {
                        Label(errorMessage, systemImage: "exclamationmark.triangle")
                            .foregroundColor(.red)
                            .font(.subheadline)
                    }
                }
            }
            .navigationTitle("Edit Home Base")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        viewModel.cancelEditing()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        viewModel.saveHomeBase()
                    }
                    .fontWeight(.semibold)
                    .disabled(viewModel.editingName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .disabled(viewModel.isLoading)
        }
        .overlay {
            if viewModel.isLoading {
                LoadingOverlay(message: "Validating address...")
            }
        }
        .onChange(of: viewModel.isEditing) { isEditing in
            if !isEditing {
                dismiss()
            }
        }
    }
}

#Preview {
    VStack {
        HomeBaseView(viewModel: HomeBaseViewModel())
        Spacer()
    }
    .padding()
} 