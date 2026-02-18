import SwiftUI
import NimbleViews

// MARK: - Nearby Transfer View
struct NearbyTransferView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NBList(.localized("Nearby Transfer")) {
            // Header Section
            Section {
                ZStack {
                    LinearGradient(
                        colors: [Color.indigo.opacity(0.15), Color.purple.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .cornerRadius(22)
                    
                    VStack(spacing: 16) {
                        Image(systemName: "antenna.radiowaves.left.and.right")
                            .font(.system(size: 54))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.indigo, .purple, .blue],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .ifAvailableiOS18SymbolPulse()
                        
                        VStack(spacing: 8) {
                            Text(.localized("Wireless Transfer"))
                                .font(.system(.title2, design: .rounded, weight: .bold))

                            Text(.localized("Move your backups between devices instantly using a secure, direct connection."))
                                .font(.system(.subheadline, design: .rounded))
                                .multilineTextAlignment(.center)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 20)
                        }
                    }
                    .padding(.vertical, 40)
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
            }
            
            // Quick Start Section
            Section {
                NavigationLink(destination: PairingView()) {
                    HStack(spacing: 18) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [.blue.opacity(0.2), .blue.opacity(0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 56, height: 56)
                            
                            Image(systemName: "bolt.fill")
                                .font(.title2)
                                .foregroundStyle(.blue)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(.localized("Start New Transfer"))
                                .font(.system(.headline, design: .rounded))
                            Text(.localized("Send or receive a backup securely."))
                                .font(.system(.caption, design: .rounded))
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 10)
                }
            } header: {
                AppearanceSectionHeader(title: String.localized("Actions"), icon: "play.fill")
            }
            
            // How It Works Section
            Section {
                featureCard(
                    icon: "lock.shield.fill",
                    iconColor: .green,
                    title: .localized("End-to-End Security"),
                    description: .localized("All transfers are encrypted and happen directly between your devices. Your data never leaves your local network.")
                )
                
                featureCard(
                    icon: "wifi.router.fill",
                    iconColor: .blue,
                    title: .localized("Direct Connection"),
                    description: .localized("Uses Multipeer Connectivity to establish a fast, direct link via Wi-Fi or Bluetooth without needing the internet.")
                )
                
                featureCard(
                    icon: "speedometer",
                    iconColor: .orange,
                    title: .localized("Lightning Fast"),
                    description: .localized("High-speed data transfer with real-time progress monitoring, speed reporting, and automatic error recovery.")
                )
            } header: {
                AppearanceSectionHeader(title: String.localized("Why Nearby Transfer?"), icon: "sparkles")
            }
            
            // Requirements Section
            Section {
                requirementRow(
                    icon: "network",
                    text: .localized("Same Network: Both devices must be on the same Wi-Fi or within Bluetooth range.")
                )
                
                requirementRow(
                    icon: "iphone.gen2",
                    text: .localized("App Version: Both devices should have the latest Portal version for best compatibility.")
                )
                
                requirementRow(
                    icon: "battery.100.bolt",
                    text: .localized("Power: Ensure sufficient battery or connect to power for large backup transfers.")
                )
            } header: {
                AppearanceSectionHeader(title: String.localized("Requirements"), icon: "checklist")
            }
            
            // About Section
            Section {
                VStack(alignment: .leading, spacing: 16) {
                    Text(.localized("Supported Data Types"))
                        .font(.system(.headline, design: .rounded))
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        transferItemRow(icon: "checkmark.seal.fill", text: .localized("Certificates"), color: .blue)
                        transferItemRow(icon: "app.badge.fill", text: .localized("Signed Apps"), color: .green)
                        transferItemRow(icon: "square.and.arrow.down.fill", text: .localized("Imported"), color: .orange)
                        transferItemRow(icon: "globe.fill", text: .localized("Sources"), color: .purple)
                        transferItemRow(icon: "puzzlepiece.extension.fill", text: .localized("Frameworks"), color: .cyan)
                        transferItemRow(icon: "gearshape.fill", text: .localized("Settings"), color: .gray)
                    }
                }
                .padding(.vertical, 12)
            } header: {
                AppearanceSectionHeader(title: String.localized("Details"), icon: "info.circle.fill")
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Helper Views
    
    @ViewBuilder
    private func featureCard(icon: String, iconColor: Color, title: LocalizedStringKey, description: LocalizedStringKey) -> some View {
        HStack(alignment: .top, spacing: 18) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(iconColor.opacity(0.12))
                    .frame(width: 48, height: 48)
                
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(iconColor)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(.primary)
                
                Text(description)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(2)
            }
        }
        .padding(.vertical, 8)
    }
    
    @ViewBuilder
    private func requirementRow(icon: String, text: LocalizedStringKey) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .foregroundStyle(.blue)
                .font(.system(size: 18))
                .frame(width: 24)
                .padding(.top, 2)
            
            Text(text)
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 6)
    }
    
    @ViewBuilder
    private func transferItemRow(icon: String, text: LocalizedStringKey, color: Color) -> some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 28, height: 28)

                Image(systemName: icon)
                    .foregroundStyle(color)
                    .font(.system(size: 12, weight: .bold))
            }
            
            Text(text)
                .font(.system(.caption, design: .rounded, weight: .medium))
                .foregroundStyle(.primary.opacity(0.8))

            Spacer()
        }
        .padding(8)
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(12)
    }
}
