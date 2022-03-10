//
// Wire
// Copyright (C) 2022 Wire Swiss GmbH
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
import WireRequestStrategy
import WireNotificationEngine
import WireCommonComponents
import WireDataModel
import WireSyncEngine
import UIKit

public class NotificationService: UNNotificationServiceExtension, NotificationSessionDelegate {

    // MARK: - Properties

    private var session: NotificationSession?
    private var contentHandler: ((UNNotificationContent) -> Void)?

    private lazy var accountManager: AccountManager = {
        let sharedContainerURL = FileManager.sharedContainerDirectory(for: appGroupID)
        let account = AccountManager(sharedDirectory: sharedContainerURL)
        return account
    }()

    private var appGroupID: String {
        guard let groupID = Bundle.main.applicationGroupIdentifier else {
            fatalError("cannot get app group identifier")
        }

        return groupID
    }

    // MARK: - Methods

    public override func didReceive(
        _ request: UNNotificationRequest,
        withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
    ) {
        self.contentHandler = contentHandler

        guard
            let accountID = request.content.userInfo.accountId(),
            let session = try? createSession(accountID: accountID)
        else {
            // TODO: what happens here?
            return
        }

        session.processPushNotification(with: request.content.userInfo) { isUserAuthenticated in
            if !isUserAuthenticated {
                contentHandler(.empty)
            }
        }

        // Retain the session otherwise it will tear down.
        self.session = session
    }

    public override func serviceExtensionTimeWillExpire() {
        // TODO: discuss with product/design what should we display
        guard let contentHandler = contentHandler else { return }
        contentHandler(.empty)
        tearDown()
    }

    public func notificationSessionDidGenerateNotification(_ notification: ZMLocalNotification?) {
        defer { tearDown() }
        guard let contentHandler = contentHandler else { return }
        contentHandler(notification?.content ?? .empty)
    }


    // MARK: - Helpers

    private func tearDown() {
        // Content and handler should only be consumed once.
        contentHandler = nil

        // Let the session deinit so it can tear down.
        session = nil
    }

    private func createSession(accountID: UUID) throws -> NotificationSession {
        return try NotificationSession(
            applicationGroupIdentifier: appGroupID,
            accountIdentifier: accountID,
            environment: BackendEnvironment.shared,
            analytics: nil,
            delegate: self,
            useLegacyPushNotifications: false
        )
    }
}

// MARK: - Extensions

extension UNNotificationRequest {

    var mutableContent: UNMutableNotificationContent? {
        return content.mutableCopy() as? UNMutableNotificationContent
    }

}

extension UNNotificationContent {

    // With the "filtering" entitlement, we can tell iOS to not display a user notification by
    // passing empty content to the content handler.
    // See https://developer.apple.com/documentation/bundleresources/entitlements/com_apple_developer_usernotifications_filtering

    static var empty: Self {
        return Self()
    }

}
