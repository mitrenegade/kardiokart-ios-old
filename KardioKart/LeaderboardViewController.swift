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
    }
    
    override func viewWillAppear(animated: Bool) {
        queryUsers()
        super.viewWillAppear(animated)
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("leaderboardCell") as! LeaderboardTableViewCell
        if let user = self.users?[indexPath.row] {
            let postfixDict: [Int: String] = [0: "th", 1: "st", 2: "nd", 3: "rd", 4: "th", 5: "th", 6: "th", 7: "th", 8: "th", 9: "th"]
            let userPosition = indexPath.row + 1;
            let userPositionLastDigit = userPosition % 10
            let userPositionPostfix = postfixDict[userPositionLastDigit]!
            cell.positionLabel.text = "\(userPosition)\(userPositionPostfix)"
            cell.stepLabel.text = String(user["stepCount"])
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
    
    func queryUsers() {
        let query = PFUser.query()
        query?.orderByDescending("stepCount")
        query?.findObjectsInBackgroundWithBlock { (result, error) -> Void in
            if let result = result {
                self.users = result
                self.tableView.reloadData()
            }
        }
    }
}
