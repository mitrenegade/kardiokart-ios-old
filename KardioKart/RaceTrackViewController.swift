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
    
    var animationTimer: NSTimer?
    var animationPercent: Double = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()

        for user in userAvatars.keys {
            userAvatars[user]?.removeFromSuperview()
            userAvatars[user] = nil
        }
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(refreshAvatars), name: "positions:changed", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(refreshPowerups), name: "powerups:changed", object: nil)
        
        // make sure that cached steps are from today, or clear them
        let calendar = NSCalendar.init(calendarIdentifier: NSCalendarIdentifierGregorian)
        if let lastAnimationDate: NSDate = NSUserDefaults.standardUserDefaults().objectForKey("steps:cached:date") as? NSDate {
            let day = calendar?.component(NSCalendarUnit.Day, fromDate: lastAnimationDate)
            let today = calendar?.component(NSCalendarUnit.Day, fromDate: NSDate())
            if day != today {
                NSUserDefaults.standardUserDefaults().removeObjectForKey("steps:cached")
                NSUserDefaults.standardUserDefaults().synchronize()
            }
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        queryUsers()
        updateCurrentLapLabel()
        super.viewWillAppear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
    
    // MARK: Steps from Parse
    func queryUsers() {
        let query = PFUser.query()
        query?.orderByDescending("stepCount")
        query?.findObjectsInBackgroundWithBlock { (result, error) -> Void in
            if let users = result as? [PFUser] {
                self.users = users
                self.startAnimationForNewSteps(users)
                
                for user in users {
                    if user.objectId == PFUser.currentUser()?.objectId {
                        self.currentUser = user
                    }
                }
                
                self.listenForLiveUpdates()
            }
        }
    }
    
    // MARK: Cached steps
    func startAnimationForNewSteps(users: [PFUser]) {
        // do initial animation
        let interval: NSTimeInterval = 0.01 // every 1/100 second, total 1 second animation
        if animationTimer == nil {
            animationTimer = NSTimer.scheduledTimerWithTimeInterval(interval, target: self, selector: #selector(tick), userInfo: nil, repeats: true)
            animationTimer!.fire()
        }
    }
    
    func cachedStepsForUser(user: PFUser) -> Double {
        guard let userId = user.objectId else { return 0 }

        let key = "steps:cached"
        let allCachedSteps = NSUserDefaults.standardUserDefaults().objectForKey(key) as? [String: Double] ?? [:]
        let userCachedSteps = allCachedSteps[userId] ?? 0
        return userCachedSteps
    }
    
    func updateCachedStepsForUsers(users: [PFUser]) {
        let key = "steps:cached"
        var allCachedSteps = NSUserDefaults.standardUserDefaults().objectForKey(key) as? [String: Double] ?? [:]
        for user: PFUser in users {
            guard let userId = user.objectId else { return }
            let endSteps = user["stepCount"] as? Double ?? 0
            allCachedSteps[userId] = endSteps
        }
        print("allCachedSteps: \(allCachedSteps)")
        NSUserDefaults.standardUserDefaults().setObject(allCachedSteps, forKey: key)
        NSUserDefaults.standardUserDefaults().setObject(NSDate(), forKey: "steps:cached:date")

        NSUserDefaults.standardUserDefaults().synchronize()
    }
    
    func listenForLiveUpdates() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(refreshCurrentSteps(_:)), name: "steps:live:updated", object: nil)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    // MARK: Animation of cached steps
    internal func tick() {
        if let _ = self.animationTimer {
            self.nextAnimation()
        }
    }
    
    func nextAnimation() {
        guard let users = self.users else { return }
        print("animationPercent \(animationPercent)")

        for user: PFUser in users {
            let startSteps = cachedStepsForUser(user)
            let endSteps = user["stepCount"] as? Double ?? startSteps
            
            let step = Double(endSteps - startSteps) / 100.0 * self.animationPercent + Double(startSteps)
            if user.objectId == self.currentUser?.objectId {
                print("animating start \(startSteps) step \(step) end \(endSteps)")
            }
            self.animateUser(user, step: step)
        }
        
        animationPercent += 1
        if animationPercent >= 100 {
            animationTimer?.invalidate()
            animationTimer = nil
            
            self.updateCachedStepsForUsers(users)
            animationPercent = 0
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
    
    // MARK: - Active listener
    func refreshCurrentSteps(notification: NSNotification) {
        guard let user = self.currentUser else { return }
        guard let users = self.users else { return }
        guard let userInfo = notification.userInfo else { return }
        guard let steps: [[String: AnyObject]] = userInfo["steps"] as? [[String: AnyObject]] else { return }

        var total = 0.0
        for sample: [String: AnyObject] in steps {
            if let count = sample["count"] as? Double {
                total = total + count
            }
        }
        
        // update stepcount locally
        user["stepCount"] = total
        
//        print("user stepcount \(user["stepCount"]) allUsers \(self.users)")
        userPlace.text = "\(NSDate()): \(total)"

        // animate updated step count
        self.startAnimationForNewSteps(users)
    }
    
    // MARK: - Powerups
    func refreshPowerups() {
    }
}
