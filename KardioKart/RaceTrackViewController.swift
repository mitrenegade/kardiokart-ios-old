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
    var acquiringPowerupIndex: Int = -1
    
    // Powerup Items
    // imageview goes from right to left
    @IBOutlet weak var item0: UIImageView!
    @IBOutlet weak var item1: UIImageView!
    @IBOutlet weak var item2: UIImageView!
    @IBOutlet weak var item3: UIImageView!
    var powerupItemViews: [UIImageView]!
    var powerupItems: [PowerupItem]?
    
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
        powerupItemViews = [item0, item1, item2, item3]
        
        self.listenFor("positions:changed", action: #selector(refreshAvatars), object: nil)
        self.listenFor("powerups:changed", action: #selector(refreshPowerups), object: nil)
        
        StepManager.sharedManager.initialize()
        StepManager.sharedManager.startTracking()

        manager.trackController = self
        manager.checkCacheDate()
        if RaceManager.currentRace() != nil {
            self.refreshRace()
        }
        else {
            self.listenFor("race:changed", action: #selector(refreshRace), object: nil)
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewWillAppear(animated)
        manager.checkCacheDate()
        
        self.refreshPowerups()
        self.refreshAvatars()
        
        self.updatePowerupItemView()

        // TEST
        /*
        wait(5) {
//            self.acquirePowerup(self.powerups.values.first!, index: 0)
            // airplane mode
            StepManager.sharedManager.startTracking()
        }
        */
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    deinit {
        self.stopListeningFor("positions:changed")
        self.stopListeningFor("powerups:changed")
        self.stopListeningFor("race:changed")
    }
    
    // MARK: Race
    func refreshRace() {
        self.stopListeningFor("race:changed")
        // when race has been loaded, query users and listen for updates to steps
        self.activityIndicator.startAnimating()
        manager.queryUsers { (success, error) in
            if !success {
                if let error = error where error.code == 209 {
                    RaceManager.sharedManager.logout()
                }
                else {
                    self.simpleAlert("Could not load users", message: "There was an error. Please restart the app and try again")
                    self.activityIndicator.stopAnimating()
                }
            }
            else {
                self.activityIndicator.stopAnimating()
                
                // initial step update doesn't get triggered on first login because users don't exist
                StepManager.sharedManager.startTracking()
            }
        }
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
//        print("animationPercent \(animationPercent)")
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
//                print("animating start \(startSteps) step \(step) end \(endSteps)")
            }
            self.animateUser(user, step: step)
            if user == RaceManager.sharedManager.currentUser {
                updateCurrentLapLabel(step)
            }
            
            if animationPercent >= 100 {
                manager.currentSteps[userId] = manager.newStepsToAnimate[userId]
            }
        }
        
        if animationPercent >= 100 {
            animationTimer?.invalidate()
            animationTimer = nil
            
            animationPercent = 0
            
            RaceManager.sharedManager.updateCachedSteps()
        }
    }

    func animateUser(user: PFUser, step: Double) {
        guard let avatar = self.avatarForUser(user) else { return }
        
        if user.objectId == manager.currentUser?.objectId {
            //print("Animating steps for user \(user.objectId!) to \(step)")
        }
        
        if let point = self.raceTrack.pointForSteps(step) {
            avatar.center = point
            avatar.hidden = false
        }
        else {
            avatar.hidden = true
        }
        
        if user.objectId == PFUser.currentUser()?.objectId {
            let percent = self.raceTrack.trackPosition(step) * 100
            let index = Int(percent)
            //print("User percent \(index)")
            if let powerup = powerups[index] {
                self.acquirePowerup(powerup, index: index)
            }
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
            
            let steps = RaceManager.sharedManager.cachedStepsForUser(user)
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
    
    func updateCurrentLapLabel(step: Double) {
        let lapLength:Double = 2500
        let totalLaps:Int = 20
        
        let currentLap:Int = Int(step / lapLength)
        lapCount.text = "Lap \(currentLap) of \(totalLaps)"
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
    
    func acquirePowerup(powerup: Powerup, index: Int) {
        guard index != acquiringPowerupIndex else { return }
        guard let powerupView = self.powerupViews[powerup.objectId!] as? PowerupView else { return }
        if let items = self.powerupItems {
            if items.count >= 3 {
                return
            }
        }

        acquiringPowerupIndex = index
        PowerupManager.sharedManager.acquirePowerup(powerup) {[weak self] (results, error) in
            if let error = error {
                print("Acquire powerup error: \(error)")
            }
            else {
                if let item = results?.first {
                    var type = "unknown item"
                    if let itemType = item.type {
                        type = itemType
                    }
                    print("You have received a(n) \(type)")
                    self?.animatePowerup(item, fromView: powerupView)
                }
            }
        }
    }
    
    func animatePowerup(item: PowerupItem, fromView: PowerupView) {
        let image = item.icon
        let iconView: UIImageView = UIImageView(image: image)
        iconView.frame = item0.frame
        self.view.addSubview(iconView)
        
        var fromPoint: CGPoint = fromView.center
        fromPoint.x += self.raceTrack.frame.origin.x
        fromPoint.y += self.raceTrack.frame.origin.y
        iconView.center = fromPoint
        let toView = self.powerupItemViews[self.powerupItems?.count ?? 0]
        var toPoint = toView.center
        toPoint.x += toView.superview!.frame.origin.x
        toPoint.y += toView.superview!.frame.origin.y
        
        UIView.animateWithDuration(2, animations: {
            iconView.center = toPoint
            }) { (complete) in
                iconView.removeFromSuperview()
                iconView.hidden = true
                
                self.powerupItems = nil
                self.updatePowerupItemView()
        }
    }
    
    
    func resetPowerupItemView() {
        self.powerupItems = nil
        
        for view: UIImageView in self.powerupItemViews {
            view.image = nil
        }
        self.item0.image = UIImage(named: "morePowerups")
    }
    
    func updatePowerupItemView() {
        if let userPowerups = self.powerupItems {
            var count = 0
            for powerup in userPowerups {
                let iconView = self.powerupItemViews[count]
                let image = powerup.icon
                iconView.image = image
                count += 1
            }
            if count <= 3 {
                let iconView = self.powerupItemViews[count]
                iconView.image = UIImage(named: "morePowerups")
            }
        }
        else {
            PowerupManager.sharedManager.queryPowerupItems { (results, error) in
                if let error = error {
                    self.resetPowerupItemView()
                    if error.code == 209 {
                        RaceManager.sharedManager.logout()
                    }
                    else {
                        self.simpleAlert("Powerups not found", defaultMessage: "There was an issue loading your powerups", error: error)
                    }
                    return
                }
                else {
                    if let userPowerups = results as? [PowerupItem] {
                        self.powerupItems = userPowerups
                        self.updatePowerupItemView()
                    }
                }
            }
        }
    }
}
