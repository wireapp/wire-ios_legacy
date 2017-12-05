//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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
import Mixpanel
import CocoaLumberjackSwift

let MixpanelDistinctIdKey = "MixpanelDistinctIdKey"

fileprivate enum MixpanelSuperProperties: String {
    case city = "$city"
    case region = "$region"
    case ignore = "$ignore"
}

extension Dictionary where Key == String, Value == Any {
    fileprivate static func bridgeOrDescription(for object: Any) -> MixpanelType? {
        if object is MixpanelType {
            return (object as! MixpanelType)
        }
        else if object is NSString {
            return ((object as! NSString) as String)
        }
        else if object is CustomStringConvertible {
            return (object as! CustomStringConvertible).description
        }
        else {
            return nil
        }
    }

    fileprivate func propertiesRemovingLocation() -> Properties {
        var finalAttributes: Properties = self.mapKeysAndValues(keysMapping: identity) { key, value in
            return type(of: self).bridgeOrDescription(for: value)!
        }
        finalAttributes[MixpanelSuperProperties.city.rawValue] = ""
        finalAttributes[MixpanelSuperProperties.region.rawValue] = ""
        return finalAttributes
    }
}

final class AnalyticsMixpanelProvider: NSObject, AnalyticsProvider {
    private var mixpanelInstance: MixpanelInstance? = .none
    
    
    private static let enabledEvents = Set<String>([
        conversationMediaCompleteActionEventName,
        "settings.opted_in_tracking",
        "settings.opted_out_tracking",
        "e2ee.failed_message_decyption",
        "start.opened_start_screen",
        "start.opened_person_registration",
        "start.opened_team_registration",
        "start.opened_login",
        "team.verified",
        "team.accepted_terms",
        "team.created",
        "team.finished_invite_step",
        "settings.opened_manage_team",
        "registration.succeeded",
        "calling.joined_call",
        "calling.joined_video_call",
        "calling.established_call",
        "calling.established_video_call",
        "calling.ended_call",
        "calling.ended_video_call",
        "calling.initiated_call",
        "calling.initiated_video_call",
        "calling.received_call",
        "calling.received_video_call",
        "calling.avs_metrics_ended_call",
        ])
    
    private static let enabledSuperProperties = Set<String>([
        "app",
        "team.in_team",
        "team.size",
        MixpanelSuperProperties.city.rawValue,
        MixpanelSuperProperties.region.rawValue
        ])
    
    deinit {
        DDLogInfo("AnalyticsMixpanelProvider \(self) deallocated")
    }
    
    override init() {
        if !MixpanelAPIKey.isEmpty {
            mixpanelInstance = Mixpanel.initialize(token: MixpanelAPIKey)
        }
        super.init()
        mixpanelInstance?.distinctId = mixpanelDistinctId
        mixpanelInstance?.minimumSessionDuration = 2_000
        mixpanelInstance?.loggingEnabled = false
        DDLogInfo("AnalyticsMixpanelProvider \(self) started")
        
        if DeveloperMenuState.developerMenuEnabled(),
            let uuidString = mixpanelInstance?.distinctId {
            DDLogError("Mixpanel distinctId = `\(uuidString)`")
        }
        
        self.setSuperProperty("app", value: "ios")
        self.setSuperProperty(MixpanelSuperProperties.city.rawValue, value: "")
        self.setSuperProperty(MixpanelSuperProperties.region.rawValue, value: "")
    }
    
    var mixpanelDistinctId: String {
        if let id = UserDefaults.shared().string(forKey: MixpanelDistinctIdKey) {
            return id
        }
        else {
            let id = UUID().transportString()
            UserDefaults.shared().set(id, forKey: MixpanelDistinctIdKey)
            UserDefaults.shared().synchronize()
            return id
        }
    }
    
    public var isOptedOut : Bool = false {
        didSet {
            if isOptedOut {
                self.mixpanelInstance?.flush(completion: {})
            }
        }
    }
    
    func tagEvent(_ event: String, attributes: [String: Any] = [:]) {
        guard let mixpanelInstance = self.mixpanelInstance else {
            return
        }
        
        guard AnalyticsMixpanelProvider.enabledEvents.contains(event) else {
            DDLogInfo("Analytics: event \(event) is disabled")
            return
        }
        
        mixpanelInstance.track(event: event, properties: attributes.propertiesRemovingLocation())
    }
    
    func setSuperProperty(_ name: String, value: String?) {
        guard let mixpanelInstance = self.mixpanelInstance else {
            return
        }
        
        guard AnalyticsMixpanelProvider.enabledSuperProperties.contains(name) else {
            DDLogInfo("Analytics: Super property \(name) is disabled")
            return
        }
        
        if let valueNotNil = value {
            mixpanelInstance.registerSuperProperties([name: valueNotNil])
        }
        else {
            mixpanelInstance.unregisterSuperProperty(name)
        }
    }
}
