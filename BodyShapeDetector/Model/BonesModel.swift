import Foundation
import Vision

struct BonesModel {
    static let bones: [(VNHumanBodyPoseObservation.JointName, VNHumanBodyPoseObservation.JointName)] = [
        (.rightShoulder, .leftShoulder),
        
        (.leftShoulder, .leftElbow),
        (.leftElbow, .leftWrist),

        (.rightShoulder, .rightElbow),
        (.rightElbow, .rightWrist),

        (.leftShoulder, .leftHip),
        (.rightShoulder, .rightHip),
        
        
        (.leftHip, .rightHip),
        
        
        (.leftHip, .leftKnee),
        (.leftKnee, .leftAnkle),

        
        (.rightHip, .rightKnee),
        (.rightKnee, .rightAnkle),
    ]
}
