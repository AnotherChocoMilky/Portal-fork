import SwiftUI
import NimbleViews

// MARK: - View
struct InstallationView: View {
    @State private var _showServerSheet = false

    var body: some View {
        NBList(.localized("Installation")) {
            Section {
                Button {
                    _showServerSheet = true
                    HapticsManager.shared.softImpact()
                } label: {
                    Label {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(.localized("Server & SSL"))
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(.primary)
                            Text(.localized("Configure signing server and SSL certificates"))
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: "server.rack")
                            .foregroundStyle(.blue)
                    }
                }
            }
        }
        .sheet(isPresented: $_showServerSheet) {
            ServerView()
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }
}
