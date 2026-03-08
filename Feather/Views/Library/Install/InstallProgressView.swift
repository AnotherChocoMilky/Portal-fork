
import SwiftUI
import IDeviceSwift

enum InstallSource {
    case source(name: String)
    case userImported
}

struct InstallProgressView<Footer: View>: View {
    @State private var _isPulsing = false
    @State private var _installStarted = false
    @State private var _appeared = false
    @State private var _appSizeString: String = ""

    var app: AppInfoPresentable
    @ObservedObject var viewModel: InstallerStatusViewModel
    var installSource: InstallSource
    let footer: () -> Footer

    var onInstall: (() -> Void)?
    var onOpen: (() -> Void)?

    init(
        app: AppInfoPresentable,
        viewModel: InstallerStatusViewModel,
        installSource: InstallSource = .userImported,
        onInstall: (() -> Void)? = nil,
        onOpen: (() -> Void)? = nil,
        @ViewBuilder footer: @escaping () -> Footer = { EmptyView() }
    ) {
        self.app = app
        self.viewModel = viewModel
        self.installSource = installSource
        self.onInstall = onInstall
        self.onOpen = onOpen
        self.footer = footer
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {}

            VStack {
                Spacer()
                _sheetCard()
                    .offset(y: _appeared ? 0 : 300)
                    .animation(.spring(response: 0.45, dampingFraction: 0.85), value: _appeared)
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 8)
        }
        .onAppear {
            _isPulsing = true
            _computeAppSize()
            withAnimation {
                _appeared = true
            }
        }
    }

    @ViewBuilder
    private func _sheetCard() -> some View {
        VStack(spacing: 0) {
            _headerRow()
                .padding(.bottom, 16)

            _appInfoCard()
                .padding(.bottom, 8)

            Divider()
                .opacity(0.3)
                .padding(.vertical, 8)

            _actionArea()
                .padding(.top, 4)
        }
        .padding(22)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: -5)
    }

    @ViewBuilder
    private func _headerRow() -> some View {
        HStack {
            Text("Install App")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.primary)

            Spacer()

            footer()
        }
    }

    @ViewBuilder
    private func _appInfoCard() -> some View {
        HStack(spacing: 14) {
            _appIcon()

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(app.name ?? "App")
                        .font(.headline)
                        .bold()
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    if !_appSizeString.isEmpty {
                        Text(_appSizeString)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color(.systemGray5))
                            .cornerRadius(4)
                    }
                }

                _sourceLabel()

                if let bundleID = app.identifier {
                    Text("Bundle ID: \(bundleID)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(15)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    @ViewBuilder
    private func _sourceLabel() -> some View {
        switch installSource {
        case .source(let name):
            Text(name)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(1)
        case .userImported:
            Text("User Imported")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
    }

    @ViewBuilder
    private func _actionArea() -> some View {
        if viewModel.isCompleted {
            _completedSection()
        } else if _installStarted && viewModel.isInProgress {
            if viewModel.status == .none {
                _packagingSection()
            } else {
                _progressSection()
            }
        } else {
            _installButton()
        }
    }

    @ViewBuilder
    private func _packagingSection() -> some View {
        VStack(spacing: 6) {
            Text(viewModel.statusLabel)
                .font(.caption)
                .foregroundColor(.secondary)

            ProgressView()
                .progressViewStyle(.circular)
                .scaleEffect(0.8)
        }
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private func _installButton() -> some View {
        Button {
            _installStarted = true
            onInstall?()
        } label: {
            Text("Install")
                .font(.headline)
                .foregroundColor(.white)
                .frame(width: 200, height: 46)
                .background(Color.blue)
                .clipShape(Capsule())
        }
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private func _progressSection() -> some View {
        VStack(spacing: 10) {
            Text("Installing...")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)

            ProgressView(value: viewModel.overallProgress)
                .progressViewStyle(.linear)
                .tint(.blue)

            Text(viewModel.formattedProgress)
                .font(.caption)
                .foregroundColor(.secondary)
                .monospacedDigit()
        }
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private func _completedSection() -> some View {
        VStack(spacing: 8) {
            if viewModel.isError {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.red)
                Text("Failed")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.red)
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.green)
                Text("Installed")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.green)

                Button {
                    onOpen?()
                } label: {
                    Text("Open")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(width: 200, height: 46)
                        .background(Color.blue)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private func _appIcon() -> some View {
        FRAppIconView(app: app, size: 60)
            .frame(width: 60, height: 60)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .scaleEffect(_isPulsing && viewModel.isInProgress ? 1.02 : 1.0)
            .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: _isPulsing)
    }

    private func _computeAppSize() {
        if let url = app.archiveURL {
            do {
                let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
                if let fileSize = attributes[.size] as? UInt64 {
                    _appSizeString = _formatBytes(fileSize)
                }
            } catch {}
        }

        if _appSizeString.isEmpty {
            if let uuidDir = Storage.shared.getUuidDirectory(for: app) {
                let size = _directorySize(url: uuidDir)
                if size > 0 {
                    _appSizeString = _formatBytes(UInt64(size))
                }
            }
        }
    }

    private func _formatBytes(_ bytes: UInt64) -> String {
        let kb = Double(bytes) / 1024
        let mb = kb / 1024
        let gb = mb / 1024

        if gb >= 1.0 {
            return String(format: "%.1f GB", gb)
        } else {
            return String(format: "%.0f MB", max(mb, 1))
        }
    }

    private func _directorySize(url: URL) -> Int64 {
        let fm = FileManager.default
        guard let enumerator = fm.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey], options: [.skipsHiddenFiles]) else {
            return 0
        }
        var total: Int64 = 0
        for case let fileURL as URL in enumerator {
            if let values = try? fileURL.resourceValues(forKeys: [.fileSizeKey]),
               let size = values.fileSize {
                total += Int64(size)
            }
        }
        return total
    }
}
