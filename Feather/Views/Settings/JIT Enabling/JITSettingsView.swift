//
//  JITSettingsView.swift
//  Feather
//

import SwiftUI
import NimbleViews
import IDeviceSwift
import OSLog

// MARK: - JITSettingsView

/// Main JIT configuration interface.
/// Allows pairing file import, shows pairing/VPN status, and triggers JIT enabling.
struct JITSettingsView: View {

    @StateObject private var manager = JITManager.shared
    @AppStorage("Feather.showHeaderViews") private var showHeaderViews = true

    @State private var isPairingPresented = false
    @State private var isAppSelectionPresented = false
    @State private var selectedBundleID: String = ""
    @State private var vpnAvailable = false
    @State private var hasPairing = false
    @State private var showStatusSheet = false

    // MARK: - Body

    var body: some View {
        List {
            statusSection
            pairingSection
            vpnSection
            fallbackSection
            enableSection
            helpSection
        }
        .scrollContentBackground(.hidden)
        .listStyle(.insetGrouped)
        .navigationTitle(String.localized("JIT Enabling"))
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isPairingPresented) {
            FileImporterRepresentableView(
                allowedContentTypes: [.xmlPropertyList, .plist, .mobiledevicepairing],
                onDocumentsPicked: { urls in
                    guard let url = urls.first else { return }
                    FR.movePairing(url)
                    hasPairing = PairingManager.shared.hasPairingFile
                }
            )
            .ignoresSafeArea()
        }
        .sheet(isPresented: $isAppSelectionPresented) {
            JITAppSelectionView { bundleID in
                selectedBundleID = bundleID
                Task { await enableJIT(for: bundleID) }
            }
        }
        .sheet(isPresented: $showStatusSheet) {
            jitStatusSheet
        }
        .onAppear {
            refreshStatus()
        }
    }

    // MARK: - Sections

    private var statusSection: some View {
        Section {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(statusColor.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: statusIcon)
                        .font(.system(size: 22))
                        .foregroundStyle(statusColor)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(manager.state.displayTitle)
                        .font(.system(size: 16, weight: .semibold))
                    if case .failed(let error) = manager.state {
                        Text(error.localizedDescription)
                            .font(.caption)
                            .foregroundStyle(.red)
                    } else {
                        Text(statusSubtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                if manager.state.isInProgress {
                    ProgressView()
                }
            }
            .padding(.vertical, 4)
        } header: {
            SettingsSectionHeader(title: String.localized("Status"), icon: "info.circle.fill")
        }
    }

    private var pairingSection: some View {
        Section {
            Button {
                isPairingPresented = true
            } label: {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.15))
                            .frame(width: 36, height: 36)
                        Image(systemName: "square.and.arrow.down")
                            .font(.system(size: 16))
                            .foregroundStyle(.blue)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(String.localized("Import Pairing File"))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)
                        Text(String.localized("Required for device connection"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: hasPairing ? "checkmark.circle.fill" : "chevron.right")
                        .font(hasPairing ? .system(size: 18) : .caption)
                        .foregroundStyle(hasPairing ? .green : .secondary)
                }
                .padding(.vertical, 2)
            }
        } header: {
            SettingsSectionHeader(title: String.localized("Pairing"), icon: "person.badge.key.fill")
        } footer: {
            if hasPairing {
                Text(String.localized("Pairing file loaded and validated."))
                    .foregroundStyle(.green)
            } else {
                Text(String.localized("No pairing file found. Import one to continue."))
                    .foregroundStyle(.orange)
            }
        }
    }

    private var vpnSection: some View {
        Section {
            if vpnAvailable {
                Button {
                    UIApplication.open("localdevvpn://enable?scheme=feather")
                } label: {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.green.opacity(0.15))
                                .frame(width: 36, height: 36)
                            Image(systemName: "link")
                                .font(.system(size: 16))
                                .foregroundStyle(.green)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(String.localized("Connect to LocalDevVPN"))
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.primary)
                            Text(String.localized("Enable loopback VPN"))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.vertical, 2)
                }
            } else {
                Button {
                    UIApplication.open("https://apps.apple.com/us/app/localdevvpn/id6755608044")
                } label: {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.orange.opacity(0.15))
                                .frame(width: 36, height: 36)
                            Image(systemName: "arrow.down.app")
                                .font(.system(size: 16))
                                .foregroundStyle(.orange)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(String.localized("Download LocalDevVPN"))
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.primary)
                            Text(String.localized("Required for loopback routing"))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.vertical, 2)
                }
            }
        } header: {
            SettingsSectionHeader(title: String.localized("VPN"), icon: "network")
        } footer: {
            Text(String.localized("A loopback VPN is required for debugserver communication over localhost."))
        }
    }

    private var fallbackSection: some View {
        Section {
            ForEach(Array(JITFallbackRegistry.availableStrategies.enumerated()), id: \.offset) { _, strategy in
                Button {
                    manager.selectedFallbackStrategyIdentifier = strategy.identifier
                } label: {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.indigo.opacity(0.15))
                                .frame(width: 36, height: 36)
                            Image(systemName: "arrow.uturn.backward.circle")
                                .font(.system(size: 16))
                                .foregroundStyle(.indigo)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(String.localized(strategy.displayName))
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.primary)
                            Text(String.localized(strategy.strategyDescription))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if manager.selectedFallbackStrategyIdentifier == strategy.identifier {
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.accentColor)
                        }
                    }
                    .padding(.vertical, 2)
                }
                .foregroundStyle(.primary)
            }
        } header: {
            SettingsSectionHeader(title: String.localized("Fallback Method"), icon: "arrow.uturn.backward.circle.fill")
        } footer: {
            Text(String.localized("The fallback method is invoked automatically when a recoverable error occurs during JIT enabling."))
        }
    }

    private var enableSection: some View {
        Section {
            Button {
                isAppSelectionPresented = true
            } label: {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.accentColor.opacity(0.15))
                            .frame(width: 36, height: 36)
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(Color.accentColor)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(String.localized("Enable JIT for App"))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)
                        Text(selectedBundleID.isEmpty
                             ? String.localized("Select an installed app")
                             : selectedBundleID)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .padding(.vertical, 2)
            }
            .disabled(manager.state.isInProgress)

            if manager.state == .jitEnabled {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text(String.localized("JIT enabled successfully!"))
                        .font(.subheadline)
                        .foregroundStyle(.green)
                }
            }
        } header: {
            SettingsSectionHeader(title: String.localized("Actions"), icon: "bolt.circle.fill")
        }
    }

    private var helpSection: some View {
        Section {
            Button {
                UIApplication.open("https://github.com/StephenDev0/StikDebug-Guide/blob/main/pairing_file.md")
            } label: {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.purple.opacity(0.15))
                            .frame(width: 36, height: 36)
                        Image(systemName: "questionmark.circle")
                            .font(.system(size: 16))
                            .foregroundStyle(.purple)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(String.localized("Pairing File Guide"))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)
                        Text(String.localized("Learn how to get a pairing file"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .padding(.vertical, 2)
            }
        } header: {
            SettingsSectionHeader(title: String.localized("Help"), icon: "books.vertical.fill")
        }
    }

    // MARK: - Status sheet

    private var jitStatusSheet: some View {
        NavigationStack {
            List {
                Section {
                    JITStatusView(manager: manager)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }
                if case .failed(let error) = manager.state {
                    Section {
                        Text(error.localizedDescription)
                            .font(.subheadline)
                            .foregroundStyle(.red)
                    } header: {
                        SettingsSectionHeader(title: String.localized("Error Detail"), icon: "exclamationmark.triangle.fill")
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .navigationTitle(String.localized("JIT Status"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(String.localized("Done")) { showStatusSheet = false }
                }
            }
        }
    }

    // MARK: - Computed helpers

    private var statusIcon: String {
        switch manager.state {
        case .idle:                  return "circle.dashed"
        case .validatingPairing:     return "doc.badge.gearshape"
        case .checkingVPN:           return "network"
        case .connectingLockdown:    return "lock.shield"
        case .connectingDebugServer: return "ant.circle"
        case .jitEnabled:            return "bolt.circle.fill"
        case .failed:                return "exclamationmark.triangle.fill"
        }
    }

    private var statusColor: Color {
        switch manager.state {
        case .idle:                  return .secondary
        case .jitEnabled:            return .green
        case .failed:                return .red
        default:                     return .accentColor
        }
    }

    private var statusSubtitle: String {
        switch manager.state {
        case .idle:                  return String.localized("Import a pairing file and enable VPN to begin")
        case .validatingPairing:     return String.localized("Reading pairing record...")
        case .checkingVPN:           return String.localized("Verifying loopback connectivity...")
        case .connectingLockdown:    return String.localized("Authenticating with device...")
        case .connectingDebugServer: return String.localized("Attaching to process...")
        case .jitEnabled:            return String.localized("The selected app now has JIT enabled")
        case .failed:                return String.localized("See error detail below")
        }
    }

    // MARK: - Actions

    private func enableJIT(for bundleID: String) async {
        showStatusSheet = true
        do {
            try await manager.enableJIT(for: bundleID)
        } catch {
            Logger.jit.error("Failed to enable JIT: \(error.localizedDescription)")
        }
    }

    private func refreshStatus() {
        hasPairing = PairingManager.shared.hasPairingFile
        if let url = URL(string: "localdevvpn://") {
            vpnAvailable = UIApplication.shared.canOpenURL(url)
        }
    }
}
