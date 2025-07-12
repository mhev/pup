import SwiftUI
import UIKit
import Foundation

struct AddVisitBottomSheet: View {
    @StateObject private var viewModel = AddVisitViewModel()
    @State private var dragOffset: CGSize = .zero
    @State private var keyboardHeight: CGFloat = 0
    @Binding var isPresented: Bool
    
    let defaultDate: Date?
    let onSave: (Visit) -> Void
    
    init(isPresented: Binding<Bool>, defaultDate: Date? = nil, onSave: @escaping (Visit) -> Void) {
        self._isPresented = isPresented
        self.defaultDate = defaultDate
        self.onSave = onSave
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background overlay
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        dismissSheet()
                    }
                
                // Bottom sheet content
                VStack(spacing: 0) {
                    Spacer()
                    
                    bottomSheetContent
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Config.cardBackgroundColor)
                                .shadow(color: Config.shadowColor, radius: 20, x: 0, y: -5)
                        )
                        .offset(y: dragOffset.height > 0 ? dragOffset.height : 0)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    if value.translation.height > 0 {
                                        dragOffset = value.translation
                                    }
                                }
                                .onEnded { value in
                                    if value.translation.height > 100 {
                                        dismissSheet()
                                    } else {
                                        withAnimation(.spring()) {
                                            dragOffset = .zero
                                        }
                                    }
                                }
                        )
                }
                .ignoresSafeArea(edges: .bottom)
            }
        }
        .onAppear {
            if let defaultDate = defaultDate {
                viewModel.setDefaultDate(defaultDate)
            }
            setupKeyboardObservers()
        }
        .onDisappear {
            removeKeyboardObservers()
        }
    }
    
    private var bottomSheetContent: some View {
        VStack(spacing: 0) {
            // Handle bar
            handleBar
            
            // Header
            headerSection
            
            // Quick select clients (if available)
            if !viewModel.savedClientsService.savedClients.isEmpty {
                quickSelectSection
            }
            
            // Main form content
            ScrollView {
                VStack(spacing: Config.sectionSpacing) {
                    clientInfoSection
                    locationSection
                    serviceDetailsSection
                    timeWindowSection
                    notesSection
                }
                .padding(.horizontal, Config.largeSpacing)
                .padding(.bottom, Config.largeSpacing)
            }
            
            // Action buttons
            actionButtons
        }
        .padding(.bottom, keyboardHeight > 0 ? keyboardHeight - 34 : 0) // Adjust for keyboard
    }
    
    private var handleBar: some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(Color.secondary.opacity(0.5))
            .frame(width: 40, height: 6)
            .padding(.top, 12)
    }
    
    private var headerSection: some View {
        VStack(spacing: 4) {
            Text("Add Visit")
                .font(.system(size: Config.largeTitleFontSize, weight: .bold))
                .foregroundColor(.primary)
            
            if let selectedClient = viewModel.selectedSavedClient {
                Text("Using saved client: \(selectedClient.clientName)")
                    .font(.system(size: Config.captionFontSize))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, Config.sectionSpacing)
    }
    
    private var quickSelectSection: some View {
        VStack(alignment: .leading, spacing: Config.itemSpacing) {
            Text("Quick Select")
                .font(.system(size: Config.bodyFontSize, weight: .semibold))
                .foregroundColor(.primary)
                .padding(.horizontal, Config.largeSpacing)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Config.itemSpacing) {
                    ForEach(viewModel.savedClientsService.savedClients.prefix(5)) { client in
                        QuickSelectClientCard(
                            client: client,
                            isSelected: viewModel.selectedSavedClient?.id == client.id
                        ) {
                            if viewModel.selectedSavedClient?.id == client.id {
                                viewModel.clearSelectedClient()
                            } else {
                                viewModel.selectSavedClient(client)
                            }
                        }
                    }
                }
                .padding(.horizontal, Config.largeSpacing)
            }
        }
        .padding(.bottom, Config.sectionSpacing)
    }
    
    private var clientInfoSection: some View {
        VStack(alignment: .leading, spacing: Config.itemSpacing) {
            SectionHeader(title: "Client Information", icon: "person.fill")
            
            VStack(spacing: Config.itemSpacing) {
                ModernTextField(
                    title: "Client Name",
                    text: $viewModel.clientName,
                    icon: "person.fill"
                )
                
                ModernTextField(
                    title: "Pet Name",
                    text: $viewModel.petName,
                    icon: "pawprint.fill"
                )
            }
        }
    }
    
    private var locationSection: some View {
        VStack(alignment: .leading, spacing: Config.itemSpacing) {
            SectionHeader(title: "Location", icon: "location.fill")
            
            ModernTextField(
                title: "Address",
                text: $viewModel.address,
                icon: "mappin.and.ellipse",
                isMultiline: true
            )
        }
    }
    
    private var serviceDetailsSection: some View {
        VStack(alignment: .leading, spacing: Config.itemSpacing) {
            SectionHeader(title: "Service Details", icon: "briefcase.fill")
            
            // Service type picker
            VStack(alignment: .leading, spacing: Config.itemSpacing) {
                Text("Service Type")
                    .font(.system(size: Config.bodyFontSize, weight: .medium))
                    .foregroundColor(.primary)
                
                LazyHGrid(rows: Array(repeating: GridItem(.flexible()), count: 2), spacing: Config.itemSpacing) {
                    ForEach(ServiceType.allCases, id: \.self) { type in
                        ServiceTypeCard(
                            type: type,
                            isSelected: viewModel.serviceType == type
                        ) {
                            viewModel.serviceType = type
                        }
                    }
                }
            }
            
            // Duration slider
            VStack(alignment: .leading, spacing: Config.itemSpacing) {
                HStack {
                    Text("Duration")
                        .font(.system(size: Config.bodyFontSize, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text(viewModel.formattedDuration)
                        .font(.system(size: Config.bodyFontSize, weight: .semibold))
                        .foregroundColor(Config.evergreenColor)
                }
                
                Slider(value: $viewModel.duration, in: 10...180, step: 5)
                    .tint(Config.evergreenColor)
            }
        }
    }
    
    private var timeWindowSection: some View {
        VStack(alignment: .leading, spacing: Config.itemSpacing) {
            SectionHeader(title: "Time Window", icon: "clock.fill")
            
            HStack(spacing: Config.sectionSpacing) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Start Time")
                        .font(.system(size: Config.captionFontSize, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    DatePicker("", selection: $viewModel.startTime, displayedComponents: [.date, .hourAndMinute])
                        .labelsHidden()
                        .datePickerStyle(.compact)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("End Time")
                        .font(.system(size: Config.captionFontSize, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    DatePicker("", selection: $viewModel.endTime, displayedComponents: [.date, .hourAndMinute])
                        .labelsHidden()
                        .datePickerStyle(.compact)
                }
            }
            
            if !viewModel.isTimeWindowValid {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                        .font(.system(size: Config.captionFontSize))
                    
                    Text("Time window is shorter than service duration")
                        .font(.system(size: Config.captionFontSize))
                        .foregroundColor(.orange)
                }
            }
        }
    }
    
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: Config.itemSpacing) {
            SectionHeader(title: "Notes", icon: "note.text")
            
            ModernTextField(
                title: "Additional notes (optional)",
                text: $viewModel.notes,
                icon: "note.text",
                isMultiline: true
            )
        }
    }
    
    private var actionButtons: some View {
        HStack(spacing: Config.sectionSpacing) {
            Button("Cancel") {
                dismissSheet()
            }
            .font(.system(size: Config.bodyFontSize, weight: .medium))
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Config.sectionSpacing)
            .background(
                RoundedRectangle(cornerRadius: Config.buttonCornerRadius)
                    .fill(Color.secondary.opacity(0.1))
            )
            
            Button("Save Visit") {
                saveVisit()
            }
            .font(.system(size: Config.bodyFontSize, weight: .semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Config.sectionSpacing)
            .background(
                RoundedRectangle(cornerRadius: Config.buttonCornerRadius)
                    .fill(viewModel.isFormValid && viewModel.isTimeWindowValid ? Config.evergreenColor : Color.secondary.opacity(0.3))
            )
            .disabled(!viewModel.isFormValid || !viewModel.isTimeWindowValid || viewModel.isLoading)
        }
        .padding(.horizontal, Config.largeSpacing)
        .padding(.bottom, Config.largeSpacing)
        .background(Config.cardBackgroundColor)
    }
    
    private func saveVisit() {
        Task {
            do {
                let visit = try await viewModel.createVisit()
                await MainActor.run {
                    onSave(visit)
                    dismissSheet()
                }
            } catch {
                // Error handled by view model
            }
        }
    }
    
    private func dismissSheet() {
        withAnimation(.spring()) {
            isPresented = false
        }
    }
    
    // MARK: - Keyboard Handling
    
    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillShowNotification,
            object: nil,
            queue: .main
        ) { notification in
            if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                withAnimation(.easeInOut(duration: 0.3)) {
                    keyboardHeight = keyboardFrame.height
                }
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillHideNotification,
            object: nil,
            queue: .main
        ) { _ in
            withAnimation(.easeInOut(duration: 0.3)) {
                keyboardHeight = 0
            }
        }
    }
    
    private func removeKeyboardObservers() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
}

// MARK: - Supporting Views

struct SectionHeader: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack(spacing: Config.itemSpacing) {
            Image(systemName: icon)
                .font(.system(size: Config.bodyFontSize))
                .foregroundColor(Config.evergreenColor)
            
            Text(title)
                .font(.system(size: Config.bodyFontSize, weight: .semibold))
                .foregroundColor(.primary)
        }
    }
}

struct ModernTextField: View {
    let title: String
    @Binding var text: String
    let icon: String
    var isMultiline: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: Config.captionFontSize, weight: .medium))
                .foregroundColor(.secondary)
            
            HStack(spacing: Config.itemSpacing) {
                Image(systemName: icon)
                    .font(.system(size: Config.bodyFontSize))
                    .foregroundColor(Config.evergreenColor)
                    .frame(width: 20)
                
                if isMultiline {
                    TextField("", text: $text, axis: .vertical)
                        .lineLimit(2...4)
                } else {
                    TextField("", text: $text)
                }
            }
            .padding(Config.cardPadding)
            .background(
                RoundedRectangle(cornerRadius: Config.buttonCornerRadius)
                    .fill(Config.primaryColor.opacity(0.5))
            )
        }
    }
}

struct QuickSelectClientCard: View {
    let client: SavedClient
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 4) {
                Text(client.petName)
                    .font(.system(size: Config.bodyFontSize, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text(client.clientName)
                    .font(.system(size: Config.captionFontSize))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            .frame(width: 100, height: 50)
            .padding(Config.itemSpacing)
            .background(
                RoundedRectangle(cornerRadius: Config.buttonCornerRadius)
                    .fill(isSelected ? Config.evergreenColor.opacity(0.1) : Config.primaryColor.opacity(0.5))
                    .overlay(
                        RoundedRectangle(cornerRadius: Config.buttonCornerRadius)
                            .stroke(isSelected ? Config.evergreenColor : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ServiceTypeCard: View {
    let type: ServiceType
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Config.itemSpacing) {
                Image(systemName: type.icon)
                    .font(.system(size: Config.bodyFontSize))
                    .foregroundColor(isSelected ? .white : type.color)
                
                Text(type.rawValue)
                    .font(.system(size: Config.captionFontSize, weight: .medium))
                    .foregroundColor(isSelected ? .white : .primary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Config.itemSpacing)
            .padding(.horizontal, Config.itemSpacing)
            .background(
                RoundedRectangle(cornerRadius: Config.buttonCornerRadius)
                    .fill(isSelected ? type.color : Config.primaryColor.opacity(0.5))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    AddVisitBottomSheet(
        isPresented: .constant(true),
        defaultDate: Date()
    ) { _ in }
} 