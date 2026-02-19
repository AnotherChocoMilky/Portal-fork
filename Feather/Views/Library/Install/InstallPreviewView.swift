import SwiftUI
import NimbleViews
import IDeviceSwift

// MARK: - Modern Install Preview View
struct InstallPreviewView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    @AppStorage("Feather.useShareSheetForArchiving") private var _useShareSheet: Bool = false
    @AppStorage("Feather.installationMethod") private var _installationMethod: Int = 0
    @AppStorage("Feather.serverMethod") private var _serverMethod: Int = 0
    @State private var _isWebviewPresenting = false
    @State private var appearAnimation = false
    @State private var _contentOpacity: Double = 1.0
    @State private var _metalState: MetalAnimationState = .idle
    @State private var _errorMessage: String? = nil
    
    var app: AppInfoPresentable
    @StateObject var viewModel: InstallerStatusViewModel
    @StateObject var installer: ServerInstaller
    
    @State var isSharing: Bool
    @State var fromLibraryTab: Bool = true
    
    init(app: AppInfoPresentable, isSharing: Bool = false, fromLibraryTab: Bool = true) {
        self.app = app
        self.isSharing = isSharing
        self.fromLibraryTab = fromLibraryTab
        let viewModel = InstallerStatusViewModel(isIdevice: UserDefaults.standard.integer(forKey: "Feather.installationMethod") == 1)
        self._viewModel = StateObject(wrappedValue: viewModel)
        self._installer = StateObject(wrappedValue: try! ServerInstaller(app: app, viewModel: viewModel))
    }
    
    var body: some View {
        ZStack {
            // Full-screen Metal background for the card
            ZStack {
                MetalIntegratedStateView(state: $_metalState)
                    .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
                    .ignoresSafeArea()

                // Glass overlay to make text readable but keep the metal noticeable
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .fill(.ultraThinMaterial.opacity(0.6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 32, style: .continuous)
                            .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                    )
            }
            .shadow(color: .black.opacity(0.2), radius: 25, x: 0, y: 15)
            .padding(16)
            
            VStack(spacing: 24) {
                Spacer()
                
                // Elevated App Icon Section
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Color.accentColor.opacity(0.15))
                            .frame(width: 100, height: 100)
                            .blur(radius: 20)

                        FRAppIconView(app: app, size: 80)
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                            .shadow(color: .black.opacity(0.2), radius: 12, x: 0, y: 6)
                            .scaleEffect(appearAnimation ? 1 : 0.8)
                    }

                    VStack(spacing: 4) {
                        Text(app.name ?? "Unknown App")
                            .font(.system(size: 22, weight: .bold, design: .rounded))

                        Text(app.identifier ?? "")
                            .font(.system(size: 13, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }
                }
                
                // Progress and Status
                VStack(spacing: 12) {
                    if let error = _errorMessage {
                        errorLabel(error)
                    } else {
                        statusBadge
                    }

                    InstallProgressCompactView(viewModel: viewModel)
                        .padding(.horizontal, 40)
                }

                Spacer()

                // Actions
                actionButtons
                    .padding(.bottom, 20)
            }
            .padding(32)
            .opacity(appearAnimation ? 1 : 0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                appearAnimation = true
            }
            _install()
            BackgroundAudioManager.shared.start()
        }
        .onDisappear {
            BackgroundAudioManager.shared.stop()
        }
        .sheet(isPresented: $_isWebviewPresenting) {
            SafariRepresentableView(url: installer.pageEndpoint).ignoresSafeArea()
        }
        .onChange(of: viewModel.status) { newStatus in
            _handleStatusChange(newStatus)
        }
        .onReceive(viewModel.$status) { newStatus in
            if _installationMethod == 0 {
                if case .ready = newStatus {
                    if _serverMethod == 0 {
                        UIApplication.shared.open(URL(string: installer.iTunesLink)!)
                    } else if _serverMethod == 1 || _serverMethod == 2 {
                        _isWebviewPresenting = true
                    }
                }
                
                if case .sendingPayload = newStatus, (_serverMethod == 1 || _serverMethod == 2) {
                    _isWebviewPresenting = false
                }
                
                if case .completed = newStatus {
                    BackgroundAudioManager.shared.stop()
                }
            }
        }
    }
    
    private var statusBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: viewModel.statusImage)
                .bounceEffect(viewModel.status)
            Text(viewModel.statusLabel)
                .font(.system(size: 14, weight: .semibold))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Capsule().fill(Color.accentColor.opacity(0.1)))
        .foregroundStyle(Color.accentColor)
    }

    @ViewBuilder
    private func errorLabel(_ message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
            Text(message)
                .font(.system(size: 13, weight: .bold))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Capsule().fill(Color.red.opacity(0.2)))
        .foregroundStyle(.red)
        .onTapGesture {
            withAnimation {
                _errorMessage = nil
                _metalState = .loading
                _install()
            }
        }
    }
    
    @ViewBuilder
    private var actionButtons: some View {
        if viewModel.isCompleted {
            if fromLibraryTab {
                Button {
                    UIApplication.openApp(with: app.identifier ?? "")
                } label: {
                    Text("Open App")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.green)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .shadow(color: .green.opacity(0.3), radius: 10, x: 0, y: 5)
                }
                .padding(.horizontal, 20)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            } else {
                HStack(spacing: 12) {
                    Button {
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            NotificationCenter.default.post(
                                name: Notification.Name("Feather.openSigningView"),
                                object: app
                            )
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "pencil")
                            Text("Modify")
                        }
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.accentColor)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    
                    Button {
                        viewModel.status = .none
                        viewModel.uploadProgress = 0
                        viewModel.packageProgress = 0
                        viewModel.installProgress = 0
                        _install()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.down.circle.fill")
                            Text("Install")
                        }
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.green)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                }
                .padding(.horizontal, 20)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        } else if _errorMessage != nil {
            Button {
                dismiss()
            } label: {
                Text("Close")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    private func _install() {
        guard isSharing || app.identifier != Bundle.main.bundleIdentifier! || _installationMethod == 1 else {
            UIAlertController.showAlertWithOk(
                title: .localized("Install"),
                message: .localized("You cannot update '%@' with itself, please use an alternative tool to update it like a online signer or diffrent app.", arguments: Bundle.main.name)
            )
            return
        }
        
        Task.detached {
            await MainActor.run { _metalState = .loading }

            do {
                let handler = await ArchiveHandler(app: app, viewModel: viewModel)
                try await handler.move()
                let packageUrl = try await handler.archive()
                
                if await !isSharing {
                    if await _installationMethod == 0 {
                        await MainActor.run {
                            _metalState = .success
                            installer.packageUrl = packageUrl
                            viewModel.status = .ready
                        }
                    } else if await _installationMethod == 1 {
                        let handler = await InstallationProxy(viewModel: viewModel)
                        try await handler.install(at: packageUrl, suspend: app.identifier == Bundle.main.bundleIdentifier!)
                        await MainActor.run { _metalState = .success }
                    }
                } else {
                    let package = try await handler.moveToArchive(packageUrl, shouldOpen: !_useShareSheet)
                    await MainActor.run {
                        _metalState = .success
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            dismiss()
                            if _useShareSheet, let package {
                                UIActivityViewController.show(activityItems: [package])
                            }
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    _errorMessage = error.localizedDescription
                    _metalState = .error
                }
            }
        }
    }

    private func _handleStatusChange(_ status: InstallerStatusViewModel.InstallerStatus) {
        switch status {
        case .none: break
        case .ready: _metalState = .success
        case .sendingManifest, .sendingPayload, .installing: _metalState = .loading
        case .completed(_):
            _metalState = .success
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { dismiss() }
        case .broken(let error):
            _errorMessage = error.localizedDescription
            _metalState = .error
        }
    }
}

struct InstallProgressCompactView: View {
    @ObservedObject var viewModel: InstallerStatusViewModel

    var body: some View {
        VStack(spacing: 8) {
            ProgressView(value: viewModel.overallProgress)
                .tint(viewModel.isCompleted ? .green : .accentColor)
                .scaleEffect(x: 1, y: 1.5, anchor: .center)

            if viewModel.overallProgress > 0 && viewModel.overallProgress < 1 {
                Text("\(Int(viewModel.overallProgress * 100))%")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
        }
        .animation(.spring(), value: viewModel.overallProgress)
    }
}
