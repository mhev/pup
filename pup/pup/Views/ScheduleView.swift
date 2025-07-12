import SwiftUI

struct ScheduleView: View {
    @EnvironmentObject var viewModel: ScheduleViewModel
    @State private var showingAddVisit = false
    @State private var showingDatePicker = false
    
    private var dayOfWeek: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: viewModel.selectedDate)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background color
                Config.primaryColor
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                // Home Base section
                HomeBaseView(viewModel: viewModel.homeBaseViewModel)
                    .padding(.horizontal)
                    .padding(.top, 4)
                
                // Header with route optimization info
                if let route = viewModel.optimizedRoute {
                    RouteInfoCard(route: route)
                        .environmentObject(viewModel)
                        .padding(.horizontal)
                        .padding(.top, 8)
                } else if !viewModel.upcomingVisits.isEmpty {
                    OptimizeRouteButton(viewModel: viewModel)
                        .padding(.horizontal)
                        .padding(.top, 8)
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
            }
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: viewModel.goToPreviousDay) {
                        Image(systemName: "chevron.left")
                            .fontWeight(.semibold)
                    }
                }
                
                ToolbarItem(placement: .principal) {
                    Button(action: { showingDatePicker = true }) {
                        VStack(spacing: 2) {
                            Text(viewModel.selectedDateTitle)
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            if !viewModel.isToday {
                                Text(dayOfWeek)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .foregroundColor(.primary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 12) {
                        Button(action: viewModel.goToNextDay) {
                            Image(systemName: "chevron.right")
                                .fontWeight(.semibold)
                        }
                        
                        Button(action: { showingAddVisit = true }) {
                            Image(systemName: "plus")
                                .fontWeight(.semibold)
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAddVisit) {
                AddVisitView(defaultDate: viewModel.selectedDate) { visit in
                    viewModel.addVisit(visit)
                    showingAddVisit = false
                }
            }
            .sheet(isPresented: $showingDatePicker) {
                CompactDatePickerView(viewModel: viewModel)
            }
            .overlay {
                if viewModel.todaysVisits.isEmpty {
                    EmptyScheduleView(selectedDate: viewModel.selectedDate, isToday: viewModel.isToday) {
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

struct CompactDatePickerView: View {
    @ObservedObject var viewModel: ScheduleViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                DatePicker("Select Date", 
                          selection: $viewModel.selectedDate,
                          in: Date()...,
                          displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .padding()
                
                HStack(spacing: 16) {
                    Button("Today") {
                        viewModel.selectedDate = Date()
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.capsule)
                    
                    Button("Tomorrow") {
                        viewModel.selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.capsule)
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("Select Date")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

struct OptimizeRouteButton: View {
    @ObservedObject var viewModel: ScheduleViewModel
    @State private var isAnimating = false
    
    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.3)) {
                isAnimating = true
            }
            viewModel.optimizeCurrentRoute()
        }) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Config.accentColor.opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    if viewModel.isLoading {
                        // Animated loading state
                        ZStack {
                            Circle()
                                .stroke(Color.purple.opacity(0.3), lineWidth: 3)
                                .frame(width: 30, height: 30)
                            
                            Circle()
                                .trim(from: 0, to: 0.7)
                                .stroke(Color.purple, lineWidth: 3)
                                .frame(width: 30, height: 30)
                                .rotationEffect(.degrees(isAnimating ? 360 : 0))
                                .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: isAnimating)
                        }
                    } else {
                        Image(systemName: "brain")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.purple)
                            .scaleEffect(isAnimating ? 1.1 : 1.0)
                            .animation(.easeInOut(duration: 0.3), value: isAnimating)
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.isLoading ? "Optimizing Route..." : "Optimize Route")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    if viewModel.isLoading {
                        Text("AI is calculating the best route")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("Get AI-powered route optimization for \(viewModel.upcomingVisits.count) visits")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                if !viewModel.isLoading {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Config.cardBackgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Config.accentColor.opacity(0.3), lineWidth: 1.5)
                    )
                    .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(viewModel.isLoading)
        .onChange(of: viewModel.isLoading) { loading in
            if loading {
                isAnimating = true
            } else {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isAnimating = false
                }
            }
        }
    }
}

struct RouteInfoCard: View {
    let route: Route
    @EnvironmentObject var viewModel: ScheduleViewModel
    @State private var isReasoningExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "location.circle.fill")
                    .foregroundColor(.blue)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Optimized Route")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    if viewModel.homeBaseViewModel.homeBase.isSet {
                        Text("Starting from \(viewModel.homeBaseViewModel.homeBase.name)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
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
            
            if let reasoning = route.aiReasoning {
                Divider()
                    .padding(.vertical, 4)
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .foregroundColor(.purple)
                            .font(.subheadline)
                        
                        Text("AI Insights")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.purple)
                        
                        Spacer()
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        if isReasoningExpanded {
                            ScrollView {
                                Text(reasoning)
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                                    .padding(.leading, 4)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .frame(maxHeight: 120)
                        } else {
                            Text(reasoning)
                                .font(.subheadline)
                                .foregroundColor(.primary)
                                .lineLimit(3)
                                .padding(.leading, 4)
                        }
                        
                        // Show more/less button
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                isReasoningExpanded.toggle()
                            }
                        }) {
                            HStack(spacing: 4) {
                                Text(isReasoningExpanded ? "Show less" : "Show more")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.purple)
                                
                                Image(systemName: isReasoningExpanded ? "chevron.up" : "chevron.down")
                                    .font(.caption)
                                    .foregroundColor(.purple)
                            }
                        }
                        .padding(.leading, 4)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Config.cardBackgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Config.accentColor.opacity(0.3), lineWidth: 1.5)
                )
                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
        )
    }
}

struct VisitCard: View {
    let visit: Visit
    let onComplete: () -> Void
    @State private var showingCompletionAlert = false
    
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
                            .foregroundColor(visit.serviceType.color)
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
                        .foregroundColor(Color(red: 0.0, green: 0.7, blue: 0.0))
                }
                
                Spacer()
                
                Button("Complete") {
                    showingCompletionAlert = true
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
                .controlSize(.small)
                .tint(Config.accentColor)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Config.cardBackgroundColor)
                .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
        )
        .alert("Complete Visit", isPresented: $showingCompletionAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Complete") {
                onComplete()
            }
        } message: {
            Text("Mark \(visit.petName)'s \(visit.serviceType.rawValue.lowercased()) as completed?")
        }
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
                .foregroundColor(Color(red: 0.0, green: 0.7, blue: 0.0))
            
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
    let selectedDate: Date
    let isToday: Bool
    let onAddVisit: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 60))
                .foregroundColor(.blue.opacity(0.6))
            
            VStack(spacing: 8) {
                Text(emptyTitle)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(emptyMessage)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button("Add Visit") {
                onAddVisit()
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
            .tint(Config.accentColor)
        }
        .padding(.horizontal, 40)
    }
    
    private var emptyTitle: String {
        if isToday {
            return "No visits scheduled today"
        } else {
            return "No visits scheduled"
        }
    }
    
    private var emptyMessage: String {
        if isToday {
            return "Add your first visit to get started with route optimization"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE, MMM d"
            return "No visits scheduled for \(formatter.string(from: selectedDate))"
        }
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