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
import Countly
import WireSyncEngine

private let zmLog = ZMSLog(tag: "Analytics")

extension Int {
    func logRound(factor: Double = 6) -> Int {
        return Int(ceil(pow(2, (floor(factor * log2(Double(self))) / factor))))
    }
}

protocol CountlyInstance {
    func recordEvent(_ key: String, segmentation: [String : String]?)
    func start(with config: CountlyConfig)
    
    static func sharedInstance() -> Self
}

extension Countly: CountlyInstance {}

final class AnalyticsCountlyProvider: AnalyticsProvider {

    /// flag for recording session is begun
    private var sessionBegun: Bool = false

    private struct StoredEvent {
        let event: String
        let attributes: [String: Any]
    }

    /// store the events before selfUser is assigned. Send them and clear after selfUser is set
    private var storedEvents: [StoredEvent] = []
    
    var storedEventsCount: Int {
        return storedEvents.count
    }

    var isOptedOut: Bool {
        get {
            return !sessionBegun
        }

        set {
            newValue ? Countly.sharedInstance().endSession() :
                       Countly.sharedInstance().beginSession()

            sessionBegun = !isOptedOut
        }
    }

    var selfUser: UserType? {
        didSet {
            guard selfUser != nil else {
                endSession()
                return
            }

            if !sessionBegun {
                beginSession()
            }

            updateUserProperties()

            storedEvents.forEach {
                tagEvent($0.event, attributes: $0.attributes)
            }

            storedEvents.removeAll()
        }
    }
    
    var countlyInstanceType: CountlyInstance.Type
    var countlyAppKey: String

    init?(countlyInstanceType: CountlyInstance.Type = Countly.self,
          countlyAppKey: String? = Bundle.countlyAppKey) {
        guard let countlyAppKey = countlyAppKey else { return nil }
        
        self.countlyAppKey = countlyAppKey
        self.countlyInstanceType = countlyInstanceType
        isOptedOut = false
    }

    deinit {
        zmLog.info("AnalyticsCountlyProvider \(self) deallocated")
    }

    private func beginSession() {
        guard
            shouldTracksEvent,
            let selfUser = selfUser as? ZMUser,
            let analyticsIdentifier = selfUser.analyticsIdentifier
        else {
            return
        }

        guard
            !countlyAppKey.isEmpty,
            let countlyURL = BackendEnvironment.shared.countlyURL
        else {
            let appKey = String(describing: Bundle.countlyAppKey)
            let url = String(describing: BackendEnvironment.shared.countlyURL)
            zmLog.error("AnalyticsCountlyProvider is not created. Bundle.countlyAppKey = \(appKey), countlyURL = \(url). Please check COUNTLY_APP_KEY is set in .xcconfig file")
            return
        }
                
        let config: CountlyConfig = CountlyConfig()
        config.appKey = countlyAppKey
        config.host = countlyURL.absoluteString
        config.manualSessionHandling = true
        
        config.deviceID = analyticsIdentifier
        countlyInstanceType.sharedInstance().start(with: config)

        // Changing Device ID after app started
        // ref: https://support.count.ly/hc/en-us/articles/360037753511-iOS-watchOS-tvOS-macOS#section-resetting-stored-device-id
        Countly.sharedInstance().setNewDeviceID(analyticsIdentifier, onServer:true)
        
        zmLog.info("AnalyticsCountlyProvider \(self) started")
        sessionBegun = true
    }

    private func endSession() {
        Countly.sharedInstance().endSession()
        sessionBegun = false
    }

    private var shouldTracksEvent: Bool {
        return selfUser?.isTeamMember == true
    }

    /// update user properties after self user changes
    private func updateUserProperties() {
        guard shouldTracksEvent,
            let selfUser = selfUser as? ZMUser,
            let team = selfUser.team,
            let teamID = team.remoteIdentifier
        else {

            //clean up
            ["team_team_id",
             "team_user_type",
             "team_team_size",
             "user_contacts"].forEach {
                Countly.user().unSet($0)
            }

            Countly.user().save()
            isOptedOut = true

            return
        }

        let userProperties: [String: Any] = ["team_team_id": teamID,
                                             "team_user_type": selfUser.teamRole,
                                             "team_team_size": team.members.count,
                                             "user_contacts": team.members.count.logRound()]

        let convertedAttributes = userProperties.countlyStringValueDictionary

        for(key, value) in convertedAttributes {
            Countly.user().set(key, value: value)
        }

        Countly.user().save()
    }

    func tagEvent(_ event: String,
                  attributes: [String: Any]) {
        //store the event before self user is assigned, send it later when self user is ready.
        guard selfUser != nil else {            
            storedEvents.append(StoredEvent(event: event, attributes: attributes))
            return
        }

        guard shouldTracksEvent else {
            return
        }

        var convertedAttributes = attributes.countlyStringValueDictionary

        convertedAttributes["app_name"] = "ios"
        convertedAttributes["app_version"] = Bundle.main.shortVersionString

        countlyInstanceType.sharedInstance().recordEvent(event, segmentation: convertedAttributes)
    }

    func setSuperProperty(_ name: String, value: Any?) {
        //TODO
    }

    func flush(completion: Completion?) {
        isOptedOut = true
        completion?()
    }
}

extension Dictionary where Key == String, Value == Any {

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

    var countlyStringValueDictionary: [String: String] {
        let convertedAttributes: [String: String] = [String: String](uniqueKeysWithValues:
            map { key, value in (key, countlyValue(rawValue: value)) })

        return convertedAttributes
    }
}
