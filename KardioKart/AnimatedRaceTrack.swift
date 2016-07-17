//
//  AnimatedRaceTrack.swift
//  KardioKart
//
//  Created by Bobby Ren on 7/14/16.
//  Copyright © 2016 Kartio. All rights reserved.
//

import UIKit

class AnimatedRaceTrack: RaceTrack {
    var speed: Double = 0.1 // in percent per second, 0 to 1
    var percentOffset: Double = 0 // 0 to 1
    var timer: NSTimer?
    var timerInterval: NSTimeInterval = 0.01 // in seconds

    // path calculated by portions
    var radius: CGFloat!
    var point0: CGPoint! // beginning of segment0 (straight)
    var point1: CGPoint! // end of segment0, beginning of segment1 (arc)
    var center2: CGPoint! // center of segment 1
    var point3: CGPoint! // beginning of segment 2 (straight)
    var point4: CGPoint! // end of segment2, beginning of segment3 (arc)
    var center5: CGPoint! // center of segment3
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.timer = NSTimer.scheduledTimerWithTimeInterval(timerInterval, target: self, selector: #selector(tick), userInfo: nil, repeats: true)
        self.timer?.fire()
    }
    
    func tick() {
        percentOffset = percentOffset + (speed * timerInterval)
        if percentOffset >= 1 {
            percentOffset = percentOffset - 1
        }
        self.setNeedsLayout()
        NSNotificationCenter.defaultCenter().postNotificationName("positions:changed", object: nil)
    }

    override func pointForSteps(steps: Int) -> CGPoint? {
        var percent = min(1, Double(steps) / 10000.0) + percentOffset
        // for an animating track, percent is augmented
        if percent > 1.0 {
            percent = percent - 1.0
        }
        let point = self.pointForPercent(percent)
//        print("steps: \(steps) percent \(percent) point \(point)")
        return point
    }
    
    func setupPoints() {
        self.radius = self.frame.size.width / 2 - self.trackWidth

        point0 = CGPointMake(self.trackWidth, self.frame.size.height - self.trackWidth - self.radius)
        point1 = CGPointMake(self.trackWidth, self.radius + self.trackWidth)
        center2 = CGPointMake(self.radius + self.trackWidth, self.radius + self.trackWidth)
        point3 = CGPointMake(self.frame.size.width - self.trackWidth, self.radius + self.trackWidth)
        point4 = CGPointMake(self.frame.size.width - self.trackWidth, self.frame.size.height - self.trackWidth - self.radius)
        center5 = CGPointMake(self.radius + self.trackWidth, self.frame.size.height - self.radius - self.trackWidth)
    }

    override func setupTrack() {
        self.setupPoints()
        
        let path = CGPathCreateMutable()
        
        // segment 0: straight line
        CGPathMoveToPoint(path, nil, self.point0.x, self.point0.y)
        CGPathAddLineToPoint(path, nil, self.point1.x, self.point1.y)
        
        // segment 1: arc
        // Positive Y axis is down
        // also clockwise seems to be reversed
        CGPathAddArc(path, nil, self.center2.x, self.center2.y, self.radius, CGFloat(M_PI), CGFloat(2*M_PI), false)

        CGPathMoveToPoint(path, nil, self.point3.x, self.point3.y)
        CGPathAddLineToPoint(path, nil, self.point4.x, self.point4.y)
        CGPathAddArc(path, nil, self.center5.x, self.center5.y, self.radius, 0, CGFloat(M_PI), false)

        self.path = UIBezierPath(CGPath: path)
    }
    
    func lengthOfSegment(segment: RaceTrackSegment) -> CGFloat {
        if segment == .Straight0 {
            let length = self.point0.y - self.point1.y
            //print("length of segment \(segment) = \(length)")
            return length
        }
        else if segment == .Straight2 {
            let length = self.point4.y - self.point3.y
            //print("length of segment \(segment) = \(length)")
            return length
        }
        let length = CGFloat(M_PI) * self.radius
        //print("length of segment \(segment) = \(length)")
        return length
    }
    
    func totalLength() -> CGFloat {
        let segments: [RaceTrackSegment] = [.Straight0, .Arc1, .Straight2, .Arc3]
        let length = segments.map { (segment) -> CGFloat in
            return self.lengthOfSegment(segment)
        }.reduce(0, combine: +)
        return length
    }
    
    func segmentForPercent(percent: Double) -> RaceTrackSegment {
        var lengthOfTrackCovered = self.totalLength() * CGFloat(percent)
//        print("finding segment for \(percent)")
        let segments: [RaceTrackSegment] = [.Straight0, .Arc1, .Straight2, .Arc3]
        for segment in segments {
            let segmentLength = self.lengthOfSegment(segment)
//            print("length left: \(lengthOfTrackCovered) segment \(segment) = \(segmentLength)")
            if lengthOfTrackCovered < segmentLength {
                return segment
            }
            lengthOfTrackCovered -= segmentLength
        }
        return .Arc3 // last segment
    }
    
    func pointForPercent(percent: Double) -> CGPoint {
        let segment = segmentForPercent(percent)
        switch segment {
        case .Straight0:
            let length = CGFloat(percent) * self.totalLength()
            return CGPointMake(self.point0.x, self.point0.y - length)
        case .Arc1:
            let length = CGFloat(percent) * self.totalLength() - self.lengthOfSegment(.Straight0)
            let angle = CGFloat(M_PI) * (length / self.lengthOfSegment(.Arc1))
//            print("length \(length) of \(self.lengthOfSegment(.Arc1)) angle \(angle) x \(x) y \(y)")
            let x = self.center2.x - self.radius * cos(angle)
            let y = self.center2.y - self.radius * sin(angle)
            return CGPointMake(x, y)
        case .Straight2:
            let length = self.totalLength() * CGFloat(percent)  - self.lengthOfSegment(.Straight0) - self.lengthOfSegment(.Arc1)
            return CGPointMake(self.point3.x, self.point3.y + length)
        case .Arc3:
            let length = CGFloat(percent) * self.totalLength() - self.lengthOfSegment(.Straight0) - self.lengthOfSegment(.Arc1) - self.lengthOfSegment(.Straight2)
            let angle = CGFloat(M_PI) * (length / self.lengthOfSegment(.Arc3))
            //            print("length \(length) of \(self.lengthOfSegment(.Arc3)) angle \(angle) x \(x) y \(y)")
            let x = self.center5.x + self.radius * cos(angle)
            let y = self.center5.y + self.radius * sin(angle)
            return CGPointMake(x, y)
        }
    }
}
