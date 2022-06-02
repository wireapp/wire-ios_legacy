////
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
import WireSyncEngine
import UserNotifications

@objc class UserNotificationCenterMock: NSObject, UserNotificationCenter {

    weak var delegate: UNUserNotificationCenterDelegate?

    /// Identifiers of scheduled notification requests.
    @objc var scheduledRequests = [UNNotificationRequest]()

    /// Identifiers of removed notifications.
    @objc var removedNotifications = Set<String>()

    /// The registered notification categories for the app.
    @objc var registeredNotificationCategories = Set<UNNotificationCategory>()

    /// The requested authorization options for the app.
    @objc var requestedAuthorizationOptions: UNAuthorizationOptions = []

    func setNotificationCategories(_ categories: Set<UNNotificationCategory>) {
        registeredNotificationCategories.formUnion(categories)
    }

    func requestAuthorization(options: UNAuthorizationOptions,
                              completionHandler: @escaping (Bool, Error?) -> Void) {
        requestedAuthorizationOptions.insert(options)
    }

    func add(_ request: UNNotificationRequest, withCompletionHandler: ((Error?) -> Void)?) {
        scheduledRequests.append(request)
    }

    func removePendingNotificationRequests(withIdentifiers identifiers: [String]) {
        removedNotifications.formUnion(identifiers)
    }

    func removeDeliveredNotifications(withIdentifiers identifiers: [String]) {
        removedNotifications.formUnion(identifiers)
    }

    func removeAllNotifications(withIdentifiers identifiers: [String]) {
        removePendingNotificationRequests(withIdentifiers: identifiers)
        removeDeliveredNotifications(withIdentifiers: identifiers)
    }
}
