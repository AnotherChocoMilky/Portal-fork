import SwiftUI
import NimbleViews
import UIKit
import Darwin
import IDeviceSwift

// MARK: - Certificate Experience Type
enum CertificateExperience: String, CaseIterable {
    case developer = "Developer"
    case enterprise = "Enterprise"
    
    var displayName: String { rawValue }
}

// MARK: - Settings View
struct SettingsView: View {
    @State private var developerTapCount = 0
    @State private var lastTapTime: Date?
    @State private var _isFetchingFullData = false
    @State private var _showAddSource = false
    @State private var showDeveloperConfirmation = false
    @State private var navigateToCheckForUpdates = false
    @AppStorage("isDeveloperModeEnabled") private var isDeveloperModeEnabled = false
    @AppStorage("Feather.certificateExperience") private var certificateExperience: String = CertificateExperience.developer.rawValue
    @AppStorage("forceShowGuides") private var forceShowGuides = false
    @AppStorage("Feather.saveDataToDevice") private var saveDataToDevice = false
    @AppStorage("Feather.greetingsName") private var greetingsName: String = ""
    @AppStorage("Feather.tabBar.dashboard") private var showDashboard = true
    @StateObject private var hideManager = SettingsHideManager.shared
    @Environment(\.navigateToUpdates) private var navigateToUpdates
    
    private var isEnterprise: Bool { certificateExperience == CertificateExperience.enterprise.rawValue }
    
    var body: some View {
        NBNavigationView(.localized("Settings")) {
            List {
                headerSection
                fetchProgressSection
                generalSection
                preferencesSection
                dataSection
                saveDataSection
                resourcesSection
                if !isEnterprise { appSection }
                if isDeveloperModeEnabled { developerSection }
            }
            .scrollContentBackground(.hidden)
            .listStyle(.insetGrouped)
        }
        .fullScreenCover(isPresented: $_showAddSource) {
            SourcesAddView()
        }
        .alert(String.localized("Enable Developer Mode"), isPresented: $showDeveloperConfirmation) {
            Button(String.localized("Cancel"), role: .cancel) { developerTapCount = 0 }
            Button(String.localized("Enable")) {
                isDeveloperModeEnabled = true
                developerTapCount = 0
                HapticsManager.shared.success()
            }
        } message: {
            Text(String.localized("Developer Mode provides advanced debugging tools for app developers. This is NOT recommended for regular users as it may cause instability and crashes. Use at your own risk."))
        }
        .onChange(of: greetingsName) { newValue in
            if newValue == "42" {
                ToastManager.shared.show("🌌 The meaning of life, the universe, and everything.", type: .info)
                HapticsManager.shared.success()
            }
        }
        .onChange(of: navigateToUpdates.wrappedValue) { shouldNavigate in
            if shouldNavigate {
                navigateToCheckForUpdates = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    navigateToUpdates.wrappedValue = false
                }
            }
        }
    }
    
    // MARK: - Sections
    
    private var headerSection: some View {
        Section {
            CoreSignHeaderView(hideAboutButton: true)
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
        }
    }

    @ObservedObject private var sourcesViewModel = SourcesViewModel.shared
    @ObservedObject private var updateManager = AppUpdateTrackingManager.shared

    private var fetchProgressSection: some View {
        Group {
            if _isFetchingFullData {
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color.accentColor.opacity(0.1))
                                    .frame(width: 38, height: 38)

                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundStyle(Color.accentColor)
                                    .rotationEffect(.degrees(_isFetchingFullData ? 360 : 0))
                                    .animation(.linear(duration: 2).repeatForever(autoreverses: false), value: _isFetchingFullData)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Refreshing Sources")
                                    .font(.system(size: 16, weight: .bold, design: .rounded))

                                Text(sourcesViewModel.fetchProgress < 1.0 ? "Downloading Repository Data..." : "Finalizing Updates...")
                                    .font(.system(size: 12))
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Text("\(Int(sourcesViewModel.fetchProgress * 100))%")
                                .font(.system(size: 14, weight: .bold, design: .monospaced))
                                .foregroundStyle(Color.accentColor)
                        }

                        ProgressView(value: sourcesViewModel.fetchProgress)
                            .tint(Color.accentColor)
                            .scaleEffect(x: 1, y: 1.5, anchor: .center)
                            .clipShape(Capsule())

                        HStack {
                            Label("\(sourcesViewModel.sources.count) Loaded", systemImage: "tray.full.fill")
                            Spacer()
                            if sourcesViewModel.fetchProgress < 1.0 {
                                Text("Step \(Int(sourcesViewModel.fetchProgress * Double(_sources.count))) Of \(_sources.count)")
                            }
                        }
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 8)
                }
            }
        }
    }

    private var generalSection: some View {
        Section {
            SettingsRow(icon: "gearshape.fill", title: String.localized("General"), color: .accentColor, destination: GeneralView())
        }
    }

    private var preferencesSection: some View {
        Section {
            if showDashboard && !hideManager.isHidden("settings.home") {
                SettingsRow(icon: "house.fill", title: String.localized("Home"), color: .accentColor, destination: HomeSettingsView())
            }
            if !hideManager.isHidden("settings.appearance") {
                SettingsRow(icon: "gear.badge", title: String.localized("Display & Interface"), color: .accentColor, destination: AppearanceView())
            }

            if !hideManager.isHidden("settings.language") {
                Button {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    SettingsRowContent(icon: "translate", title: String.localized("Language"), color: .accentColor)
                }
            }
        } header: {
            SettingsSectionHeader(title: String.localized("Customizations"), icon: "slider.horizontal.3")
                .onLongPressGesture(minimumDuration: 2.0) {
                    ToastManager.shared.show("🤫 Hidden Credits: Portal was crafted with ❤️ by Dylan and the WSF Team.", type: .info)
                    HapticsManager.shared.success()
                }
        }
    }
    
    @FetchRequest(
        entity: AltSource.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \AltSource.order, ascending: true)]
    ) private var _sources: FetchedResults<AltSource>

    private var dataSection: some View {
        Section {
            if !hideManager.isHidden("settings.files") {
                SettingsRow(icon: "folder.fill", title: String.localized("Files"), color: .accentColor, destination: FilesSettingsView())
            }
            if !hideManager.isHidden("settings.addSource") {
                SettingsActionRow(icon: "binoculars.circle.fill", title: String.localized("Sources"), color: .accentColor) {
                    _showAddSource = true
                }
            }

            if !hideManager.isHidden("settings.backupRestore") {
                SettingsRow(icon: "externaldrive.fill.badge.timemachine", title: String.localized("Backup & Restore"), color: .accentColor, destination: BackupRestoreView())
            }

            if !hideManager.isHidden("settings.repoBuilder") {
                SettingsRow(icon: "list.star", title: String.localized("Repository Builder"), color: .accentColor, destination: RepoBuilder())
            }

            if !hideManager.isHidden("settings.fetchData") {
                SettingsActionRow(icon: "arrow.clockwise.circle.fill", title: _isFetchingFullData ? String.localized("Fetching Source Data...") : String.localized("Fetch Full Data"), color: .accentColor, isLoading: _isFetchingFullData) {
                    Task {
                        _isFetchingFullData = true
                        // Fetch both manager's data
                        await SourcesViewModel.shared.forceFetchAllSources(_sources)
                        await AppUpdateTrackingManager.shared.manualFetchAllSources()
                        _isFetchingFullData = false
                        HapticsManager.shared.success()
                    }
                }
            }
        } header: {
            SettingsSectionHeader(title: String.localized("App Management"), icon: "externaldrive.fill")
        }
    }
    
    private var saveDataSection: some View {
        Section {
            Toggle(isOn: $saveDataToDevice) {
                HStack(spacing: 8) {
                    SettingsRowContent(icon: "person.text.rectangle.fill", title: String.localized("Save Data To Device"), color: .accentColor)

                    Text("Beta")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue)
                        .clipShape(Capsule())
                }
            }
        } footer: {
            Text(.localized("Generates a unique persistent ID on your device to recover your saved data and certificates even after app reinstallation or Bundle ID changes."))
        }
    }

    private var resourcesSection: some View {
        Section {
            if !hideManager.isHidden("settings.guides") {
                SettingsRow(icon: "apple.intelligence", title: String.localized("Guides With AI"), color: .accentColor, destination: GuidesSettingsView())
            }
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
    
    private var appSection: some View {
        Section {
            if !hideManager.isHidden("settings.appIcons") {
                SettingsRow(icon: "app.badge.fill", title: String.localized("App Icons"), color: .accentColor, destination: AppIconView())
            }
            if !hideManager.isHidden("settings.updates") {
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
            SettingsSectionHeader(title: String.localized("App"), icon: "app.fill")
        }
    }
    
    private var developerSection: some View {
        Section {
            if !hideManager.isHidden("settings.debug") {
                SettingsRow(icon: "person.2.badge.gearshape.fill", title: String.localized("Debug"), color: .red, destination: DeveloperView())
            }
        } header: {
            SettingsSectionHeader(title: String.localized("Internal"), icon: "wrench.and.screwdriver.fill")
        }
    }

}

