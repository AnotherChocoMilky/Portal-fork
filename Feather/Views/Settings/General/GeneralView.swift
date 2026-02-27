import SwiftUI
import NimbleViews

struct GeneralView: View {
    @StateObject private var hideManager = SettingsHideManager.shared
    @AppStorage("Feather.certificateExperience") private var certificateExperience: String = CertificateExperience.developer.rawValue

    private var isEnterprise: Bool { certificateExperience == CertificateExperience.enterprise.rawValue }

    var body: some View {
        List {
            headerSection

            signingSection

            dataSection
        }
        .scrollContentBackground(.hidden)
        .listStyle(.insetGrouped)
        .navigationTitle(.localized("General"))
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Sections

    private var headerSection: some View {
        Section {
            GeneralHeaderView()
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
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
            if !hideManager.isHidden("settings.logs") {
                SettingsRow(icon: "ecg.text.page", title: String.localized("Logs"), color: .accentColor, destination: AppLogsView())
            }
        } header: {
            SettingsSectionHeader(title: String.localized("Data & Maintenance"), icon: "externaldrive.fill")
        }
    }
}

#Preview {
    GeneralView()
}
