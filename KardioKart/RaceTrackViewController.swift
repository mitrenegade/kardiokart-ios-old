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
    let scorePerLap = 2000.0
    var userAvatars: [String: RaceTrackAvatar] = [:]
    @IBOutlet weak var trackPath: UIView!
    @IBOutlet weak var lapCount: UILabel!
    @IBOutlet weak var userPlace: UILabel!
    var users: [PFUser]?

    override func viewDidLoad() {
        super.viewDidLoad()
        for user in userAvatars.keys {
            userAvatars[user]?.removeFromSuperview()
            userAvatars[user] = nil
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
    
    func addUserAvatars() {
        guard let users = self.users else { return }
        for user in users {
            var avatar = userAvatars[user.objectId!]
            if avatar == nil {
                avatar = RaceTrackAvatar(user: user)
                userAvatars[user.objectId!] = avatar
                self.view.addSubview(avatar!)
            }
            let steps = user["stepCount"] as? Int ?? 0
            if let point = self.raceTrack.pointForSteps(steps) {
                avatar!.center = point
                avatar!.hidden = false
            }
            else {
                avatar!.hidden = true
            }
        }

    }
    
    func updateLapPositionLabel(position: Int) {
        let postfixDict: [Int: String] = [0: "th", 1: "st", 2: "nd", 3: "rd", 4: "th", 5: "th", 6: "th", 7: "th", 8: "th", 9: "th"]
        let userPosition = position + 1;
        let userPositionLastDigit = userPosition % 10
        let userPositionPostfix = postfixDict[userPositionLastDigit]!
        userPlace.text = "\(userPosition)\(userPositionPostfix) Place"
    }
    
    func updateCurrentLapLabel() {
        if let user = PFUser.currentUser(){
            let lapLength:Double = 2500
            let totalLaps:Int = 20
            let step_count = user["stepCount"] as? Double ?? 0.0
            let currentLap:Int = Int(step_count / lapLength)
            lapCount.text = "Lap \(currentLap) of \(totalLaps)"
        }
    }
    
    func queryUsers() {
        let query = PFUser.query()
        query?.orderByDescending("stepCount")
        query?.findObjectsInBackgroundWithBlock { (result, error) -> Void in
            if let result = result {
                self.users = result as? [PFUser]
                self.addUserAvatars()
            }
        }
    }
}
