import SwiftUI
import IDeviceSwift

// MARK: - Redesigned Install Progress View
struct InstallProgressView: View {
    var app: AppInfoPresentable
    @ObservedObject var viewModel: InstallerStatusViewModel
    
    @State private var _metalState: MetalAnimationState = .idle
    @State private var _pulseTrigger = false

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                // Background Metal Animation
                MetalIntegratedStateView(state: $_metalState)
                    .frame(height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(Color.primary.opacity(0.05), lineWidth: 1)
                    )

                HStack(spacing: 20) {
                    // App icon with heavy shadow
                    FRAppIconView(app: app, size: 64)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 5)

                    VStack(alignment: .leading, spacing: 8) {
                        Text(app.name ?? "App")
                            .font(.system(size: 18, weight: .bold, design: .rounded))

                        statusLabel
                    }

                    Spacer()
                }
                .padding(.horizontal, 24)
            }

            // Modern progress bar
            VStack(spacing: 6) {
                ProgressView(value: viewModel.overallProgress)
                    .tint(viewModel.isCompleted ? .green : .accentColor)

                HStack {
                    Text(viewModel.statusLabel)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)

                    Spacer()

                    Text("\(Int(viewModel.overallProgress * 100))%")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 8)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .onChange(of: viewModel.status) { newStatus in
            _updateMetalState(newStatus)
        }
        .onAppear {
            _updateMetalState(viewModel.status)
            _pulseTrigger = true
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
    
    @ViewBuilder
    private var statusLabel: some View {
        HStack(spacing: 6) {
            if viewModel.isCompleted {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundStyle(.green)
                Text("Ready")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.green)
            } else if case .broken = viewModel.status {
                Image(systemName: "xmark.octagon.fill")
                    .foregroundStyle(.red)
                Text("Error")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.red)
            } else {
                Circle()
                    .fill(Color.accentColor)
                    .frame(width: 8, height: 8)
                    .pulseEffect(_pulseTrigger)

                Text("In Progress")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.accentColor)
            }
        }
    }
}
