//
//  LoadingViewController.swift
//  KardioKart
//
//  Created by Brent Raines on 10/5/15.
//  Copyright © 2015 Kartio. All rights reserved.
//
import UIKit
import Foundation

class LoadingViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(animated: Bool) {
        wait(3.0) {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let initialViewController = storyboard.instantiateViewControllerWithIdentifier("TabBarController")
            UIApplication.sharedApplication().keyWindow?.rootViewController = initialViewController
        }
    }    
}
