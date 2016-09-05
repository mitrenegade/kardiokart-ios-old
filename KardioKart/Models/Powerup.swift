//
//  Powerup.swift
//  KardioKart
//
//  Created by Bobby Ren on 9/5/16.
//  Copyright © 2016 Kartio. All rights reserved.
//

import UIKit
import Parse

class Powerup: PFObject {
    @NSManaged var count: NSNumber?
    @NSManaged var position: NSNumber?
    @NSManaged var race: PFObject?
}

extension Powerup: PFSubclassing {
    static func parseClassName() -> String {
        return "Powerup"
    }
}

