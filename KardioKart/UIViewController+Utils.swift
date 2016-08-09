//
//  UIViewController+Utils.swift
//  LotSportz
//
//  Created by Bobby Ren on 5/8/16.
//  Copyright © 2016 Bobby Ren. All rights reserved.
//

import UIKit

extension UIViewController {
    
    func simpleAlert(title: String, defaultMessage: String?, error: NSError?) {
        if error != nil {
            if let msg = error!.userInfo["error"] as? String {
                self.simpleAlert(title, message: msg)
                return
            }
        }
        self.simpleAlert(title, message: defaultMessage)
    }
    
    func simpleAlert(title: String, message: String?) {
        self.simpleAlert(title, message: message, completion: nil)
    }
    
    func simpleAlert(title: String, message: String?, completion: (() -> Void)?) {
        let alert: UIAlertController = UIAlertController.simpleAlert(title, message: message, completion: completion)
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func appDelegate() -> AppDelegate {
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        return appDelegate
    }
}

extension NSObject {
    
    // MARK: - Notifications
    func listenFor(notificationName: String, action: Selector, object: AnyObject?) {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: action, name: notificationName, object: object)
    }
    
    func stopListeningFor(notificationName: String) {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: notificationName, object: nil)
    }
    
    func notify(notificationName: String, object: AnyObject?, userInfo: [NSObject: AnyObject]?) {
        NSNotificationCenter.defaultCenter().postNotificationName(notificationName, object: object, userInfo: userInfo)
    }
}

extension UIAlertController {
    class func simpleAlert(title: String, message: String?, completion: (() -> Void)?) -> UIAlertController {
        let alert: UIAlertController = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        alert.view.tintColor = UIColor.blackColor()
        alert.addAction(UIAlertAction(title: "Close", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
            print("cancel")
            if completion != nil {
                completion!()
            }
        }))
        return alert
    }
    
}