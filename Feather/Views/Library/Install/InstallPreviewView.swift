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
            // Modern glass background with integrated Metal
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    MetalIntegratedStateView(state: $_metalState)
                        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                        .opacity(0.4)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(Color.primary.opacity(0.12), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
            
            VStack(spacing: 16) {
                InstallProgressView(app: app, viewModel: viewModel)
                    .scaleEffect(appearAnimation ? 1 : 0.9)
                    .opacity(appearAnimation ? 1 : 0)
                
                if _errorMessage == nil {
                    statusLabel
                        .offset(y: appearAnimation ? 0 : 10)
                        .opacity(appearAnimation ? 1 : 0)
                } else {
                    errorLabel
                }
                
                actionButtons
                    .offset(y: appearAnimation ? 0 : 15)
                    .opacity(appearAnimation ? 1 : 0)
            }
            .padding(20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .padding(24)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
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
    
    // MARK: - Error Label
    @ViewBuilder
    private var errorLabel: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.white)

            Text(_errorMessage ?? "Unknown Error")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white)
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(Color.red)
        )
        .transition(.scale.combined(with: .opacity))
        .onTapGesture {
            withAnimation {
                _errorMessage = nil
                _metalState = .idle
            }
        }
    }

    // MARK: - Status Label
    @ViewBuilder
    private var statusLabel: some View {
        HStack(spacing: 8) {
            Image(systemName: viewModel.statusImage)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(statusColor)
            
            Text(viewModel.statusLabel)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(statusColor.opacity(0.1))
        )
        .animation(.easeInOut(duration: 0.3), value: viewModel.statusImage)
    }
    
    private var statusColor: Color {
        if viewModel.isCompleted {
            return .green
        } else if case .broken = viewModel.status {
            return .red
        }
        return .accentColor
    }
    
    // MARK: - Action Buttons
    @ViewBuilder
    private var actionButtons: some View {
        if viewModel.isCompleted {
            if fromLibraryTab {
                Button {
                    UIApplication.openApp(with: app.identifier ?? "")
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.up.forward.app.fill")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Open")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            colors: [.green, .green.opacity(0.85)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(Capsule())
                    .shadow(color: .green.opacity(0.4), radius: 10, x: 0, y: 5)
                }
                .transition(AnyTransition.scale.combined(with: .opacity))
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
                                .font(.system(size: 13, weight: .semibold))
                            Text("Modify")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 10)
                        .background(
                            LinearGradient(
                                colors: [Color.accentColor, Color.accentColor.opacity(0.85)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(Capsule())
                        .shadow(color: Color.accentColor.opacity(0.35), radius: 8, x: 0, y: 4)
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
                                .font(.system(size: 13, weight: .semibold))
                            Text("Install")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 10)
                        .background(
                            LinearGradient(
                                colors: [.green, .green.opacity(0.85)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(Capsule())
                        .shadow(color: .green.opacity(0.35), radius: 8, x: 0, y: 4)
                    }
                }
                .transition(AnyTransition.scale.combined(with: .opacity))
            }
        }
    }
    
    // MARK: - Install logic to avoid signing the app with the same app
    private func _install() {
        guard isSharing || app.identifier != Bundle.main.bundleIdentifier! || _installationMethod == 1 else {
            UIAlertController.showAlertWithOk(
                title: .localized("Install"),
                message: .localized("You cannot update '%@' with itself, please use an alternative tool to update it like a online signer or diffrent app.", arguments: Bundle.main.name)
            )
            return
        }
        
        Task.detached {
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.4)) {
                    _metalState = .loading
                }
            }

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
                    
                    if await !_useShareSheet {
                        await MainActor.run {
                            _metalState = .success
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                dismiss()
                            }
                        }
                    } else {
                        if let package {
                            await MainActor.run {
                                _metalState = .success
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                    dismiss()
                                    UIActivityViewController.show(activityItems: [package])
                                }
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
        case .none:
            break
        case .ready:
            _metalState = .success
        case .sendingManifest, .sendingPayload, .installing:
            _metalState = .loading
        case .completed(_):
            _metalState = .success
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                dismiss()
            }
        case .broken(let error):
            _errorMessage = error.localizedDescription
            _metalState = .error
        }
    }
}

// MARK: - Helper ViewModifier for iOS 16 compatibility
struct ContentTransitionModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
            content
                .contentTransition(.symbolEffect)
        } else {
            content
                .animation(.easeInOut(duration: 0.2), value: UUID())
        }
    }
}
