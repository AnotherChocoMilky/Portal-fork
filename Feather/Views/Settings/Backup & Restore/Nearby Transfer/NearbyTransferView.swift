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
                        colors: [Color.purple.opacity(0.1), Color.blue.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .cornerRadius(20)
                    
                    VStack(spacing: 12) {
                        Image(systemName: "antenna.radiowaves.left.and.right")
                            .font(.system(size: 40))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.purple, .blue],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        Text(.localized("Transfer backups wirelessly between devices using Nearby Transfer."))
                            .font(.system(.subheadline, design: .rounded))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal)
                    }
                    .padding(.vertical, 30)
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            }
            
            // Quick Start Section
            Section {
                NavigationLink(destination: PairingView()) {
                    HStack(spacing: 16) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color.blue.opacity(0.15))
                                .frame(width: 50, height: 50)
                            
                            Image(systemName: "arrow.left.arrow.right.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.blue)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(.localized("Start Transfer"))
                                .font(.headline)
                            Text(.localized("Send or receive a backup."))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
            } header: {
                AppearanceSectionHeader(title: String.localized("Quick Start"), icon: "bolt.fill")
            }
            
            // How It Works Section
            Section {
                featureCard(
                    icon: "lock.shield.fill",
                    iconColor: .green,
                    title: .localized("Secure & Encrypted"),
                    description: .localized("All transfers are fully private and never shared with anyone and run fully on both senders and receivers devices and in your network.")
                )
                
                featureCard(
                    icon: "wifi",
                    iconColor: .blue,
                    title: .localized("No Internet Required"),
                    description: .localized("Transfer happens directly between devices using local Wi-Fi or Bluetooth.")
                )
                
                featureCard(
                    icon: "speedometer",
                    iconColor: .orange,
                    title: .localized("Fast & Reliable"),
                    description: .localized("Direct device to device transfer with real time progress monitoring and speed reporting using Apple's Multipeer Connectivity framework.")
                )
            } header: {
                AppearanceSectionHeader(title: String.localized("Features"), icon: "star.fill")
            }
            
            // Requirements Section
            Section {
                requirementRow(
                    icon: "network",
                    text: "Both devices must be on the same Wi-Fi network or within Bluetooth range."
                )
                
                requirementRow(
                    icon: "iphone.gen2",
                    text: "Both devices must have the latest version of Portal installed. If not, it can cause compatibility issues."
                )
                
                requirementRow(
                    icon: "battery.100",
                    text: "Recommended to have sufficient battery or connect to power since both devices will be actively transferring data."
                )
            } header: {
                AppearanceSectionHeader(title: String.localized("Requirements"), icon: "checkmark.circle.fill")
            }
            
            // About Section
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text(.localized("What Gets Transferred?"))
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        transferItemRow(icon: "checkmark.seal.fill", text: "Certificates & Profiles", color: .blue)
                        transferItemRow(icon: "app.badge.fill", text: "Signed Apps", color: .green)
                        transferItemRow(icon: "square.and.arrow.down.fill", text: "Imported Apps", color: .orange)
                        transferItemRow(icon: "globe.fill", text: "Sources", color: .purple)
                        transferItemRow(icon: "puzzlepiece.extension.fill", text: "Default Frameworks", color: .cyan)
                        transferItemRow(icon: "archivebox.fill", text: "Archives", color: .indigo)
                        transferItemRow(icon: "gearshape.fill", text: "Settings", color: .gray)
                    }
                }
                .padding(.vertical, 8)
            } header: {
                AppearanceSectionHeader(title: String.localized("About"), icon: "info.circle.fill")
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Helper Views
    
    @ViewBuilder
    private func featureCard(icon: String, iconColor: Color, title: LocalizedStringKey, description: LocalizedStringKey) -> some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(iconColor)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(.primary)
                
                Text(description)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 4)
    }
    
    @ViewBuilder
    private func requirementRow(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.blue)
                .font(.body)
                .frame(width: 24)
            
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 4)
    }
    
    @ViewBuilder
    private func transferItemRow(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .font(.caption)
                .frame(width: 20)
            
            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
