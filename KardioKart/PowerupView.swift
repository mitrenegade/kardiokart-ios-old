//
//  PowerupView.swift
//  KardioKart
//
//  Created by Bobby Ren on 8/14/16.
//  Copyright © 2016 Kartio. All rights reserved.
//

import UIKit
import Parse

class PowerupView: UIView {
    var powerup: PFObject?
    
    convenience init(powerup: PFObject) {
        let count = powerup.objectForKey("count") as? Int ?? 0
        let width: CGFloat = 25 * CGFloat(count)
        self.init(frame: CGRectMake(0.0, 0.0, width, 25.0))
        self.powerup = powerup

        let image: UIImage? = UIImage(named: "block")
        let point = self.frame.size.width / 2 - (width / 2 * CGFloat(count))
        for i in 1 ..< count {
            let boxView: UIImageView = UIImageView(image: image)
            boxView.center = CGPointMake(point + width / 2 * CGFloat(i), self.frame.size.height / 2)
            self.addSubview(boxView)
        }
    }
}
