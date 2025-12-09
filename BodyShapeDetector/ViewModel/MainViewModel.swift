//
//  MainViewModel.swift
//  BodyShapeDetector
//
//  Created by Rəşad Əliyev on 12/9/25.
//

import UIKit
import Vision
import AVFoundation

// Change to combine later
protocol MainViewDelegate: AnyObject {
    func didAVCapture()
    func error(_ error: Error)
}

final class MainViewModel {
    private let videoCapture = VideoCaptureManager()
    
    private weak var delegate: MainViewDelegate? = nil
    
    func subscribe(_ delegate: MainViewDelegate) {
        self.delegate = delegate
    }
    
    func subscribeToVideoDelegate(to view: UIViewController) {
        videoCapture.delegate = view as? any VideoCaptureDelegate
    }
    
    func stopCapturing(completion: (() -> Void)?) {
        videoCapture.stopCapturing(completion: completion)
    }
    
    func startCapturing(completion: (() -> Void)?) {
        videoCapture.startCapturing(completion: completion)
    }
    
    func flipCamera() {
        videoCapture.flipCamera {[weak self] error in
            if let error {
                self?.delegate?.error(error)
            }
        }
    }
    
    func setupAVCapture() {
        videoCapture.setupAVCapture {[weak self] error in
            if let error {
                self?.delegate?.error(error)
            }
            
            self?.delegate?.didAVCapture()
        }
    }
    
    private func processPose(didOutput sampleImage: CGImage, forView testView: JointSegmentView) {
        let requestHandler = VNImageRequestHandler(cgImage: sampleImage, orientation: .right)
        
        let bodyRequest = VNDetectHumanBodyPoseRequest {[weak self] request, error in
            self?.bodyPoseHandler(request: request, error: error, forView: testView)
        }
        
        do {
            try requestHandler.perform([bodyRequest])
        } catch {
            print("Unable to perform the request: \(error).")
        }
    }
    
    private func bodyPoseHandler(request: VNRequest, error: Error?, forView testView: JointSegmentView) {
        guard let observations = request.results as? [VNHumanBodyPoseObservation],
              let observation = observations.first else {
            
            DispatchQueue.main.async {
                testView.joints = [:]
            }
            return
        }
        
        let bodyParts = getBodyJointsFor(observation: observation)
        
        DispatchQueue.main.async {
            testView.joints = bodyParts
        }
    }
    
    private func getBodyJointsFor(observation: VNHumanBodyPoseObservation) -> ([VNHumanBodyPoseObservation.JointName: CGPoint]) {
        
        var joints = [VNHumanBodyPoseObservation.JointName: CGPoint]()
        guard let identifiedPoints = try? observation.recognizedPoints(.all) else {
            return joints
        }
        for (key, point) in identifiedPoints {
            guard point.confidence > 0.1 else { continue }
            if BonesModel.bones.contains(where: { $0.0 == key || $0.1 == key }) {
                joints[key] = point.location
            }
        }
        
        // add right and left hip
        guard let rightShoulder = joints[.rightShoulder],
              let leftShoulder = joints[.leftShoulder],
              let leftHip = joints[.leftHip],
              let rightHip = joints[.rightHip] else { return joints }
        
        let shoulderMid = CGPoint(
            x: (rightShoulder.x + leftShoulder.x) / 2,
            y: (rightShoulder.y + leftShoulder.y) / 2
        )
        
        let hipMid = CGPoint(
            x: (rightHip.x + leftHip.x) / 2,
            y: (rightHip.y + leftHip.y) / 2
        )
        
        let horizontalOffset = shoulderMid.x - hipMid.x
        
        let leanThreshold: CGFloat = 0.1
        
        if horizontalOffset > leanThreshold {
            print("Leaning to the right")
        } else if horizontalOffset < -leanThreshold {
            print("Leaning to the left")
        } else {
            print("Standing upright")
        }
        
        return joints
    }
    
    func finishCameraSetup(didCaptureFrame capturedImage: CGImage, forView testView: JointSegmentView, cameraImage: UIImageView) {
        
        self.processPose(didOutput: capturedImage, forView: testView)
        
        
        DispatchQueue.main.async {
            cameraImage.image = UIImage(cgImage: capturedImage, scale: 1.0, orientation: .right)
        }
    }
}
