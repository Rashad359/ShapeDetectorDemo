

import UIKit
import Vision
import CoreML
import SnapKit

class ViewController: UIViewController {
    
    private let videoCapture = VideoCapture()
    
    private var currentFrame: CGImage?
    
    private let testView: JointSegmentView = {
        let view = JointSegmentView()
        
        return view
    }()
    
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
    
    private let testImage: UIImageView = {
        let imageView = UIImageView()
//        imageView.image = .test2Photo
        
        return imageView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupAndBeginCapturingVideoFrames()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        videoCapture.stopCapturing {
            super.viewWillDisappear(animated)
        }
    }
    
    private func setupUI() {
        view.addSubview(testImage)
        view.addSubview(testView)
        view.bringSubviewToFront(testView)
        view.addSubview(handOverlayView)
        view.bringSubviewToFront(handOverlayView)
        
        testImage.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        testView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        testView.frame = testImage.frame
    }
    
    private func setupAndBeginCapturingVideoFrames() {
        videoCapture.setupAVCapture { error in
            if let error {
                print("Something went wrong: \(error)")
            }
            
            self.videoCapture.delegate = self
            
            self.videoCapture.startCapturing()
        }
    }
    
    private func processPose(cgImage: CGImage?) {
        
        guard let image = cgImage else { return }
        
        let requestHandler = VNImageRequestHandler(cgImage: image, orientation: .right)
        
        let bodyRequest = VNDetectHumanBodyPoseRequest(completionHandler: bodyPoseHandler)
        
        let handRequest = VNDetectHumanHandPoseRequest(completionHandler: handPoseHandler)
        handRequest.maximumHandCount = 1
        
        do {
            try requestHandler.perform([bodyRequest, handRequest])
        } catch {
            print("Unable to perform the request: \(error).")
        }
    }
    
    private func handPoseHandler(request: VNRequest, error: Error?) {
        guard let observations = request.results as? [VNHumanHandPoseObservation],
              let observation = observations.first else {
            DispatchQueue.main.async {
                self.handOverlayView.isHidden = true
            }
            return
        }
        
        guard let point = try? observation.recognizedPoint(.middleMCP),
              point.confidence > 0.2 else {
            DispatchQueue.main.async {
                self.handOverlayView.isHidden = true
            }
           return
        }
        
        let normalizedPoint = point.location
        
        DispatchQueue.main.async {
            let screenWidth = self.testImage.bounds.width
            let screenHeight = self.testImage.bounds.height
            
            let x = normalizedPoint.x * screenWidth
            let y = (1 - normalizedPoint.y) * screenHeight + 50
            
            self.handOverlayView.isHidden = false
            self.handOverlayView.center = CGPoint(x: x, y: y)
        }
        
    }
    
    private func bodyPoseHandler(request: VNRequest, error: Error?) {
        guard let observations = request.results as? [VNHumanBodyPoseObservation],
              let observation = observations.first else {
            
            DispatchQueue.main.async {
                self.testView.joints = [:]
            }
            return
        }
        
        let bodyParts = getBodyJointsFor(observation: observation)
        
        DispatchQueue.main.async {
            self.testView.joints = bodyParts
        }
    }
    
    private func getBodyJointsFor(observation: VNHumanBodyPoseObservation) -> ([VNHumanBodyPoseObservation.JointName: CGPoint]) {
        
        var joints = [VNHumanBodyPoseObservation.JointName: CGPoint]()
        guard let identifiedPoints = try? observation.recognizedPoints(.all) else {
            return joints
        }
        for (key, point) in identifiedPoints {
            guard point.confidence > 0.1 else { continue }
            if bones.contains(where: { $0.0 == key || $0.1 == key }) {
                joints[key] = point.location
            }
        }
        return joints
    }
    
    private func processObservation(_ observation: VNHumanBodyPoseObservation) {
        guard let recognizedPoints = try? observation.recognizedPoints(.all) else { return }
        
        let torsoJointNames: [VNHumanBodyPoseObservation.JointName] = [
            .neck,
            .rightShoulder,
            .rightHip,
            .root,
            .leftHip,
            .leftShoulder,
            .leftElbow,
            .leftWrist
        ]
        
        let imagePoints: [CGPoint] = torsoJointNames.compactMap {
            guard let point = recognizedPoints[$0], point.confidence > 0 else { return nil }
            
            // Set width and height later
            return VNImagePointForNormalizedPoint(point.location, Int(testImage.image?.size.width ?? 0), Int(testImage.image?.size.height ?? 0))
        }
        
        imagePoints.forEach { point in
            let view = UIView()
            view.frame = CGRect(x: point.x, y: point.y, width: 40, height: 40)
            view.backgroundColor = .red
            self.view.addSubview(view)
        }
    }
}


let bones: [(VNHumanBodyPoseObservation.JointName, VNHumanBodyPoseObservation.JointName)] = [
    (.neck, .leftShoulder),
    (.leftShoulder, .leftElbow),
    (.leftElbow, .leftWrist),

    (.neck, .rightShoulder),
    (.rightShoulder, .rightElbow),
    (.rightElbow, .rightWrist),

    (.neck, .root),
    
    (.root, .leftKnee),
    (.leftKnee, .leftAnkle),

    (.root, .rightKnee),
    (.rightKnee, .rightAnkle),
]


extension ViewController: VideoCaptureDelegate {
    func videoCapture(_ videoCapture: VideoCapture, didCaptureFrame capturedImage: CGImage?, didOutput sampleBuffer: CMSampleBuffer) {
        guard let image = capturedImage else { fatalError("Captured image is nil") }
        
        currentFrame = image
        
        self.processPose(cgImage: image)
        
        
        DispatchQueue.main.async {
            self.testImage.image = UIImage(cgImage: image, scale: 1.0, orientation: .right)
        }
    }
}
