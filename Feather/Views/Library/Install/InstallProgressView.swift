import SwiftUI
import IDeviceSwift

// MARK: - Modern Floating Install Progress View
struct InstallProgressView: View {
    var app: AppInfoPresentable
    @ObservedObject var viewModel: InstallerStatusViewModel
    @Environment(\.colorScheme) var colorScheme
    
    @State private var appearAnimation = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.1)
                .ignoresSafeArea()

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
                    Text(app.name ?? "App")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 24)

                    // 3. Progress Bar
                    if !viewModel.isCompleted && !isErrorState {
                        InstallProgressBar(progress: viewModel.overallProgress)
                            .frame(height: 6)
                            .padding(.horizontal, 32)
                            .padding(.bottom, 16)
                    }

                    // 4. Status Label
                    HStack(spacing: 8) {
                        if isErrorState {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(.red)
                            Text("Error")
                                .font(.system(size: 15, weight: .medium, design: .rounded))
                                .foregroundStyle(.red)
                        } else if viewModel.isCompleted {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(.green)
                            Text("Ready")
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .foregroundStyle(.green)
                        } else {
                            ProgressView()
                                .controlSize(.small)

                            Text(viewModel.statusLabel)
                                .font(.system(size: 15, weight: .medium, design: .rounded))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.bottom, 36)
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
        }
    }
    
    private var isErrorState: Bool {
        if case .broken = viewModel.status {
            return true
        }
        return false
    }
}
