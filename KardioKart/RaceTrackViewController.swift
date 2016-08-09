//
//  RaceTrackViewController.swift
//  KardioKart
//
//  Created by Robinson Greig on 10/25/15.
//  Copyright © 2015 Kartio. All rights reserved.
//

import UIKit
import Parse

class RaceTrackViewController: UIViewController {
    @IBOutlet weak var raceTrack: RaceTrack!
    var userAvatars: [String: RaceTrackAvatar] = [:]
    @IBOutlet weak var trackPath: UIView!
    @IBOutlet weak var lapCount: UILabel!
    @IBOutlet weak var userPlace: UILabel!
    var users: [PFUser]?
    var currentUser: PFUser? // current user loaded from queryUsers so information is updated - don't use PFUser.currentUser for steps
    var currentSteps: [String: Double] = [:]
    var newStepsToAnimate: [String: Double] = [:]
    var animationTimer: NSTimer?
    var animationPercent: Double = 0
    var needsAnimation = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        for user in userAvatars.keys {
            userAvatars[user]?.removeFromSuperview()
            userAvatars[user] = nil
        }
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(refreshAvatars), name: "positions:changed", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(refreshPowerups), name: "powerups:changed", object: nil)
        
        self.checkCacheDate()
        queryUsers()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.checkCacheDate()
        updateCurrentLapLabel()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func listenForLiveUpdates() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(refreshLiveSteps(_:)), name: "steps:live:updated", object: nil)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    // MARK: Initial step loading
    // load from web - should be ultimate truth
    func queryUsers() {
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
                        if let parseDate = user["stepDate"] as? NSDate where self.isToday(parseDate) {
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
                self.needsAnimation = true // always animate/force draw at start
                self.startAnimationForNewSteps()
                self.listenForLiveUpdates()
            }
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
    
    // MARK: Animation of cached steps
    func startAnimationForNewSteps() {
        guard animationTimer == nil else { return }
        for (userId, newSteps) in newStepsToAnimate {
            if let oldSteps = currentSteps[userId] where oldSteps < newSteps {
                needsAnimation = true
                break
            }
        }
        guard needsAnimation else { return }
        
        // start one round of animation timer
        let interval: NSTimeInterval = 0.01 // every 1/100 second, total 1 second animation
        animationTimer = NSTimer.scheduledTimerWithTimeInterval(interval, target: self, selector: #selector(tick), userInfo: nil, repeats: true)
        animationTimer!.fire()
    }
    
    internal func tick() {
        if let _ = self.animationTimer {
            self.nextAnimation()
        }
    }
    
    func nextAnimation() {
        guard let users = self.users else { return }
        print("animationPercent \(animationPercent)")
        animationPercent += 1

        for user: PFUser in users {
            guard let userId = user.objectId else { continue }
            guard let startSteps = self.currentSteps[userId] else { continue }
            guard let endSteps = self.newStepsToAnimate[userId] else { continue }
            
            var step = Double(endSteps - startSteps) / 100.0 * self.animationPercent + Double(startSteps)
            if endSteps < startSteps {
                step = endSteps
            }
            if user.objectId == self.currentUser?.objectId {
                print("animating start \(startSteps) step \(step) end \(endSteps)")
            }
            self.animateUser(user, step: step)
            
            if animationPercent >= 100 {
                self.currentSteps[userId] = self.newStepsToAnimate[userId]
            }
        }
        
        if animationPercent >= 100 {
            animationTimer?.invalidate()
            animationTimer = nil
            
            animationPercent = 0
            needsAnimation = false
        }
    }

    func animateUser(user: PFUser, step: Double) {
        guard let avatar = self.avatarForUser(user) else { return }
        
        if user.objectId == self.currentUser?.objectId {
            print("Animating steps for user \(user.objectId!) to \(step)")
        }
        
        if let point = self.raceTrack.pointForSteps(step) {
            avatar.center = point
            avatar.hidden = false
        }
        else {
            avatar.hidden = true
        }
    }
    
    
    // MARK: - Avatars
    func avatarForUser(user: PFUser) -> RaceTrackAvatar? {
        var avatar = userAvatars[user.objectId!]
        if avatar == nil {
            avatar = RaceTrackAvatar(user: user)
            userAvatars[user.objectId!] = avatar
            self.raceTrack.addSubview(avatar!)
            if let point = self.raceTrack.pointForStart() {
                avatar!.center = point
            }
        }
        return avatar
    }
    
    func refreshAvatars() {
        guard let users = self.users else { return }
        for user in users {
            guard let avatar = self.avatarForUser(user) else { continue }
            
            let steps = user["stepCount"] as? Double ?? 0
            if let point = self.raceTrack.pointForSteps(steps) {
                avatar.center = point
                avatar.hidden = false
            }
            else {
                avatar.hidden = true
            }
        }
    }
    
    // MARK: Position label
    func updateLapPositionLabel(position: Int) {
        let postfixDict: [Int: String] = [0: "th", 1: "st", 2: "nd", 3: "rd", 4: "th", 5: "th", 6: "th", 7: "th", 8: "th", 9: "th"]
        let userPosition = position + 1;
        let userPositionLastDigit = userPosition % 10
        let userPositionPostfix = postfixDict[userPositionLastDigit]!
        userPlace.text = "\(userPosition)\(userPositionPostfix) Place"
    }
    
    func updateCurrentLapLabel() {
        if let user = self.currentUser{
            let lapLength:Double = 2500
            let totalLaps:Int = 20
            let step_count = user["stepCount"] as? Double ?? 0.0
            let currentLap:Int = Int(step_count / lapLength)
            lapCount.text = "Lap \(currentLap) of \(totalLaps)"
        }
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
        newStepsToAnimate[userId] = total
        if currentSteps[userId] == nil {
            currentSteps[userId] = total
        }
        
        //userPlace.text = "\(NSDate()): \(total)"

        // animate updated step count
        self.startAnimationForNewSteps()
        
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
    
    // MARK: - Powerups
    func refreshPowerups() {
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
