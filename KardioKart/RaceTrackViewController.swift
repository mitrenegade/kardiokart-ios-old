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
        super.viewDidAppear(animated)
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
    
    func queryUsers() {
        let query = PFUser.query()
        query?.findObjectsInBackgroundWithBlock { (result, error) -> Void in
            if let result = result {
                self.users = result
                self.addUserAvatars()
            }
        }
    }
}
