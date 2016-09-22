//
//  Constants.swift
//  KardioKart
//
//  Created by Bobby Ren on 9/17/16.
//  Copyright © 2016 Kartio. All rights reserved.
//

import Foundation

enum Segue {
    enum Startup: String {
        case GoToLoginSignup
        case GoToRace
    }
}

enum NotificationType: String {
    case LogoutSuccess = "logout:success"
    case LoginSuccess = "login:success"
}