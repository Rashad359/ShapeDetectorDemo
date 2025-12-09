import UIKit
import Vision
import SnapKit
import Combine

final class HandViewController: BaseViewController {
    
    private let viewModel: HandViewModel
    
    private var cancellables = Set<AnyCancellable>()
    
    init(viewModel: HandViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private lazy var handOverlayView: UIView = {
        let view = UIView()
        view.frame = CGRect(x: 0, y: 0, width: 60, height: 60)
        view.layer.cornerRadius = 30
        view.backgroundColor = UIColor.blue.withAlphaComponent(0.6)
        view.layer.borderColor = UIColor.white.cgColor
        view.layer.borderWidth = 2
        view.isHidden = true
        
        return view
    }()
    
    private let cameraImage: UIImageView = {
        let imageView = UIImageView()
        
        return imageView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigation()
        setupAndBeginCapturingVideoFrames()
        setupBindings()
    }
    
    override func setupUI() {
        super.setupUI()
        view.addSubview(cameraImage)
        view.addSubview(handOverlayView)
        view.bringSubviewToFront(handOverlayView)
        
        cameraImage.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        viewModel.stopCapturing {
            super.viewWillDisappear(animated)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        viewModel.startCapturing {
            super.viewWillAppear(animated)
        }
    }
    
    private func setupAndBeginCapturingVideoFrames() {
        viewModel.setupAVCapture()
    }
    
    private func setupNavigation() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "arrow.trianglehead.2.clockwise.rotate.90.camera.fill"), style: .plain, target: self, action: #selector(didTapFlipCamera))
    }
    
    @objc private func didTapFlipCamera() {
        viewModel.flipCamera()
    }
    
    private func setupBindings() {
        viewModel.$didFinishProcess.sink { _ in
            self.viewModel.subscribeToVideoDelegate(to: self)
            self.viewModel.startCapturing(completion: nil)
        }.store(in: &cancellables)
        
        viewModel.$error.sink { error in
            if let error {
                print("Something went wrong in hand: \(error)")
            }
        }.store(in: &cancellables)
    }
}

extension HandViewController: VideoCaptureDelegate {
    func videoCapture(_ videoCapture: VideoCaptureManager, didCaptureFrame capturedImage: CGImage?, didOutput sampleBuffer: CMSampleBuffer) {
        viewModel.finishCameraSetup(didCaptureFrame: capturedImage, forView: handOverlayView, with: cameraImage)
    }
}

// MARK: - Unused or deprecated code (delete before release)

//        videoCapture.setupAVCapture { error in
//            if let error {
//                print("Something went wrong: \(error)")
//            }
//
//            self.videoCapture.delegate = self
//
//            self.videoCapture.startCapturing()
//        }

//    private func processPose(cgImage: CGImage?) {
//
//        guard let image = cgImage else { return }
//
//        let requestHandler = VNImageRequestHandler(cgImage: image, orientation: .right)
//
//        let handRequest = VNDetectHumanHandPoseRequest(completionHandler: handPoseHandler)
//        handRequest.maximumHandCount = 1
//
//        do {
//            try requestHandler.perform([handRequest])
//        } catch {
//            print("Unable to perform the request: \(error).")
//        }
//    }
    
//    private func handPoseHandler(request: VNRequest, error: Error?) {
//        guard let observations = request.results as? [VNHumanHandPoseObservation],
//              let observation = observations.first else {
//            DispatchQueue.main.async {
//                self.handOverlayView.isHidden = true
//            }
//            return
//        }
//
//        guard let point = try? observation.recognizedPoint(.middleMCP),
//              point.confidence > 0.2 else {
//            DispatchQueue.main.async {
//                self.handOverlayView.isHidden = true
//            }
//           return
//        }
//
//        let normalizedPoint = point.location
//
//        DispatchQueue.main.async {
//            let screenWidth = self.cameraImage.bounds.width
//            let screenHeight = self.cameraImage.bounds.height
//
//            let x = normalizedPoint.x * screenWidth
//            let y = (1 - normalizedPoint.y) * screenHeight + 50
//
//            self.handOverlayView.isHidden = false
//            self.handOverlayView.center = CGPoint(x: x, y: y)
//        }
//
//    }


//        guard let image = capturedImage else { fatalError("Captured image is nil") }
//
//        self.processPose(cgImage: image)
//
//
//        DispatchQueue.main.async {
//            self.cameraImage.image = UIImage(cgImage: image, scale: 1.0, orientation: .right)
//        }
