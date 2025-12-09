

import UIKit
import Vision
import CoreML
import SnapKit

class MainViewController: BaseViewController {
    
    private let viewModel: MainViewModel
    
    init(viewModel: MainViewModel, currentFrame: CGImage? = nil) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private let testView: JointSegmentView = {
        let view = JointSegmentView()
        
        return view
    }()
    
    private let testImage: UIImageView = {
        let imageView = UIImageView()
        
        return imageView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigation()
        setupAndBeginCapturingVideoFrames()
        viewModel.subscribe(self)
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
        view.addSubview(testImage)
        view.addSubview(testView)
        view.bringSubviewToFront(testView)
        
        testImage.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        testView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        testView.frame = testImage.frame
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
}

extension MainViewController: MainViewDelegate {
    func didAVCapture() {
        viewModel.subscribeToVideoDelegate(to: self)
        viewModel.startCapturing(completion: nil)
    }
    
    func error(_ error: any Error) {
        print("Somehting went wrong in main delegate \(error)")
    }
    
    
}

extension MainViewController: VideoCaptureDelegate {
    func videoCapture(_ videoCapture: VideoCaptureManager, didCaptureFrame capturedImage: CGImage?, didOutput sampleBuffer: CMSampleBuffer) {
        guard let image = capturedImage else { fatalError("Captured image is nil") }
        
        viewModel.finishCameraSetup(didCaptureFrame: image, forView: testView, cameraImage: testImage)
    }
}


// MARK: - Unused or deprecated code (delete later)

//    private func processObservation(_ observation: VNHumanBodyPoseObservation) {
//        guard let recognizedPoints = try? observation.recognizedPoints(.all) else { return }
//
//        let torsoJointNames: [VNHumanBodyPoseObservation.JointName] = [
//            .neck,
//            .rightShoulder,
//            .rightHip,
//            .root,
//            .leftHip,
//            .leftShoulder,
//            .leftElbow,
//            .leftWrist
//        ]
//
//        let imagePoints: [CGPoint] = torsoJointNames.compactMap {
//            guard let point = recognizedPoints[$0], point.confidence > 0 else { return nil }
//
//            // Set width and height later
//            return VNImagePointForNormalizedPoint(point.location, Int(testImage.image?.size.width ?? 0), Int(testImage.image?.size.height ?? 0))
//        }
//
//        imagePoints.forEach { point in
//            let view = UIView()
//            view.frame = CGRect(x: point.x, y: point.y, width: 40, height: 40)
//            view.backgroundColor = .red
//            self.view.addSubview(view)
//        }
//    }
