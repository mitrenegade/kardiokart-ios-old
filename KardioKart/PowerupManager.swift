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
    var timer: NSTimer?
    
    func initialize() {
        let interval: NSTimeInterval = 60 // poll every minute for new boxes
        timer = NSTimer.scheduledTimerWithTimeInterval(interval, target: self, selector: #selector(tick), userInfo: nil, repeats: true)
        timer!.fire()
    }
    
    // MARK: - Polling for powerups
    internal func tick() {
        // TODO: call server
        
    }
    
    class func queryPowerups(completion: ((results: [PFObject]?, error: NSError?)->Void)) {
        let query: PFQuery = PFQuery(className: "Activity")
        query.whereKey("count", equalTo: 3)        
    }

}
