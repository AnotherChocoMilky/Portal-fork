import SwiftUI
import NimbleViews

struct GeneralView: View {
    @StateObject private var hideManager = SettingsHideManager.shared
    @AppStorage("Feather.certificateExperience") private var certificateExperience: String = CertificateExperience.developer.rawValue
    @AppStorage("Feather.showHeaderViews") private var showHeaderViews = true
    @State private var navigateToCheckForUpdates = false
    @Environment(\.navigateToUpdates) private var navigateToUpdates

    private var isEnterprise: Bool { certificateExperience == CertificateExperience.enterprise.rawValue }

    var body: some View {
        List {
            headerSection

            signingSection

            dataSection

            systemSection

            resourcesSection
        }
        .onChange(of: navigateToUpdates.wrappedValue) { shouldNavigate in
            if shouldNavigate {
                navigateToCheckForUpdates = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    navigateToUpdates.wrappedValue = false
                }
            }
        }
        .scrollContentBackground(.hidden)
        .listStyle(.insetGrouped)
        .navigationTitle(.localized("General"))
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Sections

    private var headerSection: some View {
        Group {
            if showHeaderViews {
                Section {
                    GeneralHeaderView()
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }
            }
        }
    }

    private var signingSection: some View {
        Section {
            if !hideManager.isHidden("settings.liveActivities") {
                SettingsRow(icon: "widget.small.badge.plus", title: String.localized("Live Activities"), color: .accentColor, destination: LiveActivitySettingsView())
            }
            if !hideManager.isHidden("settings.certificates") {
                SettingsRow(icon: "person.badge.key.fill", title: String.localized("Certificates"), color: .accentColor, destination: CertificatesView())
            }
            if !hideManager.isHidden("settings.signing") {
                SettingsRow(icon: "signature", title: String.localized("Signing"), color: .accentColor, destination: ConfigurationView())
            }
        } header: {
            SettingsSectionHeader(title: String.localized("Signing & Services"), icon: "shield.lefthalf.filled.badge.checkmark")
        }
    }

    private var dataSection: some View {
        Section {
            if !isEnterprise && !hideManager.isHidden("settings.storage") {
                SettingsRow(icon: "externaldrive.fill.badge.person.crop", title: String.localized("Storage"), color: .accentColor, destination: ManageStorageView())
            }
            if !hideManager.isHidden("settings.backupRestore") {
                SettingsRow(icon: "externaldrive.fill.badge.timemachine", title: String.localized("Backup & Restore"), color: .accentColor, destination: BackupRestoreView())
            }
            if !hideManager.isHidden("settings.logs") {
                SettingsRow(icon: "ecg.text.page", title: String.localized("Logs"), color: .accentColor, destination: AppLogsView())
            }
        } header: {
            SettingsSectionHeader(title: String.localized("Data & Maintenance"), icon: "externaldrive.fill")
        }
    }

    private var systemSection: some View {
        Section {
            if !hideManager.isHidden("settings.language") {
                Button {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    SettingsRowContent(icon: "translate", title: String.localized("Language"), color: .accentColor)
                }
            }
            if !isEnterprise && !hideManager.isHidden("settings.updates") {
                Button {
                    navigateToCheckForUpdates = true
                } label: {
                    SettingsRowContent(icon: "arrow.triangle.2.circlepath", title: String.localized("Check For Updates"), color: .accentColor)
                }
                .simultaneousGesture(
                    LongPressGesture(minimumDuration: 2.0)
                        .onEnded { _ in
                            ToastManager.shared.show("🚀 Turbo Updates Enabled! (Just kidding)", type: .info)
                            HapticsManager.shared.success()
                        }
                )
                .navigationDestination(isPresented: $navigateToCheckForUpdates) {
                    CheckForUpdatesView()
                }
            }
        } header: {
            SettingsSectionHeader(title: String.localized("System"), icon: "iphone")
        }
    }

    private var resourcesSection: some View {
        Section {
            if !hideManager.isHidden("settings.credits") {
                SettingsRow(icon: "person.crop.circle.fill.badge.checkmark", title: String.localized("Credits"), color: .accentColor, destination: CreditsView())
            }
            if !hideManager.isHidden("settings.feedback") {
                SettingsRow(icon: "bubble.left.and.bubble.right.fill", title: String.localized("Feedback"), color: .accentColor, destination: FeedbackView())
            }
        } header: {
            SettingsSectionHeader(title: String.localized("Resources"), icon: "books.vertical.fill")
        }
    }
}

#Preview {
    GeneralView()
}
