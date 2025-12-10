import UIKit
import Vision

class JointSegmentView: UIView {
    var joints: [VNHumanBodyPoseObservation.JointName: CGPoint] = [:] {
        didSet {
            updatePathLayer()
        }
    }
    
    var imageSize: CGSize = .zero {
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
    
    private func getImageDisplayRect(imageSize: CGSize, viewBounds: CGRect, contentMode: UIView.ContentMode) -> CGRect {
        guard imageSize.width > 0 && imageSize.height > 0 else {
            return viewBounds
        }
        
        let imageAspect = imageSize.width / imageSize.height
        let viewAspect = viewBounds.width / viewBounds.height
        
        var displayRect = CGRect.zero
        
        switch contentMode {
        case .scaleAspectFit:
            if imageAspect > viewAspect {
                displayRect.size.width = viewBounds.width
                displayRect.size.height = viewBounds.width / imageAspect
                displayRect.origin.x = 0
                displayRect.origin.y = (viewBounds.height - displayRect.height) / 2
            } else {
                displayRect.size.height = viewBounds.height
                displayRect.size.width = viewBounds.height * imageAspect
                displayRect.origin.x = (viewBounds.width - displayRect.width) / 2
                displayRect.origin.y = 0
            }
            
        case .scaleAspectFill:
            if imageAspect > viewAspect {
                displayRect.size.width = viewBounds.height
                displayRect.size.height = viewBounds.height * imageAspect
                displayRect.origin.x = (viewBounds.width - displayRect.width) / 2
                displayRect.origin.y = 0
            } else {
                displayRect.size.width = viewBounds.width
                displayRect.size.height = viewBounds.width / imageAspect
                displayRect.origin.x = 0
                displayRect.origin.y = (viewBounds.height - displayRect.height) / 2
            }
        default:
            displayRect = viewBounds
        }
        
        return displayRect
    }
    
    private func updatePathLayer() {
           let flipVertical = CGAffineTransform.verticalFlip
        
        let imageDisplayRect = getImageDisplayRect(imageSize: imageSize, viewBounds: bounds, contentMode: contentMode)
        
        let scaleToImageRect = CGAffineTransform(scaleX: imageDisplayRect.width, y: imageDisplayRect.height)
        let translateToImageRect = CGAffineTransform(translationX: imageDisplayRect.origin.x, y: imageDisplayRect.origin.y)

           jointPath.removeAllPoints()
           jointSegmentPath.removeAllPoints()

           // Draw circles for joints
           for (_, point) in joints {
               let p = point.applying(flipVertical).applying(scaleToImageRect).applying(translateToImageRect)
               jointPath.append(UIBezierPath(arcCenter: p,
                                             radius: jointRadius,
                                             startAngle: 0,
                                             endAngle: .pi * 2,
                                             clockwise: true))
           }

           // Draw independent bone segments
        for (j1, j2) in BonesModel.bones {
               if let p1 = joints[j1], let p2 = joints[j2] {
                   let p1s = p1.applying(flipVertical).applying(scaleToImageRect).applying(translateToImageRect)
                   let p2s = p2.applying(flipVertical).applying(scaleToImageRect).applying(translateToImageRect)

                   jointSegmentPath.move(to: p1s)
                   jointSegmentPath.addLine(to: p2s)
               }
           }

           jointLayer.path = jointPath.cgPath
           jointSegmentLayer.path = jointSegmentPath.cgPath
       }
}
