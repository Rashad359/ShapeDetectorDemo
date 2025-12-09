//
//  VideoCapture.swift
//  BodyShapeDetector
//
//  Created by Rəşad Əliyev on 12/4/25.
//

import UIKit
import AVFoundation
import CoreVideo
import VideoToolbox

protocol VideoCaptureDelegate: AnyObject {
    func videoCapture(_ videoCapture: VideoCaptureManager, didCaptureFrame capturedImage: CGImage?, didOutput sampleBuffer: CMSampleBuffer)
}

final class VideoCaptureManager: NSObject {
    enum VideoCaptureError: Error {
        case captureIsMissing
        case invalidInput
        case invalidOutput
        case unknown
    }
    
    weak var delegate: VideoCaptureDelegate? = nil
    
    let captureSession = AVCaptureSession()
    
    let videoOutput = AVCaptureVideoDataOutput()
    
    private(set) var cameraPosition = AVCaptureDevice.Position.back
    
    private let sessionQueue = DispatchQueue(label: "Video_session")
    
    func flipCamera(completion: @escaping (Error?) -> Void) {
        sessionQueue.async {
            do {
                self.cameraPosition = self.cameraPosition == .back ? .front : .back
                
                self.captureSession.beginConfiguration()
                
                try self.setCaptureSessionInput()
                try self.setCaptureSessionOutput()
                
                self.captureSession.commitConfiguration()
                
                DispatchQueue.main.async {
                    completion(nil)
                }
            } catch {
                DispatchQueue.main.async {
                    completion(error)
                }
            }
        }
    }
    
    private func setCaptureSessionInput() throws {
        guard let captureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: cameraPosition) else {
            throw VideoCaptureError.invalidInput
        }
        
        captureSession.inputs.forEach { input in
            captureSession.removeInput(input)
        }
        
        guard let videoInput = try? AVCaptureDeviceInput(device: captureDevice) else {
            throw VideoCaptureError.invalidInput
        }
        
        guard captureSession.canAddInput(videoInput) else {
            throw VideoCaptureError.invalidInput
        }
        
        captureSession.addInput(videoInput)
    }
    
    private func setCaptureSessionOutput() throws {
        captureSession.outputs.forEach { output in
            captureSession.removeOutput(output)
        }
        
        let settings: [String: Any] = [
            String(kCVPixelBufferPixelFormatTypeKey): kCVPixelFormatType_420YpCbCr8BiPlanarFullRange
        ]
        
        videoOutput.videoSettings = settings
        
        videoOutput.alwaysDiscardsLateVideoFrames = true
        
        videoOutput.setSampleBufferDelegate(self, queue: sessionQueue)
        
        guard captureSession.canAddOutput(videoOutput) else {
            throw VideoCaptureError.invalidOutput
        }
        
        captureSession.addOutput(videoOutput)
    }
    
    func setupAVCapture(completion: @escaping (Error?) -> Void) {
        sessionQueue.async {
            do {
                try self.setupAVCapture()
                DispatchQueue.main.async {
                    completion(nil)
                }
            } catch {
                DispatchQueue.main.async {
                    completion(error)
                }
            }
        }
    }
    
    private func setupAVCapture() throws {
        if captureSession.isRunning {
            captureSession.stopRunning()
        }
        
        captureSession.beginConfiguration()
        
        captureSession.sessionPreset = .vga640x480
        
        try self.setCaptureSessionInput()
        try self.setCaptureSessionOutput()
        
        captureSession.commitConfiguration()
    }
    
    func startCapturing(completion completionHandler: (() -> Void)? = nil) {
        sessionQueue.async {
            if !self.captureSession.isRunning {
                self.captureSession.startRunning()
            }
            
            if let completionHandler {
                DispatchQueue.main.async {
                    completionHandler()
                }
            }
        }
    }
    
    func stopCapturing(completion completionHandler: (() -> Void)? = nil) {
        sessionQueue.async {
            if self.captureSession.isRunning {
                self.captureSession.stopRunning()
            }
            
            if let completionHandler {
                DispatchQueue.main.async {
                    completionHandler()
                }
            }
        }
    }
}

extension VideoCaptureManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let delegate = delegate else { return }
        
        if let pixelBuffer = sampleBuffer.imageBuffer {
            guard CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly) == kCVReturnSuccess else { return }
            
            var image: CGImage?
            
            VTCreateCGImageFromCVPixelBuffer(pixelBuffer, options: nil, imageOut: &image)
            
            CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly)
            
            DispatchQueue.main.async {
                delegate.videoCapture(self, didCaptureFrame: image, didOutput: sampleBuffer)
            }
        }
    }
}
