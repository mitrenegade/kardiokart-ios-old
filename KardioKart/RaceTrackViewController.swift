//
//  RaceTrackViewController.swift
//  KardioKart
//
//  Created by Robinson Greig on 10/25/15.
//  Copyright © 2015 Kartio. All rights reserved.
//

import UIKit

class RaceTrackViewController: UIViewController {
    @IBOutlet weak var trackPath: UIView!

    override func viewDidLoad() {
        super.viewDidLoad()

        
        
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(animated: Bool) {
        queryUsers()
        super.viewWillAppear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func queryUsers() {
        let query = PFUser.query()
        query?.findObjectsInBackgroundWithBlock { (result, error) -> Void in
            if let result = result {
                var position: Double = 55.0
                for user in result {
                    let userName = user["name"] as? String ?? ""
                    let avatar = RaceTrackAvatar(name: userName)
                    self.view.addSubview(avatar)
                    avatar.center = CGPoint(x: position, y: position)
                    position += 55.0
                }
            }
        }
    }
}
