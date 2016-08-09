//
//  RaceManager.swift
//  KardioKart
//
//  Created by Bobby Ren on 8/8/16.
//  Copyright © 2016 Kartio. All rights reserved.
//

import UIKit
import Parse
import ParseLiveQuery

class RaceManager: NSObject {
    static let sharedManager = RaceManager()

    // TODO: this could be a Race object instead of a RaceManager object
    var trackController: RaceTrackViewController?
    var users: [PFUser]?
    var currentUser: PFUser? // current user loaded from queryUsers so information is updated - don't use PFUser.currentUser for steps
    
    // locally stored steps for animation
    var currentSteps: [String: Double] = [:]
    var newStepsToAnimate: [String: Double] = [:]

    // live query for Parse steps
    let liveQueryClient = ParseLiveQuery.Client()
    var subscription: Subscription<PFUser>?
    
    // MARK: - load from web - should be ultimate truth
    func queryUsers() {
        let query = PFUser.query()
        query?.findObjectsInBackgroundWithBlock { (result, error) -> Void in
            if let users = result as? [PFUser] {
                self.users = users
                
                for user in users {
                    if user.objectId == PFUser.currentUser()?.objectId {
                        self.currentUser = user
                    }
                    self.updateParseStepsForUser(user)
                }
                self.trackController?.startAnimationForNewSteps()
//                self.listenForHealthKitUpdates()
                self.listenForParseUpdates()
            }
        }
    }
    
    func listenForParseUpdates() {
        let query = PFUser.query()?.whereKeyExists("stepCount") // TODO: query.where("raceId" == self.raceId)
        self.subscription = liveQueryClient.subscribe(query!)
            .handle(Event.Updated, { (_, user) in
                print("received update for user \(user.objectId!)")
                self.updateParseStepsForUser(user)
                self.trackController?.startAnimationForNewSteps()
        })
    }

    func listenForHealthKitUpdates() {
        NSNotificationCenter.defaultCenter().removeObserver(self)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(refreshLiveSteps(_:)), name: "steps:live:updated", object: nil)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func updateParseStepsForUser(user: PFUser) {
        // compare with cache and update to most recent
        if let userId = user.objectId {
            let cachedSteps = self.cachedStepsForUser(user) // guaranteed to be today's or 0
            var mostCurrent = cachedSteps
            let parseSteps = user["stepCount"] as? Double ?? 0
            if let parseDate = user["stepDate"] as? NSDate {
                if self.isToday(parseDate) {
                    mostCurrent = max(cachedSteps, parseSteps)
                }
            }
            else if let dateInfo = user["stepDate"] as? [String: AnyObject] {
                // HACK: in the subscription handler, the raw user type is returned
                // stepDate has a representation like 
                // 
                // stepDate =     {
                //     "__type" = Date;
                //     iso = "2016-08-09T03:27:32.978Z";
                // };
                if let parseDate = dateInfo["iso"] as? String {
                    let dateFormatter = NSDateFormatter()
                    dateFormatter.timeZone = NSTimeZone(forSecondsFromGMT: 0)
                    dateFormatter.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ss.SSS'Z'"
                    let date = dateFormatter.dateFromString(parseDate)
                    if self.isToday(date) {
                        mostCurrent = max(cachedSteps, parseSteps)
                    }
                }
            }
            self.currentSteps[userId] = mostCurrent
            self.newStepsToAnimate[userId] = mostCurrent
        }
    }

    // MARK: Cached steps
    func checkCacheDate() {
        // make sure that cached steps are from today, or clear them
        if let lastAnimationDate: NSDate = NSUserDefaults.standardUserDefaults().objectForKey("steps:cached:date") as? NSDate {
            if isToday(lastAnimationDate) {
                NSUserDefaults.standardUserDefaults().removeObjectForKey("steps:cached")
                NSUserDefaults.standardUserDefaults().synchronize()
            }
        }
    }
    
    func cachedStepsForUser(user: PFUser) -> Double {
        guard let userId = user.objectId else { return 0 }
        
        let key = "steps:cached"
        let allCachedSteps = NSUserDefaults.standardUserDefaults().objectForKey(key) as? [String: Double] ?? [:]
        let userCachedSteps = allCachedSteps[userId] ?? 0
        return userCachedSteps
    }
    
    func updateCachedSteps() {
        guard let users = self.users else { return }
        
        let key = "steps:cached"
        var allCachedSteps = NSUserDefaults.standardUserDefaults().objectForKey(key) as? [String: Double] ?? [:]
        for user in users {
            guard let userId = user.objectId else { continue }
            let endSteps = currentSteps[userId] ?? 0
            allCachedSteps[userId] = endSteps
        }
        
        print("allCachedSteps: \(allCachedSteps)")
        NSUserDefaults.standardUserDefaults().setObject(allCachedSteps, forKey: key)
        NSUserDefaults.standardUserDefaults().setObject(NSDate(), forKey: "steps:cached:date")
        
        NSUserDefaults.standardUserDefaults().synchronize()
    }

    // MARK: - Active listener
    func refreshLiveSteps(notification: NSNotification) {
        guard let user = self.currentUser else { return }
        guard let userId = user.objectId else { return }
        guard let userInfo = notification.userInfo else { return }
        guard let steps: [[String: AnyObject]] = userInfo["steps"] as? [[String: AnyObject]] else { return }
        
        var total = 0.0
        for sample: [String: AnyObject] in steps {
            if let count = sample["count"] as? Double {
                total = total + count
            }
        }
        
        // update stepcount locally
        self.newStepsToAnimate[userId] = total
        if self.currentSteps[userId] == nil {
            self.currentSteps[userId] = total
        }
        
        //userPlace.text = "\(NSDate()): \(total)"
        
        // animate updated step count
        self.trackController?.startAnimationForNewSteps()
        
        // cache to device
        self.updateCachedSteps()
        
        // update to parse if changed
        let parseCount = user["stepCount"] as? Double ?? 0
        let parseDate = user["stepDate"] as? NSDate
        if total > parseCount || !self.isToday(parseDate) {
            user["stepCount"] = total
            user["stepDate"] = NSDate()
            user.saveInBackground()
        }
    }
    
    // MARK: Utils
    func isToday(date: NSDate?) -> Bool {
        guard let date = date else { return false }
        
        let calendar = NSCalendar.init(calendarIdentifier: NSCalendarIdentifierGregorian)
        let day = calendar?.component(NSCalendarUnit.Day, fromDate: date)
        let today = calendar?.component(NSCalendarUnit.Day, fromDate: NSDate())
        return day == today
    }

}
