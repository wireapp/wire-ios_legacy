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

final class AnalyticsMixpanelProvider: NSObject, AnalyticsProvider {
    private var mixpanelInstance: MixpanelInstance? = .none
    
    override init() {
        if !AnalyticsAPIKey.isEmpty {
            mixpanelInstance = Mixpanel.initialize(token: AnalyticsAPIKey)
        }
        super.init()
    }
    
    public var isOptedOut : Bool {
        get {
            return !(mixpanelInstance?.loggingEnabled ?? false)
        }
        
        set {
            mixpanelInstance?.loggingEnabled = !newValue
        }
    }
    
    func tagScreen(_ screen: String) {
        // TODO
    }
    
    func tagEvent(_ event: String) {
        tagEvent(event, attributes: [:])
    }
    
    func tagEvent(_ event: String, attributes: [AnyHashable : Any]? = [:]) {
        var attributes = attributes ?? [:]
        attributes["app"] = "ios"
        
        print("event: \(event), attributes: \(attributes)")
        // mixpanelInstance?.track(event: event, properties: attributes)
    }
    
    func setCustomDimension(_ dimension: Int32, value: String) {
        // TODO
    }
}
