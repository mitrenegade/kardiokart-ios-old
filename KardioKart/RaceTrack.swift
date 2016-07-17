//
//  RaceTrack.swift
//  KardioKart
//
//  Created by Robinson Greig on 10/25/15.
//  Copyright © 2015 Kartio. All rights reserved.
//

import UIKit

enum RaceTrackSegment {
    case Straight0
    case Arc1
    case Straight2
    case Arc3
}

// THIS CLASS SHOULD BE ABSTRACT

class RaceTrack: UIView {
    var path: UIBezierPath!

    // Track parameters
    var trackColor: UIColor {
        return UIColor(red:0.333,  green:0.427,  blue:0.475, alpha:1)
    }
    
    var trackWidth: CGFloat {
        return 5.0
    }

    // draw
    override func drawRect(rect: CGRect) {
        self.setupTrack()
        self.trackColor.setStroke()
        path.lineWidth = CGFloat(self.trackWidth)
        path.stroke()
    }
    
    internal func setupTrack() {
        let radius = self.frame.width / 2
        var rect = self.frame
        rect.origin.x = 0
        rect.origin.y = 0
        let insetRect = CGRectInset(rect, CGFloat(self.trackWidth/2), CGFloat(self.trackWidth))
        self.path = UIBezierPath(roundedRect: insetRect, cornerRadius: radius)
    }

    // MARK: - Track calculations
    func pointForSteps(steps: Int) -> CGPoint? {
        return CGPointMake(self.frame.size.width / 2, self.frame.size.height / 2)
    }
    
    func pointForStart() -> CGPoint? {
        return self.pointForSteps(0)
    }
}
