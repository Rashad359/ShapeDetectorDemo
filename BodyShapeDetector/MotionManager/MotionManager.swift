import Foundation
import CoreMotion


final class MotionManager {
    
    static let shared = MotionManager()
    
    private let motionManager = CMMotionManager()
    
    func startDeviceMotionUpdates(completion: @escaping (Bool) -> Void) {
        guard motionManager.isDeviceMotionAvailable else {
            print("Device motion is not available")
            return
        }
        
        motionManager.deviceMotionUpdateInterval = 1.0 / 60.0
        
        motionManager.startDeviceMotionUpdates(to: OperationQueue.main) {[weak self] motion, error in
            guard let motion = motion, error == nil else {
                return
            }
            
            self?.detectTilt(from: motion, completion: completion)
        }
    }
    
    private func detectTilt(from motion: CMDeviceMotion, completion: @escaping (Bool) -> Void) {
        let roll = motion.attitude.roll
        
        let pitch = motion.attitude.pitch
        
        let rollDegrees = roll * 180 / .pi
        let pitchDegrees = pitch * 180 / .pi
        
        let tiltThreshold: Double = 20.0
        
        if abs(rollDegrees) > tiltThreshold && abs(pitchDegrees) > tiltThreshold {
            completion(true)
            
        } else {
            completion(false)
        }
    }
}
