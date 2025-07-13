//
//  pupApp.swift
//  pup
//
//  Created by Michael Heverly on 6/24/25.
//

import SwiftUI

@main
struct PupApp: App {
    @State private var showOnboarding = !UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                // Background color
                Config.primaryColor
                    .ignoresSafeArea()
                
                if showOnboarding {
                    OnboardingView(showOnboarding: $showOnboarding)
                        .onDisappear {
                            UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
                        }
                } else {
                    ContentView()
                }
            }
            .preferredColorScheme(.light)
        }
    }
}
