//
//  AppDelegate.swift
//  KardioKart
//
//  Created by Brent Raines on 10/5/15.
//  Copyright © 2015 Kartio. All rights reserved.
//

import UIKit
import Parse
import ParseFacebookUtilsV4
let PARSE_APP_ID: String = "8DNaf4CXUXGYNMo9D7AJIJsbCZF2jtntIzBUOLpX"
let PARSE_SERVER_URL: String = "https://kardiokart-server.herokuapp.com/parse"
let PARSE_CLIENT_KEY: String = "unused"

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        HealthManager.sharedManager.enableBackgroundDelivery()
        HealthManager.sharedManager.observeSteps()
        
        // Parse
        let configuration = ParseClientConfiguration {
            $0.applicationId = PARSE_APP_ID
            $0.clientKey = PARSE_CLIENT_KEY
            $0.server = PARSE_SERVER_URL
        }
        Parse.initializeWithConfiguration(configuration)
        
        // Facebook
        FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
        PFFacebookUtils.initializeFacebookWithApplicationLaunchOptions(launchOptions);
        
        initializeUserInterface()
        
        PowerupManager.sharedManager.initialize()
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        FBSDKAppEvents.activateApp()
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject) -> Bool {
        return FBSDKApplicationDelegate.sharedInstance().application(application, openURL: url, sourceApplication: sourceApplication, annotation: annotation)
    }
    
    func initializeUserInterface() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        window = UIWindow(frame: UIScreen.mainScreen().bounds)
        
        if PFUser.currentUser() != nil {
            let initialViewController = storyboard.instantiateViewControllerWithIdentifier("TabBarController")
            window?.rootViewController = initialViewController
        } else {
            let initialViewController = storyboard.instantiateViewControllerWithIdentifier("OnboardingNavigationController")
            window?.rootViewController = initialViewController
        }
        
        self.window?.makeKeyAndVisible()
    }

    // Push
    // MARK: - Push
    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        // Store the deviceToken in the current Installation and save it to Parse
        
        let installation = PFInstallation.currentInstallation()
        installation.setDeviceTokenFromData(deviceToken)
        let channel: String = "global"
        installation.addUniqueObject(channel, forKey: "channels") // subscribe to global channel

        installation.saveInBackground()
        
        let channels = installation.objectForKey("channels")
        print("installation registered for remote notifications: token \(deviceToken) channel \(channels)")
    }
    
    func application(application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError) {
        print("failed: error \(error)")
        NSNotificationCenter.defaultCenter().postNotificationName("push:enable:failed", object: nil)
    }
    
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject]) {
        print("notification received: \(userInfo)")
        /* format:
         [aps: {
         alert = "test push 2";
         sound = default;
         }]
         
         ]
         */
        guard let title = userInfo["title"] as? String else { return }
        guard let message = userInfo["message"] as? String else { return }
        guard let sender = userInfo["sender"] as? String else {
            return
        }
        
        //let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        //alert.addAction(UIAlertAction(title: "Ok", style: .Default, handler: nil))
        
        //self.revealController?.presentViewController(alert, animated: true, completion: nil)
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
}

