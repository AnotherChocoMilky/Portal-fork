import SwiftUI
import CoreData
import IDeviceSwift

// MARK: - Batch Signing View
struct BatchSigningView: View {
    @Environment(\.dismiss) private var dismiss
    let apps: [AppInfoPresentable]
    let onComplete: () -> Void
    
    @FetchRequest(
        entity: Imported.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Imported.dateAdded, ascending: false)]
    ) private var importedApps: FetchedResults<Imported>
    
    @FetchRequest(
        entity: CertificatePair.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \CertificatePair.date, ascending: false)]
    ) private var certificates: FetchedResults<CertificatePair>
    
    @State private var selectedApps: Set<String> = []
    @State private var selectedCertificateIndex = 0
    @State private var isSigningBatch = false
    @State private var batchProgress: Double = 0
    @State private var currentSigningApp: String = ""
    @State private var batchResults: [BatchSignResult] = []
    @State private var autoInstall = true
    @State private var currentPhase: BatchPhase = .signing
    @State private var signedAppsForInstall: [AppInfoPresentable] = []
    
    // Edit functionality
    @State private var appOptions: [String: Options] = [:] // UUID -> Custom Options
    @State private var editingAppId: String? = nil
    @State private var showEditSheet = false
    
    @AppStorage("Feather.installationMethod") private var installationMethod: Int = 0
    @AppStorage("Feather.serverMethod") private var _serverMethod: Int = 0
    
    enum BatchPhase {
        case signing
        case installing
        case completed
    }
    
    struct BatchSignResult: Identifiable {
        let id = UUID()
        let appName: String
        let success: Bool
        var message: String
        var installLink: String? = nil
        var app: AppInfoPresentable? = nil
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        headerSection

                        certificateSection

                        optionsSection

                        appSelectionSection

                        if !batchResults.isEmpty {
                            resultsSection
                        }

                        actionSection
                            .padding(.bottom, 30)
                    }
                }

                // Progress Overlay
                if isSigningBatch {
                    progressOverlay
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showEditSheet) {
                if let appId = editingAppId,
                   let app = apps.first(where: { $0.uuid == appId }) {
                    BatchAppEditSheet(
                        app: app,
                        options: Binding(
                            get: { appOptions[appId] ?? createDefaultOptions(for: app) },
                            set: { appOptions[appId] = $0 }
                        ),
                        onDismiss: {
                            showEditSheet = false
                        }
                    )
                }
            }
        }
    }

    // MARK: - Subviews

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Batch Signing")
                    .font(.system(.largeTitle, design: .rounded).bold())
                Text("Sign multiple apps at once")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title)
                    .foregroundStyle(.secondary)
                    .symbolRenderingMode(.hierarchical)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal)
        .padding(.top, 20)
    }

    private var certificateSection: some View {
        BatchCard(title: "Signing Certificate", icon: "checkmark.seal.fill", iconColor: .blue) {
            if certificates.isEmpty {
                HStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text("No Certificates Available")
                        .foregroundStyle(.secondary)
                    Spacer()
                }
            } else {
                Menu {
                    ForEach(Array(certificates.enumerated()), id: \.element.uuid) { index, cert in
                        Button {
                            selectedCertificateIndex = index
                        } label: {
                            HStack {
                                if selectedCertificateIndex == index {
                                    Image(systemName: "checkmark")
                                }
                                Text(cert.nickname ?? "Certificate \(index + 1)")
                            }
                        }
                    }
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(certificates[selectedCertificateIndex].nickname ?? "Certificate \(selectedCertificateIndex + 1)")
                                .font(.headline)
                                .foregroundStyle(.primary)
                            Text("Tap to change")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private var optionsSection: some View {
        BatchCard(title: "Batch Options", icon: "gearshape.fill", iconColor: .gray) {
            VStack(alignment: .leading, spacing: 12) {
                Toggle(isOn: $autoInstall) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Auto Install")
                            .font(.headline)
                        Text("Install apps automatically after signing")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .tint(.accentColor)

                Divider()

                HStack {
                    Image(systemName: "info.circle")
                        .font(.caption)
                    Text("Apps will be signed using the selected certificate and global signing options unless customized.")
                        .font(.caption)
                }
                .foregroundStyle(.secondary)
            }
        }
    }

    private var appSelectionSection: some View {
        BatchCard(title: "Select Apps (\(selectedApps.count))", icon: "app.badge.checkmark.fill", iconColor: .green) {
            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button(selectedApps.count == apps.count ? "Deselect All" : "Select All") {
                        withAnimation {
                            if selectedApps.count == apps.count {
                                selectedApps.removeAll()
                            } else {
                                selectedApps = Set(apps.compactMap { $0.uuid })
                            }
                        }
                    }
                    .font(.caption.bold())
                }
                .padding(.bottom, 8)

                if apps.isEmpty {
                    Text("No Apps Available")
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 20)
                } else {
                    VStack(spacing: 12) {
                        ForEach(apps, id: \.uuid) { app in
                            BatchAppRowModern(
                                app: app,
                                isSelected: selectedApps.contains(app.uuid ?? ""),
                                hasCustomOptions: appOptions[app.uuid ?? ""] != nil,
                                onToggle: {
                                    toggleAppSelection(app)
                                },
                                onEdit: {
                                    editingAppId = app.uuid
                                    showEditSheet = true
                                }
                            )

                            if app.uuid != apps.last?.uuid {
                                Divider()
                            }
                        }
                    }
                }
            }
        }
    }

    private var resultsSection: some View {
        BatchCard(title: "Signing Results", icon: "checklist", iconColor: .purple) {
            VStack(spacing: 12) {
                ForEach(batchResults) { result in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 12) {
                            Image(systemName: result.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .font(.title3)
                                .foregroundStyle(result.success ? .green : .red)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(result.appName)
                                    .font(.subheadline.weight(.medium))
                                Text(result.message)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            if result.success, let link = result.installLink {
                                Button {
                                    if let url = URL(string: link) {
                                        UIApplication.shared.open(url)
                                    }
                                } label: {
                                    Text("Install")
                                        .font(.caption.bold())
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.accentColor)
                                        .foregroundStyle(.white)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }

                    if result.id != batchResults.last?.id {
                        Divider()
                    }
                }
                
                if batchResults.contains(where: { $0.success && $0.installLink != nil }) {
                    Button {
                        installAllSigned()
                    } label: {
                        Label("Install All Signed", systemImage: "arrow.down.circle.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.accentColor.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.top, 8)
                }
            }
        }
    }

    private var actionSection: some View {
        Button {
            startBatchSigning()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "signature")
                    .font(.title3.bold())
                Text("Sign Selected Apps (\(selectedApps.count))")
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(selectedApps.isEmpty || certificates.isEmpty || isSigningBatch ? Color.gray : Color.accentColor)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: Color.accentColor.opacity(0.3), radius: 10, y: 5)
        }
        .disabled(selectedApps.isEmpty || certificates.isEmpty || isSigningBatch)
        .padding(.horizontal)
    }

    private var progressOverlay: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .transition(.opacity)

            VStack(spacing: 24) {
                // Animated Icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.accentColor.opacity(0.5), Color.accentColor.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)
                        .blur(radius: 10)

                    Image(systemName: currentPhase == .signing ? "signature" : "arrow.down.circle.fill")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundStyle(.white)
                        .pulseEffect(true)
                }

                VStack(spacing: 16) {
                    Text(currentPhase == .signing ? "Signing Apps" : "Installing Apps")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.white)

                    Text(currentSigningApp)
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.9))
                        .lineLimit(1)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 280)

                    // Progress Bar
                    VStack(spacing: 10) {
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.white.opacity(0.2))

                                RoundedRectangle(cornerRadius: 10)
                                    .fill(
                                        LinearGradient(
                                            colors: [.accentColor, .accentColor.opacity(0.8)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: geometry.size.width * batchProgress)
                                    .animation(.spring(), value: batchProgress)
                            }
                        }
                        .frame(height: 12)

                        Text("\(Int(batchProgress * 100))%")
                            .font(.system(.body, design: .monospaced).bold())
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 30)
                }
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .padding(20)
            .transition(.scale.combined(with: .opacity))
        }
    }

    // MARK: - Logic
    
    private func createDefaultOptions(for app: AppInfoPresentable) -> Options {
        var options = OptionsManager.shared.options
        options.appName = app.name
        options.appVersion = app.version
        options.appIdentifier = app.identifier
        return options
    }
    
    private func toggleAppSelection(_ app: AppInfoPresentable) {
        guard let id = app.uuid else { return }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            if selectedApps.contains(id) {
                selectedApps.remove(id)
            } else {
                selectedApps.insert(id)
            }
        }
    }
    
    private func startBatchSigning() {
        guard !selectedApps.isEmpty, certificates.indices.contains(selectedCertificateIndex) else { return }
        
        isSigningBatch = true
        batchProgress = 0
        batchResults.removeAll()
        currentPhase = .signing
        
        let appsToSign = apps.filter { selectedApps.contains($0.uuid ?? "") }
        let totalApps = Double(appsToSign.count)
        
        AppLogManager.shared.info("Starting batch signing for \(Int(totalApps)) apps", category: "BatchSign")
        
        Task {
            signedAppsForInstall.removeAll()
            
            for (index, app) in appsToSign.enumerated() {
                await MainActor.run {
                    currentSigningApp = app.name ?? "App \(index + 1)"
                    batchProgress = Double(index) / totalApps
                }
                
                let selectedCert = certificates[selectedCertificateIndex]
                let signingOptions = appOptions[app.uuid ?? ""] ?? OptionsManager.shared.options
                
                await withCheckedContinuation { continuation in
                    if _serverMethod == 2 {
                        // Remote Signing
                        FR.remoteSignPackageFile(
                            app,
                            using: signingOptions,
                            certificate: selectedCert
                        ) { result in
                            DispatchQueue.main.async {
                                switch result {
                                case .success(let installLink):
                                    let res = BatchSignResult(
                                        appName: app.name ?? "Unknown",
                                        success: true,
                                        message: "Signed Successfully (Remote)",
                                        installLink: installLink,
                                        app: app
                                    )
                                    batchResults.append(res)

                                    if autoInstall {
                                        if let url = URL(string: installLink) {
                                            UIApplication.shared.open(url)
                                        }
                                    }
                                case .failure(let error):
                                    let res = BatchSignResult(
                                        appName: app.name ?? "Unknown",
                                        success: false,
                                        message: error.localizedDescription,
                                        app: app
                                    )
                                    batchResults.append(res)
                                }
                                continuation.resume()
                            }
                        }
                    } else {
                        // Local Signing
                        FR.signPackageFile(
                            app,
                            using: signingOptions,
                            icon: nil,
                            certificate: selectedCert
                        ) { error in
                            DispatchQueue.main.async {
                                if let error {
                                    let res = BatchSignResult(
                                        appName: app.name ?? "Unknown",
                                        success: false,
                                        message: error.localizedDescription,
                                        app: app
                                    )
                                    batchResults.append(res)
                                } else {
                                    let res = BatchSignResult(
                                        appName: app.name ?? "Unknown",
                                        success: true,
                                        message: "Signed Successfully",
                                        app: app
                                    )
                                    batchResults.append(res)
                                    signedAppsForInstall.append(app)
                                }
                                continuation.resume()
                            }
                        }
                    }
                }
                
                // For local signing, we can generate the link if needed
                if _serverMethod != 2 && autoInstall && signedAppsForInstall.contains(where: { $0.uuid == app.uuid }) {
                    await triggerInstallation(for: app, appIndex: index)
                }
            }

            await MainActor.run {
                batchProgress = 1.0
                isSigningBatch = false
                selectedApps.removeAll()
                HapticsManager.shared.success()
                ToastManager.shared.show("✅ Batch Signing Completed", type: .success)
            }
        }
    }
    
    private func triggerInstallation(for app: AppInfoPresentable, appIndex: Int) async {
        await MainActor.run {
            currentPhase = .installing
        }
        
        do {
            let viewModel = InstallerStatusViewModel(isIdevice: installationMethod == 1)
            let handler = ArchiveHandler(app: app, viewModel: viewModel)
            try await handler.move()
            let packageUrl = try await handler.archive()
            
            if installationMethod == 0 {
                let installer = try ServerInstaller(app: app, viewModel: viewModel)
                await MainActor.run {
                    installer.packageUrl = packageUrl
                    viewModel.status = .ready

                    let link = installer.iTunesLink
                    updateBatchResult(for: app, message: "Signed - Ready to Install", link: link)

                    if let url = URL(string: link) {
                        UIApplication.shared.open(url)
                    }
                }
            } else if installationMethod == 1 {
                let installProxy = InstallationProxy(viewModel: viewModel)
                try await installProxy.install(at: packageUrl, suspend: app.identifier == Bundle.main.bundleIdentifier)
                
                await MainActor.run {
                    updateBatchResult(for: app, message: "Signed and Installed")
                }
            }
        } catch {
            await MainActor.run {
                updateBatchResult(for: app, message: "Signed, Install Failed: \(error.localizedDescription)")
            }
        }
        
        await MainActor.run {
            currentPhase = .signing
        }
    }
    
    private func updateBatchResult(for app: AppInfoPresentable, message: String, link: String? = nil) {
        if let idx = batchResults.firstIndex(where: { $0.app?.uuid == app.uuid && $0.success }) {
            var updated = batchResults[idx]
            updated.message = message
            if let link = link {
                updated.installLink = link
            }
            batchResults[idx] = updated
        }
    }
    
    private func installAllSigned() {
        let links = batchResults.compactMap { $0.installLink }
        for link in links {
            if let url = URL(string: link) {
                UIApplication.shared.open(url)
            }
        }
    }
}

// MARK: - Batch Card
struct BatchCard<Content: View>: View {
    let title: LocalizedStringKey
    let icon: String
    let iconColor: Color
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.footnote.bold())
                    .foregroundStyle(.white)
                    .padding(6)
                    .background(iconColor, in: Circle())
                
                Text(title)
                    .font(.system(.subheadline, design: .rounded).bold())
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 4)

            content()
                .padding(16)
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .shadow(color: .black.opacity(0.03), radius: 5, x: 0, y: 2)
        }
        .padding(.horizontal)
    }
}

// MARK: - Modern App Row
struct BatchAppRowModern: View {
    let app: AppInfoPresentable
    let isSelected: Bool
    let hasCustomOptions: Bool
    let onToggle: () -> Void
    let onEdit: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggle) {
                HStack(spacing: 12) {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
                        .bounceEffect(isSelected)
                    
                    FRAppIconView(app: app, size: 45)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(app.name ?? "Unknown App")
                            .font(.system(.subheadline, design: .rounded).bold())
                            .foregroundStyle(.primary)
                        
                        Text(app.identifier ?? "Unknown Bundle ID")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            Button(action: onEdit) {
                Image(systemName: "slider.horizontal.3")
                    .font(.subheadline.bold())
                    .foregroundStyle(hasCustomOptions ? .white : .accentColor)
                    .padding(8)
                    .background(hasCustomOptions ? Color.orange : Color.accentColor.opacity(0.1), in: Circle())
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Batch App Edit Sheet
struct BatchAppEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    let app: AppInfoPresentable
    @Binding var options: Options
    let onDismiss: () -> Void
    
    @State private var editedName: String = ""
    @State private var editedBundleId: String = ""
    @State private var editedVersion: String = ""
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    header
                    
                    appInfoSection
                    
                    modificationSection

                    tweakSection

                    actionButtons
                }
                .padding(.vertical)
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationBarHidden(true)
            .onAppear {
                editedName = options.appName ?? app.name ?? ""
                editedBundleId = options.appIdentifier ?? app.identifier ?? ""
                editedVersion = options.appVersion ?? app.version ?? ""
            }
        }
    }

    private var header: some View {
        HStack {
            Text("Customize App")
                .font(.system(.title2, design: .rounded).bold())
            Spacer()
            Button("Done") {
                saveAndDismiss()
            }
            .font(.headline)
        }
        .padding(.horizontal)
    }

    private var appInfoSection: some View {
        VStack(spacing: 16) {
            FRAppIconView(app: app, size: 80)
                .shadow(radius: 10)

            VStack(spacing: 4) {
                Text(app.name ?? "Unknown")
                    .font(.headline)
                Text(app.identifier ?? "Unknown")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .padding(.horizontal)
    }

    private var modificationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("General")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
                .padding(.leading)

            VStack(spacing: 0) {
                customTextField(title: "App Name", text: $editedName)
                Divider().padding(.leading)
                customTextField(title: "Bundle ID", text: $editedBundleId)
                Divider().padding(.leading)
                customTextField(title: "Version", text: $editedVersion)
            }
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .padding(.horizontal)
        }
    }

    private var tweakSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tweaks & Files")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
                .padding(.leading)

            NavigationLink {
                SigningTweaksView(options: $options)
            } label: {
                HStack {
                    Image(systemName: "wrench.and.screwdriver.fill")
                        .foregroundStyle(.green)
                    Text("Injection Options")
                        .foregroundStyle(.primary)
                    Spacer()
                    if !options.injectionFiles.isEmpty {
                        Text("\(options.injectionFiles.count) Files")
                            .font(.caption.bold())
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.green.opacity(0.1), in: Capsule())
                            .foregroundStyle(.green)
                    }
                    Image(systemName: "chevron.right")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .padding(.horizontal)
            }
        }
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button {
                saveAndDismiss()
            } label: {
                Text("Apply Changes")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }

            Button {
                dismiss()
            } label: {
                Text("Discard")
                    .font(.subheadline.bold())
                    .foregroundStyle(.red)
            }
        }
        .padding(.horizontal)
        .padding(.top, 10)
    }

    private func customTextField(title: String, text: Binding<String>) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(width: 80, alignment: .leading)

            TextField(title, text: text)
                .font(.subheadline)
        }
        .padding()
    }

    private func saveAndDismiss() {
        if !editedName.isEmpty { options.appName = editedName }
        if !editedBundleId.isEmpty { options.appIdentifier = editedBundleId }
        if !editedVersion.isEmpty { options.appVersion = editedVersion }
        dismiss()
        onDismiss()
    }
}
