import SwiftUI
import AVFoundation

struct BarcodeScannerView: View {
    let onScan: (String) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                BarcodeCameraView(onScan: onScan)
                    .ignoresSafeArea()

                // Viewfinder overlay
                VStack {
                    Spacer()
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.8), lineWidth: 2)
                            .frame(width: 280, height: 160)

                        // Corner markers
                        CornerMarkers()
                            .frame(width: 280, height: 160)
                    }
                    Text("Position barcode within frame")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.9))
                        .padding(.top, 20)
                    Spacer()
                }
            }
            .navigationTitle("Scan Barcode")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(.white)
                }
            }
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        }
    }
}

// MARK: - Corner Markers

private struct CornerMarkers: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let len: CGFloat = 24
            let lw: CGFloat = 3

            ZStack {
                // Top-left
                Path { p in
                    p.move(to: CGPoint(x: 0, y: len))
                    p.addLine(to: CGPoint(x: 0, y: 0))
                    p.addLine(to: CGPoint(x: len, y: 0))
                }.stroke(Color.white, lineWidth: lw)

                // Top-right
                Path { p in
                    p.move(to: CGPoint(x: w - len, y: 0))
                    p.addLine(to: CGPoint(x: w, y: 0))
                    p.addLine(to: CGPoint(x: w, y: len))
                }.stroke(Color.white, lineWidth: lw)

                // Bottom-left
                Path { p in
                    p.move(to: CGPoint(x: 0, y: h - len))
                    p.addLine(to: CGPoint(x: 0, y: h))
                    p.addLine(to: CGPoint(x: len, y: h))
                }.stroke(Color.white, lineWidth: lw)

                // Bottom-right
                Path { p in
                    p.move(to: CGPoint(x: w - len, y: h))
                    p.addLine(to: CGPoint(x: w, y: h))
                    p.addLine(to: CGPoint(x: w, y: h - len))
                }.stroke(Color.white, lineWidth: lw)
            }
        }
    }
}

// MARK: - Camera UIViewRepresentable

struct BarcodeCameraView: UIViewRepresentable {
    let onScan: (String) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onScan: onScan)
    }

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .black

        let session = AVCaptureSession()
        context.coordinator.session = session

        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.videoGravity = .resizeAspectFill
        view.layer.addSublayer(preview)
        context.coordinator.previewLayer = preview

        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            context.coordinator.startSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted {
                    context.coordinator.startSession()
                }
            }
        default:
            break
        }

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.previewLayer?.frame = uiView.bounds
    }

    static func dismantleUIView(_ uiView: UIView, coordinator: Coordinator) {
        coordinator.session?.stopRunning()
    }

    final class Coordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
        let onScan: (String) -> Void
        var session: AVCaptureSession?
        var previewLayer: AVCaptureVideoPreviewLayer?
        private var hasScanned = false

        init(onScan: @escaping (String) -> Void) {
            self.onScan = onScan
        }

        func startSession() {
            guard let session else { return }

            guard let device = AVCaptureDevice.default(for: .video),
                  let input = try? AVCaptureDeviceInput(device: device) else { return }

            session.addInput(input)

            let output = AVCaptureMetadataOutput()
            session.addOutput(output)
            output.setMetadataObjectsDelegate(self, queue: .main)
            output.metadataObjectTypes = [.ean8, .ean13, .upce, .code128, .code39, .qr, .pdf417]

            DispatchQueue.global(qos: .userInitiated).async {
                session.startRunning()
            }
        }

        func metadataOutput(
            _ output: AVCaptureMetadataOutput,
            didOutput metadataObjects: [AVMetadataObject],
            from connection: AVCaptureConnection
        ) {
            guard !hasScanned,
                  let object = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
                  let value = object.stringValue else { return }

            hasScanned = true
            session?.stopRunning()

            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            onScan(value)
        }
    }
}

#Preview {
    BarcodeScannerView { barcode in
        print("Scanned: \(barcode)")
    }
}
