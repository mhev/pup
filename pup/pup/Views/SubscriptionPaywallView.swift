import SwiftUI
import StoreKit

struct SubscriptionPaywallView: View {
    @StateObject private var subscriptionService = SubscriptionService.shared
    @State private var showingPromoCode = false
    @State private var promoCodeText = ""
    @State private var selectedProduct: Product?
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Config.primaryColor
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: Config.sectionSpacing) {
                        // Header
                        headerView
                        
                        // Premium Features
                        premiumFeaturesView
                        
                        // Subscription Options
                        subscriptionOptionsView
                        
                        // Promo Code Section
                        promoCodeSection
                        
                        // Terms and Privacy
                        termsAndPrivacyView
                    }
                    .padding(.horizontal, Config.largeSpacing)
                    .padding(.bottom, Config.largeSpacing)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Restore") {
                        Task {
                            await subscriptionService.updateSubscriptionStatus()
                        }
                    }
                    .font(.system(size: Config.bodyFontSize))
                }
            }
        }
        .alert("Error", isPresented: .constant(subscriptionService.errorMessage != nil)) {
            Button("OK") {
                subscriptionService.errorMessage = nil
            }
        } message: {
            if let errorMessage = subscriptionService.errorMessage {
                Text(errorMessage)
            }
        }
    }
    
    private var headerView: some View {
        VStack(spacing: Config.sectionSpacing) {
            // App Icon
            Image(systemName: "pawprint.fill")
                .font(.system(size: 60))
                .foregroundColor(Config.evergreenColor)
            
            Text("Unlock Premium")
                .font(.system(size: Config.largeTitleFontSize, weight: .bold))
                .foregroundColor(Config.evergreenColor)
            
            Text("Get full access to all Martina features")
                .font(.system(size: Config.bodyFontSize))
                .foregroundColor(Config.evergreenColor.opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, Config.largeSpacing)
    }
    
    private var premiumFeaturesView: some View {
        VStack(spacing: Config.sectionSpacing) {
            Text("Premium Features")
                .font(.system(size: Config.headingFontSize, weight: .semibold))
                .foregroundColor(Config.evergreenColor)
            
            VStack(spacing: Config.itemSpacing) {
                FeatureRow(icon: ContextIcons.mileage, title: "Mileage Tracking", description: "Automatic GPS logging and tax deduction estimates")
                FeatureRow(icon: ContextIcons.tips, title: "Income & Tips", description: "Track earnings with CSV import support")
                FeatureRow(icon: ContextIcons.analytics, title: "Analytics Dashboard", description: "Detailed insights and performance metrics")
                FeatureRow(icon: ContextIcons.reminders, title: "Smart Reminders", description: "Location-based alerts and notifications")
                FeatureRow(icon: ContextIcons.ai, title: "AI Assistant", description: "Chat support and care recommendations")
                FeatureRow(icon: "📤", title: "Calendar/CSV Import", description: "Import schedules from Rover, Wag, and calendars")
            }
        }
        .cardStyle()
    }
    
    private var subscriptionOptionsView: some View {
        VStack(spacing: Config.sectionSpacing) {
            Text("Choose Your Plan")
                .font(.system(size: Config.headingFontSize, weight: .semibold))
                .foregroundColor(Config.evergreenColor)
            
            VStack(spacing: Config.itemSpacing) {
                ForEach(subscriptionService.products, id: \.id) { product in
                    SubscriptionOptionCard(
                        product: product,
                        isSelected: selectedProduct?.id == product.id,
                        onSelect: { selectedProduct = product }
                    )
                }
            }
            
            // Purchase Button
            if let selectedProduct = selectedProduct {
                Button(action: {
                    Task {
                        let success = await subscriptionService.purchase(product: selectedProduct)
                        if success {
                            isPresented = false
                        }
                    }
                }) {
                    HStack {
                        if subscriptionService.isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Subscribe")
                                .font(.system(size: Config.bodyFontSize, weight: .semibold))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Config.sectionSpacing)
                    .background(Config.evergreenColor)
                    .foregroundColor(.white)
                    .cornerRadius(Config.buttonCornerRadius)
                }
                .disabled(subscriptionService.isLoading)
                .padding(.top, Config.sectionSpacing)
            }
        }
        .cardStyle()
    }
    
    private var promoCodeSection: some View {
        VStack(spacing: Config.sectionSpacing) {
            if showingPromoCode {
                VStack(spacing: Config.itemSpacing) {
                    TextField("Enter promo code", text: $promoCodeText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.allCharacters)
                        .disableAutocorrection(true)
                    
                    HStack(spacing: Config.itemSpacing) {
                        Button("Cancel") {
                            showingPromoCode = false
                            promoCodeText = ""
                        }
                        .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Button("Redeem") {
                            Task {
                                let success = await subscriptionService.redeemPromoCode(promoCodeText)
                                if success {
                                    isPresented = false
                                } else {
                                    subscriptionService.errorMessage = "Invalid promo code"
                                }
                            }
                        }
                        .foregroundColor(Config.evergreenColor)
                        .disabled(promoCodeText.isEmpty)
                    }
                }
                .cardStyle()
            } else {
                Button("Have a promo code?") {
                    showingPromoCode = true
                }
                .foregroundColor(Config.evergreenColor)
                .font(.system(size: Config.bodyFontSize))
            }
        }
    }
    
    private var termsAndPrivacyView: some View {
        VStack(spacing: Config.itemSpacing) {
            Text("By subscribing, you agree to our Terms of Service and Privacy Policy. Subscriptions auto-renew unless cancelled.")
                .font(.system(size: Config.captionFontSize))
                .foregroundColor(Config.evergreenColor.opacity(0.7))
                .multilineTextAlignment(.center)
            
            HStack(spacing: Config.largeSpacing) {
                Link("Terms of Service", destination: URL(string: "https://hevllc.com/terms-of-service.html")!)
                Link("Privacy Policy", destination: URL(string: "https://hevllc.com/privacy-policy.html")!)
            }
            .font(.system(size: Config.captionFontSize))
            .foregroundColor(Config.evergreenColor)
        }
        .padding(.top, Config.sectionSpacing)
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: Config.sectionSpacing) {
            Text(icon)
                .font(.system(size: Config.headingFontSize))
                .frame(width: 32, height: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: Config.bodyFontSize, weight: .semibold))
                    .foregroundColor(Config.evergreenColor)
                
                Text(description)
                    .font(.system(size: Config.captionFontSize))
                    .foregroundColor(Config.evergreenColor.opacity(0.8))
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct SubscriptionOptionCard: View {
    let product: Product
    let isSelected: Bool
    let onSelect: () -> Void
    
    @StateObject private var subscriptionService = SubscriptionService.shared
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: Config.sectionSpacing) {
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
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(product.displayName)
                            .font(.system(size: Config.bodyFontSize, weight: .semibold))
                            .foregroundColor(Config.evergreenColor)
                        
                        if let savingsText = subscriptionService.savingsText(for: product) {
                            Text(savingsText)
                                .font(.system(size: Config.captionFontSize, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Config.evergreenColor)
                                .cornerRadius(12)
                        }
                    }
                    
                    Text(product.description)
                        .font(.system(size: Config.captionFontSize))
                        .foregroundColor(Config.evergreenColor.opacity(0.8))
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(product.displayPrice)
                        .font(.system(size: Config.bodyFontSize, weight: .bold))
                        .foregroundColor(Config.evergreenColor)
                    
                    if product.id == "com.hev.pup.yearly" {
                        Text("$10.00/month")
                            .font(.system(size: Config.captionFontSize, weight: .medium))
                            .foregroundColor(Config.evergreenColor.opacity(0.8))
                    }
                }
            }
            .padding(Config.cardPadding)
            .background(
                RoundedRectangle(cornerRadius: Config.cardCornerRadius)
                    .fill(isSelected ? Config.evergreenColor.opacity(0.08) : Color.white)
                    .stroke(isSelected ? Config.evergreenColor : Color.gray.opacity(0.3), lineWidth: isSelected ? 2 : 1)
                    .shadow(
                        color: Config.shadowColor,
                        radius: Config.cardShadowRadius,
                        x: Config.cardShadowOffset.width,
                        y: Config.cardShadowOffset.height
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
