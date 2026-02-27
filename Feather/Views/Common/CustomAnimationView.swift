import SwiftUI

struct CustomAnimationView: View {
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            // Full-screen background
            Color(UIColor.systemBackground)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Central Animation Area
                ZStack {
                    // 1. Large background shape
                    Circle()
                        .fill(Color.accentColor.opacity(0.15))
                        .frame(width: 240, height: 240)
                        .scaleEffect(isAnimating ? 1.0 : 0.6)
                        .opacity(isAnimating ? 1.0 : 0.0)
                        .animation(.spring(response: 0.9, dampingFraction: 0.7).delay(0.1), value: isAnimating)

                    // 2. Decorative shapes (staggered)
                    // Top Left
                    Circle()
                        .fill(Color.accentColor.opacity(0.3))
                        .frame(width: 24, height: 24)
                        .offset(x: isAnimating ? -110 : -160, y: isAnimating ? -90 : -140)
                        .opacity(isAnimating ? 1 : 0)
                        .scaleEffect(isAnimating ? 1 : 0.2)
                        .animation(.spring(response: 0.7, dampingFraction: 0.6).delay(0.4), value: isAnimating)

                    // Top Right
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.blue.opacity(0.3))
                        .frame(width: 20, height: 20)
                        .rotationEffect(.degrees(isAnimating ? 45 : 0))
                        .offset(x: isAnimating ? 100 : 150, y: isAnimating ? -70 : -120)
                        .opacity(isAnimating ? 1 : 0)
                        .scaleEffect(isAnimating ? 1 : 0.2)
                        .animation(.spring(response: 0.7, dampingFraction: 0.6).delay(0.5), value: isAnimating)

                    // Bottom Right
                    Circle()
                        .fill(Color.purple.opacity(0.3))
                        .frame(width: 32, height: 32)
                        .offset(x: isAnimating ? 90 : 140, y: isAnimating ? 100 : 150)
                        .opacity(isAnimating ? 1 : 0)
                        .scaleEffect(isAnimating ? 1 : 0.2)
                        .animation(.spring(response: 0.7, dampingFraction: 0.6).delay(0.6), value: isAnimating)

                    // Bottom Left
                    Circle()
                        .fill(Color.orange.opacity(0.3))
                        .frame(width: 18, height: 18)
                        .offset(x: isAnimating ? -90 : -140, y: isAnimating ? 80 : 130)
                        .opacity(isAnimating ? 1 : 0)
                        .scaleEffect(isAnimating ? 1 : 0.2)
                        .animation(.spring(response: 0.7, dampingFraction: 0.6).delay(0.7), value: isAnimating)

                    // 3. Central SF Symbol Icon
                    Image(systemName: "bell.badge.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 110, height: 110)
                        .foregroundStyle(Color.accentColor)
                        .symbolRenderingMode(.hierarchical)
                        .scaleEffect(isAnimating ? 1.0 : 0.01)
                        .rotationEffect(.degrees(isAnimating ? 0 : -25))
                        .opacity(isAnimating ? 1.0 : 0.0)
                        .animation(.spring(response: 0.6, dampingFraction: 0.5).delay(0.3), value: isAnimating)
                }
                .padding(.bottom, 60)

                // 4. Headline Text
                Text("Enable Notifications")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .opacity(isAnimating ? 1.0 : 0.0)
                    .offset(y: isAnimating ? 0 : 20)
                    .animation(.easeOut(duration: 0.7).delay(0.8), value: isAnimating)
                    .padding(.horizontal, 24)

                // 5. Subtitle Text
                Text("Get notified when your apps are ready to be installed or when updates are available.")
                    .font(.system(size: 17, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 12)
                    .padding(.horizontal, 40)
                    .opacity(isAnimating ? 1.0 : 0.0)
                    .offset(y: isAnimating ? 0 : 10)
                    .animation(.easeOut(duration: 0.8).delay(1.0), value: isAnimating)

                Spacer()

                // Action Buttons
                VStack(spacing: 16) {
                    Button(action: {
                        // Action for granting permission
                    }) {
                        Text("Allow Access")
                            .font(.system(size: 19, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.accentColor)
                                    .shadow(color: Color.accentColor.opacity(0.3), radius: 10, x: 0, y: 5)
                            )
                    }
                    .padding(.horizontal, 32)
                    .scaleEffect(isAnimating ? 1.0 : 0.9)
                    .opacity(isAnimating ? 1.0 : 0.0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(1.2), value: isAnimating)

                    Button(action: {
                        // Action for skipping
                    }) {
                        Text("Maybe Later")
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                    .opacity(isAnimating ? 1.0 : 0.0)
                    .animation(.easeOut(duration: 0.6).delay(1.4), value: isAnimating)
                }
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            // Trigger animation sequence
            isAnimating = true
        }
    }
}

#Preview {
    CustomAnimationView()
}
