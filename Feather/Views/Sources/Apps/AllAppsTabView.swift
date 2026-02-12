import SwiftUI
import AltSourceKit

struct AllAppsTabView: View {
    @AppStorage("Feather.useNewAllAppsView") private var useNewAllAppsView: Bool = true
    @StateObject private var viewModel = SourcesViewModel.shared

    var body: some View {
        Group {
            if useNewAllAppsView {
                AllAppsView(isTab: true, object: Storage.shared.getSources(), viewModel: viewModel)
            } else {
                VStack(spacing: 20) {
                    Spacer()

                    ZStack {
                        Circle()
                            .fill(Color.accentColor.opacity(0.1))
                            .frame(width: 100, height: 100)

                        Image(systemName: "rectangle.stack.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(Color.accentColor)
                    }

                    VStack(spacing: 12) {
                        Text("New Apps View Required")
                            .font(.title2.bold())
                            .multilineTextAlignment(.center)

                        Text("In order so you can see the apps here, enable the New Apps View on Settings > Appearance and turn it on.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }

                    Spacer()
                }
                .padding()
                .background(Color(UIColor.systemGroupedBackground))
            }
        }
    }
}
