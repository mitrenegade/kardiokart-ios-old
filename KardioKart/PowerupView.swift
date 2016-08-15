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
        let boxSize: CGFloat = 24
        let width: CGFloat = boxSize * CGFloat(count)
        self.init(frame: CGRectMake(0.0, 0.0, width, boxSize))
        self.powerup = powerup

        let image: UIImage? = UIImage(named: "block")
        let firstCenter = (self.frame.size.width - (boxSize * CGFloat(count-1)))/2
        for i in 0 ..< count {
            let boxView: UIImageView = UIImageView(image: image)
            boxView.center = CGPointMake(firstCenter + boxSize * CGFloat(i), self.frame.size.height / 2)
            self.addSubview(boxView)
        }
        /*
        self.backgroundColor = UIColor.redColor()
        self.layer.borderWidth = 1
        self.layer.borderColor = UIColor.grayColor().CGColor
        self.layer.cornerRadius = boxSize/2
        self.clipsToBounds = true
        */
    }
}
