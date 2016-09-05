//
//  PowerupItem.swift
//  KardioKart
//
//  Created by Bobby Ren on 9/5/16.
//  Copyright © 2016 Kartio. All rights reserved.
//

import UIKit
import Parse

enum PowerupItemType: String {
    case Mushroom = "mushroom"
    case RedShell = "redshell"
}

class PowerupItem: PFObject {
    @NSManaged var type: String?
    
    @NSManaged var user: PFUser?
}

extension PowerupItem: PFSubclassing {
    static func parseClassName() -> String {
        return "PowerupItem"
    }
}

extension PowerupItem {
    // utils
    var isMushroom: Bool {
        return self.type?.lowercaseString == PowerupItemType.Mushroom.rawValue
    }

    var isRedShell: Bool {
        return self.type?.lowercaseString == PowerupItemType.RedShell.rawValue
    }
    
    var icon: UIImage {
        var image = UIImage(named: "Mushroom")!
        if self.isRedShell {
            image = UIImage(named: "RedShell")!
        }
        return image
    }
}