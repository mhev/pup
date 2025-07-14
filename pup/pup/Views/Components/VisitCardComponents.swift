import SwiftUI

// MARK: - Redesigned Visit Card

struct ModernVisitCard: View {
    let visit: Visit
    let isCompactMode: Bool
    let onComplete: () -> Void
    let onTap: (() -> Void)?
    let onDelete: (() -> Void)?
    
    @State private var dragOffset: CGSize = .zero
    @State private var isShowingCompleteAction = false
    @State private var showingDeleteAlert = false
    
    init(visit: Visit, isCompactMode: Bool = false, onComplete: @escaping () -> Void, onTap: (() -> Void)? = nil, onDelete: (() -> Void)? = nil) {
        self.visit = visit
        self.isCompactMode = isCompactMode
        self.onComplete = onComplete
        self.onTap = onTap
        self.onDelete = onDelete
    }
    
    var body: some View {
        ZStack {
            // Background delete action
            HStack {
                Spacer()
                
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        dragOffset = .zero
                    }
                    
                    // Haptic feedback
                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                    impactFeedback.impactOccurred()
                    
                    showingDeleteAlert = true
                }) {
                    VStack {
                        Image(systemName: "trash")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                        
                        if !isCompactMode {
                            Text("Delete")
                                .font(.system(size: Config.captionFontSize, weight: .medium))
                                .foregroundColor(.white)
                        }
                    }
                    .frame(width: 80, height: isCompactMode ? 60 : 80)
                    .background(Color.red)
                    .cornerRadius(Config.cardCornerRadius)
                }
                .padding(.trailing, Config.cardPadding)
            }
            .opacity(dragOffset.width < -30 ? 1 : 0)
            
            // Main card content
            VStack(alignment: .leading, spacing: Config.itemSpacing) {
                HStack(alignment: .top, spacing: Config.sectionSpacing) {
                    // Pet and client info
                    VStack(alignment: .leading, spacing: 2) {
                        Text(visit.petName)
                            .font(.system(size: Config.bodyLargeFontSize, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Text(visit.clientName)
                            .font(.system(size: Config.bodyFontSize))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Service type chip and time
                    VStack(alignment: .trailing, spacing: Config.itemSpacing) {
                        ServiceTypeChip(serviceType: visit.serviceType)
                        
                        Text(visit.timeWindow)
                            .font(.system(size: Config.captionFontSize, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
                
                if !isCompactMode {
                    // Location with city + distance
                    HStack(spacing: Config.itemSpacing) {
                        Image(systemName: "location")
                            .font(.system(size: Config.captionFontSize))
                            .foregroundColor(Config.navigationColor)
                        
                        Text(extractCityFromAddress(visit.address))
                            .font(.system(size: Config.captionFontSize))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        // Distance placeholder (would be calculated from user location)
                        Text("2.3 mi")
                            .font(.system(size: Config.captionFontSize, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    
                    // Notes if present
                    if let notes = visit.notes, !notes.isEmpty {
                        Text(notes)
                            .font(.system(size: Config.captionFontSize))
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    
                    // Flexible indicator
                    if visit.isFlexible {
                        HStack {
                            Image(systemName: "clock.badge.checkmark")
                                .font(.system(size: Config.captionFontSize))
                                .foregroundColor(Config.evergreenColor)
                            
                            Text("Flexible timing")
                                .font(.system(size: Config.captionFontSize))
                                .foregroundColor(Config.evergreenColor)
                            
                            Spacer()
                        }
                    }
                }
            }
            .padding(Config.cardPadding)
            .background(
                RoundedRectangle(cornerRadius: Config.cardCornerRadius)
                    .fill(Config.cardBackgroundColor)
                    .shadow(
                        color: Config.shadowColor,
                        radius: Config.cardShadowRadius,
                        x: Config.cardShadowOffset.width,
                        y: Config.cardShadowOffset.height
                    )
            )
            .offset(dragOffset)
            .simultaneousGesture(
                DragGesture()
                    .onChanged { value in
                        // Only allow left swipe and prioritize horizontal movement
                        let horizontalDistance = abs(value.translation.width)
                        let verticalDistance = abs(value.translation.height)
                        
                        // Only activate card swipe if user is clearly swiping horizontally
                        if horizontalDistance > verticalDistance && value.translation.width < 0 {
                            dragOffset = value.translation
                        }
                    }
                    .onEnded { value in
                        let horizontalDistance = abs(value.translation.width)
                        let verticalDistance = abs(value.translation.height)
                        
                        // Only complete the swipe if it was primarily horizontal
                        if horizontalDistance > verticalDistance {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                if value.translation.width < -80 {
                                    // Show delete confirmation
                                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                                    impactFeedback.impactOccurred()
                                    dragOffset = .zero
                                    showingDeleteAlert = true
                                } else {
                                    // Snap back
                                    dragOffset = .zero
                                }
                            }
                        } else {
                            // Reset if it was primarily vertical (scrolling)
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                dragOffset = .zero
                            }
                        }
                    }
            )
            .onTapGesture {
                if let onTap = onTap {
                    onTap()
                }
            }
        }
        .alert("Delete Visit", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                onDelete?()
            }
        } message: {
            Text("Are you sure you want to delete \(visit.petName)'s \(visit.serviceType.rawValue.lowercased())? This action cannot be undone.")
        }
    }
    
    private func extractCityFromAddress(_ address: String) -> String {
        let components = address.components(separatedBy: ", ")
        if components.count > 1 {
            return components[1] // Usually city is the second component
        }
        return components.first ?? address
    }
}

// MARK: - Service Type Chip

struct ServiceTypeChip: View {
    let serviceType: ServiceType
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: serviceTypeIcon)
                .font(.system(size: 12, weight: .medium))
            
            Text(serviceTypeText)
                .font(.system(size: 10, weight: .medium))
                .lineLimit(1)
        }
        .iconChip(color: serviceTypeColor)
    }
    
    private var serviceTypeIcon: String {
        switch serviceType {
        case .walk:
            return "figure.walk"
        case .sitting:
            return "house.fill"
        case .dropIn:
            return "clock.fill"
        case .overnight:
            return "moon.fill"
        }
    }
    
    private var serviceTypeText: String {
        switch serviceType {
        case .walk:
            return "Walk"
        case .sitting:
            return "Sit"
        case .dropIn:
            return "Drop-in"
        case .overnight:
            return "Overnight"
        }
    }
    
    private var serviceTypeColor: Color {
        switch serviceType {
        case .walk:
            return Config.navigationColor
        case .sitting:
            return Config.evergreenColor
        case .dropIn:
            return .orange
        case .overnight:
            return Config.aiInsightColor
        }
    }
}

// MARK: - Time-based Grouping

enum TimeOfDay: String, CaseIterable {
    case morning = "Morning"
    case midday = "Midday"
    case afternoon = "Afternoon"
    case evening = "Evening"
    
    var timeRange: String {
        switch self {
        case .morning:
            return "6:00 AM - 12:00 PM"
        case .midday:
            return "12:00 PM - 3:00 PM"
        case .afternoon:
            return "3:00 PM - 6:00 PM"
        case .evening:
            return "6:00 PM - 10:00 PM"
        }
    }
    
    var icon: String {
        switch self {
        case .morning:
            return "sunrise.fill"
        case .midday:
            return "sun.max.fill"
        case .afternoon:
            return "sun.dust.fill"
        case .evening:
            return "moon.stars.fill"
        }
    }
    
    func contains(_ date: Date) -> Bool {
        let hour = Calendar.current.component(.hour, from: date)
        
        switch self {
        case .morning:
            return hour >= 6 && hour < 12
        case .midday:
            return hour >= 12 && hour < 15
        case .afternoon:
            return hour >= 15 && hour < 18
        case .evening:
            return hour >= 18 && hour < 22
        }
    }
}

struct TimeGroupHeader: View {
    let timeOfDay: TimeOfDay
    let visitCount: Int
    let isExpanded: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: Config.sectionSpacing) {
                Image(systemName: timeOfDay.icon)
                    .font(.system(size: Config.bodyFontSize))
                    .foregroundColor(Config.evergreenColor)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(timeOfDay.rawValue)
                        .font(.system(size: Config.bodyLargeFontSize, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text("\(visitCount) visit\(visitCount == 1 ? "" : "s") • \(timeOfDay.timeRange)")
                        .font(.system(size: Config.captionFontSize))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.system(size: Config.captionFontSize, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, Config.sectionSpacing)
            .padding(.horizontal, Config.cardPadding)
            .background(
                RoundedRectangle(cornerRadius: Config.cardCornerRadius)
                    .fill(Config.cardBackgroundColor.opacity(0.6))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Grouped Visit Section

struct GroupedVisitSection: View {
    let timeOfDay: TimeOfDay
    let visits: [Visit]
    let isCompactMode: Bool
    let onCompleteVisit: (Visit) -> Void
    let onTapVisit: (Visit) -> Void
    let onDeleteVisit: (Visit) -> Void
    
    @State private var isExpanded = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: Config.sectionSpacing) {
            TimeGroupHeader(
                timeOfDay: timeOfDay,
                visitCount: visits.count,
                isExpanded: isExpanded,
                onToggle: { isExpanded.toggle() }
            )
            
            if isExpanded {
                LazyVStack(spacing: Config.sectionSpacing) {
                    ForEach(visits) { visit in
                        ModernVisitCard(
                            visit: visit,
                            isCompactMode: isCompactMode,
                            onComplete: {
                                onCompleteVisit(visit)
                            },
                            onTap: {
                                onTapVisit(visit)
                            },
                            onDelete: {
                                onDeleteVisit(visit)
                            }
                        )
                    }
                }
            }
        }
    }
} 