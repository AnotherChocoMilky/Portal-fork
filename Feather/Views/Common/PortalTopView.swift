import SwiftUI

struct PortalTopView: View {
    var body: some View {
        GeometryReader { geometry in
            let safeAreaTop = geometry.safeAreaInsets.top

            VStack(spacing: 0) {
                ZStack(alignment: .bottom) {
                    // Glass style interface
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .frame(height: max(safeAreaTop, 44) + 10)
                        .mask(
                            VStack(spacing: 0) {
                                Color.black
                                LinearGradient(colors: [.black, .clear], startPoint: .top, endPoint: .bottom)
                                    .frame(height: 10)
                            }
                        )
                        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)

                    // Portal Title
                    HStack {
                        Text("Portal")
                            .font(.system(size: 14, weight: .black, design: .rounded))
                            .kerning(1.0)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.accentColor, Color.accentColor.opacity(0.7)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .padding(.bottom, 8)
                            .shadow(color: Color.accentColor.opacity(0.2), radius: 4, x: 0, y: 2)
                    }
                }
                .ignoresSafeArea()

                Spacer()
            }
        }
        .allowsHitTesting(false)
        .zIndex(1000)
    }
}
