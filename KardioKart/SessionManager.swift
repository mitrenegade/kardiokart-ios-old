//
//  SessionManager.swift
//  KardioKart
//
//  Created by Brent Raines on 10/6/15.
//  Copyright © 2015 Kartio. All rights reserved.
//

import Foundation

class SessionManager: NSObject {
    static let sharedManager = SessionManager()
    
    func isSignedIn() -> Bool {
        return FBSDKAccessToken.currentAccessToken() != nil
    }
    
    func name() -> String {
        let firstName = FBSDKProfile.currentProfile().firstName
        let lastName = FBSDKProfile.currentProfile().lastName
        return "\(firstName) \(lastName[lastName.startIndex])."
    }
}