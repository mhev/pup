import SwiftUI

struct MainTabView: View {
    @StateObject private var scheduleViewModel = ScheduleViewModel()
    
    var body: some View {
        ZStack {
            // Background color
            Config.primaryColor
                .ignoresSafeArea()
            
            TabView {
                ModernScheduleView()
                    .environmentObject(scheduleViewModel)
                    .tabItem {
                        Label("Schedule", systemImage: "calendar")
                    }
                
                RouteMapView()
                    .environmentObject(scheduleViewModel)
                    .tabItem {
                        Label("Map", systemImage: "map")
                    }
                
                IncomeDashboardView()
                    .tabItem {
                        Label("Income", systemImage: "dollarsign.circle")
                    }
                
                ProfileView()
                    .tabItem {
                        Label("Profile", systemImage: "person.circle")
                    }
            }
            .accentColor(Config.evergreenColor)
        }
    }
}

#Preview {
    MainTabView()
} 