import AVFoundation
import SwiftUI

// MARK: - QR Scanner Result

struct QRScanResult {
  let roomId: String
  let roomName: String
  let alreadyMember: Bool
}

// MARK: - QRScannerView

struct QRScannerView: View {
  @Environment(\.dismiss) var dismiss

  var onJoinedRoom: ((String) -> Void)? // Passes roomId on success

  @State private var scannedCode: String? = nil
  @State private var isProcessing = false
  @State private var scanResult: QRScanResult? = nil
  @State private var errorMessage: String? = nil
  @State private var cameraPermissionGranted = false
  @State private var showPermissionDenied = false

  var body: some View {
    ZStack {
      Color.black.ignoresSafeArea()

      if showPermissionDenied {
        permissionDeniedView
      } else if let result = scanResult {
        successView(result: result)
      } else if let error = errorMessage {
        errorView(message: error)
      } else {
        // Camera Preview
        CameraPreviewView(onCodeScanned: handleScan)
          .ignoresSafeArea()

        // Scanner Overlay
        scannerOverlay
      }

      // Close Button (always visible)
      VStack {
        HStack {
          Spacer()
          Button(action: { dismiss() }) {
            Image(systemName: "xmark.circle.fill")
              .font(.system(size: 32))
              .foregroundColor(.white.opacity(0.8))
              .shadow(radius: 4)
          }
          .padding(24)
        }
        Spacer()
      }
    }
    .onAppear {
      checkCameraPermission()
    }
  }

  // MARK: - Scanner Overlay

  private var scannerOverlay: some View {
    VStack(spacing: 24) {
      Spacer()

      // Scanning Frame
      ZStack {
        RoundedRectangle(cornerRadius: 20)
          .stroke(Color.white.opacity(0.6), lineWidth: 3)
          .frame(width: 260, height: 260)

        // Corner accents
        ForEach(0..<4, id: \.self) { corner in
          CornerAccent(corner: corner)
        }

        if isProcessing {
          ProgressView()
            .progressViewStyle(CircularProgressViewStyle(tint: .white))
            .scaleEffect(1.5)
        }
      }

      Text(isProcessing ? "Joining room..." : "Point camera at QR code")
        .font(.system(size: 16, weight: .medium))
        .foregroundColor(.white.opacity(0.8))

      Spacer()
      Spacer()
    }
  }

  // MARK: - Success View

  private func successView(result: QRScanResult) -> some View {
    VStack(spacing: 24) {
      Spacer()

      Image(systemName: "checkmark.circle.fill")
        .font(.system(size: 80))
        .foregroundColor(.green)

      Text(result.alreadyMember ? "Already a Member" : "Join Request Sent!")
        .font(.system(size: 24, weight: .bold))
        .foregroundColor(.white)

      Text(result.alreadyMember
        ? "You're already a member of \"\(result.roomName)\""
        : "You've requested to join \"\(result.roomName)\"")
        .font(.system(size: 16))
        .foregroundColor(.gray)
        .multilineTextAlignment(.center)
        .padding(.horizontal, 40)

      Button(action: {
        onJoinedRoom?(result.roomId)
        dismiss()
      }) {
        Text("Continue")
          .font(.system(size: 18, weight: .bold))
          .frame(maxWidth: .infinity)
          .padding()
          .background(Color.blue)
          .foregroundColor(.white)
          .cornerRadius(16)
      }
      .padding(.horizontal, 40)
      .padding(.top, 16)

      Spacer()
    }
  }

  // MARK: - Error View

  private func errorView(message: String) -> some View {
    VStack(spacing: 24) {
      Spacer()

      Image(systemName: "exclamationmark.triangle.fill")
        .font(.system(size: 80))
        .foregroundColor(.orange)

      Text("Scan Failed")
        .font(.system(size: 24, weight: .bold))
        .foregroundColor(.white)

      Text(message)
        .font(.system(size: 16))
        .foregroundColor(.gray)
        .multilineTextAlignment(.center)
        .padding(.horizontal, 40)

      Button(action: {
        errorMessage = nil
        scannedCode = nil
      }) {
        Text("Try Again")
          .font(.system(size: 18, weight: .bold))
          .frame(maxWidth: .infinity)
          .padding()
          .background(Color.blue)
          .foregroundColor(.white)
          .cornerRadius(16)
      }
      .padding(.horizontal, 40)
      .padding(.top, 16)

      Spacer()
    }
  }

  // MARK: - Permission Denied View

  private var permissionDeniedView: some View {
    VStack(spacing: 24) {
      Spacer()

      Image(systemName: "camera.fill")
        .font(.system(size: 60))
        .foregroundColor(.gray)

      Text("Camera Access Required")
        .font(.system(size: 24, weight: .bold))
        .foregroundColor(.white)

      Text("BestBefore needs camera access to scan QR codes. Please enable it in Settings.")
        .font(.system(size: 16))
        .foregroundColor(.gray)
        .multilineTextAlignment(.center)
        .padding(.horizontal, 40)

      Button(action: {
        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
          UIApplication.shared.open(settingsURL)
        }
      }) {
        Text("Open Settings")
          .font(.system(size: 18, weight: .bold))
          .frame(maxWidth: .infinity)
          .padding()
          .background(Color.blue)
          .foregroundColor(.white)
          .cornerRadius(16)
      }
      .padding(.horizontal, 40)

      Spacer()
    }
  }

  // MARK: - Logic

  private func checkCameraPermission() {
    switch AVCaptureDevice.authorizationStatus(for: .video) {
    case .authorized:
      cameraPermissionGranted = true
    case .notDetermined:
      AVCaptureDevice.requestAccess(for: .video) { granted in
        DispatchQueue.main.async {
          if granted {
            cameraPermissionGranted = true
          } else {
            showPermissionDenied = true
          }
        }
      }
    case .denied, .restricted:
      showPermissionDenied = true
    @unknown default:
      showPermissionDenied = true
    }
  }

  private func handleScan(_ code: String) {
    // Prevent double processing
    guard !isProcessing, scannedCode == nil else { return }

    // Parse the BestBefore QR format: "bestbefore:room:<roomId>"
    guard code.hasPrefix("bestbefore:room:") else {
      errorMessage = "This QR code is not a valid BestBefore room code."
      return
    }

    let roomId = String(code.dropFirst("bestbefore:room:".count))
    guard !roomId.isEmpty else {
      errorMessage = "Invalid QR code data."
      return
    }

    scannedCode = code
    isProcessing = true

    Task {
      do {
        let result = try await Database.shared.joinRoomViaQR(roomId: roomId)
        await MainActor.run {
          self.scanResult = QRScanResult(
            roomId: roomId,
            roomName: result.roomName,
            alreadyMember: result.alreadyMember
          )
          self.isProcessing = false
        }
      } catch {
        await MainActor.run {
          self.errorMessage = error.localizedDescription
          self.isProcessing = false
          self.scannedCode = nil
        }
      }
    }
  }
}

// MARK: - Corner Accent Shape

private struct CornerAccent: View {
  let corner: Int

  var body: some View {
    let size: CGFloat = 30
    let frameSize: CGFloat = 260

    Path { path in
      switch corner {
      case 0: // Top-Left
        path.move(to: CGPoint(x: 0, y: size))
        path.addLine(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: size, y: 0))
      case 1: // Top-Right
        path.move(to: CGPoint(x: frameSize - size, y: 0))
        path.addLine(to: CGPoint(x: frameSize, y: 0))
        path.addLine(to: CGPoint(x: frameSize, y: size))
      case 2: // Bottom-Left
        path.move(to: CGPoint(x: 0, y: frameSize - size))
        path.addLine(to: CGPoint(x: 0, y: frameSize))
        path.addLine(to: CGPoint(x: size, y: frameSize))
      case 3: // Bottom-Right
        path.move(to: CGPoint(x: frameSize - size, y: frameSize))
        path.addLine(to: CGPoint(x: frameSize, y: frameSize))
        path.addLine(to: CGPoint(x: frameSize, y: frameSize - size))
      default: break
      }
    }
    .stroke(Color.blue, style: StrokeStyle(lineWidth: 4, lineCap: .round))
    .frame(width: frameSize, height: frameSize)
  }
}

// MARK: - AVFoundation Camera Preview

struct CameraPreviewView: UIViewControllerRepresentable {
  var onCodeScanned: (String) -> Void

  func makeUIViewController(context: Context) -> CameraViewController {
    let vc = CameraViewController()
    vc.onCodeScanned = onCodeScanned
    return vc
  }

  func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {}
}

class CameraViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
  var onCodeScanned: ((String) -> Void)?

  private let captureSession = AVCaptureSession()
  private var previewLayer: AVCaptureVideoPreviewLayer?
  private var hasScanned = false

  override func viewDidLoad() {
    super.viewDidLoad()
    setupCamera()
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    previewLayer?.frame = view.bounds
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    DispatchQueue.global(qos: .userInitiated).async { [weak self] in
      if self?.captureSession.isRunning == false {
        self?.captureSession.startRunning()
      }
    }
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    DispatchQueue.global(qos: .userInitiated).async { [weak self] in
      if self?.captureSession.isRunning == true {
        self?.captureSession.stopRunning()
      }
    }
  }

  private func setupCamera() {
    guard let device = AVCaptureDevice.default(for: .video),
      let input = try? AVCaptureDeviceInput(device: device)
    else {
      return
    }

    if captureSession.canAddInput(input) {
      captureSession.addInput(input)
    }

    let metadataOutput = AVCaptureMetadataOutput()
    if captureSession.canAddOutput(metadataOutput) {
      captureSession.addOutput(metadataOutput)
      metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
      metadataOutput.metadataObjectTypes = [.qr]
    }

    let preview = AVCaptureVideoPreviewLayer(session: captureSession)
    preview.videoGravity = .resizeAspectFill
    preview.frame = view.bounds
    view.layer.addSublayer(preview)
    self.previewLayer = preview

    DispatchQueue.global(qos: .userInitiated).async { [weak self] in
      self?.captureSession.startRunning()
    }
  }

  func metadataOutput(
    _ output: AVCaptureMetadataOutput,
    didOutput metadataObjects: [AVMetadataObject],
    from connection: AVCaptureConnection
  ) {
    guard !hasScanned,
      let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
      let stringValue = metadataObject.stringValue
    else { return }

    hasScanned = true

    // Haptic feedback
    let generator = UINotificationFeedbackGenerator()
    generator.notificationOccurred(.success)

    onCodeScanned?(stringValue)
  }
}
