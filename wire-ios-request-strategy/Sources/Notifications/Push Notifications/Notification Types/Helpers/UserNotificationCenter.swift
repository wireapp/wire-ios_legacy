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

import Foundation
import UserNotifications

/**
 * An abstraction of the `UNUserNotificationCenter` object to facilitate
 * mocking for unit tests.
 */

public protocol UserNotificationCenter: AnyObject {

    /// The object that processes incoming notifications and actions.
    var delegate: UNUserNotificationCenterDelegate? { get set }

    /// Registers the notification types and the custom actions they support.
    func setNotificationCategories(_ categories: Set<UNNotificationCategory>)

    // Requests authorization to use notifications.
    func requestAuthorization(options: UNAuthorizationOptions, completionHandler: @escaping (Bool, Error?) -> Void)

    /// Schedules the request to display a local notification.
    func add(_ request: UNNotificationRequest, withCompletionHandler: ((Error?) -> Void)?)

    /// Unschedules the specified notification requests.
    func removePendingNotificationRequests(withIdentifiers identifiers: [String])

    /// Removes the specified notification requests from Notification Center
    func removeDeliveredNotifications(withIdentifiers identifiers: [String])

    /// Removes all pending requests and delivered notifications with the given identifiers.
    func removeAllNotifications(withIdentifiers identifiers: [String])
}

extension UNUserNotificationCenter: UserNotificationCenter {

    public func removeAllNotifications(withIdentifiers identifiers: [String]) {
        removePendingNotificationRequests(withIdentifiers: identifiers)
        removeDeliveredNotifications(withIdentifiers: identifiers)
    }
}
