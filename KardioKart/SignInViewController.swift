//
//  SignInViewController.swift
//  KardioKart
//
//  Created by Brent Raines on 10/5/15.
//  Copyright © 2015 Kartio. All rights reserved.
//

import UIKit

class SignInViewController: UIViewController, FBSDKLoginButtonDelegate {
    @IBOutlet weak var fbLoginButton: FBSDKLoginButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        fbLoginButton.readPermissions = ["public_profile", "email", "user_friends"]
        fbLoginButton.delegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func loginButton(loginButton: FBSDKLoginButton!, didCompleteWithResult result: FBSDKLoginManagerLoginResult!, error: NSError!) {
        if SessionManager.sharedManager.isSignedIn() {
            self.performSegueWithIdentifier("ShowHealthKitSetupSegue", sender: self.navigationController)
        }
    }
    
    func loginButtonDidLogOut(loginButton: FBSDKLoginButton!) {
        // Do some stuff here for logging out of FB
    }


}

