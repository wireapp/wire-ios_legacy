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
import HockeySDK
import WireExtensionComponents


@objc public class TrackingManager: NSObject {
    private let UserDefaultDidMigrateLocalyticsSettingInitially = "DidMigrateLocalyticsSettingInitially"
    private let flowManagerObserver: NSObjectProtocol
    
    private override init() {
        AVSFlowManager.getInstance()?.setEnableMetrics(!ExtensionSettings.shared.disableCrashAndAnalyticsSharing)
        
        flowManagerObserver = NotificationCenter.default.addObserver(forName: FlowManager.AVSFlowManagerCreatedNotification, object: nil, queue: OperationQueue.main, using: { _ in
            AVSFlowManager.getInstance()?.setEnableMetrics(!ExtensionSettings.shared.disableCrashAndAnalyticsSharing)
        })
    }
    
    public static let shared = TrackingManager()
    
    @objc public func migrateFromLocalytics() {
        if !UserDefaults.shared().bool(forKey: UserDefaultDidMigrateLocalyticsSettingInitially) {
            Localytics.integrate(LocalyticsAPIKey)
            let isOptedOut = Localytics.isOptedOut()
            self.disableCrashAndAnalyticsSharing = isOptedOut
            UserDefaults.shared().set(true, forKey: UserDefaultDidMigrateLocalyticsSettingInitially)
        }
    }
}

extension TrackingManager: TrackingInterface {
    public var disableCrashAndAnalyticsSharing: Bool {
        set {
            BITHockeyManager.shared().setTrackingEnabled(!newValue)
            Analytics.shared().isOptedOut = newValue
            AVSFlowManager.getInstance()?.setEnableMetrics(!newValue)
            ExtensionSettings.shared.disableCrashAndAnalyticsSharing = newValue
        }
        
        get {
            return ExtensionSettings.shared.disableCrashAndAnalyticsSharing
        }
    }
}
