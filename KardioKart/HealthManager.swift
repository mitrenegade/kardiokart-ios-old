//
//  HealthManager.swift
//  KardioKart
//
//  Created by Brent Raines on 10/5/15.
//  Copyright © 2015 Kartio. All rights reserved.
//

import Foundation
import HealthKit
import Parse

class HealthManager: NSObject {
    static let sharedManager = HealthManager()
    let healthKitStore: HKHealthStore = HKHealthStore()
    
    func authorizeHealthKit(completion: ((success:Bool, error:NSError!) -> Void)!) {
        let healthKitTypesToRead: Set = [HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierStepCount)!]
        let healthKitTypesToWrite: Set<HKSampleType> = []
        
        if !HKHealthStore.isHealthDataAvailable() {
            let error = NSError(domain: "com.Kartio.KardioKart", code: 2, userInfo: [NSLocalizedDescriptionKey:"HealthKit is not available in this Device"])
            if completion != nil {
                completion(success: false, error: error)
            }
            return
        }
        
        healthKitStore.requestAuthorizationToShareTypes(healthKitTypesToWrite, readTypes: healthKitTypesToRead) {
            (success, error) -> Void in
            
            if completion != nil {
                completion(success: success, error: error)
            }
            
            if success {
                NSUserDefaults.standardUserDefaults().setBool(true, forKey: "healthkitEnabled")
                self.observeSteps()
            }
        }
    }
    
    func isHealthEnabled() -> Bool {
        if let healthkitEnabled = NSUserDefaults.standardUserDefaults().valueForKey("healthkitEnabled") as? Bool {
            return healthkitEnabled
        }
        return false
    }
    
    func enableBackgroundDelivery() {
        let steps = HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierStepCount)!
        healthKitStore.enableBackgroundDeliveryForType(steps, frequency: .Immediate, withCompletion: {
            success, error in
            if error != nil {
                print("*** An error occured while setting up the stepCount observer. \(error!.localizedDescription) ***")
            }
        })
    }
    
    func getStepCount(completion: ((steps: Double)->Void)?) {
        let calendar = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)
        let past = calendar?.startOfDayForDate(NSDate())
        
        let sampleType = HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierStepCount)
        let predicate = HKQuery.predicateForSamplesWithStartDate(past, endDate: NSDate(), options: .None)
        
        let query = HKStatisticsQuery(quantityType: sampleType!,
                                      quantitySamplePredicate: predicate,
                                      options: .CumulativeSum) { query, result, error in
                                        var totalSteps: Double = 0
                                        if let quantity = result!.sumQuantity() {
                                            let unit = HKUnit.countUnit()
                                            totalSteps = quantity.doubleValueForUnit(unit)
                                        }
                                        completion?(steps: totalSteps)
        }
        
        healthKitStore.executeQuery(query)
    }
    
    
    func setUserSteps(steps: Double) {
        guard let _ = PFUser.currentUser() else { return }
        
        let params: [String: AnyObject] = ["stepCount": steps]
        PFCloud.callFunctionInBackground("updateStepsForUser", withParameters: params, block: { (results, error) in
            print("results: \(results) error: \(error)")
        })
    }
    
    func observeSteps() {
        if isHealthEnabled() {
            let steps = HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierStepCount)!
            let query = HKObserverQuery(sampleType: steps, predicate: nil, updateHandler: {
                query, completionHandler, error in
                if error != nil {
                    print("*** An error occured while setting up the stepCount observer. \(error!.localizedDescription) ***")
                    return
                }
                
                self.getStepCount({ (steps) in
                    self.setUserSteps(steps)
                    self.sendLocalNotificationForSteps(steps)
                })
                completionHandler()
            })
            
            healthKitStore.executeQuery(query)
        }
    }

    // MARK: - local notifications
    //create local notification
    func sendLocalNotificationForSteps(steps: Double) {
        let notificationSettings = UIUserNotificationSettings(forTypes: [.Alert, .Badge, .Sound], categories: nil)
        UIApplication.sharedApplication().registerUserNotificationSettings(notificationSettings)

        let notification = UILocalNotification()
        notification.fireDate = NSDate().dateByAddingTimeInterval(5)
        
        notification.alertBody = "New step count: \(steps)"
        UIApplication.sharedApplication().scheduleLocalNotification(notification)
        
        let scheduled = UIApplication.sharedApplication().scheduledLocalNotifications
        print("scheduled notifications: \(scheduled)")
    }
    
    func application(application: UIApplication, didReceiveLocalNotification notification: UILocalNotification) {
        print("local notification received: \(notification)")
        /*
        let alert = UIAlertController(title: "Alert", message: "You have an event in one hour!", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .Default, handler: nil))
        
        self.revealController?.presentViewController(alert, animated: true, completion: nil)
         */
    }

}
