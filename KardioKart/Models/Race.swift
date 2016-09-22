//
//  Race.swift
//  KardioKart
//
//  Created by Bobby Ren on 9/22/16.
//  Copyright © 2016 Kartio. All rights reserved.
//
import UIKit
import Parse

class Race: PFObject {
    @NSManaged var day: NSNumber?
    @NSManaged var totalSteps: NSNumber?
}

extension Race: PFSubclassing {
    static func parseClassName() -> String {
        return "Race"
    }
}

