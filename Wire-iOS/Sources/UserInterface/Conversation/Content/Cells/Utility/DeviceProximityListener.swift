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
    
    fileprivate(set) var raisedToEar: Bool = false {
        didSet {
            if oldValue != self.raisedToEar {
                self.stateChanged?(self.raisedToEar)
            }
        }
    }
    
    typealias RaisedToEarHandler = (_ raisedToEar: Bool) -> Void
    
    var stateChanged: RaisedToEarHandler? = nil
    var listening: Bool = false
    
    func startListening() {
        guard !self.listening else {
            return
        }

        self.listening = true
        UIDevice.current.isProximityMonitoringEnabled = true
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleProximityChange),
                                                   name: NSNotification.Name.UIDeviceProximityStateDidChange,
                                                 object: nil)
    }
    
    func stopListening() {
        guard self.listening else {
            return
        }
        self.listening = false
        UIDevice.current.isProximityMonitoringEnabled = false
        NotificationCenter.default.removeObserver(self)
    }
    
    func handleProximityChange(_ notification: Notification) {
        self.raisedToEar = UIDevice.current.proximityState
    }
    
    deinit {
        self.stopListening()
    }
}
