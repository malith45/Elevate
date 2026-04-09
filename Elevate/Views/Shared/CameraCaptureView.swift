import SwiftUI
import AVFoundation

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

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        checkCameraAccess()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if session.isRunning == false {
            session.startRunning()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        session.stopRunning()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }

    private func checkCameraAccess() {
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
            showAccessDeniedMessage()
        }
    }

    private func configureSession() {
        session.beginConfiguration()
        session.sessionPreset = .photo

        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input)
        else {
            session.commitConfiguration()
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
        accessLabel.frame = CGRect(x: 24, y: 0, width: view.bounds.width - 48, height: 120)
        accessLabel.center = view.center
        view.addSubview(accessLabel)

        let closeButton = UIButton(type: .system)
        closeButton.setTitle("Close", for: .normal)
        closeButton.setTitleColor(.white, for: .normal)
        closeButton.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        closeButton.layer.cornerRadius = 16
        closeButton.frame = CGRect(x: (view.bounds.width - 120) / 2, y: view.bounds.height - 90, width: 120, height: 40)
        closeButton.addTarget(self, action: #selector(closeCamera), for: .touchUpInside)
        view.addSubview(closeButton)
    }

    @objc private func closeCamera() {
        onDismiss?()
    }

    private func configureCaptureButton() {
        let button = UIButton(type: .system)
        button.setTitle("Capture", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        button.layer.cornerRadius = 24
        button.frame = CGRect(x: (view.bounds.width - 140) / 2, y: view.bounds.height - 90, width: 140, height: 48)
        button.addTarget(self, action: #selector(capturePhoto), for: .touchUpInside)
        view.addSubview(button)
    }

    @objc private func capturePhoto() {
        if session.isRunning == false {
            session.startRunning()
        }
        guard let connection = output.connection(with: .video), connection.isEnabled else {
            accessLabel.text = "Camera is unavailable. Try again on a physical device."
            accessLabel.textColor = .white
            accessLabel.numberOfLines = 0
            accessLabel.textAlignment = .center
            accessLabel.frame = CGRect(x: 24, y: 0, width: view.bounds.width - 48, height: 120)
            accessLabel.center = view.center
            if accessLabel.superview == nil {
                view.addSubview(accessLabel)
            }
            return
        }
        let settings = AVCapturePhotoSettings()
        output.capturePhoto(with: settings, delegate: self)
    }

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let data = photo.fileDataRepresentation() {
            onCapture?(data)
        }
        onDismiss?()
    }
}
