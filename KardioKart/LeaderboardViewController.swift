//
//  LeaderboardViewController.swift
//  KardioKart
//
//  Created by Brent Raines on 10/6/15.
//  Copyright © 2015 Kartio. All rights reserved.
//
import UIKit
import Foundation
import Parse

class LeaderboardViewController: UITableViewController {
    var users: [PFObject]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(updateSteps), name: "positions:changed", object: nil)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.updateSteps()
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("leaderboardCell") as! LeaderboardTableViewCell
        if let user = self.users?[indexPath.row] {
            let postfixDict: [Int: String] = [0: "th", 1: "st", 2: "nd", 3: "rd", 4: "th", 5: "th", 6: "th", 7: "th", 8: "th", 9: "th"]
            let userPosition = indexPath.row + 1;
            let userPositionLastDigit = userPosition % 10
            let userPositionPostfix = postfixDict[userPositionLastDigit]!
            cell.positionLabel.text = "\(userPosition)\(userPositionPostfix)"
            if let steps = RaceManager.sharedManager.newStepsToAnimate[user.objectId!] {
                cell.stepLabel.text = "\(Int(steps))"
            }
            cell.nameLabel.text = user["name"] as? String
        }

        return cell
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let users = users {
            return users.count
        }
        
        return 0
    }
    
    func updateSteps() {
        if let users = RaceManager.sharedManager.users {
            self.users = users.sort({ (user1, user2) -> Bool in
                guard let steps1 = RaceManager.sharedManager.newStepsToAnimate[user1.objectId!] else { return false }
                guard let steps2 = RaceManager.sharedManager.newStepsToAnimate[user2.objectId!] else { return false }
                return steps1 > steps2
            })
            self.tableView.reloadData()
        }
    }
    
    func queryUsers() {
        let query = PFUser.query()
        query?.orderByDescending("stepCount")
        query?.findObjectsInBackgroundWithBlock { (result, error) -> Void in
            if let result = result {
                self.users = result
                self.tableView.reloadData()
            }
            else {
                print("Error \(error)")
            }
        }
    }
}
