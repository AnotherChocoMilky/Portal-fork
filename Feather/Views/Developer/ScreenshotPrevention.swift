import SwiftUI

struct ScreenshotPreventionView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "eye.slash.fill")
                .font(.system(size: 80))
                .foregroundStyle(.orange.gradient)
                .padding(.top, 40)

            VStack(spacing: 12) {
                Text("What are you doing?")
                    .font(.title.bold())
                    .multilineTextAlignment(.center)

                Text("You cannot screenshot anything on Developer Mode to maintain this information private.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()

            Button {
                dismiss()
            } label: {
                Text("I Understand")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.orange)
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
        .background(Color(UIColor.systemBackground))
    }
}

#Preview {
    ScreenshotPreventionView()
}
