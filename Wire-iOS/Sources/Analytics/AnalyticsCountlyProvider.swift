
// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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
import WireSystem
import Countly

private let zmLog = ZMSLog(tag: "Analytics")

final class AnalyticsCountlyProvider: AnalyticsProvider {
    
    private var sessionBegun: Bool = false
    
    var isOptedOut: Bool {
        get {
            return !sessionBegun
        }
        set {
            if newValue {
                Countly.sharedInstance().beginSession()
            } else {
                Countly.sharedInstance().endSession()
            }
            
            sessionBegun = !isOptedOut
        }
    }
        
    init?() {
        guard let countlyAppKey = Bundle.countlyAppKey,
              !countlyAppKey.isEmpty,
              let countlyHost = Bundle.countlyHost else {
                return nil
        }
        
        let config: CountlyConfig = CountlyConfig()
        config.appKey = countlyAppKey
        config.host = countlyHost
        config.deviceID = CLYTemporaryDeviceID //TODO: wait for ID generation task done
        config.manualSessionHandling = true
        Countly.sharedInstance().start(with: config)

        zmLog.info("AnalyticsCountlyProvider \(self) started")

        self.isOptedOut = false
        sessionBegun = true
    }
    
    deinit {
        zmLog.info("AnalyticsCountlyProvider \(self) deallocated")
    }
    

    func tagEvent(_ event: String, attributes: [String : Any]? = nil) {
        //TODO: casting
        Countly.sharedInstance().recordEvent(event, segmentation:attributes as! [String : String])
    }
    
    func setSuperProperty(_ name: String, value: Any?) {
        //TODO
    }
    
    func flush(completion: Completion?) {
        isOptedOut = true
        completion?()
    }
}
