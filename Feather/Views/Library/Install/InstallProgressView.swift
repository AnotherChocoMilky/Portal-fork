import SwiftUI
import IDeviceSwift

// MARK: - Redesigned Toaster Install Progress View
struct InstallProgressView: View {
    var app: AppInfoPresentable
    @ObservedObject var viewModel: InstallerStatusViewModel
    
    @State private var _pulseTrigger = false
    @State private var appearAnimation = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            HStack(spacing: 12) {
            // Compact App icon
            FRAppIconView(app: app, size: 40)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)

            VStack(alignment: .leading, spacing: 2) {
                Text(app.name ?? "App")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .lineLimit(1)

                statusLabel
            }

            Spacer()

            // Modern compact circular progress
            ZStack {
                Circle()
                    .stroke(Color.accentColor.opacity(0.15), lineWidth: 3)
                    .frame(width: 32, height: 32)

                Circle()
                    .trim(from: 0, to: viewModel.overallProgress)
                    .stroke(
                        viewModel.isCompleted ? Color.green : Color.accentColor,
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .frame(width: 32, height: 32)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(), value: viewModel.overallProgress)

                if viewModel.isCompleted {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.green)
                } else {
                    Text("\(Int(viewModel.overallProgress * 100))")
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        .padding(.horizontal, 16)
        Spacer()
        }
        .opacity(appearAnimation ? 1 : 0)
        .offset(y: appearAnimation ? 0 : 10)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                appearAnimation = true
            }
            _pulseTrigger = true
        }
    }
    
    @ViewBuilder
    private var statusLabel: some View {
        HStack(spacing: 4) {
            if viewModel.isCompleted {
                Text("Ready")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.green)
            } else if case .broken = viewModel.status {
                Text("Error")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.red)
            } else {
                Circle()
                    .fill(Color.accentColor)
                    .frame(width: 6, height: 6)
                    .pulseEffect(_pulseTrigger)

                Text(viewModel.statusLabel)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
    }
}
