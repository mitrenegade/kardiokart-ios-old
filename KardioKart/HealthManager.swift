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

let STEPS_QUERY_INTERVAL_FOREGROUND: NSTimeInterval = 10 // 5 second updates while app is active

class HealthManager: NSObject {
    static let sharedManager = HealthManager()
    let healthKitStore: HKHealthStore = HKHealthStore()
    
    var timer: NSTimer?
    
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
    
    func getStepTotal(start start: NSDate?, end: NSDate?, completion: ((steps: Double)->Void)?) {
        /*
        guard !Platform.isSimulator else {
            completion!(steps:5000)
            return
        }
        */
        
        let calendar = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)
        let beginningOfDay = calendar?.startOfDayForDate(NSDate())
        
        let sampleType = HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierStepCount)
        let predicate = HKQuery.predicateForSamplesWithStartDate(start ?? beginningOfDay, endDate: end ?? NSDate(), options: .None)
        
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
    
    private var SIMULATED_STEPS = 5000
    func getStepSamples(start start: NSDate?, end: NSDate?, completion: ((steps: AnyObject)->Void)?) {
        guard !Platform.isSimulator else {
            var allSamples: [[String: AnyObject]] = [[String: AnyObject]]()
            SIMULATED_STEPS = SIMULATED_STEPS + 50
            allSamples.append(["count":SIMULATED_STEPS, "start": NSDate(), "end": NSDate()])
            completion!(steps:allSamples)
            return
        }
        
        let calendar = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)
        let beginningOfDay = calendar?.startOfDayForDate(NSDate())

        let sampleType = HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierStepCount)
        let predicate = HKQuery.predicateForSamplesWithStartDate(start ?? beginningOfDay, endDate: end ?? NSDate(), options: .None)

        let stepsSampleQuery = HKSampleQuery(sampleType: sampleType!,
                                             predicate: predicate,
                                             limit: 1000,
                                             sortDescriptors: nil)
        { [unowned self] (query, results, error) in
            var allSamples: [[String: AnyObject]] = [[String: AnyObject]]()
            if let results = results as? [HKQuantitySample] {
                for sample: HKQuantitySample in results {
                    let steps = sample.quantity.doubleValueForUnit(HKUnit.countUnit())
                    let start = sample.startDate
                    let end = sample.endDate
                    
                    allSamples.append(["count":steps, "start": start, "end": end])
                }
                completion?(steps: allSamples)
            }
        }
        
        healthKitStore.executeQuery(stepsSampleQuery)
    }

    
    func setUserSteps(steps: Double, completion: (()->Void)?) {
        guard let _ = PFUser.currentUser() else { return }
        
        var params: [String: AnyObject] = ["stepCount": steps]
        params["isBackground"] = UIApplication.sharedApplication().applicationState == UIApplicationState.Background

        PFCloud.callFunctionInBackground("updateStepsForUser", withParameters: params, block: { (results, error) in
            print("results: \(results) error: \(error)")
            completion?()
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
                
                self.getStepTotal(start: nil, end: nil, completion: { (steps) in
                    self.setUserSteps(steps, completion: { 
                        self.sendLocalNotificationForSteps(steps)
                        completionHandler()
                    })
                })
            })
            
            healthKitStore.executeQuery(query)
            
            NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(didEnterBackground), name: "app:to:background", object: nil)
            NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(didEnterForeground), name: "app:to:foreground", object: nil)
        }
    }

    // MARK: - local notifications
    //create local notification
    func sendLocalNotificationForSteps(steps: Double) {
        /*
        let notificationSettings = UIUserNotificationSettings(forTypes: [.Alert, .Badge, .Sound], categories: nil)
        UIApplication.sharedApplication().registerUserNotificationSettings(notificationSettings)

        let notification = UILocalNotification()
        notification.fireDate = NSDate().dateByAddingTimeInterval(5)
        
        notification.alertBody = "New step count: \(steps)"
        notification.soundName = UILocalNotificationDefaultSoundName
        UIApplication.sharedApplication().scheduleLocalNotification(notification)
        
        let scheduled = UIApplication.sharedApplication().scheduledLocalNotifications
        print("scheduled notifications: \(scheduled)")
        */
    }
    
    func application(application: UIApplication, didReceiveLocalNotification notification: UILocalNotification) {
        print("local notification received: \(notification)")
        /*
        let alert = UIAlertController(title: "Alert", message: "You have an event in one hour!", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .Default, handler: nil))
        
        self.revealController?.presentViewController(alert, animated: true, completion: nil)
         */
    }
    
    // MARK: - Backgrounding
    func didEnterBackground() {
        self.timer?.invalidate()
        self.timer = nil
    }
    
    func didEnterForeground() {
        self.timer?.invalidate()
        
        self.timer = NSTimer.scheduledTimerWithTimeInterval(STEPS_QUERY_INTERVAL_FOREGROUND, target: self, selector: #selector(tick), userInfo: nil, repeats: true)
        self.timer?.fire()
    }
    
    func tick() {
        self.getStepSamples(start: nil, end: nil) { (steps) in
            print("health manager tick")
            dispatch_async(dispatch_get_main_queue(), { 
                NSNotificationCenter.defaultCenter().postNotificationName("steps:live:updated", object: nil, userInfo: ["steps": steps])
            })
        }
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
}
