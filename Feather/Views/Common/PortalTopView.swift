import SwiftUI

struct PortalTopView: View {
    var body: some View {
        GeometryReader { geometry in
            let safeAreaTop = geometry.safeAreaInsets.top

            VStack(spacing: 0) {
                HStack {
                    Spacer()

                    // Floating Pill
                    Text("Portal")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.accentColor)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                        .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)

                    Spacer()
                }
                .frame(height: max(safeAreaTop, 20))

                Spacer()
            }
        }
        .allowsHitTesting(false)
        .zIndex(1000)
        .ignoresSafeArea(edges: .top)
    }
}
