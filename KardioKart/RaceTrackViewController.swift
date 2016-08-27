//
//  RaceTrackViewController.swift
//  KardioKart
//
//  Created by Robinson Greig on 10/25/15.
//  Copyright © 2015 Kartio. All rights reserved.
//

import UIKit
import Parse

let POWERUP_POSITION_BUFFER = 0

// TODO: caching issues. sometimes old steps are loaded from cache. 
// maybe this is caused by bad internet and each time queryUsers is done, the old values are used, even if new steps have been cached.
// TODO: drawing issues. When powerups are drawn, they appear over avatars.
// TODO: Animation issues. refreshAvatars moves avatars without animation. (solved?)
// TODO: past midnight, existing user steps are still used and not filtered away by date

class RaceTrackViewController: UIViewController {
    @IBOutlet weak var raceTrack: RaceTrack!
    @IBOutlet weak var trackPath: UIView!
    @IBOutlet weak var lapCount: UILabel!
    @IBOutlet weak var userPlace: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!

    var animationTimer: NSTimer?
    var animationPercent: Double = 0
    
    // Avatars
    var userAvatars: [String: RaceTrackAvatar] = [:]
    weak var myAvatar: RaceTrackAvatar?
    
    // Powerups
    var powerupViews: [String: UIView] = [:]
    var powerups: [Int:Powerup] = [Int:Powerup]()
    
    private var didInitialAnimation: Bool = false
    var needsAnimation: Bool {
        get {
            for (userId, newSteps) in manager.newStepsToAnimate {
                if let oldSteps = manager.currentSteps[userId] where oldSteps < newSteps {
                    return true
                }
            }
            if didInitialAnimation {
                return false
            }
            didInitialAnimation = true
            return true
        }
    }

    var manager: RaceManager = RaceManager.sharedManager
    
    override func viewDidLoad() {
        super.viewDidLoad()

        for user in userAvatars.keys {
            userAvatars[user]?.removeFromSuperview()
            userAvatars[user] = nil
        }
        
        self.clearPowerups()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(refreshAvatars), name: "positions:changed", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(refreshPowerups), name: "powerups:changed", object: nil)
        
        StepManager.sharedManager.initialize()
        StepManager.sharedManager.startTracking()

        manager.trackController = self
        manager.checkCacheDate()
        // query users and listen for updates to steps
        self.activityIndicator.startAnimating()
        manager.queryUsers { (success) in
            if !success {
                self.simpleAlert("Could not load users", message: "There was an error. Please restart the app and try again")
                self.activityIndicator.stopAnimating()
            }
            else {
                self.activityIndicator.stopAnimating()
            }
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewWillAppear(animated)
        manager.checkCacheDate()
        updateCurrentLapLabel()
        
        self.refreshPowerups()
        self.refreshAvatars()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: Animation of cached steps
    func startAnimationForNewSteps() {
        guard animationTimer == nil else { return }
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
        guard let users = manager.users else { return }
        print("animationPercent \(animationPercent)")
        animationPercent += 1

        for user: PFUser in users {
            guard let userId = user.objectId else { continue }
            guard let startSteps = manager.currentSteps[userId] else { continue }
            guard let endSteps = manager.newStepsToAnimate[userId] else { continue }
            
            var step = Double(endSteps - startSteps) / 100.0 * self.animationPercent + Double(startSteps)
            if endSteps < startSteps {
                step = endSteps
            }
            if user.objectId == manager.currentUser?.objectId {
                print("animating start \(startSteps) step \(step) end \(endSteps)")
            }
            self.animateUser(user, step: step)
            
            if animationPercent >= 100 {
                manager.currentSteps[userId] = manager.newStepsToAnimate[userId]
            }
        }
        
        if animationPercent >= 100 {
            animationTimer?.invalidate()
            animationTimer = nil
            
            animationPercent = 0
        }
    }

    func animateUser(user: PFUser, step: Double) {
        guard let avatar = self.avatarForUser(user) else { return }
        
        if user.objectId == manager.currentUser?.objectId {
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
    func avatarForUser(user: PFUser?) -> RaceTrackAvatar? {
        guard let user = user else { return nil }
        
        var avatar = userAvatars[user.objectId!]
        if avatar == nil {
            avatar = RaceTrackAvatar(user: user)
            userAvatars[user.objectId!] = avatar
            self.raceTrack.addSubview(avatar!)
            if let point = self.raceTrack.pointForStart() {
                avatar!.center = point
            }
            
        }
        
        // set myAvatar
        if user.objectId == manager.currentUser?.objectId {
            self.myAvatar = avatar

            // make sure current user's avatar is always on top
            avatar!.removeFromSuperview()
            self.raceTrack.addSubview(avatar!)
        }
        
        return avatar
    }
    
    func refreshAvatars() {
        guard let users = manager.users else { return }
        for user in users {
            guard let avatar = self.avatarForUser(user) else { continue }
            
            let steps = user["stepCount"] as? Double ?? 0
            if let _ = self.raceTrack.pointForSteps(steps) {
                //avatar.center = point
                avatar.hidden = false
                avatar.removeFromSuperview()
                self.raceTrack.addSubview(avatar)
            }
            else {
                avatar.hidden = true
            }
        }
        
        self.startAnimationForNewSteps()
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
        if let user = manager.currentUser{
            let lapLength:Double = 2500
            let totalLaps:Int = 20
            let step_count = user["stepCount"] as? Double ?? 0.0
            let currentLap:Int = Int(step_count / lapLength)
            lapCount.text = "Lap \(currentLap) of \(totalLaps)"
        }
    }
    
    // MARK: - Powerups
    func clearPowerups() {
        for (_, view) in self.powerupViews {
            view.removeFromSuperview()
        }
        self.powerupViews.removeAll()
        self.powerups.removeAll()
    }
    
    func removePowerupView(objectId: String) {
        guard let powerupView: PowerupView = self.powerupViews[objectId] as? PowerupView else { return }
        powerupView.removeFromSuperview()
        if let position = powerupView.powerup?.objectForKey("position") as? Int {
            self.powerups[position] = nil
        }
        self.powerupViews[objectId] = nil
    }
    
    func addPowerupView(powerup: Powerup) {
        guard let position = powerup.objectForKey("position") as? Int else { return }
        guard let objectId = powerup.objectId else { return }
        guard self.powerupViews[objectId] == nil else { return }
        
        // Powerup position buffer is 0 because web handles not inserting powerups close to each other
        for i in position - POWERUP_POSITION_BUFFER ..< position + POWERUP_POSITION_BUFFER + 1 {
            if let _ = self.powerups[i] {
                // item exists within a range of the powerup
                return
            }
        }
        
        let newPowerupView = PowerupView(powerup: powerup)
        if let percent = powerup.objectForKey("position") as? Double {
            let point = self.raceTrack.pointForPercent(percent/100.0)
            newPowerupView.center = point
        }
        self.raceTrack.addSubview(newPowerupView)
        self.powerupViews[objectId] = newPowerupView
        self.powerups[position] = powerup
    }
    
    func refreshPowerups() {
        guard let powerups = PowerupManager.sharedManager.powerups else {
            self.clearPowerups()
            return
        }
        
        for powerup in powerups {
            guard let objectId = powerup.objectId else { continue }
            
            if let powerupView = self.powerupViews[objectId] as? PowerupView {
                guard let count = powerupView.powerup?.objectForKey("count") as? Int else { continue }
                guard let newCount = powerup.objectForKey("count") as? Int else {
                    self.removePowerupView(objectId)
                    continue
                }
                if newCount == 0 {
                    self.removePowerupView(objectId)
                    continue
                }
                if newCount != count {
                    self.removePowerupView(objectId)
                    self.addPowerupView(powerup)
                }
            }
            else {
                self.addPowerupView(powerup)
            }
        }
    }
    
}
