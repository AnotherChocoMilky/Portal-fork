import SwiftUI

struct VariedTabbarView: View {
    @AppStorage("feature_experimentalUI") var experimentalUI = false
    @AppStorage("Feather.enableCustomTabBar") var enableCustomTabBar = false
    
    @State private var cornerSequence: [Int] = []

    var body: some View {
        ZStack {
            _mainTabContent

            // Invisible Corner Tap Buttons
            GeometryReader { geo in
                ZStack {
                    // Top Left (0)
                    cornerButton(index: 0, rect: CGRect(x: 0, y: 0, width: 50, height: 50))
                    // Top Right (1)
                    cornerButton(index: 1, rect: CGRect(x: geo.size.width - 50, y: 0, width: 50, height: 50))
                    // Bottom Right (2)
                    cornerButton(index: 2, rect: CGRect(x: geo.size.width - 50, y: geo.size.height - 100, width: 50, height: 50))
                    // Bottom Left (3)
                    cornerButton(index: 3, rect: CGRect(x: 0, y: geo.size.height - 100, width: 50, height: 50))
                }
            }
            .allowsHitTesting(true)
        }
    }

    @ViewBuilder
    private func cornerButton(index: Int, rect: CGRect) -> some View {
        Color.white.opacity(0.001)
            .frame(width: rect.width, height: rect.height)
            .position(x: rect.midX, y: rect.midY)
            .onTapGesture {
                handleCornerTap(index)
            }
    }

    private func handleCornerTap(_ index: Int) {
        cornerSequence.append(index)
        if cornerSequence.count > 4 {
            cornerSequence.removeFirst()
        }

        if cornerSequence == [0, 1, 2, 3] { // TL, TR, BR, BL
            EasterEggManager.shared.neonTheme.toggle()
            ToastManager.shared.show(EasterEggManager.shared.neonTheme ? "🌈 Neon Theme Activated!" : "🌑 Neon Theme Deactivated!", type: .success)
            HapticsManager.shared.success()
            cornerSequence.removeAll()
        }
    }

    @ViewBuilder
    private var _mainTabContent: some View {
        _tabGroup
            .simultaneousGesture(
                DragGesture(minimumDistance: 30)
                    .onEnded { value in
                        let horizontal = value.translation.width
                        let vertical = value.translation.height

                        if abs(horizontal) > abs(vertical) {
                            if horizontal > 0 {
                                EasterEggManager.shared.handleKonamiKey(.right)
                            } else {
                                EasterEggManager.shared.handleKonamiKey(.left)
                            }
                        } else {
                            if vertical > 0 {
                                EasterEggManager.shared.handleKonamiKey(.down)
                            } else {
                                EasterEggManager.shared.handleKonamiKey(.up)
                            }
                        }
                    }
            )
            .simultaneousGesture(
                TapGesture(count: 2)
                    .onEnded {
                        EasterEggManager.shared.handleKonamiKey(.b)
                    }
            )
            .simultaneousGesture(
                TapGesture(count: 3)
                    .onEnded {
                        EasterEggManager.shared.handleKonamiKey(.a)
                    }
            )
            .onAppear {
                // Konami code is hard to do with just swipes.
                // Let's also support it via a notification or similar.
            }
            .withEasterEggs()
    }

    @ViewBuilder
    private var _tabGroup: some View {
        if enableCustomTabBar {
            // Custom modern tab bar (Developer option)
            CustomTabBarUI()
        } else if experimentalUI {
            // Experimental UI
            ExperimentalTabbarView()
        } else {
            // Original UI
            if #available(iOS 18, *) {
                ExtendedTabbarView()
            } else {
                TabbarView()
            }
        }
    }
}
