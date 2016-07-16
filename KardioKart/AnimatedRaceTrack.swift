//
//  AnimatedRaceTrack.swift
//  KardioKart
//
//  Created by Bobby Ren on 7/14/16.
//  Copyright © 2016 Kartio. All rights reserved.
//

import UIKit

class AnimatedRaceTrack: RaceTrack {
    var speed: Double = 10
    var offset: Double = 0
    var timer: NSTimer?
    var timerInterval: NSTimeInterval = 0.01

    override func awakeFromNib() {
        super.awakeFromNib()
        self.timer = NSTimer.scheduledTimerWithTimeInterval(timerInterval, target: self, selector: #selector(tick), userInfo: nil, repeats: true)
        self.timer?.fire()
    }
    
    func tick() {
        guard self.pointsInPath.count > 0 else { return }
        offset = offset + (speed * timerInterval)
        if Int(offset) >= self.pointsInPath.count {
            offset = offset - Double(self.pointsInPath.count)
        }
        self.setNeedsLayout()
        NSNotificationCenter.defaultCenter().postNotificationName("positions:changed", object: nil)
    }
    
    override func pointIndexForSteps(steps: Int) -> Int {
        let pointIndex = super.pointIndexForSteps(steps)
        guard pointIndex >= 0 else { return -1 }
        return (pointIndex + Int(offset)) % self.pointsInPath.count
    }
}
