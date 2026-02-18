import SwiftUI

struct IPAExplorerProvisionViewer: View {
    let fileURL: URL
    @State private var certificate: Certificate?

    var body: some View {
        List {
            if let cert = certificate {
                Section(.localized("Metadata")) {
                    InfoRow(label: .localized("Name"), value: cert.Name)
                    InfoRow(label: .localized("Team ID"), value: cert.TeamIdentifier.joined(separator: ", "))
                    InfoRow(label: .localized("Team Name"), value: cert.TeamName)
                    InfoRow(label: .localized("App ID Name"), value: cert.AppIDName)
                    InfoRow(label: .localized("UUID"), value: cert.UUID)
                    InfoRow(label: .localized("Created"), value: cert.CreationDate.formatted())
                    InfoRow(label: .localized("Expires"), value: cert.ExpirationDate.formatted())
                }

                Section(.localized("Capabilities")) {
                    InfoRow(label: .localized("Device Count"), value: cert.ProvisionsAllDevices == true ? "Unlimited" : "\(cert.ProvisionedDevices?.count ?? 0)")
                    InfoRow(label: .localized("Platform"), value: cert.Platform.joined(separator: ", "))
                }

                if let entitlements = cert.Entitlements {
                    Section(.localized("Entitlements")) {
                        ForEach(entitlements.keys.sorted(), id: \.self) { key in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(key)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text("\(entitlements[key]?.description ?? "")")
                                    .font(.system(.body, design: .monospaced))
                            }
                        }
                    }
                }
            } else {
                Text(.localized("Loading..."))
            }
        }
        .navigationTitle("embedded.mobileprovision")
        .onAppear {
            loadProvision()
        }
    }

    private func loadProvision() {
        let reader = CertificateReader(fileURL)
        certificate = reader.decoded
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
