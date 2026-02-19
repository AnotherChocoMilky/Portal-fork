import SwiftUI
import IDeviceSwift

// MARK: - Compact Install Progress View
struct InstallProgressView: View {
    var app: AppInfoPresentable
    @ObservedObject var viewModel: InstallerStatusViewModel
    
    @State private var _metalState: MetalAnimationState = .idle

    var body: some View {
        HStack(spacing: 12) {
            // App icon - simple, no effects
            FRAppIconView(app: app, size: 44)
            
            // Status label with symbol
            statusLabel
        }
        .padding(12)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground).opacity(0.4))

                MetalIntegratedStateView(state: $_metalState)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .opacity(0.2)
            }
        )
        .onChange(of: viewModel.status) { newStatus in
            _updateMetalState(newStatus)
        }
        .onAppear {
            _updateMetalState(viewModel.status)
        }
    }

    private func _updateMetalState(_ status: InstallerStatusViewModel.InstallerStatus) {
        switch status {
        case .none:
            _metalState = .idle
        case .sendingManifest, .sendingPayload, .installing:
            _metalState = .loading
        case .ready, .completed(_):
            _metalState = .success
        case .broken(_):
            _metalState = .error
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
                MetalLoadingIndicator(size: 20)
                Text(viewModel.statusLabel)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
    }

}
