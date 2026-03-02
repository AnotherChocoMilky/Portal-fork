
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
            Color.black.opacity(0.45)
                .ignoresSafeArea()

            VStack {
                Spacer()
                    .frame(minHeight: 0, maxHeight: .infinity)

                _card()

                Spacer()
                    .frame(minHeight: 0, idealHeight: 80, maxHeight: .infinity)
            }
        }
        .onAppear {
            _isPulsing = true
            _loadIconColors()
        }
    }

    @ViewBuilder
    private func _card() -> some View {
        VStack(spacing: 16) {
            _appIcon()
                .scaleEffect(_isPulsing ? 1.02 : 1.0)
                .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: _isPulsing)

            VStack(spacing: 10) {
                Text(app.name ?? "App")
                    .font(.headline)
                    .bold()
                    .multilineTextAlignment(.center)
                    .foregroundColor(colorManager.primaryColor.adaptiveForeground)

                _progressBar()
                    .padding(.horizontal, 4)

                Text(viewModel.statusLabel)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .kerning(-0.2)
                    .foregroundColor(colorManager.primaryColor.adaptiveForeground.opacity(0.7))
                    .multilineTextAlignment(.center)
            }

            footer()
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 24)
        .background(_cardBackground())
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: .black.opacity(0.25), radius: 24, x: 0, y: 8)
        .padding(.horizontal, 40)
    }

    @ViewBuilder
    private func _cardBackground() -> some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    colorManager.primaryColor,
                    colorManager.secondaryColor
                ]),
                startPoint: .top,
                endPoint: .bottom
            )

            RadialGradient(
                gradient: Gradient(colors: [colorManager.primaryColor.opacity(0.6), .clear]),
                center: UnitPoint(x: 0.5, y: 0.3),
                startRadius: 0,
                endRadius: 200
            )

            Rectangle()
                .fill(.ultraThinMaterial)
        }
    }

    @ViewBuilder
    private func _progressBar() -> some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(colorManager.primaryColor.adaptiveForeground.opacity(0.2))
                    .frame(height: 4)

                RoundedRectangle(cornerRadius: 4)
                    .fill(colorManager.primaryColor)
                    .frame(width: geometry.size.width * CGFloat(viewModel.overallProgress), height: 4)
                    .animation(.smooth, value: viewModel.overallProgress)
            }
        }
        .frame(height: 4)
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
            .frame(width: 72, height: 72)
            .shadow(color: colorManager.primaryColor.opacity(0.6), radius: 12, x: 0, y: 6)
            .overlay {
                RoundedRectangle(cornerRadius: 72 * 0.2237)
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
