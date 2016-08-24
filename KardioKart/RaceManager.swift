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
    
    var trackController: RaceTrackViewController?
    var users: [PFUser]?
    var currentUser: PFUser? // current user loaded from queryUsers so information is updated - don't use PFUser.currentUser for steps
    
    // locally stored steps for animation
    var currentSteps: [String: Double] = [:]
    var newStepsToAnimate: [String: Double] = [:]

    // live query for Parse steps
    let liveQueryClient = ParseLiveQuery.Client()
    var subscription: Subscription<PFUser>?

    var _currentRace: PFObject?
    
    class func currentRace() -> PFObject? {
        // TODO: currentRace does not have to do with the day, but with the user's race ID?
        //if sharedManager.isRaceToday() {
        //    return sharedManager._currentRace
        //}
        if sharedManager._currentRace != nil {
            return sharedManager._currentRace
        }
        
        // kick off a query, and set the current race to any result
        sharedManager.queryRace { (race) in
            sharedManager._currentRace = race
        }
        // return nil because we currently don't have a current race
        return nil
    }
    
    func initialize() {
        // kick off a query, and set the current race to any result
        self.queryRace { (race) in
            self._currentRace = race
            if !PowerupManager.sharedManager.isSubscribed {
                PowerupManager.sharedManager.getAllPowerups()
                PowerupManager.sharedManager.subscribeToUpdates()
            }
        }
    }
    
    var today: Int {
        get {
            let calendar = NSCalendar.init(calendarIdentifier: NSCalendarIdentifierGregorian)
            guard let day = calendar?.component(NSCalendarUnit.Day, fromDate: NSDate()) else {
                return -1
            }
            return day
        }
    }
    
    private func queryRace(completion: ((race: PFObject?) -> Void)) {
        let query = PFQuery(className: "Race")
//        query.whereKey("day", equalTo: today)
        query.getFirstObjectInBackgroundWithBlock { (object, error) in
            if let _ = error {
                print("error!")
                completion(race: nil)
            }
            else {
                completion(race: object)
            }
        }
    }
    
    // MARK: - load from web - should be ultimate truth
    func queryUsers(completion: ((success: Bool)->())?) {
        let query = PFUser.query()

        query?.findObjectsInBackgroundWithBlock { (result, error) -> Void in
            if let users = result as? [PFUser] {
                self.users = users
                
                for user in users {
                    if user.objectId == PFUser.currentUser()?.objectId {
                        self.currentUser = user
                    }
                    // compare with cache and update to most recent
                    if let userId = user.objectId {
                        let cachedSteps = self.cachedStepsForUser(user) // guaranteed to be today's or 0
                        let parseSteps = user["stepCount"] as? Double ?? 0
                        if let parseDate = user["stepDate"] as? Int where parseDate == self.today {
                            let mostCurrent = max(cachedSteps, parseSteps)
                            self.currentSteps[userId] = mostCurrent
                            self.newStepsToAnimate[userId] = mostCurrent
                        }
                        else {
                            self.currentSteps[userId] = cachedSteps
                            self.newStepsToAnimate[userId] = cachedSteps
                        }
                    }
                }
                NSNotificationCenter.defaultCenter().postNotificationName("positions:changed", object: nil)
                self.listenForStepUpdates()
                self.subscribeToUserUpdates()
                completion?(success: true)
            }
            else if let _ = error {
                completion?(success: false)
            }
        }
    }
    
    func subscribeToUserUpdates() {
        // step updates for other users
        let query = PFUser.query()?.whereKeyExists("stepCount") // TODO: query.where("raceId" == self.raceId)
        if let userId = PFUser.currentUser()?.objectId {
            query?.whereKey("objectId", notEqualTo: userId)
        }
        self.subscription = liveQueryClient.subscribe(query!)
            .handle(Event.Updated, { (_, user) in
                dispatch_async(dispatch_get_main_queue(), { 
                    print("received update for user \(user.objectId!)")
                    self.updateStepsFromParse(user)
                    NSNotificationCenter.defaultCenter().postNotificationName("positions:changed", object: nil)
                })
        })
    }

    func listenForStepUpdates() {
        NSNotificationCenter.defaultCenter().removeObserver(self)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(refreshLiveSteps(_:)), name: "steps:live:updated", object: nil)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func updateStepsFromParse(user: PFUser) {
        // animates steps received from parse for another user through live query
        if let userId = user.objectId {
            let parseSteps = user["stepCount"] as? Double ?? 0
            var mostCurrent = self.currentSteps[userId] ?? 0
            if let day = user["stepDate"] as? Int where day == today {
                mostCurrent = max(mostCurrent, parseSteps)
            }
            self.newStepsToAnimate[userId] = mostCurrent
        }
    }

    func updateStepsToParse(steps: Double, completion: (()->Void)?) {
        guard let _ = PFUser.currentUser() else { return }
        
        var params: [String: AnyObject] = ["stepCount": steps]
        params["isBackground"] = UIApplication.sharedApplication().applicationState == UIApplicationState.Background
        
        PFCloud.callFunctionInBackground("updateStepsForUser", withParameters: params, block: { (results, error) in
            print("results: \(results) error: \(error)")
            completion?()
        })
    }

    // MARK: Cached steps
    func checkCacheDate() {
        // make sure that cached steps are from today, or clear them
        if let lastAnimationDate: NSDate = self.lastCacheDate where isToday(lastAnimationDate) {
            print("Current cached steps are for today, do nothing")
            return
        }
        
        // otherwise clear it
        NSUserDefaults.standardUserDefaults().removeObjectForKey("steps:cached")
        NSUserDefaults.standardUserDefaults().synchronize()
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
        self.lastCacheDate = NSDate()
        
        NSUserDefaults.standardUserDefaults().synchronize()
    }

    // MARK: - Active listener
    func refreshLiveSteps(notification: NSNotification) {
        // updated steps for current user
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
        
        guard total > self.newStepsToAnimate[userId] else {
            print("Received step total \(total) but stepcount already at \(self.newStepsToAnimate[userId])")
            return
        }
        
        // update stepcount locally
        self.newStepsToAnimate[userId] = total
        if self.currentSteps[userId] == nil {
            self.currentSteps[userId] = total
        }
        
        //userPlace.text = "\(NSDate()): \(total)"
        
        // cache to device
        self.updateCachedSteps()
        
        // update to parse if changed
        let parseCount = user["stepCount"] as? Double ?? 0
        let parseDate = user["stepDate"] as? NSDate
        if total > parseCount || !self.isToday(parseDate) {

            self.updateStepsToParse(total, completion: {
                print("user steps \(total) saved to parse")
            })
        }

        // animate updated step count
        NSNotificationCenter.defaultCenter().postNotificationName("positions:changed", object: nil)
    }
    
    // MARK: Utils
    func isToday(date: NSDate?) -> Bool {
        guard let date = date else { return false }
        
        let calendar = NSCalendar.init(calendarIdentifier: NSCalendarIdentifierGregorian)
        let day = calendar?.component(NSCalendarUnit.Day, fromDate: date)
        return day == today
    }

    private func isRaceToday() -> Bool {
        // TODO: make into Race extension
        guard let race = _currentRace else { return false }
        guard let day = race.objectForKey("day") as? Int else { return false }
        return day == today
    }
    
    var lastCacheDate: NSDate? {
        get {
            return NSUserDefaults.standardUserDefaults().objectForKey("steps:cached:date") as? NSDate
        }
        set {
            NSUserDefaults.standardUserDefaults().setObject(lastCacheDate, forKey: "steps:cached:date")
        }
    }
}
