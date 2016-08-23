
//
//  StepManager.swift
//  KardioKart
//
//  Created by Bobby Ren on 8/21/16.
//  Copyright © 2016 Kartio. All rights reserved.
//
// uses pedometer to deliver updated steps at a higher rate

import UIKit
import CoreMotion

class StepManager: NSObject {
    static let sharedManager = StepManager()

    var pedometer = CMPedometer()
    
    func initialize() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(didEnterBackground), name: "app:to:background", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(didEnterForeground), name: "app:to:foreground", object: nil)
    }
    
    // MARK: - Backgrounding
    func didEnterBackground() {
        // cache steps
        // enable background updates from health manager?
    }
    
    func didEnterForeground() {
        // start tracking again
    }

    // MARK: Step tracking
    func startTracking() {
        let start = self.lastCacheDate
        self.getStepSamples(start: start, end: nil) { (steps) in
            dispatch_async(dispatch_get_main_queue(), {
                NSNotificationCenter.defaultCenter().postNotificationName("steps:live:updated", object: nil, userInfo: ["steps": steps])
            })
            
            // cache steps if we hit a box or if the app is closed
        }
    }

    private var SIMULATED_STEPS = 5000
    func getStepSamples(start start: NSDate?, end: NSDate?, completion: ((steps: AnyObject)->Void)?) {
        /*
        guard !Platform.isSimulator else {
            var allSamples: [[String: AnyObject]] = [[String: AnyObject]]()
            SIMULATED_STEPS = SIMULATED_STEPS + 50
            allSamples.append(["count":SIMULATED_STEPS, "start": NSDate(), "end": NSDate()])
            completion!(steps:allSamples)
            return
        }
        */
        
        let calendar = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)
        let beginningOfDay = calendar?.startOfDayForDate(NSDate())

        let startDate = start ?? beginningOfDay!
        
        self.pedometer.startPedometerUpdatesFromDate(startDate) { (data, error) in
            var allSamples: [[String: AnyObject]] = [[String: AnyObject]]()
            if let pedometerData = data {
                print("results: \(pedometerData)")
                let steps = pedometerData.numberOfSteps.doubleValue
                allSamples.append(["count": steps, "start": startDate])
                /*
                for sample: AnyObject in results {
                    print("sample: \(sample)")
                    let steps = sample.quantity.doubleValueForUnit(HKUnit.countUnit())
                    let start = sample.startDate
                    let end = sample.endDate
                    
                    allSamples.append(["count":steps, "start": start, "end": end])
                }
                 */
                completion?(steps: allSamples)
            }
        }
    }

    // MARK: Cached step counts
    var lastCacheDate: NSDate? {
        get {
            if let date = NSUserDefaults.standardUserDefaults().objectForKey("pedometer:cached:date") as? NSDate where date.isToday() {
                return date
            }
            let calendar = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)
            return calendar?.startOfDayForDate(NSDate())
        }
        set {
            NSUserDefaults.standardUserDefaults().setObject(lastCacheDate, forKey: "pedometer:cached:date")
            NSUserDefaults.standardUserDefaults().synchronize()
        }
    }

    func checkCacheDate() {
        // make sure that cached steps are from today, or clear them
        if let lastAnimationDate: NSDate = self.lastCacheDate where lastAnimationDate.isToday() {
            print("Current cached steps are for today, do nothing")
            return
        }
        
        // otherwise clear it
        NSUserDefaults.standardUserDefaults().removeObjectForKey("pedometer:cached")
        NSUserDefaults.standardUserDefaults().synchronize()
    }
    
    var cachedSteps: Double {
        get {
            let key = "pedometer:cached"
            self.checkCacheDate()
            let cachedSteps = NSUserDefaults.standardUserDefaults().objectForKey(key) as? Double
            return cachedSteps ?? 0
        }
        set {
            NSUserDefaults.standardUserDefaults().setObject(cachedSteps, forKey: "pedometer:cached")
            NSUserDefaults.standardUserDefaults().synchronize()
        }
    }
}
