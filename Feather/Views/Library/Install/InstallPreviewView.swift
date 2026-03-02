import SwiftUI
import NimbleViews
import IDeviceSwift

// MARK: - Modern Floating Install Preview View
struct InstallPreviewView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    @AppStorage("Feather.useShareSheetForArchiving") private var _useShareSheet: Bool = false
    @AppStorage("Feather.installationMethod") private var _installationMethod: Int = 0
    @AppStorage("Feather.serverMethod") private var _serverMethod: Int = 0
    @State private var _isWebviewPresenting = false
    @State private var appearAnimation = false
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
            Color.black.opacity(0.1)
                .ignoresSafeArea()
                .onTapGesture {
                    if viewModel.isCompleted || _errorMessage != nil {
                        dismiss()
                    }
                }

            VStack {
                Spacer()

                // Floating Container
                VStack(spacing: 0) {
                    // 1. App Icon
                    FRAppIconView(app: app, size: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                        .padding(.top, 36)
                        .padding(.bottom, 20)

                    // 2. App Name
                    Text(app.name ?? "Unknown App")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 24)

                    // 3. Progress Bar
                    if !viewModel.isCompleted && _errorMessage == nil {
                        InstallProgressBar(progress: viewModel.overallProgress)
                            .frame(height: 6)
                            .padding(.horizontal, 32)
                            .padding(.bottom, 16)
                    }

                    // 4. Status Label
                    HStack(spacing: 8) {
                        if let error = _errorMessage {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(.red)
                            Text(error)
                                .font(.system(size: 15, weight: .medium, design: .rounded))
                                .foregroundStyle(.red)
                                .lineLimit(1)
                        } else {
                            if !viewModel.isCompleted {
                                ProgressView()
                                    .controlSize(.small)
                            } else {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundStyle(.green)
                            }

                            Text(viewModel.statusLabel)
                                .font(.system(size: 15, weight: .medium, design: .rounded))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.bottom, (viewModel.isCompleted || _errorMessage != nil) ? 20 : 36)

                    // Action Buttons
                    if viewModel.isCompleted || _errorMessage != nil {
                        VStack(spacing: 12) {
                            if viewModel.isCompleted {
                                Button {
                                    if fromLibraryTab {
                                        UIApplication.openApp(with: app.identifier ?? "")
                                    } else {
                                        dismiss()
                                    }
                                } label: {
                                    HStack {
                                        Image(systemName: fromLibraryTab ? "play.fill" : "checkmark")
                                        Text(fromLibraryTab ? "Open App" : "Done")
                                    }
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(Color.accentColor)
                                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                }
                            } else if _errorMessage != nil {
                                Button {
                                    dismiss()
                                } label: {
                                    HStack {
                                        Image(systemName: "xmark")
                                        Text("Close")
                                    }
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(Color.red)
                                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                }
                            }
                        }
                        .padding(.horizontal, 32)
                        .padding(.bottom, 36)
                    }
                }
                .frame(maxWidth: 400) // Max width for larger devices
                .background {
                    RoundedRectangle(cornerRadius: 32, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    colorScheme == .dark ? Color(UIColor.secondarySystemGroupedBackground) : .white,
                                    colorScheme == .dark ? Color(UIColor.systemGroupedBackground) : Color(UIColor.secondarySystemBackground)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: .black.opacity(0.12), radius: 30, x: 0, y: 15)
                }
                .padding(.horizontal, 24) // Outer padding for all sizes

                Spacer()
            }
        }
        .opacity(appearAnimation ? 1 : 0)
        .offset(y: appearAnimation ? 0 : 20)
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
                    } else if _serverMethod == 3 {
                        UIApplication.shared.open(URL(string: installer.iTunesLinkExternal)!)
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
    
    private func _install() {
        guard isSharing || app.identifier != Bundle.main.bundleIdentifier! || _installationMethod == 1 else {
            UIAlertController.showAlertWithOk(
                title: .localized("Install"),
                message: .localized("You cannot update '%@' with itself, please use an alternative tool to update it like a online signer or diffrent app.", arguments: Bundle.main.name)
            )
            return
        }
        
        Task.detached {
            do {
                let handler = await ArchiveHandler(app: app, viewModel: viewModel)
                try await handler.move()
                let packageUrl = try await handler.archive()
                
                if await !isSharing {
                    if await _installationMethod == 0 {
                        await MainActor.run {
                            installer.packageUrl = packageUrl
                            viewModel.status = .ready
                        }
                    } else if await _installationMethod == 1 {
                        let handler = await InstallationProxy(viewModel: viewModel)
                        do {
                            try await handler.install(at: packageUrl, suspend: app.identifier == Bundle.main.bundleIdentifier!)
                        } catch {
                            await MainActor.run {
                                _errorMessage = error.localizedDescription
                                viewModel.status = .broken(error)
                            }
                        }
                    }
                } else {
                    let package = try await handler.moveToArchive(packageUrl, shouldOpen: !_useShareSheet)
                    await MainActor.run {
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
                }
            }
        }
    }

    private func _handleStatusChange(_ status: InstallerStatusViewModel.InstallerStatus) {
        switch status {
        case .none, .ready, .sendingManifest, .sendingPayload, .installing: break
        case .completed(_):
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                if !fromLibraryTab {
                    dismiss()
                }
            }
        case .broken(let error):
            _errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Local Modern Progress Bar
struct InstallProgressBar: View {
    let progress: Double

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.primary.opacity(0.06))

                Capsule()
                    .fill(Color.accentColor)
                    .frame(width: geo.size.width * CGFloat(min(max(progress, 0), 1)))
                    .animation(.spring(response: 0.5, dampingFraction: 0.8), value: progress)
            }
        }
    }
}
