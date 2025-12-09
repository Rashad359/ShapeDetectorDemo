//
//  HandViewModel.swift
//  BodyShapeDetector
//
//  Created by Rəşad Əliyev on 12/5/25.
//

import UIKit
import Vision
import Combine

final class HandViewModel {
    
    @Published private(set) var didFinishProcess: Bool = false
    
    @Published private(set) var error: Error? = nil
    
    private let videoCapture = VideoCaptureManager()
    
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
                self?.error = error
            }
        }
    }
    
    func setupAVCapture() {
        videoCapture.setupAVCapture {[weak self] error in
            if let error {
                self?.error = error
            }
            
            self?.didFinishProcess = true
        }
    }
    
    private func processPose(cgImage: CGImage?, forView overlayView: UIView, camera: UIImageView) {
        
        guard let image = cgImage else { return }

        let requestHandler = VNImageRequestHandler(cgImage: image, orientation: .right)

        let handRequest = VNDetectHumanHandPoseRequest {[weak self] request, error in
            self?.handPoseHandler(request: request, error: error, overlayView: overlayView, camera: camera)
        }
        handRequest.maximumHandCount = 1

        do {
            try requestHandler.perform([handRequest])
        } catch {
            print("Unable to perform the request: \(error).")
        }
    }
    
    private func handPoseHandler(request: VNRequest, error: Error?, overlayView: UIView, camera: UIImageView) {
        guard let observations = request.results as? [VNHumanHandPoseObservation],
              let observation = observations.first else {
            DispatchQueue.main.async {
                overlayView.isHidden = true
            }
            return
        }
        
        guard let point = try? observation.recognizedPoint(.middleMCP),
              point.confidence > 0.2 else {
            DispatchQueue.main.async {
                overlayView.isHidden = true
            }
           return
        }
        
        let normalizedPoint = point.location
        
        DispatchQueue.main.async {
            let screenWidth = camera.bounds.width
            let screenHeight = camera.bounds.height
            
            let x = normalizedPoint.x * screenWidth
            let y = (1 - normalizedPoint.y) * screenHeight + 50
            
            overlayView.isHidden = false
            overlayView.center = CGPoint(x: x, y: y)
        }
        
    }
    
    func finishCameraSetup(didCaptureFrame capturedImage: CGImage?, forView overlayView: UIView, with camera: UIImageView) {
        guard let image = capturedImage else { fatalError("Captured image is nil") }
        
        self.processPose(cgImage: image, forView: overlayView, camera: camera)
        
        
        DispatchQueue.main.async {
            
            camera.image = UIImage(cgImage: image, scale: 1.0, orientation: .right)
        }
    }
}
