import SwiftUI
import MapKit

struct RouteMapView: View {
    @EnvironmentObject var viewModel: ScheduleViewModel
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 30.2672, longitude: -97.7431), // Austin, TX
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    
    var body: some View {
        NavigationStack {
            ZStack {
                Map(coordinateRegion: $region, annotationItems: viewModel.todaysVisits) { visit in
                    MapAnnotation(coordinate: visit.coordinate.clLocation) {
                        VisitMarker(visit: visit)
                    }
                }
                .ignoresSafeArea()
                
                VStack {
                    Spacer()
                    
                    if let route = viewModel.optimizedRoute {
                        RouteBottomSheet(route: route)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color(.systemBackground))
                                    .shadow(radius: 10)
                            )
                            .padding()
                    }
                }
            }
            .navigationTitle("Route Map")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                updateRegion()
            }
            .onChange(of: viewModel.todaysVisits) { _ in
                updateRegion()
            }
        }
    }
    
    private func updateRegion() {
        guard !viewModel.todaysVisits.isEmpty else { return }
        
        let coordinates = viewModel.todaysVisits.map { $0.coordinate.clLocation }
        let minLat = coordinates.map { $0.latitude }.min() ?? 0
        let maxLat = coordinates.map { $0.latitude }.max() ?? 0
        let minLon = coordinates.map { $0.longitude }.min() ?? 0
        let maxLon = coordinates.map { $0.longitude }.max() ?? 0
        
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        
        let span = MKCoordinateSpan(
            latitudeDelta: (maxLat - minLat) * 1.5,
            longitudeDelta: (maxLon - minLon) * 1.5
        )
        
        region = MKCoordinateRegion(center: center, span: span)
    }
}

struct VisitMarker: View {
    let visit: Visit
    
    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(Color(visit.serviceType.color))
                    .frame(width: 40, height: 40)
                    .shadow(radius: 4)
                
                Image(systemName: visit.serviceType.icon)
                    .foregroundColor(.white)
                    .font(.system(size: 16, weight: .semibold))
            }
            
            Text(visit.petName)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemBackground))
                        .shadow(radius: 2)
                )
        }
    }
}

struct RouteBottomSheet: View {
    let route: Route
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Today's Route")
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Text("Optimized for \(route.visits.count) visits")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(Int(route.efficiency * 100))% Efficient")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color(route.efficiencyColor))
                    
                    Text(route.formattedDistance)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(route.visits.enumerated()), id: \.element.id) { index, visit in
                        RouteStepCard(visit: visit, stepNumber: index + 1)
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.horizontal, -20)
        }
        .padding(20)
    }
}

struct RouteStepCard: View {
    let visit: Visit
    let stepNumber: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("\(stepNumber)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(width: 20, height: 20)
                    .background(Circle().fill(Color.blue))
                
                Spacer()
                
                Image(systemName: visit.serviceType.icon)
                    .foregroundColor(Color(visit.serviceType.color))
                    .font(.caption)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(visit.petName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                
                Text(visit.timeWindow)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .frame(width: 120)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
}

#Preview {
    RouteMapView()
        .environmentObject(ScheduleViewModel())
} 