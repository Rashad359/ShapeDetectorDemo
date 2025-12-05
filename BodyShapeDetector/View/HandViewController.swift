//
//  HandViewController.swift
//  BodyShapeDetector
//
//  Created by Rəşad Əliyev on 12/5/25.
//

import UIKit
import Vision
import CoreML
import SnapKit

final class HandViewController: UIViewController {
    
    private let videoCapture = VideoCapture()
    
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
        setupUI()
        setupAndBeginCapturingVideoFrames()
    }
    
    private func setupUI() {
        view.addSubview(cameraImage)
        view.addSubview(handOverlayView)
        view.bringSubviewToFront(handOverlayView)
        
        cameraImage.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        videoCapture.startCapturing {
            super.viewWillAppear(animated)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        videoCapture.stopCapturing {
            super.viewWillDisappear(animated)
        }
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
        
        let handRequest = VNDetectHumanHandPoseRequest(completionHandler: handPoseHandler)
        handRequest.maximumHandCount = 1
        
        do {
            try requestHandler.perform([handRequest])
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
            let screenWidth = self.cameraImage.bounds.width
            let screenHeight = self.cameraImage.bounds.height
            
            let x = normalizedPoint.x * screenWidth
            let y = (1 - normalizedPoint.y) * screenHeight + 50
            
            self.handOverlayView.isHidden = false
            self.handOverlayView.center = CGPoint(x: x, y: y)
        }
        
    }
}

extension HandViewController: VideoCaptureDelegate {
    func videoCapture(_ videoCapture: VideoCapture, didCaptureFrame capturedImage: CGImage?, didOutput sampleBuffer: CMSampleBuffer) {
        guard let image = capturedImage else { fatalError("Captured image is nil") }
        
//        currentFrame = image
        
        self.processPose(cgImage: image)
        
        
        DispatchQueue.main.async {
            self.cameraImage.image = UIImage(cgImage: image, scale: 1.0, orientation: .right)
        }
    }
}

