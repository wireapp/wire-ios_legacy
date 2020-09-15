
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
                zmLog.error("AnalyticsCountlyProvider is not created. Bundle.countlyAppKey = \(String(describing: Bundle.countlyAppKey)), Bundle.countlyHost = \(String(describing: Bundle.countlyHost)). Please check COUNTLY_APP_KEY & COUNTLY_HOST is set in .xcconfig file")
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
    

    func tagEvent(_ event: String, attributes: [String : Any]) {
        //TODO: casting
//        ["is_global_ephemeral": "0", "conversation_type": "group", "message_action": "location", "with_service": "0", "is_ephemeral": "0", "user_type": "guest", "is_allow_guests": "1"]
        
        // DONE/disabled:
        //        message.is_ephemeral_message
        //        message.ephemeral_expiration
        //        message_action
        //        conversation_type
        //        conversation.ephemeral_message
        //        message.is_reply
        //        message.mention
        
        
//        conversation_size
//        conversation.allow_guests
//        conversation_guests
//        conversation_guests_pro
//        conversation_guests_wireless
//        conversation_services
        
        let convertedAttributes: [String: String] = Dictionary(uniqueKeysWithValues:
            attributes.map { key, value in (key, "\(value)") })
        
        print(attributes)
        
        print(convertedAttributes)

        Countly.sharedInstance().recordEvent(event, segmentation:convertedAttributes)
    }
    
    func setSuperProperty(_ name: String, value: Any?) {
        //TODO
    }
    
    func flush(completion: Completion?) {
        isOptedOut = true
        completion?()
    }
}
