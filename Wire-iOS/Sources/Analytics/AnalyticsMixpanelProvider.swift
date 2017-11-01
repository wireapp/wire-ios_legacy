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
        "e2ee.failed_message_decyption"
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
        mixpanelInstance?.minimumSessionDuration = 2_000
        mixpanelInstance?.loggingEnabled = false
        self.setSuperProperty("app", value: "ios")
        self.setSuperProperty(MixpanelSuperProperties.city.rawValue, value: "")
        self.setSuperProperty(MixpanelSuperProperties.region.rawValue, value: "")
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
