
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

final class AnalyticsCountlyProvider: NSObject, AnalyticsProvider {
    
    //TODO:
    var isOptedOut: Bool {
        get {
            return false //mixpanelInstance?.hasOptedOutTracking() ?? true
        }
        set {
//            if newValue == true {
//                mixpanelInstance?.optOutTracking()
//            } else {
//                mixpanelInstance?.optInTracking()
//            }
        }
    }
        
    override init(
//        defaults: UserDefaults
    ) {
        
        if let countlyAppKey = Bundle.countlyAppKey,
            let countlyHost = Bundle.countlyHost {
            let config: CountlyConfig = CountlyConfig()
            config.appKey = countlyAppKey
            config.host = countlyHost
            Countly.sharedInstance().start(with: config)
        }

        super.init()
        zmLog.info("AnalyticsCountlyProvider \(self) started")
    }
    
    deinit {
        zmLog.info("AnalyticsCountlyProvider \(self) deallocated")
    }
    

    func tagEvent(_ event: String, attributes: [String : Any]) {
        //TODO
    }
    
    func setSuperProperty(_ name: String, value: Any?) {
        //TODO
    }
    
    func flush(completion: (() -> Void)?) {
        //TODO
    }
}
