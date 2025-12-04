//
//  JointSegmentView.swift
//  BodyShapeDetector
//
//  Created by Rəşad Əliyev on 12/3/25.
//

import UIKit
import Vision

class JointSegmentView: UIView {
    var joints: [VNHumanBodyPoseObservation.JointName: CGPoint] = [:] {
        didSet {
            updatePathLayer()
        }
    }

    private let jointRadius: CGFloat = 3.0
    private let jointLayer = CAShapeLayer()
    private var jointPath = UIBezierPath()

    private let jointSegmentWidth: CGFloat = 2.0
    private let jointSegmentLayer = CAShapeLayer()
    private var jointSegmentPath = UIBezierPath()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayer()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayer()
    }

    func resetView() {
        jointLayer.path = nil
        jointSegmentLayer.path = nil
    }

    private func setupLayer() {
        jointSegmentLayer.lineCap = .round
        jointSegmentLayer.lineWidth = jointSegmentWidth
        jointSegmentLayer.fillColor = UIColor.clear.cgColor
        jointSegmentLayer.strokeColor = #colorLiteral(red: 0.6078431373, green: 0.9882352941, blue: 0, alpha: 1).cgColor
        layer.addSublayer(jointSegmentLayer)
        let jointColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1).cgColor
        jointLayer.strokeColor = jointColor
        jointLayer.fillColor = jointColor
        layer.addSublayer(jointLayer)
    }

//    private func updatePathLayer() {
//        let flipVertical = CGAffineTransform.verticalFlip
//        let scaleToBounds = CGAffineTransform(scaleX: bounds.width, y: bounds.height)
//        jointPath.removeAllPoints()
//        jointSegmentPath.removeAllPoints()
//        // Add all joints and segments
//        for index in 0 ..< jointsOfInterest.count {
//            if let nextJoint = joints[jointsOfInterest[index]] {
//                let nextJointScaled = nextJoint.applying(flipVertical).applying(scaleToBounds)
//                let nextJointPath = UIBezierPath(arcCenter: nextJointScaled, radius: jointRadius,
//                                                 startAngle: CGFloat(0), endAngle: CGFloat.pi * 2, clockwise: true)
//                jointPath.append(nextJointPath)
//                if jointSegmentPath.isEmpty {
//                    jointSegmentPath.move(to: nextJointScaled)
//                } else {
//                    jointSegmentPath.addLine(to: nextJointScaled)
//                }
//            }
//        }
//        jointLayer.path = jointPath.cgPath
//        jointSegmentLayer.path = jointSegmentPath.cgPath
//    }
    
    private func updatePathLayer() {
           let flipVertical = CGAffineTransform.verticalFlip
           let scaleToBounds = CGAffineTransform(scaleX: bounds.width, y: bounds.height)

           jointPath.removeAllPoints()
           jointSegmentPath.removeAllPoints()

           // Draw circles for joints
           for (_, point) in joints {
               let p = point.applying(flipVertical).applying(scaleToBounds)
               jointPath.append(UIBezierPath(arcCenter: p,
                                             radius: jointRadius,
                                             startAngle: 0,
                                             endAngle: .pi * 2,
                                             clockwise: true))
           }

           // Draw independent bone segments
           for (j1, j2) in bones {
               if let p1 = joints[j1], let p2 = joints[j2] {
                   let p1s = p1.applying(flipVertical).applying(scaleToBounds)
                   let p2s = p2.applying(flipVertical).applying(scaleToBounds)

                   jointSegmentPath.move(to: p1s)
                   jointSegmentPath.addLine(to: p2s)
               }
           }

           jointLayer.path = jointPath.cgPath
           jointSegmentLayer.path = jointSegmentPath.cgPath
       }
}

// MARK: - Place extension to different folders later
extension CGAffineTransform {
    static var verticalFlip = CGAffineTransform(scaleX: 1, y: -1).translatedBy(x: 0, y: -1)
}

//let jointsOfInterest: [VNHumanBodyPoseObservation.JointName] = [
//    .rightWrist,
//    .rightElbow,
//    .rightShoulder,
//    .rightHip,
//    .rightKnee,
//    .rightAnkle
//]

