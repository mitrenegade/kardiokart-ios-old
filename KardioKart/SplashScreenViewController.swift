//
//  SplashScreenViewController.swift
//  KardioKart
//
//  Created by Bobby Ren on 9/17/16.
//  Copyright © 2016 Kartio. All rights reserved.
//

import UIKit
import Parse

class SplashScreenViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        listenFor(.LoginSuccess, action: #selector(didLogin), object: nil)
        listenFor(.LogoutSuccess, action: #selector(didLogout), object: nil)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        goHome()
    }
    
    func goHome(forced: Bool = false) {
        if presentedViewController != nil {
            if forced {
                dismissViewControllerAnimated(true, completion: nil)
            }
        }
        else if let segue = self.segue() {
            self.performSegueWithIdentifier(segue, sender: nil)
        }
        /*
        guard let homeViewController = homeViewController() else { return }
        if let presented = presentedViewController {
            guard homeViewController != presented else { return }
            dismissViewControllerAnimated(true, completion: nil)
        } else {
            presentViewController(homeViewController, animated: true, completion: nil)
        }
        */
    }
    
    private func segue() -> String? {
        switch PFUser.currentUser() {
        case .None:
            return Segue.Startup.GoToLoginSignup.rawValue
        default:
            return Segue.Startup.GoToRace.rawValue
        }

    }
    
    /*
    private func homeViewController() -> UINavigationController? {
        switch PFUser.currentUser() {
        case .None:
            return UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("OnboardingNavigationController") as? UINavigationController
        case .Some:
            return UIStoryboard(name: "Provider", bundle: nil).instantiateViewControllerWithIdentifier("TabBarController") as? UINavigationController
        }
    }
 */
    
    func didLogin() {
        print("logged in")
        goHome(true)
    }
    
    func didLogout() {
        print("logged out")
        goHome(true)
    }
    
    deinit {
        stopListeningFor(.LoginSuccess)
        stopListeningFor(.LogoutSuccess)
    }
}
