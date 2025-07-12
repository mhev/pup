import SwiftUI
import MapKit

struct ModernScheduleView: View {
    @EnvironmentObject var viewModel: ScheduleViewModel
    @State private var showingAddVisit = false
    @State private var showingDatePicker = false
    @State private var isCompactMode = false
    @State private var isRouteCollapsed = false
    @State private var scrollOffset: CGFloat = 0
    @State private var selectedVisit: Visit?
    
    private var dayOfWeek: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: viewModel.selectedDate)
    }
    
    private var groupedVisits: [TimeOfDay: [Visit]] {
        var groups: [TimeOfDay: [Visit]] = [:]
        
        for timeOfDay in TimeOfDay.allCases {
            groups[timeOfDay] = viewModel.upcomingVisits.filter { visit in
                timeOfDay.contains(visit.startTime)
            }
        }
        
        return groups
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background color
                Config.primaryColor
                    .ignoresSafeArea()
                
                FloatingActionButtonContainer(
                    fabAction: {
                        showingAddVisit = true
                    }
                ) {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            // Home Base section
                            HomeBaseView(viewModel: viewModel.homeBaseViewModel)
                                .padding(.horizontal, Config.largeSpacing)
                                .padding(.top, Config.itemSpacing)
                            
                            // Route section
                            if let route = viewModel.optimizedRoute {
                                ModernRouteCard(
                                    route: route,
                                    isCollapsed: isRouteCollapsed && route.visits.allSatisfy { $0.isCompleted },
                                    onOptimize: {
                                        viewModel.optimizeCurrentRoute()
                                    },
                                    onToggleCollapse: {
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            isRouteCollapsed.toggle()
                                        }
                                    }
                                )
                                .environmentObject(viewModel)
                                .padding(.horizontal, Config.largeSpacing)
                                .padding(.top, Config.sectionSpacing)
                            } else if !viewModel.upcomingVisits.isEmpty {
                                ModernOptimizeRouteButton(
                                    visitCount: viewModel.upcomingVisits.count,
                                    isLoading: viewModel.isLoading,
                                    onOptimize: {
                                        viewModel.optimizeCurrentRoute()
                                    }
                                )
                                .padding(.horizontal, Config.largeSpacing)
                                .padding(.top, Config.sectionSpacing)
                            }
                            
                            // Visit groups
                            if !viewModel.upcomingVisits.isEmpty {
                                LazyVStack(spacing: Config.sectionSpacing) {
                                    ForEach(TimeOfDay.allCases, id: \.self) { timeOfDay in
                                        let visits = groupedVisits[timeOfDay] ?? []
                                        if !visits.isEmpty {
                                            GroupedVisitSection(
                                                timeOfDay: timeOfDay,
                                                visits: visits,
                                                isCompactMode: isCompactMode,
                                                onCompleteVisit: { visit in
                                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                                        viewModel.markVisitCompleted(visit)
                                                    }
                                                },
                                                onTapVisit: { visit in
                                                    selectedVisit = visit
                                                }
                                            )
                                        }
                                    }
                                }
                                .padding(.horizontal, Config.largeSpacing)
                                .padding(.top, Config.largeSpacing)
                            }
                            
                            // Completed visits section
                            if !viewModel.completedVisits.isEmpty {
                                CompletedVisitsModernSection(visits: viewModel.completedVisits)
                                    .padding(.horizontal, Config.largeSpacing)
                                    .padding(.top, Config.largeSpacing)
                            }
                            
                            // Bottom padding to account for FAB
                            Rectangle()
                                .fill(Color.clear)
                                .frame(height: 100)
                        }
                        .background(
                            GeometryReader { geometry in
                                Color.clear
                                    .preference(key: ScrollOffsetPreferenceKey.self, value: geometry.frame(in: .named("scroll")).minY)
                            }
                        )
                    }
                    .coordinateSpace(name: "scroll")
                    .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                        scrollOffset = value
                    }
                }
            }
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: viewModel.goToPreviousDay) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: Config.bodyFontSize, weight: .semibold))
                    }
                }
                
                ToolbarItem(placement: .principal) {
                    Button(action: { showingDatePicker = true }) {
                        VStack(spacing: 2) {
                            Text(viewModel.selectedDateTitle)
                                .font(.system(size: Config.bodyLargeFontSize, weight: .semibold))
                                .foregroundColor(.primary)
                            
                            if !viewModel.isToday {
                                Text(dayOfWeek)
                                    .font(.system(size: Config.captionFontSize))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .foregroundColor(.primary)
                    .scaleEffect(scrollOffset < -50 ? 0.9 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: scrollOffset)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: Config.sectionSpacing) {
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                isCompactMode.toggle()
                            }
                        }) {
                            Image(systemName: isCompactMode ? "list.bullet" : "square.grid.2x2")
                                .font(.system(size: Config.bodyFontSize, weight: .semibold))
                        }
                        
                        Button(action: viewModel.goToNextDay) {
                            Image(systemName: "chevron.right")
                                .font(.system(size: Config.bodyFontSize, weight: .semibold))
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAddVisit) {
                AddVisitBottomSheet(defaultDate: viewModel.selectedDate) { visit in
                    viewModel.addVisit(visit)
                    showingAddVisit = false
                }
            }
            .sheet(isPresented: $showingDatePicker) {
                CompactDatePickerView(viewModel: viewModel)
            }
            .sheet(item: $selectedVisit) { visit in
                VisitDetailBottomSheet(
                    visit: visit,
                    onComplete: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            viewModel.markVisitCompleted(visit)
                        }
                        selectedVisit = nil
                    },
                    onNavigate: {
                        // Navigate to location in Apple Maps
                        let placemark = MKPlacemark(coordinate: visit.coordinate.clLocation)
                        let mapItem = MKMapItem(placemark: placemark)
                        mapItem.name = visit.petName
                        mapItem.openInMaps(launchOptions: [
                            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
                        ])
                    }
                )
                .presentationDetents([.fraction(0.4), .medium])
                .presentationDragIndicator(.visible)
            }
            .overlay {
                if viewModel.todaysVisits.isEmpty {
                    ModernEmptyState(
                        selectedDate: viewModel.selectedDate,
                        isToday: viewModel.isToday
                    ) {
                        showingAddVisit = true
                    }
                }
            }
        }
        .onAppear {
            viewModel.requestLocationPermission()
        }
    }
}

// MARK: - Scroll Offset Preference Key

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Modern Completed Visits Section

struct CompletedVisitsModernSection: View {
    let visits: [Visit]
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: Config.sectionSpacing) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isExpanded.toggle()
                }
            }) {
                HStack(spacing: Config.sectionSpacing) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: Config.bodyFontSize))
                        .foregroundColor(Config.evergreenColor)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Completed")
                            .font(.system(size: Config.bodyLargeFontSize, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Text("\(visits.count) visit\(visits.count == 1 ? "" : "s") completed today")
                            .font(.system(size: Config.captionFontSize))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                .padding(.vertical, Config.sectionSpacing)
                .padding(.horizontal, Config.cardPadding)
                .background(
                    RoundedRectangle(cornerRadius: Config.cardCornerRadius)
                        .fill(Config.evergreenColor.opacity(0.1))
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            if isExpanded {
                LazyVStack(spacing: Config.itemSpacing) {
                    ForEach(visits) { visit in
                        CompletedVisitModernRow(visit: visit)
                    }
                }
                .transition(.opacity.combined(with: .scale))
            }
        }
    }
}

// MARK: - Modern Completed Visit Row

struct CompletedVisitModernRow: View {
    let visit: Visit
    
    var body: some View {
        HStack(spacing: Config.sectionSpacing) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: Config.bodyFontSize))
                .foregroundColor(Config.evergreenColor)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(visit.petName)
                    .font(.system(size: Config.bodyFontSize, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(visit.clientName)
                    .font(.system(size: Config.captionFontSize))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                ServiceTypeChip(serviceType: visit.serviceType)
                
                Text(visit.timeWindow)
                    .font(.system(size: Config.captionFontSize))
                    .foregroundColor(.secondary)
            }
        }
        .padding(Config.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: Config.cardCornerRadius)
                .fill(Config.cardBackgroundColor.opacity(0.6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Config.cardCornerRadius)
                .stroke(Config.evergreenColor.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Add Visit Bottom Sheet

struct AddVisitBottomSheet: View {
    let defaultDate: Date?
    let onSave: (Visit) -> Void
    
    var body: some View {
        AddVisitView(defaultDate: defaultDate, onSave: onSave)
            .presentationDetents([.height(600), .large])
            .presentationDragIndicator(.visible)
    }
}

// MARK: - Visit Detail Bottom Sheet

struct VisitDetailBottomSheet: View {
    let visit: Visit
    let onComplete: () -> Void
    let onNavigate: () -> Void
    
    var body: some View {
        VStack(spacing: Config.largeSpacing) {
            // Drag indicator
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.secondary.opacity(0.3))
                .frame(width: 40, height: 4)
                .padding(.top, Config.itemSpacing)
            
            // Visit Details
            VStack(alignment: .leading, spacing: Config.sectionSpacing) {
                HStack {
                    ServiceTypeChip(serviceType: visit.serviceType)
                    
                    Spacer()
                    
                    if visit.isCompleted {
                        Text("Completed")
                            .font(.system(size: Config.captionFontSize, weight: .medium))
                            .foregroundColor(Config.evergreenColor)
                    } else {
                        Text(visit.timeWindow)
                            .font(.system(size: Config.captionFontSize, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
                
                VStack(alignment: .leading, spacing: Config.itemSpacing) {
                    Text(visit.petName)
                        .font(.system(size: Config.headingFontSize, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text(visit.clientName)
                        .font(.system(size: Config.bodyFontSize))
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: Config.itemSpacing) {
                        Image(systemName: "location")
                            .font(.system(size: Config.captionFontSize))
                            .foregroundColor(Config.navigationColor)
                        
                        Text(visit.address)
                            .font(.system(size: Config.bodyFontSize))
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
                
                // Notes if present
                if let notes = visit.notes, !notes.isEmpty {
                    VStack(alignment: .leading, spacing: Config.itemSpacing) {
                        Text("Notes")
                            .font(.system(size: Config.captionFontSize, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        Text(notes)
                            .font(.system(size: Config.bodyFontSize))
                            .foregroundColor(.primary)
                    }
                    .padding(.horizontal, Config.cardPadding)
                    .padding(.vertical, Config.sectionSpacing)
                    .background(
                        RoundedRectangle(cornerRadius: Config.cardCornerRadius)
                            .fill(Config.cardBackgroundColor.opacity(0.5))
                    )
                }
                
                // Actions
                HStack(spacing: Config.sectionSpacing) {
                    Button(action: onNavigate) {
                        HStack {
                            Image(systemName: "location.fill")
                                .font(.system(size: Config.bodyFontSize))
                            
                            Text("Navigate")
                                .font(.system(size: Config.bodyFontSize, weight: .medium))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Config.sectionSpacing)
                        .background(
                            RoundedRectangle(cornerRadius: Config.buttonCornerRadius)
                                .fill(Config.navigationColor)
                        )
                    }
                    
                    if !visit.isCompleted {
                        Button(action: onComplete) {
                            HStack {
                                Image(systemName: "checkmark.circle")
                                    .font(.system(size: Config.bodyFontSize))
                                
                                Text("Complete")
                                    .font(.system(size: Config.bodyFontSize, weight: .medium))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Config.sectionSpacing)
                            .background(
                                RoundedRectangle(cornerRadius: Config.buttonCornerRadius)
                                    .fill(Config.evergreenColor)
                            )
                        }
                    }
                }
            }
            .padding(.horizontal, Config.largeSpacing)
            
            Spacer()
        }
        .background(Config.cardBackgroundColor)
    }
}

#Preview {
    NavigationStack {
        ModernScheduleView()
            .environmentObject(ScheduleViewModel())
    }
} 