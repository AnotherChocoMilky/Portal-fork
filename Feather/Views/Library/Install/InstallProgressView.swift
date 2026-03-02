
import SwiftUI
import IDeviceSwift

struct InstallProgressView<Footer: View>: View {
    @State private var _isPulsing = false
    @ObservedObject var colorManager = AppIconColorManager.shared

    var app: AppInfoPresentable
    @ObservedObject var viewModel: InstallerStatusViewModel
    let footer: () -> Footer

    init(
        app: AppInfoPresentable,
        viewModel: InstallerStatusViewModel,
        @ViewBuilder footer: @escaping () -> Footer = { EmptyView() }
    ) {
        self.app = app
        self.viewModel = viewModel
        self.footer = footer
    }

    var body: some View {
        ZStack {
            _background()

            VStack(spacing: 0) {
                Spacer()

                _appIcon()
                    .scaleEffect(_isPulsing ? 1.02 : 1.0)
                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: _isPulsing)
                    .padding(.bottom, 32)

                VStack(spacing: 16) {
                    VStack(spacing: 12) {
                        Text(app.name ?? "App")
                            .font(.title)
                            .bold()
                            .multilineTextAlignment(.center)
                            .foregroundColor(colorManager.primaryColor.adaptiveForeground)

                        _progressBar()
                    }

                    Text(viewModel.statusLabel)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .kerning(-0.2)
                        .foregroundColor(colorManager.primaryColor.adaptiveForeground.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 40)

                Spacer()

                footer()
                    .padding(.bottom, 32)

                Spacer()
            }
        }
        .onAppear {
            _isPulsing = true
            _loadIconColors()
        }
    }

    @ViewBuilder
    private func _background() -> some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    colorManager.primaryColor,
                    colorManager.secondaryColor
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            RadialGradient(
                gradient: Gradient(colors: [colorManager.primaryColor.opacity(0.6), .clear]),
                center: UnitPoint(x: 0.5, y: 0.38),
                startRadius: 0,
                endRadius: 300
            )
            .ignoresSafeArea()

            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
        }
    }

    @ViewBuilder
    private func _progressBar() -> some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(colorManager.primaryColor.adaptiveForeground.opacity(0.2))
                    .frame(height: 6)

                RoundedRectangle(cornerRadius: 4)
                    .fill(colorManager.primaryColor)
                    .frame(width: geometry.size.width * CGFloat(viewModel.overallProgress), height: 6)
                    .animation(.smooth, value: viewModel.overallProgress)
            }
        }
        .frame(height: 6)
    }

    private func _loadIconColors() {
        if let iconPath = Storage.shared.getAppIconFile(for: app),
           let image = UIImage(contentsOfFile: iconPath.path) {
            colorManager.extractColors(from: image, for: app.identifier)
        }
    }

    @ViewBuilder
    private func _appIcon() -> some View {
        FRAppIconView(app: app)
            .frame(width: 100, height: 100)
            .shadow(color: colorManager.primaryColor.opacity(0.6), radius: 16, x: 0, y: 8)
            .overlay {
                RoundedRectangle(cornerRadius: 100 * 0.2237)
                    .stroke(colorManager.primaryColor.opacity(0.3), lineWidth: 1)
            }
    }

    struct PieShape: Shape {
        var progress: Double

        func path(in rect: CGRect) -> Path {
            var path = Path()
            let center = CGPoint(x: rect.midX, y: rect.midY)
            let radius = min(rect.width, rect.height) / 2
            let startAngle = Angle(degrees: -90)
            let endAngle = Angle(degrees: -90 + progress * 360)

            path.move(to: center)
            path.addArc(center: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
            path.closeSubpath()

            return path
        }

        var animatableData: Double {
            get { progress }
            set { progress = newValue }
        }
    }
}
