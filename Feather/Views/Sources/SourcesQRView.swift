import SwiftUI
import CoreImage.CIFilterBuiltins

struct SourcesQRView: View {
    @Environment(\.dismiss) private var dismiss
    let data: String

    private let context = CIContext()
    private let filter = CIFilter.qrCodeGenerator()

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Scan to Import Sources")
                    .font(.headline)

                qrCodeImage
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 250, height: 250)
                    .padding(20)
                    .background(Color.white)
                    .cornerRadius(20)
                    .shadow(radius: 10)

                Text("Sharing \(data.count) Bytes Of Data")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Button {
                    let image = generateQRCode(from: data)
                    let av = UIActivityViewController(activityItems: [image], applicationActivities: nil)
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let rootVC = windowScene.windows.first?.rootViewController {
                        rootVC.present(av, animated: true)
                    }
                } label: {
                    Label("Share QR Code", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal)
            }
            .padding(.vertical, 40)
            .navigationTitle("QR Code")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var qrCodeImage: Image {
        let uiImage = generateQRCode(from: data)
        return Image(uiImage: uiImage)
    }

    private func generateQRCode(from string: String) -> UIImage {
        filter.message = Data(string.utf8)

        if let outputImage = filter.outputImage {
            if let cgimg = context.createCGImage(outputImage, from: outputImage.extent) {
                return UIImage(cgImage: cgimg)
            }
        }

        return UIImage(systemName: "xmark.circle") ?? UIImage()
    }
}
