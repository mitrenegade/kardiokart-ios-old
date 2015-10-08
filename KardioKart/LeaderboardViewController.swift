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
        cell.stepLabel.text = String(Int(HealthManager.sharedManager.stepCount()))
        cell.positionLabel.text = String(indexPath.row + 1)
        cell.nameLabel.text = "Joel \(indexPath.row + 1)"
        return cell
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 6
    }
}
