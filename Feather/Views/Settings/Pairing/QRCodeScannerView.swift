import SwiftUI
import AVFoundation

// MARK: - QR Code Scanner View
/// A SwiftUI view that opens the device camera and detects QR codes.
/// When a QR code is found, `onCodeScanned` is called once with the decoded string.
struct QRCodeScannerView: UIViewRepresentable {

    // MARK: - Input

    /// Called on the main thread with the decoded string when a valid QR code is detected.
    let onCodeScanned: (String) -> Void

    // MARK: - UIViewRepresentable

    func makeUIView(context: Context) -> CameraPreviewView {
        let view = CameraPreviewView()
        view.configure(delegate: context.coordinator)
        return view
    }

    func updateUIView(_ uiView: CameraPreviewView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onCodeScanned: onCodeScanned)
    }

    // MARK: - Coordinator

    final class Coordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
        private let onCodeScanned: (String) -> Void
        private var hasScanned = false

        init(onCodeScanned: @escaping (String) -> Void) {
            self.onCodeScanned = onCodeScanned
        }

        func metadataOutput(
            _ output: AVCaptureMetadataOutput,
            didOutput metadataObjects: [AVMetadataObject],
            from connection: AVCaptureConnection
        ) {
            guard !hasScanned,
                  let object = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
                  object.type == .qr,
                  let stringValue = object.stringValue else { return }
            hasScanned = true
            DispatchQueue.main.async {
                self.onCodeScanned(stringValue)
            }
        }
    }

    // MARK: - Camera Preview UIView

    final class CameraPreviewView: UIView {
        private var captureSession: AVCaptureSession?
        private var previewLayer: AVCaptureVideoPreviewLayer?

        override class var layerClass: AnyClass {
            AVCaptureVideoPreviewLayer.self
        }

        var videoPreviewLayer: AVCaptureVideoPreviewLayer? {
            layer as? AVCaptureVideoPreviewLayer
        }

        func configure(delegate: AVCaptureMetadataOutputObjectsDelegate) {
            let session = AVCaptureSession()
            captureSession = session

            guard let device = AVCaptureDevice.default(for: .video),
                  let input = try? AVCaptureDeviceInput(device: device),
                  session.canAddInput(input) else {
                return
            }
            session.addInput(input)

            let output = AVCaptureMetadataOutput()
            guard session.canAddOutput(output) else { return }
            session.addOutput(output)
            output.setMetadataObjectsDelegate(delegate, queue: .main)
            output.metadataObjectTypes = [.qr]

            guard let previewLayer = videoPreviewLayer else { return }
            previewLayer.session = session
            previewLayer.videoGravity = .resizeAspectFill

            DispatchQueue.global(qos: .userInitiated).async {
                session.startRunning()
            }
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            videoPreviewLayer?.frame = bounds
        }

        deinit {
            captureSession?.stopRunning()
        }
    }
}

// MARK: - QR Code Scanner Sheet
/// Full-screen sheet that shows the camera viewfinder to scan a pairing QR code.
/// Displays a framing overlay and calls `onCodeScanned` when a code is detected.
struct QRCodeScannerSheet: View {

    @Environment(\.dismiss) private var dismiss
    let onCodeScanned: (String) -> Void

    @State private var cameraPermissionDenied = false
    @State private var scannerKey = UUID()

    var body: some View {
        NavigationStack {
            ZStack {
                if cameraPermissionDenied {
                    permissionDeniedView
                } else {
                    cameraView
                }
            }
            .navigationTitle(.localized("Scan Pairing Code"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(.localized("Cancel")) { dismiss() }
                }
            }
        }
        .onAppear { checkCameraPermission() }
    }

    // MARK: - Camera View

    private var cameraView: some View {
        ZStack {
            // Live camera feed
            QRCodeScannerView { code in
                onCodeScanned(code)
                dismiss()
            }
            .id(scannerKey)
            .ignoresSafeArea()

            // Dark overlay with square cutout
            ScannerOverlayView()
                .ignoresSafeArea()

            // Instructions banner at bottom
            VStack {
                Spacer()
                Text(.localized("Point the camera at the animated pairing code\ndisplayed on the other device."))
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 16)
                    .background(.black.opacity(0.55))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .padding(.bottom, 40)
            }
        }
    }

    // MARK: - Permission Denied View

    private var permissionDeniedView: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "camera.slash.fill")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            Text(.localized("Camera Access Required"))
                .font(.title3.bold())
            Text(.localized("Please allow camera access in Settings to scan the pairing code."))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Button(.localized("Open Settings")) {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .buttonStyle(.borderedProminent)
            Spacer()
        }
    }

    // MARK: - Helpers

    private func checkCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            cameraPermissionDenied = false
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    cameraPermissionDenied = !granted
                    if granted { scannerKey = UUID() }
                }
            }
        default:
            cameraPermissionDenied = true
        }
    }
}

// MARK: - Scanner Overlay View
/// Draws a dark overlay with a square cutout in the centre for framing the QR code.
private struct ScannerOverlayView: View {
    private let squareSize: CGFloat = 250
    private let cornerRadius: CGFloat = 16
    private let cornerLength: CGFloat = 28
    private let cornerWidth: CGFloat = 4

    var body: some View {
        GeometryReader { geo in
            let rect = CGRect(
                x: (geo.size.width  - squareSize) / 2,
                y: (geo.size.height - squareSize) / 2,
                width: squareSize,
                height: squareSize
            )

            ZStack {
                // Semi-transparent black overlay
                Color.black.opacity(0.6)
                    .mask(
                        Rectangle()
                            .overlay(
                                RoundedRectangle(cornerRadius: cornerRadius)
                                    .frame(width: squareSize, height: squareSize)
                                    .blendMode(.destinationOut)
                            )
                            .compositingGroup()
                    )

                // Animated corner brackets
                CornerBrackets(
                    rect: rect,
                    cornerLength: cornerLength,
                    cornerWidth: cornerWidth,
                    cornerRadius: cornerRadius
                )
            }
        }
    }
}

// MARK: - Corner Brackets

private struct CornerBrackets: View {
    let rect: CGRect
    let cornerLength: CGFloat
    let cornerWidth: CGFloat
    let cornerRadius: CGFloat

    @State private var pulse = false

    var body: some View {
        ZStack {
            cornerPath(for: .topLeft)
            cornerPath(for: .topRight)
            cornerPath(for: .bottomLeft)
            cornerPath(for: .bottomRight)
        }
        .foregroundStyle(
            LinearGradient(
                colors: [.cyan, .purple],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .opacity(pulse ? 1.0 : 0.65)
        .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: pulse)
        .onAppear { pulse = true }
    }

    private enum Corner { case topLeft, topRight, bottomLeft, bottomRight }

    private func cornerPath(for corner: Corner) -> some View {
        Path { path in
            let r = CGPoint(x: rect.minX, y: rect.minY)
            let len = cornerLength

            switch corner {
            case .topLeft:
                path.move(to: CGPoint(x: r.x + len, y: r.y))
                path.addLine(to: CGPoint(x: r.x + cornerRadius, y: r.y))
                path.addQuadCurve(to: CGPoint(x: r.x, y: r.y + cornerRadius),
                                  control: CGPoint(x: r.x, y: r.y))
                path.addLine(to: CGPoint(x: r.x, y: r.y + len))
            case .topRight:
                let origin = CGPoint(x: rect.maxX, y: rect.minY)
                path.move(to: CGPoint(x: origin.x - len, y: origin.y))
                path.addLine(to: CGPoint(x: origin.x - cornerRadius, y: origin.y))
                path.addQuadCurve(to: CGPoint(x: origin.x, y: origin.y + cornerRadius),
                                  control: CGPoint(x: origin.x, y: origin.y))
                path.addLine(to: CGPoint(x: origin.x, y: origin.y + len))
            case .bottomLeft:
                let origin = CGPoint(x: rect.minX, y: rect.maxY)
                path.move(to: CGPoint(x: origin.x, y: origin.y - len))
                path.addLine(to: CGPoint(x: origin.x, y: origin.y - cornerRadius))
                path.addQuadCurve(to: CGPoint(x: origin.x + cornerRadius, y: origin.y),
                                  control: CGPoint(x: origin.x, y: origin.y))
                path.addLine(to: CGPoint(x: origin.x + len, y: origin.y))
            case .bottomRight:
                let origin = CGPoint(x: rect.maxX, y: rect.maxY)
                path.move(to: CGPoint(x: origin.x, y: origin.y - len))
                path.addLine(to: CGPoint(x: origin.x, y: origin.y - cornerRadius))
                path.addQuadCurve(to: CGPoint(x: origin.x - cornerRadius, y: origin.y),
                                  control: CGPoint(x: origin.x, y: origin.y))
                path.addLine(to: CGPoint(x: origin.x - len, y: origin.y))
            }
        }
        .stroke(style: StrokeStyle(lineWidth: cornerWidth, lineCap: .round))
    }
}
