import UIKit
import Vision
import CoreML
import SnapKit
import Combine
import CoreMotion

final class MainViewController: BaseViewController {
    
    private let viewModel: MainViewModel
    
    private let motionManager = CMMotionManager()
    
    private var cancellables = Set<AnyCancellable>()
    
    init(viewModel: MainViewModel, currentFrame: CGImage? = nil) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private let leftIndicatorView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.green
        view.alpha = 0
        
        return view
    }()
    
    private let rightIndicatorView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.red
        view.alpha = 0
        
        return view
    }()
    
    private let warningLabel: UILabel = {
        let label = UILabel()
        label.text = "Don't tilt your camera"
        label.textColor = .red
        label.font = UIFont.systemFont(ofSize: 24, weight: .semibold)
        
        return label
    }()
    
    private let testView: JointSegmentView = {
        let view = JointSegmentView()
        
        return view
    }()
    
    private let testImage: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        
        return imageView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupNavigation()
        
        setupAndBeginCapturingVideoFrames()
        
        setupBindings()
        
        startDeviceMotionUpdates()
    }
    
    private func startDeviceMotionUpdates() {
        viewModel.startMotionUpdates {[weak self] isTilting in
            if isTilting {
                self?.warningLabel.text = "Don't tilt your camera"
                self?.warningLabel.textColor = .red
            } else {
                self?.warningLabel.text = "Hover over the person"
                self?.warningLabel.textColor = .green
            }
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
    
    override func setupUI() {
        [testImage, leftIndicatorView, rightIndicatorView, warningLabel, testView].forEach(view.addSubview)
        
        testImage.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        testView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        leftIndicatorView.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.height.equalToSuperview()
            make.width.equalTo(view.snp.width).multipliedBy(0.5)
        }
        
        rightIndicatorView.snp.makeConstraints { make in
            make.trailing.equalToSuperview()
            make.height.equalToSuperview()
            make.width.equalTo(view.snp.width).multipliedBy(0.5)
        }
        
        warningLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(10)
            make.centerX.equalToSuperview()
        }
        
    }
    
    private func setupAndBeginCapturingVideoFrames() {
        viewModel.setupAVCapture()
    }
    
    private func setupBindings() {
        
        viewModel.$didAVCapture.sink {[weak self] _ in
            guard let strongSelf = self else { return }
            self?.viewModel.subscribeToVideoDelegate(to: strongSelf)
            self?.viewModel.startCapturing(completion: nil)
        }.store(in: &cancellables)
        
        viewModel.$error.sink { error in
            if let error {
                print("Something went wrong in main: \(error)")
            }
        }.store(in: &cancellables)
        
        viewModel.$leaningTo.sink { leanDirection in
            switch leanDirection {
            case .left:
                UIView.animate(withDuration: 0.5) {[weak self] in
                    self?.leftIndicatorView.alpha = 0.6
                    self?.rightIndicatorView.alpha = 0
                }
            case .right:
                UIView.animate(withDuration: 0.5) {[weak self] in
                    self?.rightIndicatorView.alpha = 0.6
                    self?.leftIndicatorView.alpha = 0
                }
            case .none:
                UIView.animate(withDuration: 0.5) {[weak self] in
                    self?.rightIndicatorView.alpha = 0
                    self?.leftIndicatorView.alpha = 0
                }
            }
        }.store(in: &cancellables)
    }
    
    private func setupNavigation() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "arrow.trianglehead.2.clockwise.rotate.90.camera.fill"), style: .plain, target: self, action: #selector(didTapFlipCamera))
    }
    
    @objc private func didTapFlipCamera() {
        viewModel.flipCamera()
    }
}

extension MainViewController: VideoCaptureDelegate {
    func videoCapture(_ videoCapture: VideoCaptureManager, didCaptureFrame capturedImage: CGImage?, didOutput sampleBuffer: CMSampleBuffer) {
        guard let image = capturedImage else { fatalError("Captured image is nil") }
        
        viewModel.finishCameraSetup(didCaptureFrame: image, forView: testView, cameraImage: testImage)
    }
}
