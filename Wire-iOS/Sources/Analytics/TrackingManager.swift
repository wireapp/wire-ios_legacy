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
import HockeySDK
import WireExtensionComponents


@objc public class TrackingManager: NSObject, TrackingInterface {
    private let flowManagerObserver: NSObjectProtocol
    
    private override init() {
        AVSFlowManager.getInstance()?.setEnableMetrics(!ExtensionSettings.shared.disableCrashAndAnalyticsSharing)
        
        flowManagerObserver = NotificationCenter.default.addObserver(forName: FlowManager.AVSFlowManagerCreatedNotification, object: nil, queue: OperationQueue.main, using: { _ in
            AVSFlowManager.getInstance()?.setEnableMetrics(!ExtensionSettings.shared.disableCrashAndAnalyticsSharing)
        })
    }
    
    @objc public static let shared = TrackingManager()

    @objc public var disableCrashAndAnalyticsSharing: Bool {
        set {
            Analytics.shared().isOptedOut = newValue
            AVSFlowManager.getInstance()?.setEnableMetrics(!newValue)
            updateHockeyStateIfNeeded(oldState: disableCrashAndAnalyticsSharing, newValue)
            ExtensionSettings.shared.disableCrashAndAnalyticsSharing = newValue
        }
        
        get {
            return ExtensionSettings.shared.disableCrashAndAnalyticsSharing
        }
    }

    private func updateHockeyStateIfNeeded(oldState: Bool, _ newState: Bool) {
        switch (oldState, newState) {
        case (true, false):
            BITHockeyManager.shared().setTrackingEnabled(true)
            BITHockeyManager.shared().start()
            BITHockeyManager.shared().authenticator.authenticateInstallation()

        case (false, true):
            BITHockeyManager.shared().setTrackingEnabled(false)

        default:
            return
        }
    }
}
