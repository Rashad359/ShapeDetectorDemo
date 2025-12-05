

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
    
    private let testImage: UIImageView = {
        let imageView = UIImageView()
        
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
    
    override func viewWillAppear(_ animated: Bool) {
        videoCapture.startCapturing {
            super.viewWillAppear(animated)
        }
    }
    
    private func setupUI() {
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
        
        do {
            try requestHandler.perform([bodyRequest])
        } catch {
            print("Unable to perform the request: \(error).")
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
        
        // add right and left hip
        guard let rightShoulder = joints[.rightShoulder],
              let leftShoulder = joints[.leftShoulder],
              let leftHip = joints[.leftHip],
              let rightHip = joints[.rightHip] else { return joints }
        
        let shoulderMidX = (rightShoulder.x + leftShoulder.x) / 2
        let hipMidX = (rightHip.x + leftHip.x) / 2
        
        let horizontalOffset = shoulderMidX - hipMidX
        
        let leanThreshold: CGFloat = 0.03
        
        if horizontalOffset > leanThreshold {
            print("Leaning to the right")
        } else if horizontalOffset < -leanThreshold {
            print("Leaning to the left")
        } else {
            print("Standing upright")
        }
        
        return joints
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
    
    (.root, .leftHip),
    (.root, .rightHip),
    
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
