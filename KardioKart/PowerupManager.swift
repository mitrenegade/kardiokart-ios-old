//
//  PowerupManager.swift
//  KardioKart
//
//  Created by Bobby Ren on 7/29/16.
//  Copyright © 2016 Kartio. All rights reserved.
//
// for now, handles polling

import UIKit
import Parse

class PowerupManager: NSObject {
    static let sharedManager = PowerupManager()

    var timer: NSTimer?
    var powerups: [PFObject]?
    
    func initialize() {
        let interval: NSTimeInterval = 5 // poll every minute for new boxes
        timer = NSTimer.scheduledTimerWithTimeInterval(interval, target: self, selector: #selector(tick), userInfo: nil, repeats: true)
        timer!.fire()
    }
    
    // MARK: - Polling for powerups
    internal func tick() {
        self.queryPowerups { (results, error) in
            if let error = error {
                print("Error in querying powerups: \(error)")
            }
            else {
                self.powerups = results
                print("Powerups: \(self.powerups?.count)")
                NSNotificationCenter.defaultCenter().postNotificationName("powerups:changed", object: nil)
            }
        }
    }
    
    func queryPowerups(completion: ((results: [PFObject]?, error: NSError?)->Void)) {
//        let query: PFQuery = PFQuery(className: "Powerup")
//        query.whereKey("count", greaterThan: 0)
//        query.findObjectsInBackgroundWithBlock { (results, error) in
//            completion(results: results, error: error)
//        }
    }

}
