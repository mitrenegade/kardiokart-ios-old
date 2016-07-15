//
//  RaceTrack.swift
//  KardioKart
//
//  Created by Robinson Greig on 10/25/15.
//  Copyright © 2015 Kartio. All rights reserved.
//

import UIKit

class RaceTrack: UIView {
    var path: UIBezierPath! {
        didSet {
            var translation = CGAffineTransformMakeTranslation(CGFloat(self.frame.origin.x), CGFloat(self.frame.origin.y))
            let copy = CGPathCreateMutableCopy(CGPathCreateCopyByDashingPath(self.path.CGPath, &translation, 0.0, [2,2], 2))
            self.pointsInPath.removeAll()
            
            myPathApply(copy) { element in
                switch element.memory.type {
                case .MoveToPoint:
                    self.pointsInPath.append(element.memory.points[0])
                case .AddLineToPoint:
                    self.pointsInPath.append(element.memory.points[0])
                case .AddQuadCurveToPoint:
                    self.pointsInPath.append(element.memory.points[0])
                    self.pointsInPath.append(element.memory.points[1])
                case .AddCurveToPoint:
                    self.pointsInPath.append(element.memory.points[0])
                    self.pointsInPath.append(element.memory.points[1])
                default:
                    break
                }
                print("point: \(element.memory.points[0]), \(element.memory.points[1])")
            }
        }
    }
    var pointsInPath = [CGPoint]()

    // Track parameters
    var trackColor: UIColor {
        return UIColor(red:0.333,  green:0.427,  blue:0.475, alpha:1)
    }
    
    var trackWidth: CGFloat {
        return 5.0
    }

    // Track points
    typealias MyPathApplier = @convention(block) (UnsafePointer<CGPathElement>) -> Void
    
    private func myPathApply(path: CGPath!, block: MyPathApplier) {
        let callback: @convention(c) (UnsafeMutablePointer<Void>, UnsafePointer<CGPathElement>) -> Void = { (info, element) in
            let block = unsafeBitCast(info, MyPathApplier.self)
            block(element)
        }
        
        CGPathApply(path, unsafeBitCast(block, UnsafeMutablePointer<Void>.self), unsafeBitCast(callback, CGPathApplierFunction.self))
    }
    
    // draw
    override func drawRect(rect: CGRect) {
        let radius = self.frame.width / 2
        var rect = self.frame
        rect.origin.x = 0
        rect.origin.y = 0
        let insetRect = CGRectInset(rect, CGFloat(self.trackWidth/2), CGFloat(self.trackWidth))
        self.path = UIBezierPath(roundedRect: insetRect, cornerRadius: radius)

        self.trackColor.setStroke()
        path.lineWidth = CGFloat(self.trackWidth)
        path.stroke()
    }


    // Track calculations
    func pointForSteps(steps: Int) -> CGPoint? {
        guard pointsInPath.count > 0 else { return nil }
        let pointIndex: Int = steps % pointsInPath.count

        guard pointsInPath.count > pointIndex else { return nil }
        return pointsInPath[pointIndex]
    }
}
