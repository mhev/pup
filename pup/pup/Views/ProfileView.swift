import SwiftUI

struct ProfileView: View {
    @StateObject private var savedClientsService = SavedClientsService()
    @StateObject private var scheduleViewModel = ScheduleViewModel()
    
    @State private var showingDeleteAllPetsAlert = false
    @State private var showingDeleteAllSchedulesAlert = false
    @State private var showingSavedPetsSheet = false
    @State private var showingDangerZoneSheet = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Config.primaryColor
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: Config.sectionSpacing) {
                        // Avatar + Name Header
                        profileHeaderView
                        
                        // Stats Card (2-column)
                        statsCardView
                        
                        // Features Section
                        featuresSection
                        
                        // Actions Section
                        actionsSection
                        
                        // Legal & Support Section
                        legalSupportSection
                        
                        // Version Info
                        versionInfoView
                    }
                    .padding(.horizontal, Config.largeSpacing)
                    .padding(.bottom, Config.largeSpacing)
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingSavedPetsSheet) {
            SavedPetsManagementView(savedClientsService: savedClientsService)
        }
        .sheet(isPresented: $showingDangerZoneSheet) {
            DangerZoneView(
                savedClientsService: savedClientsService,
                scheduleViewModel: scheduleViewModel
            )
        }
    }
    
    private var profileHeaderView: some View {
        HStack(spacing: Config.cardPadding) {
            // Avatar with initials
            ZStack {
                Circle()
                    .fill(Config.evergreenColor)
                    .frame(width: 64, height: 64)
                
                Text("M")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Martina")
                    .font(.system(size: Config.headingFontSize, weight: .bold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                Text("Pet Care Professional")
                    .font(.system(size: Config.bodyFontSize))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            
            Spacer()
        }
        .padding(.horizontal, Config.largeSpacing)
        .padding(.top, Config.largeSpacing)
        .padding(.bottom, Config.cardPadding)
    }
    
    private var statsCardView: some View {
        HStack(spacing: Config.cardPadding) {
            // Saved Pets Stat
            Button {
                showingSavedPetsSheet = true
            } label: {
                VStack(spacing: 4) {
                    Text("\(savedClientsService.savedClients.count)")
                        .font(.system(size: Config.largeTitleFontSize, weight: .bold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    
                    Text("Saved Pets")
                        .font(.system(size: Config.bodyFontSize, weight: .medium))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Config.cardPadding)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Divider
            Rectangle()
                .fill(Color(hex: "E4E9E6"))
                .frame(width: 1, height: 44)
            
            // Total Visits Stat
            VStack(spacing: 4) {
                Text("\(scheduleViewModel.visits.count)")
                    .font(.system(size: Config.largeTitleFontSize, weight: .bold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                Text("Total Visits")
                    .font(.system(size: Config.bodyFontSize, weight: .medium))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Config.cardPadding)
        }
        .padding(Config.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: Config.cardCornerRadius)
                .fill(Color(hex: "E7F3ED"))
                .shadow(
                    color: Config.shadowColor,
                    radius: Config.cardShadowRadius,
                    x: Config.cardShadowOffset.width,
                    y: Config.cardShadowOffset.height
                )
        )
    }
    
    private var featuresSection: some View {
        VStack(spacing: 0) {
            // Separator
            Rectangle()
                .fill(Color(hex: "E4E9E6"))
                .frame(height: 1)
                .padding(.bottom, Config.sectionSpacing)
            
            DisclosureGroup {
                VStack(spacing: 0) {
                    featureRow(
                        icon: "point.topleft.down.curvedto.point.bottomright.up",
                        title: "Route Optimization",
                        description: "Intelligent scheduling with time windows",
                        color: .purple
                    )
                    
                    featureRow(
                        icon: "map",
                        title: "Interactive Maps",
                        description: "Visual route planning and navigation",
                        color: .orange
                    )
                    
                    featureRow(
                        icon: "clock",
                        title: "Time Management",
                        description: "Flexible scheduling with duration tracking",
                        color: Config.evergreenColor
                    )
                }
                .padding(.top, Config.sectionSpacing)
            } label: {
                HStack {
                    Image(systemName: "star.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Config.evergreenColor)
                    
                    Text("Features")
                        .font(.system(size: Config.bodyLargeFontSize, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    
                    Spacer()
                }
                .padding(.vertical, Config.cardPadding)
            }
        }
    }
    
    private var actionsSection: some View {
        VStack(spacing: 0) {
            // Separator
            Rectangle()
                .fill(Color(hex: "E4E9E6"))
                .frame(height: 1)
                .padding(.bottom, Config.sectionSpacing)
            
            DisclosureGroup {
                VStack(spacing: 0) {
                    actionRow(
                        icon: "icloud.and.arrow.up",
                        title: "Backup & Restore",
                        description: "Sync data with iCloud"
                    )
                    
                    actionRow(
                        icon: "square.and.arrow.up",
                        title: "Export Data",
                        description: "Share your schedule data"
                    )
                    
                    actionRow(
                        icon: "arrow.clockwise",
                        title: "Refresh Data",
                        description: "Sync with latest information"
                    )
                    
                    // Danger Zone Row
                    Button {
                        showingDangerZoneSheet = true
                    } label: {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.red)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Danger Zone")
                                    .font(.system(size: Config.bodyFontSize, weight: .medium))
                                    .foregroundColor(.red)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                                
                                Text("Destructive actions")
                                    .font(.system(size: Config.captionFontSize))
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, Config.cardPadding)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.top, Config.sectionSpacing)
            } label: {
                HStack {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Config.evergreenColor)
                    
                    Text("Actions")
                        .font(.system(size: Config.bodyLargeFontSize, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    
                    Spacer()
                }
                .padding(.vertical, Config.cardPadding)
            }
        }
    }
    
    private var legalSupportSection: some View {
        VStack(spacing: 0) {
            // Separator
            Rectangle()
                .fill(Color(hex: "E4E9E6"))
                .frame(height: 1)
                .padding(.bottom, Config.sectionSpacing)
            
            DisclosureGroup {
                VStack(spacing: 0) {
                    legalRow(
                        icon: "hand.raised",
                        title: "Privacy Policy",
                        url: "https://mhev.github.io/privacy-policy"
                    )
                    
                    legalRow(
                        icon: "doc.text",
                        title: "Terms of Service",
                        url: "https://mhev.github.io/terms-of-service"
                    )
                }
                .padding(.top, Config.sectionSpacing)
            } label: {
                HStack {
                    Image(systemName: "questionmark.circle.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Config.evergreenColor)
                    
                    Text("Legal & Support")
                        .font(.system(size: Config.bodyLargeFontSize, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    
                    Spacer()
                }
                .padding(.vertical, Config.cardPadding)
            }
        }
    }
    
    private var versionInfoView: some View {
        VStack(spacing: 8) {
            Rectangle()
                .fill(Color(hex: "E4E9E6"))
                .frame(height: 1)
            
            VStack(spacing: 4) {
                Text("Version \(Config.appVersion)")
                    .font(.system(size: Config.captionFontSize))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                Text("Built with ❤️ for pet care professionals")
                    .font(.system(size: Config.captionFontSize))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .multilineTextAlignment(.center)
            }
            .padding(.vertical, Config.largeSpacing)
        }
    }
    
    private func featureRow(icon: String, title: String, description: String, color: Color) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: Config.bodyFontSize, weight: .medium))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                Text(description)
                    .font(.system(size: Config.captionFontSize))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
            
            Spacer()
        }
        .padding(.vertical, Config.cardPadding)
    }
    
    private func actionRow(icon: String, title: String, description: String) -> some View {
        Button {
            // TODO: Implement action
        } label: {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Config.evergreenColor)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: Config.bodyFontSize, weight: .medium))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    
                    Text(description)
                        .font(.system(size: Config.captionFontSize))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, Config.cardPadding)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func legalRow(icon: String, title: String, url: String) -> some View {
        Button {
            if let url = URL(string: url) {
                UIApplication.shared.open(url)
            }
        } label: {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Config.evergreenColor)
                    .frame(width: 24)
                
                Text(title)
                    .font(.system(size: Config.bodyFontSize, weight: .medium))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                Spacer()
                
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, Config.cardPadding)
        }
    }
}

// MARK: - Danger Zone Sheet

struct DangerZoneView: View {
    @ObservedObject var savedClientsService: SavedClientsService
    @ObservedObject var scheduleViewModel: ScheduleViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingDeleteAllPetsAlert = false
    @State private var showingDeleteAllSchedulesAlert = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Danger Zone")
                            .font(.system(size: Config.headingFontSize, weight: .bold))
                            .foregroundColor(.red)
                        
                        Text("These actions cannot be undone")
                            .font(.system(size: Config.bodyFontSize))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button("Done") {
                        dismiss()
                    }
                    .font(.system(size: Config.bodyFontSize, weight: .medium))
                    .foregroundColor(Config.evergreenColor)
                }
                .padding(Config.largeSpacing)
                .background(Config.cardBackgroundColor)
                
                // Content
                VStack(spacing: 0) {
                    dangerButton(
                        title: "Delete All Saved Pets",
                        description: "Remove all \(savedClientsService.savedClients.count) saved pets",
                        icon: "trash.fill"
                    ) {
                        showingDeleteAllPetsAlert = true
                    }
                    
                    Rectangle()
                        .fill(Color(hex: "E4E9E6"))
                        .frame(height: 1)
                        .padding(.horizontal, Config.largeSpacing)
                    
                    dangerButton(
                        title: "Delete All Schedules",
                        description: "Remove all \(scheduleViewModel.visits.count) scheduled visits",
                        icon: "calendar.badge.minus"
                    ) {
                        showingDeleteAllSchedulesAlert = true
                    }
                }
                .background(Config.cardBackgroundColor)
                
                Spacer()
            }
            .background(Config.primaryColor)
        }
        .alert("Delete All Saved Pets", isPresented: $showingDeleteAllPetsAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete All", role: .destructive) {
                savedClientsService.deleteAllClients()
                dismiss()
            }
        } message: {
            Text("This will permanently delete all your saved pets. This action cannot be undone.")
        }
        .alert("Delete All Schedules", isPresented: $showingDeleteAllSchedulesAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete All", role: .destructive) {
                scheduleViewModel.deleteAllSchedules()
                dismiss()
            }
        } message: {
            Text("This will permanently delete all your scheduled visits. This action cannot be undone.")
        }
    }
    
    private func dangerButton(title: String, description: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.red)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: Config.bodyFontSize, weight: .medium))
                        .foregroundColor(.red)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    
                    Text(description)
                        .font(.system(size: Config.captionFontSize))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding(Config.largeSpacing)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Saved Pets Management

struct SavedPetsManagementView: View {
    @ObservedObject var savedClientsService: SavedClientsService
    @Environment(\.dismiss) private var dismiss
    @State private var showingDeleteAllAlert = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Config.primaryColor
                    .ignoresSafeArea()
                
                if savedClientsService.savedClients.isEmpty {
                    ContentUnavailableView(
                        "No Saved Pets",
                        systemImage: "pawprint",
                        description: Text("Add visits to automatically save pets for quick selection later")
                    )
                } else {
                    List {
                        ForEach(savedClientsService.savedClients) { client in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(client.petName)
                                        .font(.system(size: Config.bodyFontSize, weight: .semibold))
                                        .foregroundColor(.primary)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.8)
                                    
                                    Text(client.clientName)
                                        .font(.system(size: Config.bodyFontSize))
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.8)
                                    
                                    Text(client.address)
                                        .font(.system(size: Config.captionFontSize))
                                        .foregroundColor(.secondary)
                                        .lineLimit(2)
                                        .minimumScaleFactor(0.8)
                                }
                                
                                Spacer()
                                
                                Button("Delete") {
                                    savedClientsService.deleteClient(client)
                                }
                                .font(.system(size: Config.captionFontSize, weight: .medium))
                                .foregroundColor(.red)
                            }
                            .padding(.vertical, 4)
                            .listRowBackground(Config.cardBackgroundColor)
                        }
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Saved Pets")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                if !savedClientsService.savedClients.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Clear All") {
                            showingDeleteAllAlert = true
                        }
                        .foregroundColor(.red)
                    }
                }
            }
            .alert("Delete All Pets", isPresented: $showingDeleteAllAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete All", role: .destructive) {
                    savedClientsService.deleteAllClients()
                }
            } message: {
                Text("This will permanently delete all saved pets and client information. This action cannot be undone.")
            }
        }
    }
}

#Preview {
    ProfileView()
} 