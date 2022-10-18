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
import WireCommonComponents
import UserNotifications
import WireRequestStrategy

public class NotificationService: UNNotificationServiceExtension{

    // MARK: - Properties

    let simpleService = SimpleNotificationService()
    let legacyService = LegacyNotificationService()

    // MARK: - Methods

    public override func didReceive(
        _ request: UNNotificationRequest,
        withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
    ) {
//        if  DeveloperFlag.nseDebugging.isOn {
//            DebugLogger.storage = .applicationGroup
//            UserDefaults.applicationGroup.set(DeveloperFlag.nseDebugging.isOn, forKey: DebugLogger.DebugFlagIsOnKey)
//        }

//        if DeveloperFlag.nseDebugEntryPoint.isOn {
//            DebugLogger.storage = .applicationGroup
//            UserDefaults.applicationGroup.set(DeveloperFlag.nseDebugging.isOn, forKey: DebugLogger.DebugFlagIsOnKey)
//
//            contentHandler(request.debugContent)
//            return
//        }
        DebugLogger.addStep(step: "Start - push notification was received.", eventID: "!")


//        self.contentHandler = contentHandler
//
//        guard let accountID = request.content.accountID else {
//            DebugLogger.addStep(step: "Missing account id", eventID: "!")
//            contentHandler(.debugMessageIfNeeded(message: "Missing account id."))
        if DeveloperFlag.breakMyNotifications.isOn {
            // By doing nothing, we hope to get in a state where iOS will no
            // longer deliver pushes to us.
            return
        } else if DeveloperFlag.nseV2.isOn {
            simpleService.didReceive(
                request,
                withContentHandler: contentHandler
            )
        } else {
            legacyService.didReceive(
                request,
                withContentHandler: contentHandler
            )
        }
    }

//        guard let session = try? createSession(accountID: accountID) else {
//            DebugLogger.addStep(step: "Failed to create session.", eventID: "!")
//            contentHandler(.debugMessageIfNeeded(message: "Failed to create session."))
//            return
//        }
//
//        session.processPushNotification(with: request.content.userInfo) { isUserAuthenticated in
//            if !isUserAuthenticated {
//                DebugLogger.addStep(step: "User is not authenticated.", eventID: "!")
//                contentHandler(.debugMessageIfNeeded(message: "User is not authenticated."))
//            }
//        }
//
//        // Retain the session otherwise it will tear down.
//        self.session = session
//    }
//
//    public override func serviceExtensionTimeWillExpire() {
//        guard let contentHandler = contentHandler else { return }
//        DebugLogger.addStep(step: "Extension is expiring.", eventID: "!")
//        contentHandler(.debugMessageIfNeeded(message: "Extension is expiring."))
//        tearDown()
//    }
//
//    public func notificationSessionDidGenerateNotification(
//        _ notification: ZMLocalNotification?,
//        unreadConversationCount: Int
//    ) {
//        defer { tearDown() }
//
//        guard let contentHandler = contentHandler else { return }
//        DebugLogger.addStep(step: "Callback from NE", eventID: "!")
//
//        guard let content = notification?.content else {
//            DebugLogger.addStep(step: "! No notification generated.", eventID: "!")
//            contentHandler(.debugMessageIfNeeded(message: "No notification generated."))

    public override func serviceExtensionTimeWillExpire() {
            if DeveloperFlag.breakMyNotifications.isOn {
                // By doing nothing, we hope to get in a state where iOS will no
                // longer deliver pushes to us.
                return
            } else if DeveloperFlag.nseV2.isOn {
                simpleService.serviceExtensionTimeWillExpire()
            } else {
                legacyService.serviceExtensionTimeWillExpire()
            }
        }
    }
//        guard let mutabaleContent = content as? UNMutableNotificationContent else {
//            DebugLogger.addStep(step: "! Content not mutable.", eventID: "!")
//            contentHandler(.debugMessageIfNeeded(message: "Content not mutable."))
//            return
//        }
//
//        if #available(iOS 15, *) {
//            mutabaleContent.interruptionLevel = .timeSensitive
//        }
//
//        let badgeCount = totalUnreadCount(unreadConversationCount)
//        mutabaleContent.badge = badgeCount
//        DebugLogger.addStep(step: "Updated badge count ", eventID: "!")
//        Logging.push.safePublic("Updated badge count to \(SanitizedString(stringLiteral: String(describing: badgeCount)))")
//
//        DebugLogger.addStep(step: "Final step in UI ", eventID: "!")
//        contentHandler(mutabaleContent)
//    }
//
//    public func reportCallEvent(_ event: ZMUpdateEvent, currentTimestamp: TimeInterval) {
//        guard
//            let accountID = session?.accountIdentifier,
//            let voipPayload = VoIPPushPayload(from: event, accountID: accountID, serverTimeDelta: currentTimestamp),
//            let payload = voipPayload.asDictionary
//        else {
//            return
//        }
//
//        callEventHandler.reportIncomingVoIPCall(payload)
//    }
//
//    public func notificationSessionFailedWithError(error: NotificationSessionError) {
//        DebugLogger.addStep(step: "Notification session failed with error \(error)", eventID: "!")
//        guard let contentHandler = contentHandler else { return }
//
//        switch error {
//        case .unknownAccount:
//            contentHandler(.debugMessageIfNeeded(message: "Failed with error: unknownAccount"))
//        case .accountNotAuthenticated:
//            contentHandler(.debugMessageIfNeeded(message: "Failed with error: accountNotAuthenticated"))
//        case .noEventID:
//            contentHandler(.debugMessageIfNeeded(message: "Failed with error: noEventID"))
//        case .duplicateEvent:
//            contentHandler(.debugMessageIfNeeded(message: "Failed with error: duplicateEvent"))
//        default:
//            contentHandler(.debugMessageIfNeeded(message: "Failed with error: unknown"))
//        }
//    }
//
//    // MARK: - Helpers
//
//    private func tearDown() {
//        // Content and handler should only be consumed once.
//        contentHandler = nil
//
//        // Let the session deinit so it can tear down.
//        session = nil
//    }
//
//    private func createSession(accountID: UUID) throws -> NotificationSession {
//        let session = try NotificationSession(
//            applicationGroupIdentifier: appGroupID,
//            accountIdentifier: accountID,
//            environment: BackendEnvironment.shared,
//            analytics: nil
//        )
//
//        session.delegate = self
//        return session
//    }
//
//    private func totalUnreadCount(_ unreadConversationCount: Int) -> NSNumber? {
//        guard let session = session else {
//            return nil
//        }
//        let account = self.accountManager.account(with: session.accountIdentifier)
//        account?.unreadConversationCount = unreadConversationCount
//        let totalUnreadCount = self.accountManager.totalUnreadCount
//
//        return NSNumber(value: totalUnreadCount)
//    }
//
//}
//
//// MARK: - Extensions
//
//extension UNNotificationRequest {
//
//    var mutableContent: UNMutableNotificationContent? {
//        return content.mutableCopy() as? UNMutableNotificationContent
//    }
//
//    var debugContent: UNNotificationContent {
//        let content = UNMutableNotificationContent()
//        content.title = "DEBUG 👀"
//
//        guard
//            let notificationData = self.content.userInfo["data"] as? [String: Any],
//            let userID = notificationData["user"] as? String,
//            let data = notificationData["data"] as? [String: Any],
//            let eventID = data["id"] as? String
//        else {
//            content.body = "Received a push"
//            return content
//        }
//
//        content.body = "USER: \(userID), EVENT: \(eventID)"
//        return content
//    }
//
//}
//
//extension UNNotificationContent {
//
//    // With the "filtering" entitlement, we can tell iOS to not display a user notification by
//    // passing empty content to the content handler.
//    // See https://developer.apple.com/documentation/bundleresources/entitlements/com_apple_developer_usernotifications_filtering
//
//    static var empty: Self {
//        return Self()
//    }
//
//    static func debugMessageIfNeeded(message: String) -> UNNotificationContent {
//        guard DeveloperFlag.nseDebugging.isOn else { return .empty }
//        return debug(message: message)
//    }
//
//    static func debug(message: String) -> UNNotificationContent {
//        let content = UNMutableNotificationContent()
//        content.title = "DEBUG 👀"
//        content.body = message
//        return content
//    }
//
//    var accountID: UUID? {
//        guard
//            let data = userInfo["data"] as? [String: Any],
//            let userIDString = data["user"] as? String,
//            let userID = UUID(uuidString: userIDString)
//        else {
//            return nil
//        }
//
//        return userID

//    }

//}
