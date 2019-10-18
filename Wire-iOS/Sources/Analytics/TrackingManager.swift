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
import AppCenter
import AppCenterAnalytics
import AppCenterCrashes
import AppCenterDistribute
import WireCommonComponents


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
            updateAppCenterStateIfNeeded(oldState: disableCrashAndAnalyticsSharing, newValue)
            ExtensionSettings.shared.disableCrashAndAnalyticsSharing = newValue
        }
        
        get {
            return ExtensionSettings.shared.disableCrashAndAnalyticsSharing
        }
    }

    private func updateAppCenterStateIfNeeded(oldState: Bool, _ newState: Bool) {
        switch (oldState, newState) {
        case (true, false):
            MSAppCenter.setEnabled(true)
            MSAppCenter.start()
        case (false, true):
            MSAppCenter.setEnabled(false)
        default:
            return
        }
    }
}
