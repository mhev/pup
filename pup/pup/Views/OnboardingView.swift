import SwiftUI

struct OnboardingView: View {
    @State private var currentPage = 0
    @Binding var showOnboarding: Bool
    
    var body: some View {
        ZStack {
            // Background color
            Config.primaryColor
                .ignoresSafeArea()
            
            TabView(selection: $currentPage) {
                // First screen
                OnboardingPageView(
                    title: "Welcome to Martina",
                    subtitle: "Your intelligent pet care companion",
                    description: "Streamline your pet care business with smart route optimization and scheduling.",
                    systemImage: "pawprint.fill",
                    imageColor: .green,
                    currentPage: $currentPage,
                    showOnboarding: $showOnboarding
                )
                .tag(0)
                
                // Second screen
                OnboardingPageView(
                    title: "Optimize Your Routes",
                    subtitle: "AI-powered scheduling",
                    description: "Automatically optimize your daily routes between dog walks, drop-in visits, and pet care appointments. Save time and reduce travel with intelligent scheduling.",
                    systemImage: "map.fill",
                    imageColor: .blue,
                    currentPage: $currentPage,
                    showOnboarding: $showOnboarding
                )
                .tag(1)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        }
    }
}

struct OnboardingPageView: View {
    let title: String
    let subtitle: String
    let description: String
    let systemImage: String
    let imageColor: Color
    @Binding var currentPage: Int
    @Binding var showOnboarding: Bool
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Icon
            Image(systemName: systemImage)
                .font(.system(size: 80))
                .foregroundColor(imageColor)
            
            // Content
            VStack(spacing: 16) {
                Text(title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                Text(description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            Spacer()
            
            // Navigation
            VStack(spacing: 16) {
                // Page indicator
                HStack(spacing: 8) {
                    ForEach(0..<2) { index in
                        Circle()
                            .fill(currentPage == index ? Color.primary : Color.secondary.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                }
                
                // Button
                Button(action: {
                    if currentPage < 1 {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            currentPage += 1
                        }
                    } else {
                        showOnboarding = false
                    }
                }) {
                    Text(currentPage < 1 ? "Next" : "Get Started")
                        .font(.headline)
                        .foregroundColor(Config.buttonTextColor)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Config.accentColor)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 32)
            }
            .padding(.bottom, 50)
        }
    }
}



#Preview {
    OnboardingView(showOnboarding: .constant(true))
} 