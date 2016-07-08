//
//  RaceTrack.swift
//  KardioKart
//
//  Created by Robinson Greig on 10/25/15.
//  Copyright © 2015 Kartio. All rights reserved.
//

import UIKit

class RaceTrack: UIView {
    var path = UIBezierPath()

    override func drawRect(rect: CGRect) {
        let radius = rect.width / 2
        let lineWidth = 5.0
        let insetRect = CGRectInset(rect, CGFloat(lineWidth / 2.0), CGFloat(lineWidth / 2.0))
        path = UIBezierPath(roundedRect: insetRect, cornerRadius: radius)
        UIColor(red:0.333,  green:0.427,  blue:0.475, alpha:1).setStroke()
        path.lineWidth = CGFloat(lineWidth)
        path.stroke()
    }

}
