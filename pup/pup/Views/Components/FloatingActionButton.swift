import SwiftUI

// MARK: - Floating Action Button

struct FloatingActionButton: View {
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            // Haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            
            action()
        }) {
            ZStack {
                Circle()
                    .fill(Config.evergreenColor)
                    .frame(width: 56, height: 56)
                    .shadow(
                        color: Config.shadowColor.opacity(0.3),
                        radius: 8,
                        x: 0,
                        y: 4
                    )
                
                Image(systemName: "plus")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.white)
            }
        }
        .buttonStyle(FABButtonStyle())
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    isPressed = true
                }
                .onEnded { _ in
                    isPressed = false
                }
        )
    }
}

// MARK: - FAB Button Style

struct FABButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - FAB Container

struct FloatingActionButtonContainer<Content: View>: View {
    let content: Content
    let fabAction: () -> Void
    
    init(fabAction: @escaping () -> Void, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.fabAction = fabAction
    }
    
    var body: some View {
        ZStack {
            content
            
            VStack {
                Spacer()
                
                HStack {
                    Spacer()
                    
                    FloatingActionButton(action: fabAction)
                        .padding(.trailing, Config.largeSpacing)
                        .padding(.bottom, Config.largeSpacing)
                }
            }
        }
    }
} 