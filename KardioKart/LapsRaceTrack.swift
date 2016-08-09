//
//  LapsRaceTrack.swift
//  KardioKart
//
//  Created by Bobby Ren on 8/7/16.
//  Copyright © 2016 Kartio. All rights reserved.
//

import UIKit

class LapsRaceTrack: OvalRaceTrack {
    var totalLaps: Int = 20
    
    override func pointForSteps(steps: Double) -> CGPoint? {
        let stepsPerLap = self.totalSteps / Double(self.totalLaps)
        let lapSteps = Double(steps) % stepsPerLap
        
        var percent = min(1, Double(lapSteps) / stepsPerLap)
        // for an animating track, percent is augmented
        if percent > 1.0 {
            percent = percent - 1.0
        }
        let point = self.pointForPercent(percent)
        //print("steps: \(steps) percent \(percent) point \(point)")
        return point
    }

}
