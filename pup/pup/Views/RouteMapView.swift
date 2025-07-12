import SwiftUI
import MapKit

// MARK: - Map Item Types

struct MapItem: Identifiable, Equatable, Hashable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let type: MarkerType
    let visit: Visit?
    let routeIndex: Int?
    
    enum MarkerType: Equatable, Hashable {
        case homeBase
        case visit(Int) // route index
        case nextVisit(Int) // route index
    }
    
    static func == (lhs: MapItem, rhs: MapItem) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    init(homeBase: HomeBase) {
        self.coordinate = homeBase.coordinate!.clLocation
        self.type = .homeBase
        self.visit = nil
        self.routeIndex = nil
    }
    
    init(visit: Visit, routeIndex: Int, isNext: Bool = false) {
        self.coordinate = visit.coordinate.clLocation
        self.type = isNext ? .nextVisit(routeIndex) : .visit(routeIndex)
        self.visit = visit
        self.routeIndex = routeIndex
    }
}

// MARK: - Modern Route Map View

struct RouteMapView: View {
    @EnvironmentObject var viewModel: ScheduleViewModel
    @State private var mapStyle: MapStyle = .standard
    @State private var selectedMarker: MapItem?
    @State private var position: MapCameraPosition = .automatic
    @State private var isNavigating = false
    @State private var estimatedTimeOfArrival: Date?
    @State private var longPressGesture = false
    
    private var mapItems: [MapItem] {
        var items: [MapItem] = []
        
        // Add home base if set
        if viewModel.homeBaseViewModel.homeBase.coordinate != nil {
            items.append(MapItem(homeBase: viewModel.homeBaseViewModel.homeBase))
        }
        
        // Add visits in route order
        if let route = viewModel.optimizedRoute {
            let visits = route.visits
            let nextVisitIndex = visits.firstIndex { !$0.isCompleted } ?? 0
            
            for (index, visit) in visits.enumerated() {
                let isNext = index == nextVisitIndex && !visit.isCompleted
                items.append(MapItem(visit: visit, routeIndex: index + 1, isNext: isNext))
            }
        } else {
            // Add all visits without route order
            for (index, visit) in viewModel.todaysVisits.enumerated() {
                let isNext = index == 0 && !visit.isCompleted
                items.append(MapItem(visit: visit, routeIndex: index + 1, isNext: isNext))
            }
        }
        
        return items
    }
    
    private var routePolyline: MKPolyline? {
        guard let route = viewModel.optimizedRoute else { return nil }
        
        var coordinates = route.visits.map { $0.coordinate.clLocation }
        return MKPolyline(coordinates: &coordinates, count: coordinates.count)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Map(position: $position) {
                    // Route polyline
                    if let polyline = routePolyline {
                        MapPolyline(polyline)
                            .stroke(Config.primaryColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    }
                    
                    // Map markers with clustering
                    ForEach(mapItems) { item in
                        switch item.type {
                        case .homeBase:
                            Annotation("Home Base", coordinate: item.coordinate) {
                                HomeBaseMarkerView()
                                    .onTapGesture {
                                        selectedMarker = item
                                    }
                            }
                            .annotationTitles(.hidden)
                            
                        case .visit(let index):
                            Annotation("Visit \(index)", coordinate: item.coordinate) {
                                VisitMarkerView(number: index, isCompleted: item.visit?.isCompleted ?? false)
                                    .onTapGesture {
                                        selectedMarker = item
                                    }
                            }
                            .annotationTitles(.hidden)
                            
                        case .nextVisit(let index):
                            Annotation("Next Visit", coordinate: item.coordinate) {
                                NextVisitMarkerView(number: index)
                                    .onTapGesture {
                                        selectedMarker = item
                                    }
                            }
                            .annotationTitles(.hidden)
                        }
                    }
                }
                .mapStyle(mapStyle)
                .mapControlVisibility(.automatic)
                
                // ETA Banner
                if isNavigating, let eta = estimatedTimeOfArrival {
                    VStack {
                        ETABannerView(eta: eta)
                            .padding(.horizontal, Config.largeSpacing)
                            .padding(.top, Config.itemSpacing)
                        
                        Spacer()
                    }
                }
                
                // Live Odometer Overlay
                VStack {
                    HStack {
                        LiveOdometerView()
                            .padding(.horizontal, Config.largeSpacing)
                            .padding(.top, Config.itemSpacing)
                        
                        Spacer()
                    }
                    
                    Spacer()
                }
                
                // Map Controls
                VStack {
                    Spacer()
                    
                    HStack {
                        Spacer()
                        
                        MapControlFAB(
                            onFitToRoute: fitToRoute,
                            onCycleMapStyle: cycleMapStyle,
                            currentStyle: mapStyle
                        )
                        .padding(.trailing, Config.largeSpacing)
                        .padding(.bottom, Config.largeSpacing)
                    }
                }
            }
            .navigationTitle("Route Map")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                fitToRoute()
            }
            .sheet(item: $selectedMarker) { marker in
                MarkerDetailBottomSheet(
                    marker: marker,
                    onNavigate: { startNavigation(to: marker) },
                    onMarkComplete: { markComplete(marker) }
                )
                .presentationDetents([.fraction(0.25), .medium])
                .presentationDragIndicator(.visible)
            }
        }
    }
    
    private func fitToRoute() {
        guard !mapItems.isEmpty else { return }
        
        let coordinates = mapItems.map { $0.coordinate }
        let region = MKCoordinateRegion(coordinates: coordinates)
        
        withAnimation(.easeInOut(duration: 0.8)) {
            position = .region(region)
        }
    }
    
    private func cycleMapStyle() {
        withAnimation(.easeInOut(duration: 0.3)) {
            // Cycle through map styles using debugDescription
            let currentStyle = String(describing: mapStyle)
            if currentStyle.contains("standard") {
                mapStyle = .imagery
            } else if currentStyle.contains("imagery") {
                mapStyle = .hybrid
            } else if currentStyle.contains("hybrid") {
                mapStyle = .standard
            } else {
                mapStyle = .standard
            }
        }
    }
    
    private func startNavigation(to marker: MapItem) {
        guard let visit = marker.visit else { return }
        
        isNavigating = true
        
        // Calculate ETA using MKDirections
        let request = MKDirections.Request()
        request.source = MKMapItem.forCurrentLocation()
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: marker.coordinate))
        request.requestsAlternateRoutes = false
        
        let directions = MKDirections(request: request)
        directions.calculateETA { response, error in
            DispatchQueue.main.async {
                if let eta = response?.expectedArrivalDate {
                    self.estimatedTimeOfArrival = eta
                }
            }
        }
        
        // Open in Apple Maps
        let placemark = MKPlacemark(coordinate: marker.coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = visit.petName
        mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
    }
    
    private func markComplete(_ marker: MapItem) {
        guard let visit = marker.visit else { return }
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            viewModel.markVisitCompleted(visit)
        }
        
        selectedMarker = nil
    }
    

}

// MARK: - Home Base Marker

struct HomeBaseMarkerView: View {
    var body: some View {
        ZStack {
            // Outer ring
            Circle()
                .stroke(Config.evergreenColor, lineWidth: 3)
                .frame(width: 50, height: 50)
                .background(
                    Circle()
                        .fill(Config.evergreenColor.opacity(0.1))
                        .frame(width: 50, height: 50)
                )
            
            // Inner circle
            Circle()
                .fill(Config.evergreenColor)
                .frame(width: 36, height: 36)
                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
            
            // House icon
            Image(systemName: "house.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
        }
        .padding(8) // Add padding to make it more tappable
    }
}

// MARK: - Visit Marker

struct VisitMarkerView: View {
    let number: Int
    let isCompleted: Bool
    
    var body: some View {
        ZStack {
            Circle()
                .fill(isCompleted ? Config.evergreenColor.opacity(0.3) : Config.evergreenColor)
                .frame(width: 32, height: 32)
                .shadow(color: .black.opacity(0.2), radius: 3, x: 0, y: 2)
            
            Text("\(number)")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(isCompleted ? Config.evergreenColor : .white)
        }
        .padding(8) // Add padding to make it more tappable
    }
}

// MARK: - Next Visit Marker (with pulse animation)

struct NextVisitMarkerView: View {
    let number: Int
    @State private var isPulsing = false
    
    var body: some View {
        ZStack {
            // Pulse rings
            Circle()
                .fill(Config.evergreenColor.opacity(0.3))
                .frame(width: 50, height: 50)
                .scaleEffect(isPulsing ? 1.2 : 1.0)
                .opacity(isPulsing ? 0 : 1)
                .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: false), value: isPulsing)
            
            Circle()
                .fill(Config.evergreenColor.opacity(0.2))
                .frame(width: 60, height: 60)
                .scaleEffect(isPulsing ? 1.4 : 1.0)
                .opacity(isPulsing ? 0 : 1)
                .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: false).delay(0.3), value: isPulsing)
            
            // Main marker
            Circle()
                .fill(Config.evergreenColor)
                .frame(width: 40, height: 40)
                .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
            
            Text("\(number)")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
        }
        .padding(8) // Add padding to make it more tappable
        .onAppear {
            isPulsing = true
        }
    }
}

// MARK: - Map Control FAB

struct MapControlFAB: View {
    let onFitToRoute: () -> Void
    let onCycleMapStyle: () -> Void
    let currentStyle: MapStyle
    
    var body: some View {
        Button(action: onFitToRoute) {
            Image(systemName: "target")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(
                    Circle()
                        .fill(Config.evergreenColor)
                        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                )
        }
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.5)
                .onEnded { _ in
                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                    impactFeedback.impactOccurred()
                    onCycleMapStyle()
                }
        )
        .accessibilityLabel("Fit to route")
        .accessibilityHint("Tap to fit route, long press to change map style")
    }
}

// MARK: - ETA Banner

struct ETABannerView: View {
    let eta: Date
    
    private var timeUntilArrival: String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: Date(), to: eta) ?? ""
    }
    
    var body: some View {
        HStack(spacing: Config.sectionSpacing) {
            Image(systemName: "location.fill")
                .font(.system(size: Config.bodyFontSize))
                .foregroundColor(Config.navigationColor)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Navigating")
                    .font(.system(size: Config.captionFontSize, weight: .medium))
                    .foregroundColor(.secondary)
                
                Text("ETA: \(timeUntilArrival)")
                    .font(.system(size: Config.bodyFontSize, weight: .semibold))
                    .foregroundColor(.primary)
            }
            
            Spacer()
        }
        .padding(.horizontal, Config.cardPadding)
        .padding(.vertical, Config.sectionSpacing)
        .background(
            RoundedRectangle(cornerRadius: Config.cardCornerRadius)
                .fill(Config.cardBackgroundColor)
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
}

// MARK: - Marker Detail Bottom Sheet

struct MarkerDetailBottomSheet: View {
    let marker: MapItem
    let onNavigate: () -> Void
    let onMarkComplete: () -> Void
    
    var body: some View {
        VStack(spacing: Config.largeSpacing) {
            // Drag indicator
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.secondary.opacity(0.3))
                .frame(width: 40, height: 4)
                .padding(.top, Config.itemSpacing)
            
            if case .homeBase = marker.type {
                // Home Base Details
                VStack(alignment: .leading, spacing: Config.sectionSpacing) {
                    HStack {
                        Image(systemName: "house.fill")
                            .font(.system(size: Config.bodyLargeFontSize))
                            .foregroundColor(Config.evergreenColor)
                        
                        Text("Home Base")
                            .font(.system(size: Config.bodyLargeFontSize, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Spacer()
                    }
                    
                    Button(action: onNavigate) {
                        HStack {
                            Image(systemName: "location.fill")
                                .font(.system(size: Config.bodyFontSize))
                            
                            Text("Navigate Here")
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
                }
                .padding(.horizontal, Config.largeSpacing)
                
            } else if let visit = marker.visit {
                // Visit Details
                VStack(alignment: .leading, spacing: Config.sectionSpacing) {
                    HStack {
                        ServiceTypeChip(serviceType: visit.serviceType)
                        
                        Spacer()
                        
                        if !visit.isCompleted {
                            Text("Visit \(marker.routeIndex ?? 0)")
                                .font(.system(size: Config.captionFontSize, weight: .medium))
                                .foregroundColor(.secondary)
                        } else {
                            Text("Completed")
                                .font(.system(size: Config.captionFontSize, weight: .medium))
                                .foregroundColor(Config.evergreenColor)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: Config.itemSpacing) {
                        Text(visit.petName)
                            .font(.system(size: Config.bodyLargeFontSize, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Text(visit.address)
                            .font(.system(size: Config.bodyFontSize))
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                        
                        Text(visit.timeWindow)
                            .font(.system(size: Config.bodyFontSize))
                            .foregroundColor(.primary)
                    }
                    
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
                            Button(action: onMarkComplete) {
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
            }
            
            Spacer()
        }
        .background(Config.cardBackgroundColor)
    }
}

// MARK: - Extensions

extension MKCoordinateRegion {
    init(coordinates: [CLLocationCoordinate2D]) {
        guard !coordinates.isEmpty else {
            self = MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 30.2672, longitude: -97.7431),
                span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
            )
            return
        }
        
        let minLat = coordinates.map { $0.latitude }.min()!
        let maxLat = coordinates.map { $0.latitude }.max()!
        let minLon = coordinates.map { $0.longitude }.min()!
        let maxLon = coordinates.map { $0.longitude }.max()!
        
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        
        let span = MKCoordinateSpan(
            latitudeDelta: max((maxLat - minLat) * 1.3, 0.01),
            longitudeDelta: max((maxLon - minLon) * 1.3, 0.01)
        )
        
        self = MKCoordinateRegion(center: center, span: span)
    }
}

#Preview {
    RouteMapView()
        .environmentObject(ScheduleViewModel())
} 