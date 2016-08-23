//
//  NSDate+Utils.swift
//  KardioKart
//
//  Created by Bobby Ren on 8/21/16.
//  Copyright © 2016 Kartio. All rights reserved.
//

import UIKit

extension NSDate {
    func isToday() -> Bool {
        let calendar = NSCalendar.init(calendarIdentifier: NSCalendarIdentifierGregorian)
        let today = calendar?.component(NSCalendarUnit.Day, fromDate: NSDate())
        let day = calendar?.component(NSCalendarUnit.Day, fromDate: self)
        return day == today
    }
}