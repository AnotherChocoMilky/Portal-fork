import SwiftUI

struct IPAExplorerProvisionViewer: View {
    let fileURL: URL
    @State private var certificate: Certificate?

    var body: some View {
        List {
            if let cert = certificate {
                Section(.localized("Metadata")) {
                    ProvisionInfoRow(label: .localized("Name"), value: cert.Name)
                    ProvisionInfoRow(label: .localized("Team ID"), value: cert.TeamIdentifier.joined(separator: ", "))
                    ProvisionInfoRow(label: .localized("Team Name"), value: cert.TeamName)
                    ProvisionInfoRow(label: .localized("App ID Name"), value: cert.AppIDName)
                    ProvisionInfoRow(label: .localized("UUID"), value: cert.UUID)
                    ProvisionInfoRow(label: .localized("Created"), value: cert.CreationDate.formatted())
                    ProvisionInfoRow(label: .localized("Expires"), value: cert.ExpirationDate.formatted())
                }

                Section(.localized("Capabilities")) {
                    ProvisionInfoRow(label: .localized("Device Count"), value: cert.ProvisionsAllDevices == true ? "Unlimited" : "\(cert.ProvisionedDevices?.count ?? 0)")
                    ProvisionInfoRow(label: .localized("Platform"), value: cert.Platform.joined(separator: ", "))
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

private struct ProvisionInfoRow: View {
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
