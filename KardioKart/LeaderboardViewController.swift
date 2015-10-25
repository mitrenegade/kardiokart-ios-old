//
//  LeaderboardViewController.swift
//  KardioKart
//
//  Created by Brent Raines on 10/6/15.
//  Copyright © 2015 Kartio. All rights reserved.
//

import Foundation

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
            cell.positionLabel.text = "\(indexPath.row + 1)."
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
        query?.findObjectsInBackgroundWithBlock { (result, error) -> Void in
            if let result = result {
                self.users = result.sort({
                    let steps_0 = $0["stepCount"] as! Double
                    let steps_1 = $1["stepCount"] as! Double
                    return steps_0 > steps_1
                })
                self.tableView.reloadData()
            }
        }
    }
}
