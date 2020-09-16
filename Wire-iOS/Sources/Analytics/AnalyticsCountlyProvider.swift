
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
    private var isUserSet: Bool = false
    
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
    
    //TODO: call this after switched account
    func updateUserProperties() {
        guard let selfUser = SelfUser.provider?.selfUser as? ZMUser else {
            return
        }
                
        //TODO: user id generation
        //TODO: move these to SE?
        var userProperties: [String: Any] = ["team_team_id": selfUser.hasTeam,
                                             "team_user_type": selfUser.teamRole]

        userProperties["user_id"] = selfUser.userId.uuid.zmSHA256Digest().zmHexEncodedString()

        if let teamSize = selfUser.team?.members.count.logRound() {
            userProperties["team_team_size"] = teamSize
            userProperties["user_contacts"] = teamSize
        } else {
            userProperties["user_contacts"] = ZMConversationListDirectory().conversations(by: .contacts).count
        }

        let convertedAttributes: [String: String] = Dictionary(uniqueKeysWithValues:
            userProperties.map { key, value in (key, countlyValue(rawValue: value)) })
        
        print(convertedAttributes)
        
        for(key, value) in convertedAttributes {
            Countly.user().set(key, value: value)
        }
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
        if !isUserSet {
            updateUserProperties()
            
            isUserSet = true
        }
        
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
