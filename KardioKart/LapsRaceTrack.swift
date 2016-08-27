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
    
    override func trackPosition(steps: Double) -> Double {
        let stepsPerLap = self.totalSteps / Double(self.totalLaps)
        let lapSteps = Double(steps) % stepsPerLap
        let percent = min(1, Double(lapSteps) / stepsPerLap)
        return percent
    }

}
