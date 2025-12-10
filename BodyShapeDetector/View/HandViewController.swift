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
        imageView.contentMode = .scaleAspectFit
        
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
        viewModel.$didFinishProcess.sink {[weak self] _ in
            guard let strongSelf = self else { return }
            self?.viewModel.subscribeToVideoDelegate(to: strongSelf)
            self?.viewModel.startCapturing(completion: nil)
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
