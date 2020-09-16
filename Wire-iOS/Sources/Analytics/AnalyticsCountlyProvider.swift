
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
import WireSyncEngine

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
        
//        user_id    String        Account level generated user id for BI purpose / Raphael - sha256(user-id)
//            user_contacts    Numeric    * Round with factor=6    Number of users contacts - rounded number to the nearest 5 on the client side
//        team_team_id    Boolean    True; False    True - if the user is a Team member
//        team_team_size    String        Size of the users team
//        team_user_type    String    member; external; wireless     Role of the user in the team
        
        Countly.sharedInstance().start(with: config)
        
        Countly.user().set("user_id", value:"TODO")
        
        if let selfUser = SelfUser.provider?.selfUser as? ZMUser {
            var userProperties: [String: Any] = [:]
            
            userProperties["user_contacts"] = selfUser.connection
            userProperties["team_team_id"] = selfUser.hasTeam
            if let teamSize = selfUser.team?.members.count.logRound() {
                userProperties["team_team_size"] = teamSize
            }
            userProperties["team_user_type"] = selfUser.teamRole

            let convertedAttributes: [String: String] = Dictionary(uniqueKeysWithValues:
                userProperties.map { key, value in (key, countlyValue(rawValue: value)) })

            for(key, value) in convertedAttributes {
                Countly.user().set(key, value: value)
            }
        }
        

        zmLog.info("AnalyticsCountlyProvider \(self) started")

        self.isOptedOut = false
        sessionBegun = true
    }
    
    deinit {
        zmLog.info("AnalyticsCountlyProvider \(self) deallocated")
    }
    

    private func countlyValue(rawValue: Any) -> String {
        if let boolValue = rawValue as? Bool {
            return boolValue ? "True" : "False"
        }
        
        if let teamRole = rawValue as? TeamRole {
            switch teamRole {
            case .partner:
                return "external"
            case .member, .admin, .owner:
                return "member"
            case .none:
                return "wireless"
            }
        }

        return "\(rawValue)"
    }

    func tagEvent(_ event: String,
                  attributes: [String : Any]) {
        var convertedAttributes: [String: String] = Dictionary(uniqueKeysWithValues:
            attributes.map { key, value in (key, countlyValue(rawValue: value)) })
        
        convertedAttributes["app_name"] = "ios"
        convertedAttributes["app_version"] = Bundle.main.shortVersionString
        
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
