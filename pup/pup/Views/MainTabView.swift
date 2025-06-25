import SwiftUI

struct MainTabView: View {
    @StateObject private var scheduleViewModel = ScheduleViewModel()
    
    var body: some View {
        TabView {
            ScheduleView()
                .environmentObject(scheduleViewModel)
                .tabItem {
                    Label("Schedule", systemImage: "calendar")
                }
            
            RouteMapView()
                .environmentObject(scheduleViewModel)
                .tabItem {
                    Label("Map", systemImage: "map")
                }
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.circle")
                }
        }
        .accentColor(.blue)
    }
}

#Preview {
    MainTabView()
} 