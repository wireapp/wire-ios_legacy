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
import WireNotificationEngine
import WireCommonComponents
import WireDataModel
import UIKit

public class NotificationService: UNNotificationServiceExtension, NotificationSessionDelegate {

    private typealias Content = UNMutableNotificationContent
    private typealias Handler = (UNNotificationContent) -> Void

    // MARK: - Properties

    private var session: NotificationSession?
    private var contentAndHandler: (content: Content, handler: Handler)?

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
        // TODO: what to do when no content?
        guard let content = request.mutableContent else { return }

        contentAndHandler = (content, contentHandler)

        // TODO: Check if we have accountID in request.content.userInfo
        guard
            let accountID = accountManager.selectedAccount?.userIdentifier,
            let session = try? createSession(accountID: accountID)
        else {
            // TODO: what happens here?
            return
        }

        session.processPushNotification(with: request.content.userInfo) { isUserAuthenticated in
            if !isUserAuthenticated {
                let emptyContent = UNNotificationContent()
                contentHandler(emptyContent)
            }
        }

        // Retain the session otherwise it will tear down.
        self.session = session
    }

    public override func serviceExtensionTimeWillExpire() {
        // TODO: discuss with product/design what should we display
        let emptyContent = UNNotificationContent()
        contentAndHandler?.handler(emptyContent)
    }

    public func modifyNotification(_ alert: ClientNotification, messageCount: Int) {
        defer { tearDown() }
        // TODO: what to do in else?
        guard let (content, handler) = contentAndHandler else { return }

        switch messageCount {
        case 0:
            content.title = "Oops"
            content.body = "No content to show"

        case 1:
            content.title = alert.title
            content.body = alert.body

        default:
            content.title = alert.title
            content.body = String(format: "push.notifications.bundled_message.title".localized, messageCount)
        }

        handler(content)
    }

    // MARK: - Helpers

    private func tearDown() {
        // Content and handler should only be consumed once.
        contentAndHandler = nil

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
