//
//  SignInViewController.swift
//  KardioKart
//
//  Created by Brent Raines on 10/5/15.
//  Copyright © 2015 Kartio. All rights reserved.
//

import UIKit
import ParseFacebookUtilsV4
import Parse

class SignInViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func loginWithFacebook(sender: UIButton) {
        let readPermissions = ["public_profile", "email", "user_friends"]
        PFFacebookUtils.logInInBackgroundWithReadPermissions(readPermissions) {
            (user: PFUser?, error: NSError?) -> Void in
            if let user = user {
                self.updateUserProfile(user)
                self.performSegueWithIdentifier("ShowHealthKitSetupSegue", sender: self.navigationController)
                if user.isNew {
                    print("User signed up and logged in through Facebook!")
                } else {
                    print("User logged in through Facebook!")
                }
            } else {
                print("Uh oh. The user cancelled the Facebook login.")
                self.simpleAlert("Invalid facebook login", message: "There was an issue logging in or signing up with your Facebook account. Please let us know about this error.")
                // this usually means the server is down. todo: check error
            }
        }
    }
    
    func updateUserProfile(user: PFUser) {
        let request = FBSDKGraphRequest(graphPath: "me", parameters: ["fields": "name, email"])
        request.startWithCompletionHandler({ (connection, result, error) -> Void in
            if error == nil {
                user["name"] = result?["name"] as? String
                user.email = result?["email"] as? String
                user.saveInBackground()
            } else {
                print(error)
            }
        })
    }
}

