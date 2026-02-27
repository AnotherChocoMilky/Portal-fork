import SwiftUI

struct ConfigurationHeaderView: View {
    // MARK: - Body
    var body: some View {
        headerCard
    }

    // MARK: - Header Card
    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Icon
            configurationIcon

            // Title
            Text(.localized("Configuration"))
                .font(.title2).bold()
                .foregroundStyle(Color.accentColor)

            HStack(spacing: 8) {
                // Info Row
                HStack(spacing: 6) {
                    Image(systemName: "signature")
                        .font(.system(size: 12))
                    Text(.localized("App Options"))
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                }
                .foregroundStyle(Color.accentColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.primary.opacity(0.05))
                .clipShape(Capsule())

                Text(.localized("Settings"))
                    .font(.system(size: 10, weight: .bold))
                    .kerning(1.0)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                    .foregroundStyle(Color.accentColor)
                    .overlay(
                        Capsule()
                            .stroke(Color.accentColor.opacity(0.2), lineWidth: 0.5)
                    )
            }

            Text(.localized("Customize signing parameters, entitlements, and advanced application behaviors."))
                .font(.subheadline)
                .foregroundStyle(Color.accentColor.opacity(0.7))
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(24)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 15, x: 0, y: 8)
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 0.5)
        )
    }

    @ViewBuilder
    private var configurationIcon: some View {
        ZStack {
            Color.accentColor.opacity(0.15)

            Image(systemName: "signature")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 35, height: 35)
                .foregroundColor(Color.accentColor)
        }
        .frame(width: 60, height: 60)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.white.opacity(0.15), lineWidth: 0.5)
        )
    }
}

#Preview {
    ConfigurationHeaderView()
        .padding()
}
