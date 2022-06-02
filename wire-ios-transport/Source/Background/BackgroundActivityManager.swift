//
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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

import UIKit

/**
 * A protocol for objects that can start and end background activities.
 */

@objc public protocol BackgroundActivityManager: NSObjectProtocol {
    /// Begin a background task.
    func beginBackgroundTask(withName name: String?, expirationHandler: (() -> Void)?) -> UIBackgroundTaskIdentifier

    /// End the background task.
    func endBackgroundTask(_ task: UIBackgroundTaskIdentifier)
    
    // Make sure to only access this from main thread!
    var backgroundTimeRemaining: TimeInterval { get }
    var applicationState: UIApplication.State { get }
}

extension BackgroundActivityManager {
    /// Returns application state and background time remaining
    /// This code should be called from main queue only!
    var stateDescription: String {
        if applicationState == .background {
            // Sometimes time remaining is very large even if we run in background
            let time = backgroundTimeRemaining > 100000 ? "No Limit" : String(format: "%.2f", backgroundTimeRemaining)
            return "App state: \(applicationState), time remaining: \(time)"
        } else {
            return "App state: \(applicationState)"
        }
    }
}

extension UIApplication.State: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {
        case .active:
            return "active"
        case .background:
            return "background"
        case .inactive:
            return "inactive"
        @unknown default:
            return "<uknown>"
        }
    }
}

extension UIApplication: BackgroundActivityManager {}
