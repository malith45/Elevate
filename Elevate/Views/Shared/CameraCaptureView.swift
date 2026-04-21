import SwiftUI
import AVFoundation
import UIKit

struct CameraCaptureView: UIViewControllerRepresentable {
    let onCapture: (Data) -> Void
    @Binding var isPresented: Bool

    func makeUIViewController(context: Context) -> CameraViewController {
        let controller = CameraViewController()
        controller.onCapture = onCapture
        controller.onDismiss = { isPresented = false }
        return controller
    }

    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {}
}

final class CameraViewController: UIViewController, AVCapturePhotoCaptureDelegate {
    var onCapture: ((Data) -> Void)?
    var onDismiss: (() -> Void)?

    private let session = AVCaptureSession()
    private let output = AVCapturePhotoOutput()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private let accessLabel = UILabel()
    private let simulatorPatternLabel = UILabel()
    private let simulatorSubLabel = UILabel()
    private let captureButton = UIButton(type: .system)
    private let cancelButton = UIButton(type: .system)
    private var isSimulationMode = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        checkCameraAccess()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !isSimulationMode && session.isRunning == false {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.session.startRunning()
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if !isSimulationMode {
            session.stopRunning()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
        
        let safeBottom = view.safeAreaInsets.bottom
        let bottomPadding: CGFloat = safeBottom > 0 ? safeBottom : 24
        
        // Position Main Capture Button
        captureButton.frame = CGRect(
            x: (view.bounds.width - 140) / 2,
            y: view.bounds.height - bottomPadding - 48 - 12,
            width: 140,
            height: 48
        )
        
        // Position Cancel Button
        cancelButton.frame = CGRect(
            x: 24,
            y: view.bounds.height - bottomPadding - 40 - 16,
            width: 80,
            height: 40
        )
        
        // Position Simulator Labels
        simulatorPatternLabel.frame = view.bounds
        simulatorSubLabel.frame = CGRect(
            x: 40,
            y: view.center.y + 40,
            width: view.bounds.width - 80,
            height: 60
        )
        
        // Access Label positioning
        accessLabel.frame = CGRect(x: 24, y: 0, width: view.bounds.width - 48, height: 120)
        accessLabel.center = view.center
    }

    private func checkCameraAccess() {
        #if targetEnvironment(simulator)
        isSimulationMode = true
        showSimulationMode()
        configureCaptureButton()
        #else
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            configureSession()
            configurePreview()
            configureCaptureButton()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    if granted {
                        self?.configureSession()
                        self?.configurePreview()
                        self?.configureCaptureButton()
                    } else {
                        self?.showAccessDeniedMessage()
                    }
                }
            }
        default:
            if AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) == nil {
                isSimulationMode = true
                showSimulationMode()
                configureCaptureButton()
            } else {
                showAccessDeniedMessage()
            }
        }
        #endif
    }

    private func showSimulationMode() {
        view.backgroundColor = .darkGray
        
        simulatorPatternLabel.text = "📷 SIMULATOR CAMERA"
        simulatorPatternLabel.textColor = UIColor.white.withAlphaComponent(0.3)
        simulatorPatternLabel.font = .systemFont(ofSize: 24, weight: .bold)
        simulatorPatternLabel.textAlignment = .center
        view.addSubview(simulatorPatternLabel)
        
        simulatorSubLabel.text = "Hardware not detected. Capture will return a placeholder image."
        simulatorSubLabel.textColor = UIColor.white.withAlphaComponent(0.5)
        simulatorSubLabel.font = .systemFont(ofSize: 14)
        simulatorSubLabel.numberOfLines = 0
        simulatorSubLabel.textAlignment = .center
        view.addSubview(simulatorSubLabel)
    }

    private func configureSession() {
        session.beginConfiguration()
        session.sessionPreset = .photo

        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input)
        else {
            session.commitConfiguration()
            isSimulationMode = true
            DispatchQueue.main.async {
                self.showSimulationMode()
            }
            return
        }

        session.addInput(input)

        if session.canAddOutput(output) {
            session.addOutput(output)
        }

        session.commitConfiguration()
    }

    private func configurePreview() {
        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.videoGravity = .resizeAspectFill
        preview.frame = view.bounds
        view.layer.addSublayer(preview)
        previewLayer = preview
    }

    private func showAccessDeniedMessage() {
        accessLabel.text = "Camera access is disabled. Enable it in Settings."
        accessLabel.textColor = .white
        accessLabel.numberOfLines = 0
        accessLabel.textAlignment = .center
        view.addSubview(accessLabel)

        let sheetCloseButton = UIButton(type: .system)
        sheetCloseButton.setTitle("Close", for: .normal)
        sheetCloseButton.setTitleColor(.white, for: .normal)
        sheetCloseButton.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        sheetCloseButton.layer.cornerRadius = 16
        sheetCloseButton.frame = CGRect(x: (view.bounds.width - 120) / 2, y: view.bounds.height - 90, width: 120, height: 40)
        sheetCloseButton.addTarget(self, action: #selector(closeCamera), for: .touchUpInside)
        view.addSubview(sheetCloseButton)
    }

    @objc private func closeCamera() {
        onDismiss?()
    }

    private func configureCaptureButton() {
        captureButton.setTitle("Capture", for: .normal)
        captureButton.setTitleColor(.white, for: .normal)
        captureButton.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        captureButton.layer.cornerRadius = 24
        captureButton.addTarget(self, action: #selector(capturePhoto), for: .touchUpInside)
        view.addSubview(captureButton)
        
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.setTitleColor(.white.withAlphaComponent(0.7), for: .normal)
        cancelButton.addTarget(self, action: #selector(closeCamera), for: .touchUpInside)
        view.addSubview(cancelButton)
    }

    @objc private func capturePhoto() {
        if isSimulationMode {
            captureMockPhoto()
            return
        }

        if session.isRunning == false {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.session.startRunning()
            }
        }
        guard let connection = output.connection(with: .video), connection.isEnabled else {
            isSimulationMode = true
            showSimulationMode()
            return
        }
        let settings = AVCapturePhotoSettings()
        output.capturePhoto(with: settings, delegate: self)
    }

    private func captureMockPhoto() {
        let size = CGSize(width: 1080, height: 1440)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            UIColor.darkGray.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            
            let text = "ELEVATE - SERVICE PHOTO\n(SIMULATOR MOCK)\n\nCaptured: \(Date().description)"
            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 48, weight: .bold),
                .foregroundColor: UIColor.white.withAlphaComponent(0.5)
            ]
            let nsText = NSString(string: text)
            let rect = CGRect(x: 100, y: 500, width: 880, height: 600)
            nsText.draw(in: rect, withAttributes: attrs)
        }
        
        if let data = image.jpegData(compressionQuality: 0.8) {
            onCapture?(data)
        }
        onDismiss?()
    }

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let data = photo.fileDataRepresentation() {
            onCapture?(data)
        }
        onDismiss?()
    }
}
