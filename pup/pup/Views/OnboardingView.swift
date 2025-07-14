import SwiftUI
import Foundation

struct OnboardingView: View {
    @State private var currentPage = 0
    @Binding var showOnboarding: Bool
    
    var body: some View {
        ZStack {
            // Background color
            Config.primaryColor
                .ignoresSafeArea()
            
            TabView(selection: $currentPage) {
                // Welcome screen with demo schedule
                WelcomeWithDemoView(
                    currentPage: $currentPage,
                    showOnboarding: $showOnboarding
                )
                .tag(0)
                
                // Value proposition carousel
                ValueCarouselView(
                    currentPage: $currentPage,
                    showOnboarding: $showOnboarding
                )
                .tag(1)
                
                // Import options
                OnboardingImportOptionsView(
                    currentPage: $currentPage,
                    showOnboarding: $showOnboarding
                )
                .tag(2)
                
                // Get started
                GetStartedView(
                    currentPage: $currentPage,
                    showOnboarding: $showOnboarding
                )
                .tag(3)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        }
    }
}

// MARK: - Welcome with Demo Schedule

struct WelcomeWithDemoView: View {
    @Binding var currentPage: Int
    @Binding var showOnboarding: Bool
    
    private let demoVisits = [
        DemoVisit(petName: "Max", clientName: "Sarah", time: "9:00 AM", type: .walk),
        DemoVisit(petName: "Luna", clientName: "Mike", time: "11:30 AM", type: .sitting),
        DemoVisit(petName: "Buddy", clientName: "Emily", time: "2:00 PM", type: .dropIn),
        DemoVisit(petName: "Bella", clientName: "John", time: "4:30 PM", type: .walk)
    ]
    
    var body: some View {
        VStack(spacing: Config.largeSpacing) {
            // Header
            VStack(spacing: Config.sectionSpacing) {
                Image(systemName: "pawprint.fill")
                    .font(.system(size: 60))
                    .foregroundColor(Config.evergreenColor)
                
                Text("Welcome to Martina")
                    .font(.system(size: Config.largeTitleFontSize, weight: .bold))
                    .foregroundColor(.primary)
                
                Text("Your intelligent pet care companion")
                    .font(.system(size: Config.bodyFontSize))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, Config.largeSpacing)
            
            // Demo schedule
            VStack(alignment: .leading, spacing: Config.sectionSpacing) {
                Text("Today's Schedule")
                    .font(.system(size: Config.headingFontSize, weight: .semibold))
                    .foregroundColor(.primary)
                
                VStack(spacing: Config.itemSpacing) {
                    ForEach(demoVisits) { visit in
                        DemoVisitCard(visit: visit)
                    }
                }
            }
            .cardStyle()
            .padding(.horizontal, Config.largeSpacing)
            
            Spacer()
            
            // Navigation
            OnboardingNavigation(
                currentPage: $currentPage,
                showOnboarding: $showOnboarding,
                totalPages: 4,
                nextButtonText: "See How It Works"
            )
        }
    }
}

// MARK: - Value Carousel

struct ValueCarouselView: View {
    @Binding var currentPage: Int
    @Binding var showOnboarding: Bool
    @State private var valueIndex = 0
    
    private let values = [
        ValueProposition(
            icon: ContextIcons.route,
            title: "Smart Route Optimization",
            description: "AI-powered routing saves you time and fuel costs by finding the most efficient path between visits.",
            benefit: "Save 30% on travel time"
        ),
        ValueProposition(
            icon: ContextIcons.mileage,
            title: "Automatic Mileage Tracking",
            description: "GPS-based tracking logs your business miles automatically for easy tax deductions.",
            benefit: "Maximize tax deductions"
        ),
        ValueProposition(
            icon: ContextIcons.analytics,
            title: "Business Analytics",
            description: "Track your performance with detailed insights on visits, earnings, and efficiency metrics.",
            benefit: "Grow your business faster"
        )
    ]
    
    var body: some View {
        VStack(spacing: Config.largeSpacing) {
            // Header
            VStack(spacing: Config.sectionSpacing) {
                Text("Why Pet Care Pros Love Martina")
                    .font(.system(size: Config.largeTitleFontSize, weight: .bold))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                
                Text("Transform your pet care business")
                    .font(.system(size: Config.bodyFontSize))
                    .foregroundColor(.secondary)
            }
            .padding(.top, Config.largeSpacing)
            
            // Value carousel
            TabView(selection: $valueIndex) {
                ForEach(0..<values.count, id: \.self) { index in
                    ValueCard(value: values[index])
                        .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .frame(height: 300)
            .onAppear {
                startAutoAdvance()
            }
            
            // Value indicators
            HStack(spacing: Config.itemSpacing) {
                ForEach(0..<values.count, id: \.self) { index in
                    Circle()
                        .fill(valueIndex == index ? Config.evergreenColor : Color.secondary.opacity(0.3))
                        .frame(width: 8, height: 8)
                        .animation(.easeInOut, value: valueIndex)
                }
            }
            
            Spacer()
            
                            // Navigation
                OnboardingNavigation(
                    currentPage: $currentPage,
                    showOnboarding: $showOnboarding,
                    totalPages: 4,
                    nextButtonText: "Continue"
                )
        }
    }
    
    private func startAutoAdvance() {
        Timer.scheduledTimer(withTimeInterval: 6.0, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.5)) {
                valueIndex = (valueIndex + 1) % values.count
            }
        }
    }
}

// MARK: - Import Options

struct OnboardingImportOptionsView: View {
    @Binding var currentPage: Int
    @Binding var showOnboarding: Bool
    @State private var selectedImportType: ImportType?
    
    var body: some View {
        VStack(spacing: Config.largeSpacing) {
            // Header
            VStack(spacing: Config.sectionSpacing) {
                Text("Import Your Existing Schedule")
                    .font(.system(size: Config.largeTitleFontSize, weight: .bold))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                
                Text("Get started instantly with your current bookings")
                    .font(.system(size: Config.bodyFontSize))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, Config.largeSpacing)
            
            // Import options
            VStack(spacing: Config.sectionSpacing) {
                ImportOptionCard(
                    icon: "📅",
                    title: "Calendar Import",
                    description: "Import events from your iPhone calendar",
                    type: .calendar,
                    isSelected: selectedImportType == .calendar
                ) {
                    selectedImportType = .calendar
                }
                
                ImportOptionCard(
                    icon: "📊",
                    title: "CSV Import",
                    description: "Import from Rover, Wag, or other platforms",
                    type: .csv,
                    isSelected: selectedImportType == .csv
                ) {
                    selectedImportType = .csv
                }
                
                ImportOptionCard(
                    icon: "✋",
                    title: "Manual Entry",
                    description: "Add visits one by one as you go",
                    type: .manual,
                    isSelected: selectedImportType == .manual
                ) {
                    selectedImportType = .manual
                }
            }
            .padding(.horizontal, Config.largeSpacing)
            
            Spacer()
            
            // Navigation
            OnboardingNavigation(
                currentPage: $currentPage,
                showOnboarding: $showOnboarding,
                totalPages: 4,
                nextButtonText: "Continue"
            )
        }
    }
}

// MARK: - Get Started

struct GetStartedView: View {
    @Binding var currentPage: Int
    @Binding var showOnboarding: Bool
    
    var body: some View {
        VStack(spacing: Config.largeSpacing) {
            // Header
            VStack(spacing: Config.sectionSpacing) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.green)
                
                Text("You're All Set!")
                    .font(.system(size: Config.largeTitleFontSize, weight: .bold))
                    .foregroundColor(.primary)
                
                Text("Ready to streamline your pet care business")
                    .font(.system(size: Config.bodyFontSize))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, Config.largeSpacing)
            
            // Quick tips
            VStack(spacing: Config.sectionSpacing) {
                QuickTip(
                    icon: "plus.circle.fill",
                    text: "Tap + to add your first visit"
                )
                
                QuickTip(
                    icon: "location.fill",
                    text: "Set your home base for optimal routing"
                )
                
                QuickTip(
                    icon: "sparkles",
                    text: "Let AI optimize your daily routes"
                )
            }
            .padding(.horizontal, Config.largeSpacing)
            
            Spacer()
            
            // Get started button
            Button(action: {
                showOnboarding = false
            }) {
                Text("Start Using Martina")
                    .font(.system(size: Config.bodyFontSize, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Config.sectionSpacing)
                    .background(Config.evergreenColor)
                    .cornerRadius(Config.buttonCornerRadius)
            }
            .padding(.horizontal, Config.largeSpacing)
            .padding(.bottom, Config.largeSpacing)
        }
    }
}

// MARK: - Supporting Types and Views

struct DemoVisit: Identifiable {
    let id = UUID()
    let petName: String
    let clientName: String
    let time: String
    let type: ServiceType
}

struct ValueProposition {
    let icon: String
    let title: String
    let description: String
    let benefit: String
}

enum ImportType {
    case calendar
    case csv
    case manual
}

struct DemoVisitCard: View {
    let visit: DemoVisit
    
    var body: some View {
        HStack(spacing: Config.sectionSpacing) {
            // Service type icon
            Image(systemName: visit.type.icon)
                .font(.system(size: Config.headingFontSize))
                .foregroundColor(visit.type.color)
                .frame(width: 32, height: 32)
            
            // Visit details
            VStack(alignment: .leading, spacing: 2) {
                Text(visit.petName)
                    .font(.system(size: Config.bodyFontSize, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(visit.clientName)
                    .font(.system(size: Config.captionFontSize))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Time
            Text(visit.time)
                .font(.system(size: Config.captionFontSize, weight: .medium))
                .foregroundColor(.secondary)
        }
        .padding(.vertical, Config.itemSpacing)
    }
}

struct ValueCard: View {
    let value: ValueProposition
    
    var body: some View {
        VStack(spacing: Config.largeSpacing) {
            // Icon
            Text(value.icon)
                .font(.system(size: 60))
            
            // Content
            VStack(spacing: Config.sectionSpacing) {
                Text(value.title)
                    .font(.system(size: Config.headingFontSize, weight: .bold))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                
                Text(value.description)
                    .font(.system(size: Config.bodyFontSize))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Config.largeSpacing)
                
                Text(value.benefit)
                    .font(.system(size: Config.bodyFontSize, weight: .semibold))
                    .foregroundColor(Config.evergreenColor)
                    .padding(.horizontal, Config.sectionSpacing)
                    .padding(.vertical, Config.itemSpacing)
                    .background(
                        RoundedRectangle(cornerRadius: Config.chipCornerRadius)
                            .fill(Config.evergreenColor.opacity(0.1))
                    )
            }
        }
        .padding(.horizontal, Config.largeSpacing)
    }
}

struct ImportOptionCard: View {
    let icon: String
    let title: String
    let description: String
    let type: ImportType
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Config.sectionSpacing) {
                // Icon
                Text(icon)
                    .font(.system(size: Config.largeTitleFontSize))
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: Config.bodyFontSize, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text(description)
                        .font(.system(size: Config.captionFontSize))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Selection indicator
                Circle()
                    .fill(isSelected ? Config.evergreenColor : Color.clear)
                    .stroke(isSelected ? Config.evergreenColor : Color.secondary, lineWidth: 2)
                    .frame(width: 20, height: 20)
                    .overlay(
                        Circle()
                            .fill(Color.white)
                            .frame(width: 8, height: 8)
                            .opacity(isSelected ? 1 : 0)
                    )
            }
            .padding(Config.cardPadding)
            .background(
                RoundedRectangle(cornerRadius: Config.cardCornerRadius)
                    .fill(Config.cardBackgroundColor)
                    .stroke(isSelected ? Config.evergreenColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct QuickTip: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: Config.sectionSpacing) {
            Image(systemName: icon)
                .font(.system(size: Config.headingFontSize))
                .foregroundColor(Config.evergreenColor)
            
            Text(text)
                .font(.system(size: Config.bodyFontSize))
                .foregroundColor(.primary)
            
            Spacer()
        }
        .padding(.vertical, Config.itemSpacing)
    }
}

struct OnboardingNavigation: View {
    @Binding var currentPage: Int
    @Binding var showOnboarding: Bool
    let totalPages: Int
    let nextButtonText: String
    
    var body: some View {
        VStack(spacing: Config.sectionSpacing) {
            // Page indicator
            HStack(spacing: Config.itemSpacing) {
                ForEach(0..<totalPages, id: \.self) { index in
                    Circle()
                        .fill(currentPage == index ? Config.evergreenColor : Color.secondary.opacity(0.3))
                        .frame(width: 8, height: 8)
                        .animation(.easeInOut, value: currentPage)
                }
            }
            
            // Navigation buttons
            HStack(spacing: Config.sectionSpacing) {
                if currentPage > 0 {
                    Button("Back") {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentPage -= 1
                        }
                    }
                    .font(.system(size: Config.bodyFontSize, weight: .medium))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Spacer()
                    
                    Button(nextButtonText) {
                        if currentPage < totalPages - 1 {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                currentPage += 1
                            }
                        } else {
                            showOnboarding = false
                        }
                    }
                    .font(.system(size: Config.bodyFontSize, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, Config.largeSpacing)
                    .padding(.vertical, Config.sectionSpacing)
                    .background(Config.evergreenColor)
                    .cornerRadius(Config.buttonCornerRadius)
                    
                    Spacer()
                } else {
                    // Center the button when there's no back button
                    Button(nextButtonText) {
                        if currentPage < totalPages - 1 {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                currentPage += 1
                            }
                        } else {
                            showOnboarding = false
                        }
                    }
                    .font(.system(size: Config.bodyFontSize, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, Config.largeSpacing)
                    .padding(.vertical, Config.sectionSpacing)
                    .background(Config.evergreenColor)
                    .cornerRadius(Config.buttonCornerRadius)
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.horizontal, Config.largeSpacing)
        .padding(.bottom, Config.largeSpacing)
    }
}



#Preview {
    OnboardingView(showOnboarding: .constant(true))
} 