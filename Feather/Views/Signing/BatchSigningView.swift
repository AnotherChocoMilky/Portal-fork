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
    @AppStorage("Feather.batchSigning.autoInstall") private var autoInstall = true
    @State private var currentPhase: BatchPhase = .signing
    @State private var signedAppsForInstall: [AppInfoPresentable] = []
    
    @State private var appOptions: [String: Options] = [:]
    @State private var editingAppId: String? = nil
    @State private var showEditSheet = false
    
    @AppStorage("Feather.installationMethod") private var installationMethod: Int = 0
    @AppStorage("Feather.serverMethod") private var _serverMethod: Int = 0
    
    enum BatchPhase { case signing, installing, completed }
    
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
                List {
                    certificateSection
                    optionsSection
                    appSelectionSection
                    if !batchResults.isEmpty { resultsSection }
                }
                .listStyle(.insetGrouped)
                .navigationTitle("Batch Signing")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button { dismiss() } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                                .symbolRenderingMode(.hierarchical)
                                .font(.title3)
                        }
                    }
                }
                .safeAreaInset(edge: .bottom) { actionSection }

                if isSigningBatch { progressOverlay }
            }
            .sheet(isPresented: $showEditSheet) {
                if let appId = editingAppId,
                   let app = apps.first(where: { $0.uuid == appId }) {
                    BatchAppEditSheet(
                        app: app,
                        options: Binding(
                            get: { appOptions[appId] ?? createDefaultOptions(for: app) },
                            set: { appOptions[appId] = $0 }
                        ),
                        onDismiss: { showEditSheet = false }
                    )
                }
            }
        }
    }

    // MARK: - Certificate Section

    private var certificateSection: some View {
        Section {
            if certificates.isEmpty {
                Label("No Certificates Available", systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                    .font(.subheadline)
            } else {
                Picker("Certificate", selection: $selectedCertificateIndex) {
                    ForEach(Array(certificates.enumerated()), id: \.element.uuid) { index, cert in
                        Text(cert.nickname ?? "Certificate \(index + 1)").tag(index)
                    }
                }
                .pickerStyle(.menu)
            }
        } header: {
            Label("Certificate", systemImage: "seal.fill")
                .textCase(nil)
                .font(.caption.bold())
        }
    }

    // MARK: - Options Section

    private var optionsSection: some View {
        Section {
            Toggle(isOn: $autoInstall) {
                Label("Auto Install After Signing", systemImage: "arrow.down.app.fill")
                    .font(.subheadline)
            }
            .tint(.accentColor)
        } header: {
            Label("Options", systemImage: "slider.horizontal.3")
                .textCase(nil)
                .font(.caption.bold())
        }
    }

    // MARK: - App Selection Section

    private var appSelectionSection: some View {
        Section {
            if apps.isEmpty {
                Text("No Apps Available")
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
            } else {
                ForEach(apps, id: \.uuid) { app in
                    appSelectionRow(for: app)
                }
            }
        } header: {
            HStack {
                Label("Apps (\(selectedApps.count)/\(apps.count))", systemImage: "square.stack.fill")
                    .textCase(nil)
                    .font(.caption.bold())
                Spacer()
                Button(selectedApps.count == apps.count ? "Deselect All" : "Select All") {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        if selectedApps.count == apps.count {
                            selectedApps.removeAll()
                        } else {
                            selectedApps = Set(apps.compactMap { $0.uuid })
                        }
                    }
                }
                .font(.caption.bold())
                .foregroundStyle(.accentColor)
                .textCase(nil)
            }
        }
    }

    @ViewBuilder
    private func appSelectionRow(for app: AppInfoPresentable) -> some View {
        HStack(spacing: 12) {
            Button { toggleAppSelection(app) } label: {
                HStack(spacing: 12) {
                    Image(systemName: selectedApps.contains(app.uuid ?? "") ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 20))
                        .foregroundStyle(selectedApps.contains(app.uuid ?? "") ? Color.accentColor : Color.secondary.opacity(0.4))
                        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: selectedApps.contains(app.uuid ?? ""))

                    FRAppIconView(app: app, size: 36)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                    VStack(alignment: .leading, spacing: 1) {
                        Text(app.name ?? "Unknown App")
                            .font(.subheadline.weight(.semibold))
                            .lineLimit(1)
                        Text(app.identifier ?? "")
                            .font(.caption.monospaced())
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }
            .buttonStyle(.plain)

            Spacer()

            Button {
                editingAppId = app.uuid
                showEditSheet = true
            } label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(appOptions[app.uuid ?? ""] != nil ? .white : .accentColor)
                    .padding(7)
                    .background(appOptions[app.uuid ?? ""] != nil ? Color.orange : Color.accentColor.opacity(0.12), in: Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 2)
    }

    // MARK: - Results Section

    private var resultsSection: some View {
        Section {
            ForEach(batchResults) { result in
                resultRow(for: result)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 4, leading: 12, bottom: 4, trailing: 12))
            }

            if batchResults.contains(where: { $0.success && $0.installLink != nil }) {
                Button { installAllSigned() } label: {
                    Label("Install All Signed", systemImage: "arrow.down.circle.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.borderedProminent)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
            }
        } header: {
            Label("Results", systemImage: "checkmark.seal.fill")
                .textCase(nil)
                .font(.caption.bold())
        }
    }

    @ViewBuilder
    private func resultRow(for result: BatchSignResult) -> some View {
        HStack(spacing: 10) {
            if let app = result.app {
                FRAppIconView(app: app, size: 40)
                    .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .fill(Color(UIColor.secondarySystemFill))
                        .frame(width: 40, height: 40)
                    Image(systemName: "app.badge.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(.secondary)
                }
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(result.appName)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .lineLimit(1)
                HStack(spacing: 4) {
                    Image(systemName: result.success ? "checkmark.circle.fill" : "xmark.octagon.fill")
                        .font(.caption2)
                        .foregroundStyle(result.success ? .green : .red)
                    Text(result.message)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            if result.success, let link = result.installLink {
                Button {
                    if let url = URL(string: link) { UIApplication.shared.open(url) }
                } label: {
                    Image(systemName: "arrow.down.to.line.circle.fill")
                        .font(.system(size: 22))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.blue)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        )
        .transition(.asymmetric(insertion: .push(from: .bottom).combined(with: .opacity), removal: .opacity))
    }

    // MARK: - Action Section

    private var actionSection: some View {
        VStack(spacing: 0) {
            Divider()
            Button { startBatchSigning() } label: {
                HStack(spacing: 8) {
                    Image(systemName: "signature")
                    Text(selectedApps.isEmpty ? "Select Apps to Sign" : "Sign \(selectedApps.count) App\(selectedApps.count == 1 ? "" : "s")")
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(canSign ? Color.accentColor : Color.secondary.opacity(0.3))
                .foregroundStyle(canSign ? .white : Color.secondary)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(color: canSign ? Color.accentColor.opacity(0.25) : .clear, radius: 8, y: 4)
            }
            .disabled(!canSign)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(.ultraThinMaterial)
    }

    private var canSign: Bool {
        !selectedApps.isEmpty && !certificates.isEmpty && !isSigningBatch
    }

    // MARK: - Progress Overlay

    private var progressOverlay: some View {
        ZStack {
            Color.black.opacity(0.35)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .stroke(Color.accentColor.opacity(0.15), lineWidth: 6)
                        .frame(width: 88, height: 88)
                    Circle()
                        .trim(from: 0, to: batchProgress)
                        .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .frame(width: 88, height: 88)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.3), value: batchProgress)

                    VStack(spacing: 1) {
                        Text("\(Int(batchProgress * 100))%")
                            .font(.system(.title3, design: .rounded).bold())
                        Text(currentPhase == .signing ? "Signing" : "Installing")
                            .font(.system(size: 9, weight: .bold))
                            .textCase(.uppercase)
                            .foregroundStyle(.secondary)
                            .tracking(0.5)
                    }
                }

                VStack(spacing: 6) {
                    Text(currentSigningApp)
                        .font(.system(size: 15, weight: .semibold))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                    Text(currentPhase == .signing ? "Signing in progress…" : "Installing…")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(28)
            .frame(width: 260)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
            .shadow(color: .black.opacity(0.18), radius: 24, x: 0, y: 8)
        }
        .transition(.opacity)
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
            Form {
                Section {
                    HStack(spacing: 12) {
                        FRAppIconView(app: app, size: 52)
                            .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(app.name ?? "Unknown")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                            Text(app.identifier ?? "Unknown")
                                .font(.system(size: 12, weight: .medium, design: .monospaced))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("Identifier & Build") {
                    TextField("App Name", text: $editedName)
                    TextField("Bundle ID", text: $editedBundleId)
                        .keyboardType(.URL)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    TextField("Version", text: $editedVersion)
                }

                Section {
                    NavigationLink {
                        SigningTweaksView(options: $options)
                    } label: {
                        Label("Injection Options", systemImage: "wrench.and.screwdriver.fill")
                            .foregroundStyle(.primary)
                            .badge(options.injectionFiles.count > 0 ? "\(options.injectionFiles.count)" : "")
                    }
                } header: {
                    Text("Tweaks & Files")
                }

                Section {
                    Button(action: saveAndDismiss) {
                        Text("Apply Changes")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                    .padding(.vertical, 4)

                    Button(role: .destructive) { dismiss() } label: {
                        Text("Discard")
                            .frame(maxWidth: .infinity)
                    }
                    .listRowBackground(Color.clear)
                }
            }
            .navigationTitle("Customize App")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                editedName = options.appName ?? app.name ?? ""
                editedBundleId = options.appIdentifier ?? app.identifier ?? ""
                editedVersion = options.appVersion ?? app.version ?? ""
            }
        }
    }

    private func saveAndDismiss() {
        if !editedName.isEmpty { options.appName = editedName }
        if !editedBundleId.isEmpty { options.appIdentifier = editedBundleId }
        if !editedVersion.isEmpty { options.appVersion = editedVersion }
        dismiss()
        onDismiss()
    }
}
