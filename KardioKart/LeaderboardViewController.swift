//
//  LeaderboardViewController.swift
//  KardioKart
//
//  Created by Brent Raines on 10/6/15.
//  Copyright © 2015 Kartio. All rights reserved.
//

import Foundation

class LeaderboardViewController: UITableViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("leaderboardCell") as! LeaderboardTableViewCell
        cell.positionLabel.text = "\(indexPath.row + 1)."
        cell.stepLabel.text = String(Int(HealthManager.sharedManager.stepCount()))
        cell.nameLabel.text = SessionManager.sharedManager.name()
        return cell
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
}
