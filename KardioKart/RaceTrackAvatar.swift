//
//  RaceTrackAvatar.swift
//  KardioKart
//
//  Created by Brent Raines on 10/25/15.
//  Copyright © 2015 Kartio. All rights reserved.
//

import UIKit

class RaceTrackAvatar: UIView {
    var label = UILabel()
    
    convenience init(name: String) {
        self.init(frame: CGRectMake(0.0, 0.0, 50.0, 50.0))
        label.textColor = UIColor(red:0.333,  green:0.427,  blue:0.475, alpha:1)
        self.layer.borderColor = UIColor(red:0.333,  green:0.427,  blue:0.475, alpha:1).CGColor
        self.layer.borderWidth = 2.5
        self.layer.cornerRadius = self.bounds.width / 2
        self.backgroundColor = UIColor.whiteColor()
        let names: [String] = name.componentsSeparatedByString(" ")
        var initials = ""
        for name in names {
            initials += String(name[name.startIndex])
        }
        if let font = UIFont(name: "AvenirNextCondensed-Medium", size: 25.0) {
            label.attributedText = NSAttributedString(string: initials, attributes: ["NSFontAttributeName": font])
        } else {
            label.text = initials
        }
        label.sizeToFit()
        label.center = self.center
        self.addSubview(label)
    }

}
