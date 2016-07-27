// 
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
// 
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
// 
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
// 
// You should have received a copy of the GNU General Public License
// along with this program. If not, see http://www.gnu.org/licenses/.
// 


import Foundation
import CoreMotion

class DeviceProximityListener: NSObject {

    private var heldVertically = false
    private let motionManager = CMMotionManager()
    
    private(set) var raisedToEar: Bool = false {
        didSet {
            if oldValue != self.raisedToEar {
                self.stateChanged?(raisedToEar: self.raisedToEar)
            }
        }
    }
    
    typealias RaisedToEarHandler = (raisedToEar: Bool) -> Void
    
    var stateChanged: RaisedToEarHandler? = nil
    var listening: Bool = false
    
    override init() {
        super.init()
        motionManager.deviceMotionUpdateInterval = 10.0 / 60.0
    }
    
    func startListening() {
        guard !self.listening else {
            return
        }
        self.listening = true
        startMotionListener()
        UIDevice.currentDevice().proximityMonitoringEnabled = true
        NSNotificationCenter.defaultCenter().addObserver(self,
                                               selector: #selector(handleProximityChange),
                                                   name: UIDeviceProximityStateDidChangeNotification, object: nil)
    }
    
    func startMotionListener() {
        let handler: CMDeviceMotionHandler = { [weak self] weakMotion, error in
            guard let `self` = self, motion = weakMotion else { return }
        
            // Only listen for UIDevice proximity if the device is held vertically
            self.heldVertically = (motion.gravity.z > -0.4 &&
                motion.gravity.z < 0.4 &&
                motion.gravity.y < -0.7)
        }
        
        motionManager.startDeviceMotionUpdatesUsingReferenceFrame(.XArbitraryZVertical, toQueue: NSOperationQueue(), withHandler: handler)
    }
    func stopListening() {
        guard self.listening else {
            return
        }
        self.listening = false
        motionManager.stopDeviceMotionUpdates()
        UIDevice.currentDevice().proximityMonitoringEnabled = false
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func handleProximityChange(notification: NSNotification) {
        self.raisedToEar = UIDevice.currentDevice().proximityState && self.heldVertically
    }
    
    deinit {
        self.stopListening()
    }
}
