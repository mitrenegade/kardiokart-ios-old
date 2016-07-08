//
//  RaceTrack.swift
//  KardioKart
//
//  Created by Robinson Greig on 10/25/15.
//  Copyright © 2015 Kartio. All rights reserved.
//

import UIKit

class RaceTrack: UIView {

    override func drawRect(rect: CGRect) {
        let radius = rect.width / 2
        let lineWidth = 5.0
        let insetRect = CGRectInset(rect, CGFloat(lineWidth / 2.0), CGFloat(lineWidth / 2.0))
        let trackPath = UIBezierPath(roundedRect: insetRect, cornerRadius: radius)
        UIColor(red:0.333,  green:0.427,  blue:0.475, alpha:1).setStroke()
        trackPath.lineWidth = CGFloat(lineWidth)
        trackPath.stroke()
    }
    
   /* - (void)drawRect:(CGRect)rect
    {
    // Create an oval shape to draw.
    UIBezierPath *aPath = [UIBezierPath bezierPathWithOvalInRect:
    CGRectMake(0, 0, 200, 100)];
    
    // Set the render colors.
    [[UIColor blackColor] setStroke];
    [[UIColor redColor] setFill];
    
    CGContextRef aRef = UIGraphicsGetCurrentContext();
    
    // If you have content to draw after the shape,
    // save the current state before changing the transform.
    //CGContextSaveGState(aRef);
    
    // Adjust the view's origin temporarily. The oval is
    // now drawn relative to the new origin point.
    CGContextTranslateCTM(aRef, 50, 50);
    
    // Adjust the drawing options as needed.
    aPath.lineWidth = 5;
    
    // Fill the path before stroking it so that the fill
    // color does not obscure the stroked line.
    [aPath fill];
    [aPath stroke];
    
    // Restore the graphics state before drawing any other content.
    //CGContextRestoreGState(aRef);
    }*/

    
    
    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
    }
    */

}
