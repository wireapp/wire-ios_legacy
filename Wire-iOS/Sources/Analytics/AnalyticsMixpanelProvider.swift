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

let MixpanelDistinctIdKey = "MixpanelDistinctIdKey"

private let zmLog = ZMSLog(tag: "Analytics")

fileprivate enum MixpanelSuperProperties: String {
    case city = "$city"
    case region = "$region"
    case ignore = "$ignore"
}

extension Dictionary where Key == String, Value == Any {
    fileprivate static func bridgeOrDescription(for object: Any?) -> MixpanelType? {
        guard let object = object else { return nil }
        if let object = object as? NSNumber {
            let numberType = CFNumberGetType(object)

            switch numberType {
            case .charType:
                return object.boolValue
            case .sInt8Type, .sInt16Type, .sInt32Type, .sInt64Type, .shortType, .intType, .longType, .longLongType, .cfIndexType, .nsIntegerType:
                return object.intValue
            case .float32Type, .float64Type, .floatType, .doubleType, .cgFloatType:
                return object.floatValue
            }
        } else if object is MixpanelType {
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
    private let defaults: UserDefaults
    
    // INFO: this list has to go after we are sure that we are not sending any unexpected events.
    private static let enabledEvents = Set<String>([
        conversationMediaCompleteActionEventName,
        "settings.opted_in_tracking",
        "settings.opted_out_tracking",
        "settings.changed_status",
        "start.opened_start_screen",
        "start.opened_person_registration",
        "start.opened_team_registration",
        "start.opened_login",
        "team.verified",
        "team.accepted_terms",
        "team.created",
        "team.added_team_name",
        "team.finished_invite_step",
        "settings.opened_manage_team",
        "registration.succeeded",
        "calling.joined_call",
        "calling.established_call",
        "calling.ended_call",
        "calling.initiated_call",
        "calling.received_call",
        "calling.avs_metrics_ended_call",
        "calling.call_quality_review",
        "notifications.processing",
        TeamInviteEvent.sentInvite(.teamCreation).name,
        "integration.added_service",
        "integration.removed_service",
        LinearGroupCreationFlowEvent.openedGroupCreationName,
        LinearGroupCreationFlowEvent.openedSelectParticipantsName,
        LinearGroupCreationFlowEvent.groupCreationSucceededName,
        LinearGroupCreationFlowEvent.addParticipantsName,
        ConversationEvent.toggleAllowGuestsName,
        GuestLinkEvent.created.name,
        GuestLinkEvent.copied.name,
        GuestLinkEvent.revoked.name,
        GuestLinkEvent.shared.name,
        GuestRoomEvent.created.name,
        BackupEvent.importSucceeded.name,
        BackupEvent.importFailed.name,
        BackupEvent.exportSucceeded.name,
        BackupEvent.exportFailed.name,
        "e2ee.failed_message_decyption",
        "request.loop",
        "debug.database_context_save_failure"
        ])
    
    private static let enabledSuperProperties = Set<String>([
        "app",
        "team.in_team",
        "team.size",
        MixpanelSuperProperties.city.rawValue,
        MixpanelSuperProperties.region.rawValue
        ])
    
    deinit {
        zmLog.info("AnalyticsMixpanelProvider \(self) deallocated")
    }
    
    init(defaults: UserDefaults) {
        self.defaults = defaults

        if !MixpanelAPIKey.isEmpty {
            mixpanelInstance = Mixpanel.initialize(token: MixpanelAPIKey, optOutTrackingByDefault: true)
        }
        super.init()
        mixpanelInstance?.distinctId = mixpanelDistinctId
        mixpanelInstance?.minimumSessionDuration = 2_000
        mixpanelInstance?.loggingEnabled = false
        zmLog.info("AnalyticsMixpanelProvider \(self) started")
        
        if DeveloperMenuState.developerMenuEnabled(),
            let uuidString = mixpanelInstance?.distinctId {
            zmLog.error("Mixpanel distinctId = `\(uuidString)`")
        }
        
        self.setSuperProperty("app", stringValue: "ios")
        self.setSuperProperty(MixpanelSuperProperties.city.rawValue, stringValue: "")
        self.setSuperProperty(MixpanelSuperProperties.region.rawValue, stringValue: "")
    }
    
    var mixpanelDistinctId: String {
        if let id = defaults.string(forKey: MixpanelDistinctIdKey) {
            return id
        }
        else {
            let id = UUID().transportString()
            defaults.set(id, forKey: MixpanelDistinctIdKey)
            defaults.synchronize()
            return id
        }
    }
    
    public var isOptedOut: Bool {
        get {
            return mixpanelInstance?.hasOptedOutTracking() ?? true
        }
        set {
            if newValue == true {
                mixpanelInstance?.optOutTracking()
            } else {
                mixpanelInstance?.optInTracking()
            }
        }
    }
    
    func tagEvent(_ event: String, attributes: [String: Any] = [:]) {
        guard let mixpanelInstance = self.mixpanelInstance else {
            return
        }
        
        assert(AnalyticsMixpanelProvider.enabledEvents.contains(event), "Analytics: event \(event) is disabled")
        
        mixpanelInstance.track(event: event, properties: attributes.propertiesRemovingLocation())
    }
    
    //Fallback method to avoid repeated casts to NSObject
    func setSuperProperty(_ name: String, stringValue: String?) {
        self.setSuperProperty(name, value: stringValue as NSObject?)
    }
    
    func setSuperProperty(_ name: String, value: NSObject?) {
        guard let mixpanelInstance = self.mixpanelInstance else {
            return
        }
        
        assert(AnalyticsMixpanelProvider.enabledSuperProperties.contains(name), "Analytics: Super property \(name) is disabled")
        
        if let valueNotNil = Dictionary.bridgeOrDescription(for: value) {
            mixpanelInstance.registerSuperProperties([name: valueNotNil])
        }
        else {
            mixpanelInstance.unregisterSuperProperty(name)
        }
    }
}
