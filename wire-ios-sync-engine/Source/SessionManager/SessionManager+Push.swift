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
import PushKit
import UserNotifications
import WireRequestStrategy

private let pushLog = ZMSLog(tag: "Push")

protocol PushRegistry {

    var delegate: PKPushRegistryDelegate? { get set }
    var desiredPushTypes: Set<PKPushType>? { get set }

    func pushToken(for type: PKPushType) -> Data?

}

extension PKPushRegistry: PushRegistry {}

extension PKPushPayload {
    fileprivate var stringIdentifier: String {
        if let data = dictionaryPayload["data"] as? [AnyHashable: Any], let innerData = data["data"] as? [AnyHashable: Any], let id = innerData["id"] {
            return "\(id)"
        } else {
            return self.description
        }
    }
}

// MARK: - PKPushRegistryDelegate

extension SessionManager: PKPushRegistryDelegate {

    public func pushRegistry(_ registry: PKPushRegistry, didUpdate pushCredentials: PKPushCredentials, for type: PKPushType) {
        // We're only interested in voip push kit tokens.
        guard type == .voIP else { return }

        // We only want to store the voip token if required.
        guard requiredPushTokenType == .voip else { return }

        Logging.push.safePublic("PushKit token was updated: \(pushCredentials)")

        // Give new push token to all running sessions.
        backgroundUserSessions.values.forEach { userSession in
            let pushToken = PushToken.createVOIPToken(from: pushCredentials.token)
            userSession.setPushToken(pushToken)
        }
    }

    public func pushRegistry(_ registry: PKPushRegistry, didInvalidatePushTokenFor type: PKPushType) {
        // We're only interested in voip push kit tokens.
        guard type == .voIP else { return }

        // We don't want to delete a standard push token by accident.
        guard requiredPushTokenType == .voip else { return }

        Logging.push.safePublic("PushKit token was invalidated")

        // Delete push token from all running sessions.
        backgroundUserSessions.values.forEach { userSession in
            userSession.deletePushToken()
        }
    }

    public func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType) {
        self.pushRegistry(registry, didReceiveIncomingPushWith: payload, for: type, completion: {})
    }

    public func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType, completion: @escaping () -> Void) {
        if let voipPushPayload = VoIPPushPayload(payload: payload) {
            do {
                try handleCallPushPayload(voipPushPayload, completion: completion)
            } catch let error as VOIPPushError {
                Logging.push.safePublic("Failed to handle voip push payload: \(error)")
            } catch {
                Logging.push.safePublic("Failed to handle voip push payload for unknown reason")
            }
        } else {
            handleLegacyPushPayload(payload, for: type, completion: completion)
        }
    }

    private func handleCallPushPayload(_ payload: VoIPPushPayload, completion: @escaping () -> Void) throws {
        defer { completion() }

        guard let account = accountManager.account(with: payload.accountID) else {
            throw VOIPPushError.accountNotFound
        }

        guard let session = backgroundUserSessions[account.userIdentifier] else {
            throw VOIPPushError.userSessionNotFound
        }

        guard let callKitManager = callKitManager else {
            throw VOIPPushError.callKitManagerNotFound
        }

        guard let caller = payload.caller(in: session.viewContext) else {
            throw VOIPPushError.callerNotFound
        }

        guard let conversation = payload.conversation(in: session.viewContext) else {
            throw VOIPPushError.conversationNotFound
        }

        guard let callEventContent = CallEventContent(from: payload.data) else {
            throw VOIPPushError.malformedPayloadData
        }

        // IMPORTANT: We must report the call to CallKit synchronously in this method,
        // otherwise iOS will terminate the app due to violation of use of voip pushes.
        // If we let iOS terminate our app several times, then it will stop delivering
        // voip pushes altogether (even from the notification service extension). This
        // may not be recoverable without reinstalling the app.

        do {
            if case let .incomingCall(video: video) = callEventContent.callState {
                try callKitManager.reportIncomingCall(from: caller, in: conversation, video: video)
            } else {
                try callKitManager.reportCallEnded(in: conversation, atTime: payload.timestamp, reason: .remoteEnded)
            }
        } catch let error as CallKitManager.ReportIncomingCallError {
            throw VOIPPushError.failedToReportIncomingCall(reason: error)
        } catch let error as CallKitManager.ReportTerminatingCallError {
            throw VOIPPushError.failedToReportTerminatingCall(reason: error)
        }

        guard let processor = session.syncStrategy?.callingRequestStrategy else {
            throw VOIPPushError.processorNotFound
        }

        Logging.push.safePublic("Forwarding call push payload to user session with account \(account.userIdentifier)")

        processor.processCallEvent(
            conversationUUID: payload.conversationID,
            senderUUID: payload.senderID,
            clientId: payload.senderClientID,
            conversationDomain: payload.conversationDomain,
            senderDomain: payload.senderDomain,
            payload: payload.data,
            currentTimestamp: payload.serverTimeDelta,
            eventTimestamp: payload.timestamp
        )
    }

    private func handleLegacyPushPayload(_ payload: PKPushPayload, for type: PKPushType, completion: @escaping () -> Void) {
        // We only care about voIP pushes, other types are not related to push notifications (watch complications and files)
        guard type == .voIP else { return completion() }

        Logging.push.safePublic("Received push payload: \(payload)")
        // We were given some time to run, resume background task creation.
        BackgroundActivityFactory.shared.resume()
        notificationsTracker?.registerReceivedPush()

        guard let accountId = payload.dictionaryPayload.accountId(),
              let account = self.accountManager.account(with: accountId),
              let activity = BackgroundActivityFactory.shared.startBackgroundActivity(withName: "\(payload.stringIdentifier)", expirationHandler: { [weak self] in
                  Logging.push.safePublic("Processing push payload expired: \(payload)")
                  self?.notificationsTracker?.registerProcessingExpired()
              }) else {
                  Logging.push.safePublic("Aborted processing of payload: \(payload)")
                  notificationsTracker?.registerProcessingAborted()
                  return completion()
              }

        withSession(for: account, perform: { userSession in
            Logging.push.safePublic("Forwarding push payload to user session with account \(account.userIdentifier)")

            userSession.receivedPushNotification(with: payload.dictionaryPayload, completion: { [weak self] in
                Logging.push.safePublic("Processing push payload completed")
                self?.notificationsTracker?.registerNotificationProcessingCompleted()
                BackgroundActivityFactory.shared.endBackgroundActivity(activity)
                completion()
            })
        })
    }
}

// MARK: - UNUserNotificationCenterDelegate

@objc extension SessionManager: UNUserNotificationCenterDelegate {

    // Called by the OS when the app receieves a notification while in the
    // foreground.
    public func userNotificationCenter(_ center: UNUserNotificationCenter,
                                       willPresent notification: UNNotification,
                                       withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // route to user session
        handleNotification(with: notification.userInfo) { userSession in
            userSession.userNotificationCenter(center, willPresent: notification, withCompletionHandler: completionHandler)
        }
    }

    // Called when the user engages a notification action.
    public func userNotificationCenter(_ center: UNUserNotificationCenter,
                                       didReceive response: UNNotificationResponse,
                                       withCompletionHandler completionHandler: @escaping () -> Void) {
        // Resume background task creation.
        BackgroundActivityFactory.shared.resume()
        // route to user session
        handleNotification(with: response.notification.userInfo) { userSession in
            userSession.userNotificationCenter(center, didReceive: response, withCompletionHandler: completionHandler)
        }
    }

    // MARK: Helpers

    public func configureUserNotifications() {
        guard (application as? NotificationSettingsRegistrable)?.shouldRegisterUserNotificationSettings ?? true else { return }
        notificationCenter.setNotificationCategories(PushNotificationCategory.allCategories)
        notificationCenter.requestAuthorization(options: [.alert, .badge, .sound], completionHandler: { _, _ in })
        notificationCenter.delegate = self
    }

    public func updatePushToken(for session: ZMUserSession) {
        session.managedObjectContext.performGroupedBlock { [weak session] in
            switch self.requiredPushTokenType {
            case .voip:
                if let token = self.pushRegistry.pushToken(for: .voIP) {
                    pushLog.safePublic("creating voip push token")
                    let pushToken = PushToken.createVOIPToken(from: token)
                    session?.setPushToken(pushToken)
                }
            case .standard:
                pushLog.safePublic("creating standard push token")
                self.application.registerForRemoteNotifications()
            }
        }
    }

    func handleNotification(with userInfo: NotificationUserInfo, block: @escaping (ZMUserSession) -> Void) {
        guard
            let selfID = userInfo.selfUserID,
            let account = accountManager.account(with: selfID)
            else { return }

        self.withSession(for: account, perform: block)
    }

    fileprivate func activateAccount(for session: ZMUserSession, completion: @escaping () -> Void) {
        if session == activeUserSession {
            completion()
            return
        }

        var foundSession: Bool = false
        self.backgroundUserSessions.forEach { accountId, backgroundSession in
            if session == backgroundSession, let account = self.accountManager.account(with: accountId) {

                self.select(account, completion: { _ in
                    completion()
                })
                foundSession = true
                return
            }
        }

        if !foundSession {
            fatalError("User session \(session) is not present in backgroundSessions")
        }
    }
}

extension SessionManager {

    public func showConversation(_ conversation: ZMConversation,
                                 at message: ZMConversationMessage? = nil,
                                 in session: ZMUserSession) {
        activateAccount(for: session) {
            self.presentationDelegate?.showConversation(conversation, at: message)
        }
    }

    public func showConversationList(in session: ZMUserSession) {
        activateAccount(for: session) {
            self.presentationDelegate?.showConversationList()
        }
    }

    public func showUserProfile(user: UserType) {
        self.presentationDelegate?.showUserProfile(user: user)
    }

    public func showConnectionRequest(userId: UUID) {
        self.presentationDelegate?.showConnectionRequest(userId: userId)
    }

}

extension SessionManager {

    var shouldProcessLegacyPushes: Bool {
        return requiredPushTokenType == .voip
    }

    public func updateDeviceToken(_ deviceToken: Data) {
        let pushToken = PushToken.createAPNSToken(from: deviceToken)
        // give new device token to all running sessions
        self.backgroundUserSessions.values.forEach({ userSession in
            userSession.setPushToken(pushToken)
        })
    }

}

private extension VoIPPushPayload {

    init?(payload: PKPushPayload) {
        guard let dict = payload.dictionaryPayload as? [String: Any] else {
            return nil
        }

        self.init(from: dict)
    }

    func caller(in context: NSManagedObjectContext) -> ZMUser? {
        return ZMUser.fetch(
            with: senderID,
            domain: senderDomain,
            in: context
        )
    }

    func conversation(in context: NSManagedObjectContext) -> ZMConversation? {
        return ZMConversation.fetch(
            with: conversationID,
            domain: conversationDomain,
            in: context
        )
    }

}

private extension SessionManager {

    private enum VOIPPushError: Error, SafeForLoggingStringConvertible {

        case accountNotFound
        case userSessionNotFound
        case processorNotFound
        case callKitManagerNotFound
        case callerNotFound
        case conversationNotFound
        case malformedPayloadData
        case failedToReportIncomingCall(reason: CallKitManager.ReportIncomingCallError)
        case failedToReportTerminatingCall(reason: CallKitManager.ReportTerminatingCallError)

        var safeForLoggingDescription: String {
            switch self {
            case .accountNotFound:
                return "Account not found"

            case .userSessionNotFound:
                return "User session not found"

            case .processorNotFound:
                return "Call event processor not found"

            case .callKitManagerNotFound:
                return "CallKit manager not found"

            case .callerNotFound:
                return "Caller not found"

            case .conversationNotFound:
                return "Conversation not found"

            case .malformedPayloadData:
                return "Malformed payload data"

            case .failedToReportIncomingCall(let reason):
                return reason.safeForLoggingDescription

            case .failedToReportTerminatingCall(let reason):
                return reason.safeForLoggingDescription
            }
        }

    }

}
