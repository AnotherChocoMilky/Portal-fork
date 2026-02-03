import SwiftUI
import CoreData

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
    @State private var showResults = false
    @State private var autoInstall = true
    @State private var currentPhase: BatchPhase = .signing
    @State private var installationIndex = 0
    @State private var signedAppsForInstall: [AppInfoPresentable] = []
    
    @AppStorage("Feather.installationMethod") private var installationMethod: Int = 0
    
    enum BatchPhase {
        case signing
        case installing
        case completed
    }
    
    struct BatchSignResult: Identifiable {
        let id = UUID()
        let appName: String
        let success: Bool
        let message: String
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                List {
                    // Certificate Selection
                    Section {
                        if certificates.isEmpty {
                            Text("No Certificates Available")
                                .foregroundStyle(.secondary)
                        } else {
                            Picker("Signing Certificate", selection: $selectedCertificateIndex) {
                                ForEach(Array(certificates.enumerated()), id: \.element.uuid) { index, cert in
                                    Text(cert.nickname ?? "Certificate \(index + 1)")
                                        .tag(index)
                                }
                            }
                        }
                    } header: {
                        Text("Certificate")
                    }
                    
                    // Auto Install Toggle
                    Section {
                        Toggle("Auto Install After Signing", isOn: $autoInstall)
                    } header: {
                        Text("Options")
                    } footer: {
                        Text("Automatically install apps after successful signing")
                    }

                    // App Selection
                    Section {
                        if apps.isEmpty {
                            Text("No Apps Available For Signing")
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(apps, id: \.uuid) { app in
                                BatchAppRow(
                                    app: app,
                                    isSelected: selectedApps.contains(app.uuid ?? ""),
                                    onToggle: {
                                        toggleAppSelection(app)
                                    }
                                )
                            }
                        }
                    } header: {
                        HStack {
                            Text("Select Apps (\(selectedApps.count) Selected)")
                            Spacer()
                            if !apps.isEmpty {
                                Button(selectedApps.count == apps.count ? "Deselect All" : "Select All") {
                                    withAnimation {
                                        if selectedApps.count == apps.count {
                                            selectedApps.removeAll()
                                        } else {
                                            selectedApps = Set(apps.compactMap { $0.uuid })
                                        }
                                    }
                                }
                                .font(.caption)
                            }
                        }
                    }

                    // Batch Action
                    Section {
                        Button {
                            startBatchSigning()
                        } label: {
                            HStack {
                                Image(systemName: "signature")
                                Text("Sign Selected Apps (\(selectedApps.count))")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .disabled(selectedApps.isEmpty || certificates.isEmpty || isSigningBatch)
                    } header: {
                        Text("Actions")
                    }
                    
                    // Results Section
                    if !batchResults.isEmpty {
                        Section {
                            ForEach(batchResults) { result in
                                HStack {
                                    Image(systemName: result.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                                        .foregroundStyle(result.success ? .green : .red)
                                    VStack(alignment: .leading) {
                                        Text(result.appName)
                                            .font(.subheadline)
                                        Text(result.message)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        } header: {
                            Text("Results")
                        }
                    }
                }
                
                // Progress Overlay
                if isSigningBatch {
                    ZStack {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()
                            .transition(.opacity)

                        VStack(spacing: 20) {
                            ProgressView(value: batchProgress)
                                .progressViewStyle(.circular)
                                .tint(.white)
                                .scaleEffect(1.5)

                            VStack(spacing: 8) {
                                Text(currentPhase == .signing ? "Signing Apps..." : "Installing Apps...")
                                    .font(.headline)
                                    .foregroundStyle(.white)

                                Text(currentSigningApp)
                                    .font(.subheadline)
                                    .foregroundStyle(.white.opacity(0.8))
                                    .lineLimit(1)

                                Text("\(Int(batchProgress * 100))%")
                                    .font(.caption.bold())
                                    .foregroundStyle(.white.opacity(0.6))
                            }
                        }
                        .padding(40)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                        .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
                        .transition(.scale.combined(with: .opacity))
                    }
                }
            }
            .navigationTitle("Batch Signing")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
    
    private func toggleAppSelection(_ app: AppInfoPresentable) {
        guard let id = app.uuid else { return }
        if selectedApps.contains(id) {
            selectedApps.remove(id)
        } else {
            selectedApps.insert(id)
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
                
                // Perform actual signing
                do {
                    let selectedCert = certificates[selectedCertificateIndex]
                    AppLogManager.shared.info("Signing app \(index + 1)/\(Int(totalApps)): \(app.name ?? "Unknown")", category: "BatchSign")
                    
                    try await SigningManager.shared.signApp(
                        app,
                        cert: selectedCert,
                        withOptions: OptionsManager.shared.options
                    )
                    
                    await MainActor.run {
                        let result = BatchSignResult(
                            appName: app.name ?? "Unknown",
                            success: true,
                            message: "Signed Successfully"
                        )
                        batchResults.append(result)
                        signedAppsForInstall.append(app)
                        AppLogManager.shared.success("Batch signing succeeded for \(app.name ?? "Unknown")", category: "BatchSign")
                    }
                } catch {
                    await MainActor.run {
                        let result = BatchSignResult(
                            appName: app.name ?? "Unknown",
                            success: false,
                            message: error.localizedDescription
                        )
                        batchResults.append(result)
                        AppLogManager.shared.error("Batch signing failed for \(app.name ?? "Unknown"): \(error.localizedDescription)", category: "BatchSign")
                    }
                }
            }

            await MainActor.run {
                batchProgress = 1.0
                AppLogManager.shared.success("Batch signing completed for \(Int(totalApps)) apps", category: "BatchSign")
            }
            
            // Start installation phase if autoInstall is enabled
            if autoInstall && !signedAppsForInstall.isEmpty {
                await startBatchInstallation()
            } else {
                await MainActor.run {
                    isSigningBatch = false
                    selectedApps.removeAll()
                    HapticsManager.shared.success()
                    ToastManager.shared.show("✅ Batch Signing Completed", type: .success)
                }
            }
        }
    }
    
    private func startBatchInstallation() async {
        await MainActor.run {
            currentPhase = .installing
            batchProgress = 0
        }
        
        let totalApps = Double(signedAppsForInstall.count)
        
        for (index, app) in signedAppsForInstall.enumerated() {
            await MainActor.run {
                currentSigningApp = app.name ?? "App \(index + 1)"
                batchProgress = Double(index) / totalApps
                installationIndex = index
            }
            
            AppLogManager.shared.info("Installing App \(index + 1)/\(Int(totalApps)): \(app.name ?? "Unknown")", category: "BatchSign")
            
            do {
                try await InstallationManager.shared.installApp(app, method: InstallationMethod(rawValue: installationMethod) ?? .auto)
                
                await MainActor.run {
                    if let resultIndex = batchResults.firstIndex(where: { $0.appName == (app.name ?? "Unknown") && $0.success }) {
                        batchResults[resultIndex] = BatchSignResult(
                            appName: app.name ?? "Unknown",
                            success: true,
                            message: "Signed and Installed Successfully"
                        )
                    }
                    AppLogManager.shared.success("Batch installation succeeded for \(app.name ?? "Unknown")", category: "BatchSign")
                }
            } catch {
                await MainActor.run {
                    if let resultIndex = batchResults.firstIndex(where: { $0.appName == (app.name ?? "Unknown") && $0.success }) {
                        batchResults[resultIndex] = BatchSignResult(
                            appName: app.name ?? "Unknown",
                            success: true,
                            message: "Signed Successfully, Installation Failed: \(error.localizedDescription)"
                        )
                    }
                    AppLogManager.shared.error("Batch installation failed for \(app.name ?? "Unknown"): \(error.localizedDescription)", category: "BatchSign")
                }
            }
        }
        
        await MainActor.run {
            isSigningBatch = false
            batchProgress = 1.0
            currentPhase = .completed
            selectedApps.removeAll()
            HapticsManager.shared.success()
            ToastManager.shared.show("✅ Batch Signing and Installation Completed", type: .success)
            AppLogManager.shared.success("Batch installation completed: \(Int(totalApps)) apps processed", category: "BatchSign")
        }
    }
}

// MARK: - Batch App Row
struct BatchAppRow: View {
    let app: AppInfoPresentable
    let isSelected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 12) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
                
                FRAppIconView(app: app, size: 40)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(app.name ?? "Unknown App")
                        .font(.subheadline.bold())
                        .foregroundStyle(.primary)
                    
                    Text(app.identifier ?? "Unknown Bundle ID")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
        }
        .buttonStyle(.plain)
    }
}
