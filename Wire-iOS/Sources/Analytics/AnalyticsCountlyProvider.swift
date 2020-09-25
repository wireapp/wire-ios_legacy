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

extension Int {
    func logRound(factor: Double = 6) -> Int {
        return Int(ceil(pow(2, (floor(factor * log2(Double(self))) / factor))))
    }
}

final class AnalyticsCountlyProvider: AnalyticsProvider {

    /// flag for recording session is begun
    private var sessionBegun: Bool = false
    private var isUserSet: Bool = false

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

        isOptedOut = false
        sessionBegun = true
    }

    deinit {
        zmLog.info("AnalyticsCountlyProvider \(self) deallocated")
    }

    //TODO: call this after switched account
    func updateUserProperties() {
        guard let selfUser = SelfUser.provider?.selfUser as? ZMUser,
              let team = selfUser.team else {
            return
        }

        var userProperties: [String: Any] = ["team_team_id": selfUser.hasTeam,
                                             "team_user_type": selfUser.teamRole]

        userProperties["user_id"] = selfUser.userId.uuid.zmSHA256Digest().zmHexEncodedString()

        let teamSize = team.members.count.logRound()
        userProperties["team_team_size"] = teamSize
        userProperties["user_contacts"] = teamSize

        let convertedAttributes = convertToCountlyDictionary(dictioary: userProperties)

        for(key, value) in convertedAttributes {
            Countly.user().set(key, value: value)
        }

        Countly.user().save()
    }

    private func convertToCountlyDictionary(dictioary: [String: Any]) -> [String: String] {
        let convertedAttributes: [String: String] = Dictionary(uniqueKeysWithValues:
            dictioary.map { key, value in (key, countlyValue(rawValue: value)) })

        return convertedAttributes
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
                  attributes: [String: Any]) {
        if !isUserSet {
            updateUserProperties()

            isUserSet = true
        }

        var convertedAttributes = convertToCountlyDictionary(dictioary: attributes)

        convertedAttributes["app_name"] = "ios"
        convertedAttributes["app_version"] = Bundle.main.shortVersionString

        Countly.sharedInstance().recordEvent(event, segmentation: convertedAttributes)
    }

    func setSuperProperty(_ name: String, value: Any?) {
        //TODO
    }

    func flush(completion: Completion?) {
        isOptedOut = true
        completion?()
    }
}
