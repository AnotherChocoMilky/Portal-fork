import SwiftUI
import IDeviceSwift

// MARK: - Compact Install Progress View
struct InstallProgressView: View {
    var app: AppInfoPresentable
    @ObservedObject var viewModel: InstallerStatusViewModel
    @State private var _metalState: MetalAnimationState = .idle
    @State private var _errorMessage: String? = nil
    
    var body: some View {
        HStack(spacing: 12) {
            // App icon - simple, no effects
            FRAppIconView(app: app, size: 44)
            
            // Status label with symbol
            statusLabel
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .overlay {
            FullScreenMetalStateView(state: $_metalState, errorMessage: _errorMessage)
                .ignoresSafeArea()
        }
        .onChange(of: viewModel.status) { newStatus in
            _handleStatusChange(newStatus)
        }
    }
    
    // MARK: - Status Label
    @ViewBuilder
    private var statusLabel: some View {
        HStack(spacing: 6) {
            if viewModel.isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.green)
                Text("Installed")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.green)
            } else if case .broken = viewModel.status {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.red)
                Text("Failed")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.red)
            } else {
                ProgressView()
                    .scaleEffect(0.8)
                Text(viewModel.statusLabel)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
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
        case .broken(_):
            _errorMessage = "Installation failed. Integrity could not be verified."
            _metalState = .error
        }
    }
}
