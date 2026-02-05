import SwiftUI
import NimbleViews

// MARK: - iOS 17+ Version
@available(iOS 17.0, *)
struct NearbyShareIntroView: View {
    @AppStorage("hasSeenNearbyShareIntro") var hasSeenNearbyShareIntro: Bool = false
    @Environment(\.dismiss) private var dismiss
    @State private var animateContent = false
    @State private var animateButton = false
    
    var body: some View {
        ZStack {
            // Background
            Color(uiColor: .systemBackground)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 0) {
                    Spacer(minLength: 20)
                    
                    // Main content
                    VStack(spacing: 32) {
                        // Header Icon
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.purple.opacity(0.6), Color.blue.opacity(0.6)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 100, height: 100)
                                .shadow(color: Color.purple.opacity(0.3), radius: 20, x: 0, y: 10)
                            
                            Image(systemName: "antenna.radiowaves.left.and.right")
                                .font(.system(size: 40, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        .scaleEffect(animateContent ? 1.0 : 0.8)
                        .opacity(animateContent ? 1.0 : 0.0)
                        
                        VStack(spacing: 12) {
                            // Title
                            Text("Nearby Share")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundStyle(.primary)
                                .multilineTextAlignment(.center)
                                .opacity(animateContent ? 1.0 : 0.0)
                                .offset(y: animateContent ? 0 : 20)
                            
                            // Subtitle
                            Text("With Portal 2.3, use Nearby Share to quickly transfer apps between devices")
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                                .opacity(animateContent ? 1.0 : 0.0)
                                .offset(y: animateContent ? 0 : 20)
                        }
                        .padding(.horizontal, 32)
                        
                        // Steps
                        VStack(spacing: 16) {
                            StepRow(
                                step: 1,
                                icon: "iphone.gen2",
                                title: "Open Nearby Share",
                                description: "Navigate to the Nearby Share tab in Portal",
                                delay: 0.2
                            )
                            
                            StepRow(
                                step: 2,
                                icon: "person.2.fill",
                                title: "Select Mode",
                                description: "Choose to send or receive apps",
                                delay: 0.3
                            )
                            
                            StepRow(
                                step: 3,
                                icon: "wifi.circle.fill",
                                title: "Connect Devices",
                                description: "Devices must be on the same network",
                                delay: 0.4
                            )
                            
                            StepRow(
                                step: 4,
                                icon: "arrow.down.circle.fill",
                                title: "Transfer Apps",
                                description: "Select apps and start the transfer instantly",
                                delay: 0.5
                            )
                        }
                        .padding(.horizontal, 24)
                        .opacity(animateContent ? 1.0 : 0.0)
                        
                        // Tips Section
                        VStack(spacing: 12) {
                            HStack {
                                Image(systemName: "lightbulb.fill")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.yellow)
                                Text("Tips")
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .foregroundColor(.primary)
                                Spacer()
                            }
                            
                            VStack(spacing: 8) {
                                TipRow(text: "Both devices need Portal 2.3 or later")
                                TipRow(text: "Ensure WiFi is enabled on both devices")
                                TipRow(text: "Keep devices close for better performance")
                            }
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(uiColor: .secondarySystemBackground))
                                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
                        )
                        .padding(.horizontal, 24)
                        .opacity(animateContent ? 1.0 : 0.0)
                        
                        // Got It Button
                        Button {
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                                hasSeenNearbyShareIntro = true
                            }
                            HapticsManager.shared.success()
                            dismiss()
                        } label: {
                            HStack(spacing: 12) {
                                Text("Got It!")
                                    .font(.system(size: 20, weight: .bold, design: .rounded))
                                
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 24))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(
                                LinearGradient(
                                    colors: [Color.purple.opacity(0.8), Color.blue.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: Color.purple.opacity(0.3), radius: 20, x: 0, y: 10)
                        }
                        .padding(.horizontal, 24)
                        .scaleEffect(animateButton ? 1.0 : 0.9)
                        .opacity(animateButton ? 1.0 : 0.0)
                    }
                    .padding(.vertical, 32)
                    
                    Spacer(minLength: 20)
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                animateContent = true
            }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.6)) {
                animateButton = true
            }
        }
    }
}

// MARK: - Step Row Component
@available(iOS 17.0, *)
struct StepRow: View {
    let step: Int
    let icon: String
    let title: String
    let description: String
    let delay: Double
    @State private var isVisible = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Step number badge
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.purple.opacity(0.8), Color.blue.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 32, height: 32)
                
                Text("\(step)")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            
            // Icon container
            ZStack {
                Circle()
                    .fill(Color.purple.opacity(0.15))
                    .frame(width: 56, height: 56)
                
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.purple)
                    .rotationEffect(.degrees(isVisible ? 0 : -10))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(uiColor: .secondarySystemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
        .scaleEffect(isVisible ? 1.0 : 0.8)
        .opacity(isVisible ? 1.0 : 0.0)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(delay)) {
                isVisible = true
            }
        }
    }
}

// MARK: - Tip Row Component
@available(iOS 17.0, *)
struct TipRow: View {
    let text: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 12))
                .foregroundColor(.green)
            
            Text(text)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.secondary)
            
            Spacer()
        }
    }
}

// MARK: - iOS 16 Legacy Version
struct NearbyShareIntroViewLegacy: View {
    @AppStorage("hasSeenNearbyShareIntro") var hasSeenNearbyShareIntro: Bool = false
    @Environment(\.dismiss) private var dismiss
    @State private var animateContent = false
    @State private var animateButton = false
    
    var body: some View {
        ZStack {
            // Background
            Color(uiColor: .systemBackground)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 0) {
                    Spacer(minLength: 20)
                    
                    // Main content
                    VStack(spacing: 32) {
                        // Header Icon
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.purple.opacity(0.6), Color.blue.opacity(0.6)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 100, height: 100)
                                .shadow(color: Color.purple.opacity(0.3), radius: 20, x: 0, y: 10)
                            
                            Image(systemName: "antenna.radiowaves.left.and.right")
                                .font(.system(size: 40, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        .scaleEffect(animateContent ? 1.0 : 0.8)
                        .opacity(animateContent ? 1.0 : 0.0)
                        
                        VStack(spacing: 12) {
                            // Title
                            Text("Nearby Share")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.center)
                                .opacity(animateContent ? 1.0 : 0.0)
                                .offset(y: animateContent ? 0 : 20)
                            
                            // Subtitle
                            Text("With Portal 2.3, use Nearby Share to quickly transfer apps between devices")
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                                .opacity(animateContent ? 1.0 : 0.0)
                                .offset(y: animateContent ? 0 : 20)
                        }
                        .padding(.horizontal, 32)
                        
                        // Steps
                        VStack(spacing: 16) {
                            StepRowLegacy(
                                step: 1,
                                icon: "iphone.gen2",
                                title: "Open Nearby Share",
                                description: "Navigate to the Nearby Share tab in Portal",
                                delay: 0.2
                            )
                            
                            StepRowLegacy(
                                step: 2,
                                icon: "person.2.fill",
                                title: "Select Mode",
                                description: "Choose to send or receive apps",
                                delay: 0.3
                            )
                            
                            StepRowLegacy(
                                step: 3,
                                icon: "wifi.circle.fill",
                                title: "Connect Devices",
                                description: "Devices must be on the same network",
                                delay: 0.4
                            )
                            
                            StepRowLegacy(
                                step: 4,
                                icon: "arrow.down.circle.fill",
                                title: "Transfer Apps",
                                description: "Select apps and start the transfer instantly",
                                delay: 0.5
                            )
                        }
                        .padding(.horizontal, 24)
                        .opacity(animateContent ? 1.0 : 0.0)
                        
                        // Tips Section
                        VStack(spacing: 12) {
                            HStack {
                                Image(systemName: "lightbulb.fill")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.yellow)
                                Text("Tips")
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .foregroundColor(.primary)
                                Spacer()
                            }
                            
                            VStack(spacing: 8) {
                                TipRowLegacy(text: "Both devices need Portal 2.3 or later")
                                TipRowLegacy(text: "Ensure WiFi is enabled on both devices")
                                TipRowLegacy(text: "Keep devices close for better performance")
                            }
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(uiColor: .secondarySystemBackground))
                                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
                        )
                        .padding(.horizontal, 24)
                        .opacity(animateContent ? 1.0 : 0.0)
                        
                        // Got It Button
                        Button {
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                                hasSeenNearbyShareIntro = true
                            }
                            HapticsManager.shared.success()
                            dismiss()
                        } label: {
                            HStack(spacing: 12) {
                                Text("Got It!")
                                    .font(.system(size: 20, weight: .bold, design: .rounded))
                                
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 24))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(
                                LinearGradient(
                                    colors: [Color.purple.opacity(0.8), Color.blue.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(16)
                            .shadow(color: Color.purple.opacity(0.3), radius: 20, x: 0, y: 10)
                        }
                        .padding(.horizontal, 24)
                        .scaleEffect(animateButton ? 1.0 : 0.9)
                        .opacity(animateButton ? 1.0 : 0.0)
                    }
                    .padding(.vertical, 32)
                    
                    Spacer(minLength: 20)
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                animateContent = true
            }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.6)) {
                animateButton = true
            }
        }
    }
}

// MARK: - Step Row Component (Legacy)
struct StepRowLegacy: View {
    let step: Int
    let icon: String
    let title: String
    let description: String
    let delay: Double
    @State private var isVisible = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Step number badge
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.purple.opacity(0.8), Color.blue.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 32, height: 32)
                
                Text("\(step)")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            
            // Icon container
            ZStack {
                Circle()
                    .fill(Color.purple.opacity(0.15))
                    .frame(width: 56, height: 56)
                
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.purple)
                    .rotationEffect(.degrees(isVisible ? 0 : -10))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(uiColor: .secondarySystemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
        .scaleEffect(isVisible ? 1.0 : 0.8)
        .opacity(isVisible ? 1.0 : 0.0)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(delay)) {
                isVisible = true
            }
        }
    }
}

// MARK: - Tip Row Component (Legacy)
struct TipRowLegacy: View {
    let text: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 12))
                .foregroundColor(.green)
            
            Text(text)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.secondary)
            
            Spacer()
        }
    }
}

// MARK: - Preview
@available(iOS 17.0, *)
#Preview {
    NearbyShareIntroView()
}
