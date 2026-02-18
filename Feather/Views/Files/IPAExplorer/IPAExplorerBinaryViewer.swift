import SwiftUI

struct IPAExplorerBinaryViewer: View {
    let fileURL: URL
    @State private var machoInfo: FileAnalysisEngine.MachOInformation?
    @State private var fileSize: Int64 = 0

    var body: some View {
        List {
            Section(.localized("File Info")) {
                InfoRow(label: .localized("Name"), value: fileURL.lastPathComponent)
                InfoRow(label: .localized("Size"), value: ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file))
            }

            if let info = machoInfo {
                Section(.localized("Mach-O Info")) {
                    InfoRow(label: .localized("Architectures"), value: info.architectures)
                    InfoRow(label: .localized("64-bit"), value: info.is64Bit ? .localized("Yes") : .localized("No"))
                    InfoRow(label: .localized("ARM64e"), value: info.isArm64e ? .localized("Yes") : .localized("No"))
                    InfoRow(label: .localized("PIE"), value: info.isPIE ? .localized("Yes") : .localized("No"))
                    InfoRow(label: .localized("Encrypted"), value: info.hasEncryption ? .localized("Yes") : .localized("No"))
                    InfoRow(label: .localized("Load Commands"), value: "\(info.numberOfLoadCommands)")
                }
            } else {
                Text(.localized("Analyzing..."))
            }
        }
        .navigationTitle(.localized("Binary Info"))
        .onAppear {
            analyze()
        }
    }

    private func analyze() {
        let attr = try? FileManager.default.attributesOfItem(atPath: fileURL.path)
        fileSize = attr?[.size] as? Int64 ?? 0
        machoInfo = FileAnalysisEngine.analyzeMachOFile(at: fileURL.path)
    }
}

private struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .textSelection(.enabled)
        }
    }
}
