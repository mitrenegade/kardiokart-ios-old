//
//  RaceTrackViewController.swift
//  KardioKart
//
//  Created by Robinson Greig on 10/25/15.
//  Copyright © 2015 Kartio. All rights reserved.
//

import UIKit

class RaceTrackViewController: UIViewController {
    @IBOutlet weak var raceTrack: RaceTrack!
    let scorePerLap = 2000.0
    var path: CGPath?
    var users: [PFObject] = []
    var userAvatars: [RaceTrackAvatar] = []
    var pointsInPath = [CGPoint]()
    @IBOutlet weak var trackPath: UIView!
    @IBOutlet weak var lapCount: UILabel!
    @IBOutlet weak var userPlace: UILabel!
    var users: [PFObject]?

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    typealias MyPathApplier = @convention(block) (UnsafePointer<CGPathElement>) -> Void
    
    func myPathApply(path: CGPath!, block: MyPathApplier) {
        let callback: @convention(c) (UnsafeMutablePointer<Void>, UnsafePointer<CGPathElement>) -> Void = { (info, element) in
            let block = unsafeBitCast(info, MyPathApplier.self)
            block(element)
        }
        
        CGPathApply(path, unsafeBitCast(block, UnsafeMutablePointer<Void>.self), unsafeBitCast(callback, CGPathApplierFunction.self))
    }
    
    override func viewDidAppear(animated: Bool) {
        if path == nil {
            var translation = CGAffineTransformMakeTranslation(CGFloat(raceTrack.frame.origin.x), CGFloat(raceTrack.frame.origin.y))
            path = raceTrack.path.CGPath
            path = CGPathCreateCopyByDashingPath(path, &translation, 0.0, [2,2], 2)
            path = CGPathCreateMutableCopy(path)
            myPathApply(path) { element in
                switch element.memory.type {
                case .MoveToPoint:
                    self.pointsInPath.append(element.memory.points[0])
                case .AddLineToPoint:
                    self.pointsInPath.append(element.memory.points[0])
                case .AddQuadCurveToPoint:
                    self.pointsInPath.append(element.memory.points[0])
                    self.pointsInPath.append(element.memory.points[1])
                case .AddCurveToPoint:
                    self.pointsInPath.append(element.memory.points[0])
                    self.pointsInPath.append(element.memory.points[1])
                default:
                    break
                }
            }
        }
        queryUsers()
        updateCurrentLapLabel()
        super.viewWillAppear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func addUserAvatars() {
        for avatar in userAvatars {
            avatar.removeFromSuperview()
            userAvatars.removeAtIndex(userAvatars.indexOf(avatar)!)
        }
        
        for user in users {
            let avatar = RaceTrackAvatar(user: user)
            userAvatars.append(avatar)
            self.view.addSubview(avatar)
            let score = user["stepCount"] as? Double ?? 0.0
            let pointIndex: Int = Int(((score % scorePerLap) / scorePerLap) * Double(pointsInPath.count))
            let point = pointsInPath[pointIndex]
            avatar.center = point
        }

    }
    
    func updateLapPositionLabel(position: Int) {
        let postfixDict: [Int: String] = [0: "th", 1: "st", 2: "nd", 3: "rd", 4: "th", 5: "th", 6: "th", 7: "th", 8: "th", 9: "th"]
        let userPosition = position + 1;
        let userPositionLastDigit = userPosition % 10
        let userPositionPostfix = postfixDict[userPositionLastDigit]!
        userPlace.text = "\(userPosition)\(userPositionPostfix) Place"
    }
    
    func updateCurrentLapLabel() {
        if let user = PFUser.currentUser(){
            let lapLength:Double = 2500
            let totalLaps:Int = 20
            let step_count = user["stepCount"] as? Double ?? 0.0
            let currentLap:Int = Int(step_count / lapLength)
            lapCount.text = "Lap \(currentLap) of \(totalLaps)"
        }
    }
    
    func queryUsers() {
        let query = PFUser.query()
        query?.orderByDescending("stepCount")
        query?.findObjectsInBackgroundWithBlock { (result, error) -> Void in
            if let result = result {
                for (index, user) in result.enumerate() {
                    self.users = result
                    if let currentUser = PFUser.currentUser(){
                        let userEmail = user["email"] as? String
                        let currentUserEmail = currentUser["email"] as? String
                        if userEmail == currentUserEmail {
                            self.updateLapPositionLabel(index)
                        }
                    }
                }
            }
        }
    }
}
