//
//  AnimatedRaceTrack.swift
//  KardioKart
//
//  Created by Bobby Ren on 7/24/16.
//  Copyright © 2016 Kartio. All rights reserved.
//

import UIKit

class AnimatedRaceTrack: OvalRaceTrack {
    var speed: Double = 0.1 // in percent per second, 0 to 1
    var percentOffset: Double = 0 // 0 to 1
    var timer: NSTimer?
    var timerInterval: NSTimeInterval = 0.01 // in seconds
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.initiateAnimation()
    }
    
    func initiateAnimation() {
        self.timer = NSTimer.scheduledTimerWithTimeInterval(timerInterval, target: self, selector: #selector(tick), userInfo: nil, repeats: true)
        self.timer?.fire()
    }
    
    // MARK: Ticker for animation
    internal func tick() {
        percentOffset = percentOffset + (speed * timerInterval)
        if percentOffset >= 1 {
            percentOffset = percentOffset - 1
        }
        self.setNeedsLayout()
        NSNotificationCenter.defaultCenter().postNotificationName("positions:changed", object: nil)
    }

    // MARK: Display
    override func trackPosition(steps: Double) -> Double {
        var percent = min(1.0, steps / 10000.0) + percentOffset
        // for an animating track, percent is augmented
        if percent > 1.0 {
            percent = percent - 1.0
        }
        return percent
    }

}
