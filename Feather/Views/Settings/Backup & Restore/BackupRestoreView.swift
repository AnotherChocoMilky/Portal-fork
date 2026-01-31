import SwiftUI
import NimbleViews
import ZIPFoundation
import UniformTypeIdentifiers
import CoreData

// MARK: - Backup Options
struct BackupOptions {
    var includeCertificates: Bool = true
    var includeSignedApps: Bool = true
    var includeImportedApps: Bool = true
    var includeSources: Bool = true
    var includeDefaultFrameworks: Bool = true
    var includeArchives: Bool = true
}

// MARK: - View
struct BackupRestoreView: View {
    @Environment(\.dismiss) var dismiss

    // UI State
    @State private var isImportIPAPresented = false
    @State private var isVerifyFilePickerPresented = false
    @State private var isBackupOptionsPresented = false
    @State private var showExporter = false
    @State private var showInvalidBackupError = false

    // Logic State
    @State private var backupOptions = BackupOptions()
    @State private var backupDocument: BackupDocument?
    @State private var isVerifying = false
    @State private var isRestoring = false
    @State private var isPreparingBackup = false
    @State private var isShowingPairingStatus = false
    @State private var pairingInfo: String = ""

    @AppStorage("feature_advancedBackupTools") var advancedBackupTools = false

    // MARK: Body
    var body: some View {
        NBList(.localized("Backup & Restore")) {
            // Main View Header
            Section {
                VStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.blue.opacity(0.2), .green.opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 100, height: 100)
                            .shadow(color: .blue.opacity(0.1), radius: 10, x: 0, y: 5)

                        Image(systemName: "arrow.up.doc.fill")
                            .font(.system(size: 44, weight: .bold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue, .green],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }

                    VStack(spacing: 8) {
                        Text(.localized("Backup & Restore"))
                            .font(.title2.bold())
                        Text(.localized("Keep your data safe by creating backups or restoring from a previous one."))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets())

            // Modernized Header Card
            Section {
                VStack(spacing: 0) {
                    HStack(spacing: 12) {
                        // Backup Card
                        VStack(spacing: 20) {
                            ZStack {
                                Circle()
                                    .fill(Color.blue.opacity(0.12))
                                    .frame(width: 72, height: 72)

                                Image(systemName: "arrow.up.doc.fill")
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.blue, .cyan],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            }

                            VStack(spacing: 6) {
                                Text(.localized("Backup"))
                                    .font(.system(.headline, design: .rounded, weight: .bold))
                                Text(.localized("Save Your Data"))
                                    .font(.system(.caption, design: .rounded))
                                    .foregroundStyle(.secondary)
                            }

                            Button {
                                isBackupOptionsPresented = true
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 14, weight: .bold))
                                    Text(.localized("Create"))
                                        .font(.system(.subheadline, design: .rounded, weight: .bold))
                                }
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    LinearGradient(
                                        colors: [.blue, .cyan],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                            }
                        }
                        .padding(24)
                        .background(
                            RoundedRectangle(cornerRadius: 28, style: .continuous)
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                                        .stroke(Color.blue.opacity(0.15), lineWidth: 1)
                                )
                        )

                        // Restore Backup Card
                        VStack(spacing: 20) {
                            ZStack {
                                Circle()
                                    .fill(Color.orange.opacity(0.12))
                                    .frame(width: 72, height: 72)

                                Image(systemName: "arrow.down.doc.fill")
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.orange, .yellow],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            }

                            VStack(spacing: 6) {
                                Text(.localized("Restore"))
                                    .font(.system(.headline, design: .rounded, weight: .bold))
                                Text(.localized("Apply A Backup"))
                                    .font(.system(.caption, design: .rounded))
                                    .foregroundStyle(.secondary)
                            }

                            Button {
                                isImportIPAPresented = true
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "arrow.counterclockwise.circle.fill")
                                        .font(.system(size: 14, weight: .bold))
                                    Text(.localized("Restore"))
                                        .font(.system(.subheadline, design: .rounded, weight: .bold))
                                }
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    LinearGradient(
                                        colors: [.orange, .yellow],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .shadow(color: .orange.opacity(0.3), radius: 8, x: 0, y: 4)
                            }
                        }
                        .padding(24)
                        .background(
                            RoundedRectangle(cornerRadius: 28, style: .continuous)
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                                        .stroke(Color.green.opacity(0.15), lineWidth: 1)
                                )
                        )
                    }
                }
                .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
            }
            .listRowBackground(Color.clear)

            // Advanced Tools Section
            if advancedBackupTools {
                Section {
                    Button {
                        handleExportFullDatabase()
                    } label: {
                        Label(.localized("Export Full Database"), systemImage: "cylinder.split.1x2.fill")
                    }

                    Button {
                        isVerifyFilePickerPresented = true
                    } label: {
                        Label(.localized("Verify Backup Integrity"), systemImage: "shield.checkerboard")
                    }

                    Divider()

                    Button {
                        handleClearCaches()
                    } label: {
                        Label(.localized("Clear All Caches"), systemImage: "trash.fill")
                    }

                    Button {
                        handleResetSettings()
                    } label: {
                        Label(.localized("Reset All Settings"), systemImage: "arrow.counterclockwise.circle.fill")
                    }

                    Button {
                        handleExportLogs()
                    } label: {
                        Label(.localized("Export Application Logs"), systemImage: "doc.text.fill")
                    }

                    Button {
                        handleRebuildIconCache()
                    } label: {
                        Label(.localized("Rebuild Icon Cache"), systemImage: "sparkles")
                    }

                    Button {
                        handleViewPairingStatus()
                    } label: {
                        Label(.localized("View Pairing Status"), systemImage: "link.circle.fill")
                    }
                } header: {
                    AppearanceSectionHeader(title: String.localized("Advanced Tools"), icon: "wrench.and.screwdriver.fill")
                }
            }

            // Information sections with modern cards
            Section {
                infoCard(
                    icon: "checkmark.shield.fill",
                    iconColor: .blue,
                    title: .localized("What's Included"),
                    description: .localized("Backups can include certificates, provisioning profiles, signed apps, imported apps, sources, and all app settings.")
                )

                infoCard(
                    icon: "exclamationmark.triangle.fill",
                    iconColor: .orange,
                    title: .localized("Important"),
                    description: .localized("Restoring requires the app to restart. Certificate restoration preserves files for manual re-import if needed.")
                )
            } header: {
                AppearanceSectionHeader(title: String.localized("About Backups (Beta)"), icon: "info.circle.fill")
            }
        }
        .sheet(isPresented: $isBackupOptionsPresented) {
            BackupOptionsView(
                options: $backupOptions,
                onConfirm: {
                    isBackupOptionsPresented = false
                    handleCreateBackup()
                }
            )
        }
        .sheet(isPresented: $isImportIPAPresented) {
            FileImporterRepresentableView(
                allowedContentTypes: [.zip],
                allowsMultipleSelection: false,
                onDocumentsPicked: { urls in
                    guard let url = urls.first else { return }
                    handleRestoreBackup(at: url)
                }
            )
            .ignoresSafeArea()
        }
        .fileImporter(
            isPresented: $isVerifyFilePickerPresented,
            allowedContentTypes: [.zip],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    handleVerifyBackup(at: url)
                }
            case .failure(let error):
                AppLogManager.shared.error("Failed to pick backup file for verification: \(error.localizedDescription)", category: "Backup & Restore")
            }
        }
        .fileExporter(
            isPresented: $showExporter,
            document: backupDocument,
            contentType: .zip,
            defaultFilename: "PortalBackup_\(Date().formatted(date: .numeric, time: .omitted).replacingOccurrences(of: "/", with: "-"))"
        ) { result in
            switch result {
            case .success(let url):
                AppLogManager.shared.success("Backup exported successfully to: \(url.path)", category: "Backup & Restore")
                HapticsManager.shared.success()
            case .failure(let error):
                AppLogManager.shared.error("Failed to export backup: \(error.localizedDescription)", category: "Backup & Restore")
                HapticsManager.shared.error()
            }
            // Clean up the temporary zip file after export attempt
            if let tempURL = backupDocument?.url {
                try? FileManager.default.removeItem(at: tempURL)
            }
            backupDocument = nil
        }
        .alert(.localized("Invalid Backup File"), isPresented: $showInvalidBackupError) {
            Button(.localized("OK"), role: .cancel) { }
        } message: {
            Text(.localized("Not a valid Backup file because Portal couldn't find the internal checker inside this uploaded file. Please upload an actual .zip file of a backup."))
        }
        .sheet(isPresented: $isShowingPairingStatus) {
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text(pairingInfo)
                            .font(.system(.body, design: .monospaced))
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .navigationTitle("Pairing Status")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") {
                            isShowingPairingStatus = false
                        }
                    }
                }
            }
        }
        .overlay {
            if isVerifying {
                ZStack {
                    Color.black.opacity(0.4).ignoresSafeArea()
                    VStack(spacing: 12) {
                        ProgressView()
                            .tint(.white)
                        Text("Verifying...")
                            .foregroundStyle(.white)
                    }
                    .padding(24)
                    .background(.ultraThinMaterial)
                    .cornerRadius(16)
                }
            }

            if isRestoring {
                ZStack {
                    Color.black.opacity(0.4).ignoresSafeArea()
                    VStack(spacing: 12) {
                        ProgressView()
                            .tint(.white)
                        Text("Restoring...")
                            .foregroundStyle(.white)
                    }
                    .padding(24)
                    .background(.ultraThinMaterial)
                    .cornerRadius(16)
                }
            }

            if isPreparingBackup {
                ZStack {
                    Color.black.opacity(0.4).ignoresSafeArea()
                    VStack(spacing: 12) {
                        ProgressView()
                            .tint(.white)
                        Text("Preparing Backup...")
                            .foregroundStyle(.white)
                    }
                    .padding(24)
                    .background(.ultraThinMaterial)
                    .cornerRadius(16)
                }
            }
        }
    }

    private func handleRestoreBackup(at url: URL) {
        isRestoring = true
        Task {
            let tempRestoreDir = FileManager.default.temporaryDirectory.appendingPathComponent("Restore_\(UUID().uuidString)")
            do {
                try FileManager.default.createDirectory(at: tempRestoreDir, withIntermediateDirectories: true)
                try FileManager.default.unzipItem(at: url, to: tempRestoreDir)

                let markers = ["PORTAL_BACKUP_MARKER.txt", "FEATHER_BACKUP_MARKER.txt", "PORTAL_BACKUP_CHECKER.txt"]
                let hasMarker = markers.contains { marker in
                    FileManager.default.fileExists(atPath: tempRestoreDir.appendingPathComponent(marker).path)
                }
                let hasSettings = FileManager.default.fileExists(atPath: tempRestoreDir.appendingPathComponent("settings.plist").path)

                guard hasMarker && hasSettings else {
                    try? FileManager.default.removeItem(at: tempRestoreDir)
                    await MainActor.run {
                        isRestoring = false
                        showInvalidBackupError = true
                    }
                    return
                }

                // 1. Restore UserDefaults (Settings)
                let settingsURL = tempRestoreDir.appendingPathComponent("settings.plist")
                if FileManager.default.fileExists(atPath: settingsURL.path) {
                    if let data = try? Data(contentsOf: settingsURL),
                       let dict = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any] {
                        if let bundleID = Bundle.main.bundleIdentifier {
                            UserDefaults.standard.setPersistentDomain(dict, forName: bundleID)
                        }
                    }
                }

                // 2. Restore Database
                let dbSourceDir = tempRestoreDir.appendingPathComponent("database")
                if FileManager.default.fileExists(atPath: dbSourceDir.path) {
                    if let storeURL = Storage.shared.container.persistentStoreDescriptions.first?.url {
                        let baseName = storeURL.lastPathComponent
                        let dbDestDir = storeURL.deletingLastPathComponent()
                        for f in [baseName, "\(baseName)-shm", "\(baseName)-wal"] {
                            let src = dbSourceDir.appendingPathComponent(f)
                            let dest = dbDestDir.appendingPathComponent(f)
                            if FileManager.default.fileExists(atPath: src.path) {
                                try? FileManager.default.removeItem(at: dest)
                                try FileManager.default.copyItem(at: src, to: dest)
                            }
                        }
                    }
                }

                // 3. Restore Application Files
                let fileManager = FileManager.default
                let documentsURL = Storage.shared.documentsURL

                // 3a. Certificates
                let certsSourceDir = tempRestoreDir.appendingPathComponent("certificates")
                if fileManager.fileExists(atPath: certsSourceDir.path) {
                    let certsDestDir = fileManager.certificates
                    let contents = (try? fileManager.contentsOfDirectory(at: certsSourceDir, includingPropertiesForKeys: nil)) ?? []
                    for file in contents {
                        let uuid = file.deletingPathExtension().lastPathComponent
                        let destFolder = fileManager.certificates(uuid)
                        try? fileManager.createDirectory(at: destFolder, withIntermediateDirectories: true)
                        let destFile = destFolder.appendingPathComponent(file.lastPathComponent)
                        try? fileManager.removeItem(at: destFile)
                        try? fileManager.copyItem(at: file, to: destFile)
                    }
                }

                // 3b. Signed Apps
                let signedSourceDir = tempRestoreDir.appendingPathComponent("signed_apps")
                if fileManager.fileExists(atPath: signedSourceDir.path) {
                    let signedDestDir = fileManager.signed
                    let contents = (try? fileManager.contentsOfDirectory(at: signedSourceDir, includingPropertiesForKeys: nil)) ?? []
                    for file in contents {
                        let uuid = file.deletingPathExtension().lastPathComponent
                        let destFolder = fileManager.signed(uuid)
                        try? fileManager.createDirectory(at: destFolder, withIntermediateDirectories: true)
                        let destFile = destFolder.appendingPathComponent(file.lastPathComponent)
                        try? fileManager.removeItem(at: destFile)
                        try? fileManager.copyItem(at: file, to: destFile)
                    }
                }

                // 3c. Imported Apps
                let importedSourceDir = tempRestoreDir.appendingPathComponent("imported_apps")
                if fileManager.fileExists(atPath: importedSourceDir.path) {
                    let contents = (try? fileManager.contentsOfDirectory(at: importedSourceDir, includingPropertiesForKeys: nil)) ?? []
                    for file in contents {
                        let uuid = file.deletingPathExtension().lastPathComponent
                        let destFolder = fileManager.unsigned(uuid)
                        try? fileManager.createDirectory(at: destFolder, withIntermediateDirectories: true)
                        let destFile = destFolder.appendingPathComponent(file.lastPathComponent)
                        try? fileManager.removeItem(at: destFile)
                        try? fileManager.copyItem(at: file, to: destFile)
                    }
                }

                // 3d. Default Frameworks
                let frameworksSourceDir = tempRestoreDir.appendingPathComponent("default_frameworks")
                if fileManager.fileExists(atPath: frameworksSourceDir.path) {
                    let frameworksDestDir = documentsURL.appendingPathComponent("Feather/DefaultFrameworks")
                    try? fileManager.createDirectory(at: frameworksDestDir, withIntermediateDirectories: true)
                    let contents = (try? fileManager.contentsOfDirectory(at: frameworksSourceDir, includingPropertiesForKeys: nil)) ?? []
                    for file in contents {
                        let destFile = frameworksDestDir.appendingPathComponent(file.lastPathComponent)
                        try? fileManager.removeItem(at: destFile)
                        try? fileManager.copyItem(at: file, to: destFile)
                    }
                }

                // 3e. Archives
                let archivesSourceDir = tempRestoreDir.appendingPathComponent("archives")
                if fileManager.fileExists(atPath: archivesSourceDir.path) {
                    let archivesDestDir = fileManager.archives
                    try? fileManager.createDirectory(at: archivesDestDir, withIntermediateDirectories: true)
                    let contents = (try? fileManager.contentsOfDirectory(at: archivesSourceDir, includingPropertiesForKeys: nil)) ?? []
                    for file in contents {
                        let destFile = archivesDestDir.appendingPathComponent(file.lastPathComponent)
                        try? fileManager.removeItem(at: destFile)
                        try? fileManager.copyItem(at: file, to: destFile)
                    }
                }

                // 3f. Extra Files
                let extraSourceDir = tempRestoreDir.appendingPathComponent("extra_files")
                if fileManager.fileExists(atPath: extraSourceDir.path) {
                    let contents = (try? fileManager.contentsOfDirectory(at: extraSourceDir, includingPropertiesForKeys: nil)) ?? []
                    for file in contents {
                        let destFile = documentsURL.appendingPathComponent(file.lastPathComponent)
                        try? fileManager.removeItem(at: destFile)
                        try? fileManager.copyItem(at: file, to: destFile)
                    }
                }

                try? fileManager.removeItem(at: tempRestoreDir)

                await MainActor.run {
                    isRestoring = false
                    HapticsManager.shared.success()

                    // Restart app to apply changes
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        UIApplication.shared.suspendAndReopen()
                    }
                }

            } catch {
                try? FileManager.default.removeItem(at: tempRestoreDir)
                await MainActor.run {
                    isRestoring = false
                    UIAlertController.showAlertWithOk(title: .localized("Error"), message: .localized("Failed to restore backup: \(error.localizedDescription)"))
                }
            }
        }
    }

    // MARK: - Info Card View
    @ViewBuilder
    private func infoCard(icon: String, iconColor: Color, title: LocalizedStringKey, description: LocalizedStringKey) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(iconColor)
                .frame(width: 36)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Advanced Tools Functions
    private func handleVerifyBackup(at url: URL) {
        isVerifying = true
        Task {
            let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            do {
                try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
                try FileManager.default.unzipItem(at: url, to: tempDir)

                let markers = ["PORTAL_BACKUP_MARKER.txt", "FEATHER_BACKUP_MARKER.txt", "PORTAL_BACKUP_CHECKER.txt"]
                let hasMarker = markers.contains { marker in
                    FileManager.default.fileExists(atPath: tempDir.appendingPathComponent(marker).path)
                }
                let hasSettings = FileManager.default.fileExists(atPath: tempDir.appendingPathComponent("settings.plist").path)

                try? FileManager.default.removeItem(at: tempDir)

                await MainActor.run {
                    isVerifying = false
                    if hasMarker && hasSettings {
                        UIAlertController.showAlertWithOk(title: .localized("Verification Successful"), message: .localized("This backup file is valid and can be restored."))
                    } else {
                        showInvalidBackupError = true
                    }
                }
            } catch {
                await MainActor.run {
                    isVerifying = false
                    UIAlertController.showAlertWithOk(title: .localized("Error"), message: .localized("Failed to verify backup: \(error.localizedDescription)"))
                }
            }
        }
    }

    // MARK: - Advanced Tools Functions
    private func handleClearCaches() {
        let tempDir = NSTemporaryDirectory()
        let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first?.path

        var count = 0

        do {
            let tempFiles = try FileManager.default.contentsOfDirectory(atPath: tempDir)
            for file in tempFiles {
                try? FileManager.default.removeItem(atPath: (tempDir as NSString).appendingPathComponent(file))
                count += 1
            }

            if let cacheDir = cacheDir {
                let cacheFiles = try FileManager.default.contentsOfDirectory(atPath: cacheDir)
                for file in cacheFiles {
                    try? FileManager.default.removeItem(atPath: (cacheDir as NSString).appendingPathComponent(file))
                    count += 1
                }
            }

            AppLogManager.shared.success("Cleared \(count) cache items", category: "Advanced Tools")
            UIAlertController.showAlertWithOk(title: "Caches Cleared", message: "Successfully removed \(count) temporary files and cached items.")
        } catch {
            AppLogManager.shared.error("Failed to clear caches: \(error.localizedDescription)", category: "Advanced Tools")
        }
    }

    private func handleResetSettings() {
        let alert = UIAlertController(title: "Reset All Settings", message: "Are you sure you want to reset all app settings? This will clear all preferences and restart the app.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Reset", style: .destructive) { _ in
            if let bundleID = Bundle.main.bundleIdentifier {
                UserDefaults.standard.removePersistentDomain(forName: bundleID)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                UIApplication.shared.suspendAndReopen()
            }
        })
        UIApplication.topViewController()?.present(alert, animated: true, completion: nil)
    }

    private func handleExportLogs() {
        let logs = AppLogManager.shared.exportLogs()
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("Feather_Logs_\(Date().timeIntervalSince1970).txt")
        do {
            try logs.write(to: tempURL, atomically: true, encoding: .utf8)
            UIActivityViewController.show(activityItems: [tempURL])
        } catch {
            AppLogManager.shared.error("Failed to export logs: \(error.localizedDescription)", category: "Advanced Tools")
        }
    }

    private func handleRebuildIconCache() {
        isPreparingBackup = true
        Task {
            // Logic to clear icon cache
            let docDir = Storage.shared.documentsURL
            let signedDir = docDir.appendingPathComponent("Feather/Signed")
            let importedDir = docDir.appendingPathComponent("Feather/Imported")

            for dir in [signedDir, importedDir] {
                if let enumerator = FileManager.default.enumerator(at: dir, includingPropertiesForKeys: nil) {
                    for case let fileURL as URL in enumerator {
                        if fileURL.lastPathComponent == "icon.png" || fileURL.lastPathComponent.contains("tinted_icon") {
                            try? FileManager.default.removeItem(at: fileURL)
                        }
                    }
                }
            }

            await MainActor.run {
                isPreparingBackup = false
                UIAlertController.showAlertWithOk(title: "Icon Cache Rebuilt", message: "Icons will be regenerated on next view.")
            }
        }
    }

    private func handleViewPairingStatus() {
        let pairingFileURL = Storage.shared.documentsURL.appendingPathComponent("pairingFile.plist")
        if FileManager.default.fileExists(atPath: pairingFileURL.path) {
            if let dict = NSDictionary(contentsOf: pairingFileURL) as? [String: Any] {
                var info = "Pairing File Found\n\n"
                for (key, value) in dict {
                    if key.lowercased().contains("key") || key.lowercased().contains("secret") {
                        info += "\(key): [HIDDEN]\n"
                    } else {
                        info += "\(key): \(value)\n"
                    }
                }
                pairingInfo = info
            } else {
                pairingInfo = "Pairing file found but could not be read as a dictionary."
            }
        } else {
            pairingInfo = "No pairing file found at:\n\(pairingFileURL.path)"
        }
        isShowingPairingStatus = true
    }

    private func handleExportFullDatabase() {
        guard let storeURL = Storage.shared.container.persistentStoreDescriptions.first?.url else {
            UIAlertController.showAlertWithOk(title: "Error", message: "Could not find database location")
            return
        }

        isPreparingBackup = true
        Task {
            let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            let zipURL = FileManager.default.temporaryDirectory.appendingPathComponent("PortalDatabaseBackup_\(Date().timeIntervalSince1970).zip")

            do {
                try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
                let baseName = storeURL.lastPathComponent
                let directory = storeURL.deletingLastPathComponent()
                for fileName in [baseName, "\(baseName)-shm", "\(baseName)-wal"] {
                    let fileURL = directory.appendingPathComponent(fileName)
                    if FileManager.default.fileExists(atPath: fileURL.path) {
                        try FileManager.default.copyItem(at: fileURL, to: tempDir.appendingPathComponent(fileName))
                    }
                }

                try FileManager.default.zipItem(at: tempDir, to: zipURL, shouldKeepParent: false)
                try? FileManager.default.removeItem(at: tempDir)

                await MainActor.run {
                    isPreparingBackup = false
                    backupDocument = BackupDocument(url: zipURL)
                    showExporter = true
                }
            } catch {
                await MainActor.run {
                    isPreparingBackup = false
                    UIAlertController.showAlertWithOk(title: "Error", message: "Failed to export database: \(error.localizedDescription)")
                }
            }
        }
    }

    // MARK: - Backup Functions
    private func handleCreateBackup() {
        isPreparingBackup = true
        Task {
            if let url = await prepareBackup(with: backupOptions) {
                await MainActor.run {
                    isPreparingBackup = false
                    backupDocument = BackupDocument(url: url)
                    showExporter = true
                }
            } else {
                await MainActor.run {
                    isPreparingBackup = false
                }
            }
        }
    }

    private func prepareBackup(with options: BackupOptions) async -> URL? {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        do {
            try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

            // 1. Certificates
            if options.includeCertificates {
                let certificatesDir = tempDir.appendingPathComponent("certificates")
                try? FileManager.default.createDirectory(at: certificatesDir, withIntermediateDirectories: true)
                let certificates = Storage.shared.getAllCertificates()
                var certMetadata: [[String: Any]] = []
                for cert in certificates {
                    if let uuid = cert.uuid {
                        var metadata: [String: Any] = ["uuid": uuid]
                        if let certURL = Storage.shared.getFile(.certificate, from: cert),
                           let certData = try? Data(contentsOf: certURL) {
                            try certData.write(to: certificatesDir.appendingPathComponent("\(uuid).p12"))
                            metadata["hasP12"] = true
                        }
                        if let provisionURL = Storage.shared.getFile(.provision, from: cert),
                           let provisionData = try? Data(contentsOf: provisionURL) {
                            try provisionData.write(to: certificatesDir.appendingPathComponent("\(uuid).mobileprovision"))
                            metadata["hasProvision"] = true
                        }
                        if let provisionData = Storage.shared.getProvisionFileDecoded(for: cert) {
                            metadata["name"] = provisionData.Name
                            if let teamID = provisionData.TeamIdentifier.first { metadata["teamID"] = teamID }
                            metadata["teamName"] = provisionData.TeamName
                        }
                        if let date = cert.date { metadata["date"] = date.timeIntervalSince1970 }
                        metadata["ppQCheck"] = cert.ppQCheck
                        if let password = cert.password { metadata["password"] = password }
                        certMetadata.append(metadata)
                    }
                }
                let jsonData = try JSONSerialization.data(withJSONObject: certMetadata)
                try jsonData.write(to: tempDir.appendingPathComponent("certificates_metadata.json"))
            }

            // 2. Sources
            if options.includeSources {
                let sources = Storage.shared.getSources()
                let sourcesData = sources.compactMap { source -> [String: String]? in
                    guard let urlString = source.sourceURL?.absoluteString,
                          let name = source.name,
                          let identifier = source.identifier else { return nil }
                    return ["url": urlString, "name": name, "identifier": identifier]
                }
                let jsonData = try JSONSerialization.data(withJSONObject: sourcesData)
                try jsonData.write(to: tempDir.appendingPathComponent("sources.json"))
            }

            // 3. Signed Apps
            if options.includeSignedApps {
                let signedAppsDir = tempDir.appendingPathComponent("signed_apps")
                try? FileManager.default.createDirectory(at: signedAppsDir, withIntermediateDirectories: true)
                let signedApps = (try? Storage.shared.context.fetch(Signed.fetchRequest())) ?? []
                var appsData: [[String: String]] = []
                for app in signedApps {
                    guard let uuid = app.uuid else { continue }
                    var data: [String: String] = ["uuid": uuid]
                    if let name = app.name { data["name"] = name }
                    if let identifier = app.identifier { data["identifier"] = identifier }
                    if let version = app.version { data["version"] = version }
                    if let ipaURL = FileManager.default.getPath(in: FileManager.default.signed(uuid), for: "ipa"),
                       FileManager.default.fileExists(atPath: ipaURL.path) {
                        try? FileManager.default.copyItem(at: ipaURL, to: signedAppsDir.appendingPathComponent("\(uuid).ipa"))
                        data["hasIPA"] = "true"
                    }
                    appsData.append(data)
                }
                let jsonData = try JSONSerialization.data(withJSONObject: appsData)
                try jsonData.write(to: tempDir.appendingPathComponent("signed_apps.json"))
            }

            // 4. Imported Apps
            if options.includeImportedApps {
                let importedAppsDir = tempDir.appendingPathComponent("imported_apps")
                try? FileManager.default.createDirectory(at: importedAppsDir, withIntermediateDirectories: true)
                let importedApps = (try? Storage.shared.context.fetch(Imported.fetchRequest())) ?? []
                var appsData: [[String: String]] = []
                for app in importedApps {
                    guard let uuid = app.uuid else { continue }
                    var data: [String: String] = ["uuid": uuid]
                    if let name = app.name { data["name"] = name }
                    if let identifier = app.identifier { data["identifier"] = identifier }
                    if let version = app.version { data["version"] = version }
                    if let ipaURL = FileManager.default.getPath(in: FileManager.default.unsigned(uuid), for: "ipa"),
                       FileManager.default.fileExists(atPath: ipaURL.path) {
                        try? FileManager.default.copyItem(at: ipaURL, to: importedAppsDir.appendingPathComponent("\(uuid).ipa"))
                        data["hasIPA"] = "true"
                    }
                    appsData.append(data)
                }
                let jsonData = try JSONSerialization.data(withJSONObject: appsData)
                try jsonData.write(to: tempDir.appendingPathComponent("imported_apps.json"))
            }

            // 5. Default Frameworks
            if options.includeDefaultFrameworks {
                let dest = tempDir.appendingPathComponent("default_frameworks")
                try? FileManager.default.createDirectory(at: dest, withIntermediateDirectories: true)
                let src = Storage.shared.documentsURL.appendingPathComponent("Feather/DefaultFrameworks")
                if FileManager.default.fileExists(atPath: src.path) {
                    for file in (try? FileManager.default.contentsOfDirectory(at: src, includingPropertiesForKeys: nil)) ?? [] {
                        try? FileManager.default.copyItem(at: file, to: dest.appendingPathComponent(file.lastPathComponent))
                    }
                }
            }

            // 6. Archives
            if options.includeArchives {
                let dest = tempDir.appendingPathComponent("archives")
                try? FileManager.default.createDirectory(at: dest, withIntermediateDirectories: true)
                let src = FileManager.default.archives
                if FileManager.default.fileExists(atPath: src.path) {
                    for file in (try? FileManager.default.contentsOfDirectory(at: src, includingPropertiesForKeys: nil)) ?? [] {
                        try? FileManager.default.copyItem(at: file, to: dest.appendingPathComponent(file.lastPathComponent))
                    }
                }
            }

            // 7. Extra Files (Always)
            let extraDir = tempDir.appendingPathComponent("extra_files")
            try? FileManager.default.createDirectory(at: extraDir, withIntermediateDirectories: true)
            for file in ["pairingFile.plist", "server.pem", "server.crt", "commonName.txt"] {
                let url = Storage.shared.documentsURL.appendingPathComponent(file)
                if FileManager.default.fileExists(atPath: url.path) {
                    try? FileManager.default.copyItem(at: url, to: extraDir.appendingPathComponent(file))
                }
            }

            // 8. Database (Always)
            let dbDir = tempDir.appendingPathComponent("database")
            try? FileManager.default.createDirectory(at: dbDir, withIntermediateDirectories: true)
            if let storeURL = Storage.shared.container.persistentStoreDescriptions.first?.url {
                let dir = storeURL.deletingLastPathComponent()
                for f in [storeURL.lastPathComponent, "\(storeURL.lastPathComponent)-shm", "\(storeURL.lastPathComponent)-wal"] {
                    let url = dir.appendingPathComponent(f)
                    if FileManager.default.fileExists(atPath: url.path) {
                        try? FileManager.default.copyItem(at: url, to: dbDir.appendingPathComponent(f))
                    }
                }
            }

            // 9. Settings (Always)
            let defaults = UserDefaults.standard.dictionaryRepresentation()
            let filtered = defaults.filter { k, _ in
                !k.hasPrefix("NS") && !k.hasPrefix("AK") && !k.hasPrefix("Apple") &&
                !k.hasPrefix("WebKit") && !k.hasPrefix("CPU") && !k.hasPrefix("metal")
            }
            let data = try PropertyListSerialization.data(fromPropertyList: filtered, format: .xml, options: 0)
            try data.write(to: tempDir.appendingPathComponent("settings.plist"))

            // 10. Zip
            let finalURL = FileManager.default.temporaryDirectory.appendingPathComponent("PortalBackup_\(UUID().uuidString).zip")
            try "PORTAL_BACKUP_v1.0_\(Date().timeIntervalSince1970)".write(to: tempDir.appendingPathComponent("PORTAL_BACKUP_MARKER.txt"), atomically: true, encoding: .utf8)
            try FileManager.default.zipItem(at: tempDir, to: finalURL, shouldKeepParent: false)
            try? FileManager.default.removeItem(at: tempDir)
            return finalURL
        } catch {
            await MainActor.run { UIAlertController.showAlertWithOk(title: .localized("Error"), message: .localized("Failed to prepare backup: \(error.localizedDescription)")) }
            return nil
        }
    }

}

// MARK: - BackupDocument
struct BackupDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.zip] }
    var url: URL
    init(url: URL) { self.url = url }
    init(configuration: ReadConfiguration) throws { throw CocoaError(.fileReadUnknown) }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper { return try FileWrapper(url: url) }
}

// MARK: - BackupOptionsView
struct BackupOptionsView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var options: BackupOptions
    let onConfirm: () -> Void
    var body: some View {
        NavigationView {
            NBList(.localized("Backup Options")) {
                Section {
                    VStack(spacing: 16) {
                        ZStack {
                            Circle().fill(LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.2), Color.purple.opacity(0.2)]), startPoint: .topLeading, endPoint: .bottomTrailing)).frame(width: 80, height: 80)
                            Image(systemName: "square.and.arrow.up.fill").font(.system(size: 40, weight: .semibold)).foregroundStyle(LinearGradient(gradient: Gradient(colors: [.blue, .purple]), startPoint: .topLeading, endPoint: .bottomTrailing))
                        }
                        Text(.localized("What would you like in this Portal Backup?")).font(.title2.bold()).multilineTextAlignment(.center).padding(.horizontal)
                        Text(.localized("Select the data you want to include in your backup")).font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center).padding(.horizontal)
                    }.frame(maxWidth: .infinity).padding(.vertical, 20)
                }.listRowBackground(Color.clear).listRowInsets(EdgeInsets())

                Section {
                    backupOptionToggle(icon: "checkmark.seal.fill", iconColor: .blue, title: .localized("Certificates"), description: .localized("Your signing certificates and provisioning profiles"), isOn: $options.includeCertificates)
                    backupOptionToggle(icon: "app.badge.fill", iconColor: .green, title: .localized("Signed Apps"), description: .localized("Apps you have signed with your certificates"), isOn: $options.includeSignedApps)
                    backupOptionToggle(icon: "square.and.arrow.down.fill", iconColor: .orange, title: .localized("Imported Apps"), description: .localized("Apps imported from files or other sources"), isOn: $options.includeImportedApps)
                    backupOptionToggle(icon: "globe.fill", iconColor: .purple, title: .localized("Sources"), description: .localized("Your configured app sources and repositories"), isOn: $options.includeSources)
                    backupOptionToggle(icon: "puzzlepiece.extension.fill", iconColor: .cyan, title: .localized("Default Frameworks"), description: .localized("Your automatically injected frameworks (.dylib, .deb)"), isOn: $options.includeDefaultFrameworks)
                    backupOptionToggle(icon: "archivebox.fill", iconColor: .indigo, title: .localized("Archives"), description: .localized("Your saved app archives and backups"), isOn: $options.includeArchives)
                } header: { AppearanceSectionHeader(title: String.localized("Backup Content"), icon: "list.bullet.indent") }
                .listRowBackground(Color.clear).listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))

                if options.includeSignedApps || options.includeImportedApps {
                    Section {
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "exclamationmark.triangle.fill").font(.system(size: 20)).foregroundStyle(.orange)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(.localized("Large Backup Size")).font(.headline).foregroundStyle(.primary)
                                Text(.localized("If you include Signed and Imported Apps, this backup will be large.")).font(.subheadline).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                            }
                        }.padding(16).background(Color.orange.opacity(0.1)).cornerRadius(12)
                    }.listRowBackground(Color.clear).listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }

                Section {
                    Button { onConfirm() } label: {
                        HStack { Image(systemName: "checkmark.circle.fill"); Text(.localized("Create Portal Backup")).font(.headline) }.frame(maxWidth: .infinity).padding(.vertical, 16).background(LinearGradient(gradient: Gradient(colors: [.blue, .purple]), startPoint: .leading, endPoint: .trailing)).foregroundStyle(.white).cornerRadius(12)
                    }.buttonStyle(.plain)
                    Button { dismiss() } label: { Text(.localized("Cancel")).font(.subheadline).foregroundStyle(.secondary).frame(maxWidth: .infinity) }.buttonStyle(.plain).padding(.top, 8)
                }.listRowBackground(Color.clear).listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 20, trailing: 16))
            }.navigationTitle(.localized("Backup Options")).navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button { dismiss() } label: { Image(systemName: "xmark.circle.fill").font(.system(size: 20)).foregroundStyle(.secondary) } } }
        }
    }

    @ViewBuilder
    private func backupOptionToggle(icon: String, iconColor: Color, title: LocalizedStringKey, description: LocalizedStringKey, isOn: Binding<Bool>) -> some View {
        Button { isOn.wrappedValue.toggle(); HapticsManager.shared.softImpact() } label: {
            HStack(alignment: .top, spacing: 12) {
                ZStack { Circle().fill(iconColor.opacity(0.15)).frame(width: 44, height: 44); Image(systemName: icon).font(.system(size: 20, weight: .semibold)).foregroundStyle(iconColor) }
                VStack(alignment: .leading, spacing: 4) { Text(title).font(.headline).foregroundStyle(.primary); Text(description).font(.subheadline).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true) }
                Spacer()
                Image(systemName: isOn.wrappedValue ? "checkmark.circle.fill" : "circle").font(.system(size: 24)).foregroundStyle(isOn.wrappedValue ? .blue : .gray.opacity(0.3))
            }.padding(16).background(.ultraThinMaterial).cornerRadius(12).overlay(RoundedRectangle(cornerRadius: 12).stroke(isOn.wrappedValue ? iconColor.opacity(0.3) : Color.clear, lineWidth: 1))
        }.buttonStyle(.plain)
    }
}

