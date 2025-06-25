import SwiftUI

struct ScheduleView: View {
    @EnvironmentObject var viewModel: ScheduleViewModel
    @State private var showingAddVisit = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header with route optimization info
                if let route = viewModel.optimizedRoute {
                    RouteInfoCard(route: route)
                        .padding(.horizontal)
                        .padding(.top)
                }
                
                // Visit list
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.upcomingVisits) { visit in
                            VisitCard(visit: visit) {
                                viewModel.markVisitCompleted(visit)
                            }
                        }
                        
                        if !viewModel.completedVisits.isEmpty {
                            CompletedVisitsSection(visits: viewModel.completedVisits)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, viewModel.optimizedRoute == nil ? 20 : 8)
                }
                
                Spacer()
            }
            .navigationTitle("Today's Schedule")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddVisit = true }) {
                        Image(systemName: "plus")
                            .fontWeight(.semibold)
                    }
                }
            }
            .sheet(isPresented: $showingAddVisit) {
                AddVisitView { visit in
                    viewModel.addVisit(visit)
                    showingAddVisit = false
                }
            }
            .overlay {
                if viewModel.todaysVisits.isEmpty {
                    EmptyScheduleView {
                        showingAddVisit = true
                    }
                }
            }
            .overlay {
                if viewModel.isLoading {
                    LoadingOverlay(message: "Optimizing route...")
                }
            }
        }
        .onAppear {
            viewModel.requestLocationPermission()
        }
    }
}

struct RouteInfoCard: View {
    let route: Route
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "location.circle.fill")
                    .foregroundColor(.blue)
                Text("Optimized Route")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Circle()
                    .fill(Color(route.efficiencyColor))
                    .frame(width: 8, height: 8)
                Text("\(Int(route.efficiency * 100))%")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
            }
            
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Distance")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(route.formattedDistance)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Travel Time")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(route.formattedTravelTime)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Visits")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(route.visits.count)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                
                Spacer()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
        )
    }
}

struct VisitCard: View {
    let visit: Visit
    let onComplete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(visit.petName)
                        .font(.headline)
                        .fontWeight(.semibold)
                    Text(visit.clientName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    HStack {
                        Image(systemName: visit.serviceType.icon)
                            .foregroundColor(Color(visit.serviceType.color))
                        Text(visit.serviceType.rawValue)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    
                    Text(visit.timeWindow)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            HStack {
                Image(systemName: "location")
                    .foregroundColor(.secondary)
                    .font(.caption)
                Text(visit.address)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                Spacer()
            }
            
            if let notes = visit.notes {
                Text(notes)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
            
            HStack {
                if visit.isFlexible {
                    Label("Flexible", systemImage: "clock.badge.checkmark")
                        .font(.caption)
                        .foregroundColor(.green)
                }
                
                Spacer()
                
                Button("Complete") {
                    onComplete()
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
                .controlSize(.small)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
        )
    }
}

struct CompletedVisitsSection: View {
    let visits: [Visit]
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: { isExpanded.toggle() }) {
                HStack {
                    Text("Completed (\(visits.count))")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            if isExpanded {
                ForEach(visits) { visit in
                    CompletedVisitRow(visit: visit)
                }
            }
        }
        .padding(.top, 20)
    }
}

struct CompletedVisitRow: View {
    let visit: Visit
    
    var body: some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(visit.petName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(visit.clientName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(visit.timeWindow)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
        .opacity(0.8)
    }
}

struct EmptyScheduleView: View {
    let onAddVisit: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 60))
                .foregroundColor(.blue.opacity(0.6))
            
            VStack(spacing: 8) {
                Text("No visits scheduled")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Add your first visit to get started with route optimization")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button("Add Visit") {
                onAddVisit()
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
        }
        .padding(.horizontal, 40)
    }
}

struct LoadingOverlay: View {
    let message: String
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.2)
                
                Text(message)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(radius: 20)
            )
        }
    }
}

#Preview {
    NavigationStack {
        ScheduleView()
            .environmentObject(ScheduleViewModel())
    }
} 