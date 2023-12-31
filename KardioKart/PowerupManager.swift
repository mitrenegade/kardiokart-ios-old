//
//  PowerupManager.swift
//  KardioKart
//
//  Created by Bobby Ren on 7/29/16.
//  Copyright © 2016 Kartio. All rights reserved.
//
// for now, handles polling

import UIKit
import Parse
import ParseLiveQuery

class PowerupManager: NSObject {
    static let sharedManager = PowerupManager()

    var timer: NSTimer?
    var powerups: [Powerup]?
        
    // live query for Parse objects
    let liveQueryClient = ParseLiveQuery.Client()
    var subscription: Subscription<Powerup>?
    var isSubscribed: Bool = false

    func initialize() {
        /*
        let interval: NSTimeInterval = 60 // poll every minute for new boxes
        timer = NSTimer.scheduledTimerWithTimeInterval(interval, target: self, selector: #selector(tick), userInfo: nil, repeats: true)
        timer!.fire()
        */
        
        Powerup.registerSubclass()
    }
    
    func subscribeToUpdates() {
        if LOCAL_TEST {
            return
        }
        
        // powerup updates
        guard let race = RaceManager.currentRace() else { return }
        guard let raceId = race.objectId else { return }
        let query = Powerup.query()!
        query.whereKey("raceId", equalTo: raceId)
        query.whereKey("active", notEqualTo: false)
        self.subscription = liveQueryClient.subscribe(query)
            .handle(Event.Updated, { (_, powerup) in
                if let powerups = self.powerups {
                    for p in powerups {
                        if p.objectId == powerup.objectId {
                            self.powerups!.removeAtIndex(powerups.indexOf(p)!)
                            self.powerups!.append(powerup)
                        }
                    }
                }
                dispatch_async(dispatch_get_main_queue(), {
                    //print("received update for powerup: \(powerup)")
                    NSNotificationCenter.defaultCenter().postNotificationName("powerups:changed", object: nil)
                })
            })
        isSubscribed = true
    }

    
    // MARK: - Request for all powerups - NOT USED for polling, only on startup
    internal func getAllPowerups() {
        self.queryPowerups { (results, error) in
            if error != nil {
                print("Error in querying powerups: \(error)")
            }
            else {
                self.powerups = results as? [Powerup]
                //print("Powerups: \(self.powerups?.count)")
                NSNotificationCenter.defaultCenter().postNotificationName("powerups:changed", object: nil)
            }
        }
    }
    
    func queryPowerups(completion: ((results: [PFObject]?, error: NSError?)->Void)) {
        guard let race = RaceManager.currentRace() else {
            completion(results: nil, error: nil)
            return
        }
        
        let query: PFQuery = PFQuery(className: "Powerup")
        query.whereKey("count", greaterThan: 0)
        query.whereKey("raceId", equalTo: race.objectId!)
        query.findObjectsInBackgroundWithBlock { (results, error) in
            // todo: if no powerups have been retrieved and query times out, retry x times
            if let error = error {
                print("Error \(error)")
            }

            completion(results: results, error: error)
        }
    }

    func acquirePowerup(powerup: Powerup, completion: ((results: [PowerupItem]?, error: NSError?)->Void)) {
        guard let _ = PFUser.currentUser() else { return }
        guard let powerupId = powerup.objectId else { return }
        
        let params: [String: AnyObject] = ["powerupId": powerupId]
        
        PFCloud.callFunctionInBackground("acquirePowerup", withParameters: params, block: { (results, error) in
            print("results: \(results) error: \(error)")
            if let info = results as? [NSObject: AnyObject], item = info["item"] as? PowerupItem {
                completion(results: [item], error: nil)
            }
            else {
                completion(results: nil, error: error)
            }
        })
    }
    
    func queryPowerupItems(completion: ((results: [PFObject]?, error: NSError?)->Void)? ) {
        guard let user = PFUser.currentUser() else { return }
        guard let race = RaceManager.currentRace() else { return }

        // match only powerupItems for the user in the current race
        // user isn't the same objectas the user from the queried items; must use matchesKey:inQuery
        // relationQuery returns ALL powerupItems for a user
        // the actual query is on PowerupItem, which must match the userId and the race
        
        let relation = user.relationForKey("items")
        let relationQuery = relation.query()
        let raceQuery = Race.query()?.whereKey("objectId", equalTo: race.objectId!)
        
        let query = PowerupItem.query()
        query?.whereKey("objectId", matchesKey: "objectId", inQuery: relationQuery)
        query?.whereKey("race", matchesQuery: raceQuery!)
        query?.findObjectsInBackgroundWithBlock({ (results, error) in
            if let error = error {
                completion?(results: nil, error: error)
            }
            else {
                print("Results \(results) \(results!.count)")
                completion?(results: results, error: error)
            }
        })
    }

}
