//
//  LoadingViewController.swift
//  KardioKart
//
//  Created by Brent Raines on 10/5/15.
//  Copyright © 2015 Kartio. All rights reserved.
//

import Foundation

class LoadingViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(animated: Bool) {
        delay(3.0) {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let initialViewController = storyboard.instantiateViewControllerWithIdentifier("TabBarController")
            UIApplication.sharedApplication().keyWindow?.rootViewController = initialViewController
        }
    }
    
    func delay(delay:Double, closure:()->()) {
        dispatch_after(
            dispatch_time(
                DISPATCH_TIME_NOW,
                Int64(delay * Double(NSEC_PER_SEC))
            ),
            dispatch_get_main_queue(), closure)
    }
}
