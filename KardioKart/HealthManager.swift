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
    
    func updateStepCount() {
        let now = NSDate()
        let oneDayAgo: NSTimeInterval = -24*60*60
        let past = NSDate(timeIntervalSinceNow: oneDayAgo)
        let sampleType = HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierStepCount)
        let predicate = HKQuery.predicateForSamplesWithStartDate(past, endDate: now, options: .None)
        let query = HKStatisticsQuery(quantityType: sampleType!,
            quantitySamplePredicate: predicate,
            options: .CumulativeSum) { query, result, error in
                var totalSteps: Double?
                if let quantity = result!.sumQuantity() {
                    let unit = HKUnit.countUnit()
                    totalSteps = quantity.doubleValueForUnit(unit)
                }
                
                if totalSteps != nil {
                    guard let user = PFUser.currentUser() else { return }

                    let params: [String: AnyObject] = ["stepCount": totalSteps ?? Double(0.0)]
                    PFCloud.callFunctionInBackground("updateStepsForUser", withParameters: params, block: { (results, error) in
                        print("results: \(results)")
                    })
                }
        }
        
        healthKitStore.executeQuery(query)
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
                
                self.updateStepCount()
                completionHandler()
            })
            
            healthKitStore.executeQuery(query)
        }
    }

}
