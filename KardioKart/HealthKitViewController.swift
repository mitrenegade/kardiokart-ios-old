//
//  HealthKitViewController.swift
//  KardioKart
//
//  Created by Brent Raines on 10/5/15.
//  Copyright © 2015 Kartio. All rights reserved.
//

import UIKit
import Foundation

class HealthKitViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func requestHealthKitAuthorization(sender: UIButton) {
        
        HealthManager.sharedManager.authorizeHealthKit { (authorized, error) -> Void in
            if authorized {
                self.requestPedometerAuthorization()
            } else {
                print("Healthkit authorization denied")
                if error != nil {
                    print("\(error)")
                }
            }
        }
    }
    
    func requestPedometerAuthorization() {
        StepManager.sharedManager.authorizePedometer { (success, error) in
            if success {
                dispatch_async(dispatch_get_main_queue(), {
                    self.performSegueWithIdentifier("LoadingTransitionSegue", sender: self)
                })
            }
            else {
                print("Pedometer authorization denied")
                if error != nil {
                    print("\(error)")
                }
            }
        }
    }
}