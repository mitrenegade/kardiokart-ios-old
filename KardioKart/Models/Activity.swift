//
//  Activity.swift
//  KardioKart
//
//  Created by Bobby Ren on 9/19/16.
//  Copyright © 2016 Kartio. All rights reserved.
//

import UIKit
import Parse

class Activity: PFObject {
    @NSManaged var stepCount: NSNumber?
    @NSManaged var stepDate: NSNumber?
    
    @NSManaged var user: PFUser?
    @NSManaged var race: PFObject?
}

extension Activity: PFSubclassing {
    static func parseClassName() -> String {
        return "Activity"
    }
}