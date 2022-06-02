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
import WireTransport
import UserNotifications
import WireRequestStrategy

let PushChannelUserIDKey = "user"
let PushChannelDataKey = "data"

extension Dictionary {

    public func accountId() -> UUID? {
        guard let userInfoData = self[PushChannelDataKey as! Key] as? [String: Any] else {
            Logging.push.safePublic("No data dictionary in notification userInfo payload")
            return nil
        }

        guard let userIdString = userInfoData[PushChannelUserIDKey] as? String else {
            return nil
        }

        return UUID(uuidString: userIdString)
    }
}

struct PushTokenMetadata {
    let isSandbox: Bool

    /*!
     @brief There are 4 different application identifiers which map to each of the bundle id's used
     @discussion
     com.wearezeta.zclient.ios-development (dev) - <b>com.wire.dev.ent</b>
     
     com.wearezeta.zclient.ios-internal (internal) - <b>com.wire.int.ent</b>
     
     com.wearezeta.zclient-alpha - <b>com.wire.ent</b>
     
     com.wearezeta.zclient.ios (app store) - <b>com.wire</b>
     
     @sa https://github.com/zinfra/backend-wiki/wiki/Native-Push-Notifications
     */
    let appIdentifier: String

    /*!
     @brief There are 4 transport types which depend on the token type and the environment
     @discussion <b>APNS</b> -> ZMAPNSTypeNormal (deprecated)
     
     <b>APNS_VOIP</b> -> ZMAPNSTypeVoIP
     
     <b>APNS_SANDBOX</b> -> ZMAPNSTypeNormal + Sandbox environment (deprecated)
     
     <b>APNS_VOIP_SANDBOX</b> -> ZMAPNSTypeVoIP + Sandbox environment
     
     The non-VoIP types are deprecated at the moment.
     
     @sa https://github.com/zinfra/backend-wiki/wiki/Native-Push-Notifications
     */

    var tokenType: PushToken.TokenType

    var transportType: String {
        return isSandbox ? (tokenType.transportType + "_SANDBOX") : tokenType.transportType
    }

    static func current(for tokenType: PushToken.TokenType) -> PushTokenMetadata {
        let appId = Bundle.main.bundleIdentifier ?? ""
        let buildType = BuildType.init(bundleID: appId)

        let isSandbox = ZMMobileProvisionParser().apsEnvironment == .sandbox
        let appIdentifier = buildType.certificateName

        let metadata = PushTokenMetadata(isSandbox: isSandbox, appIdentifier: appIdentifier, tokenType: tokenType)
        return metadata
    }
}

// MARK: - Register current push token

extension ZMUserSession {

    @objc public static let registerCurrentPushTokenNotificationName = Notification.Name(rawValue: "ZMUserSessionResetPushTokensNotification")

    public func registerForRegisteringPushTokenNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(ZMUserSession.registerCurrentPushToken), name: ZMUserSession.registerCurrentPushTokenNotificationName, object: nil)
    }

    func registerCurrentPushToken() {
        managedObjectContext.performGroupedBlock {
            self.sessionManager?.updatePushToken(for: self)
        }
    }

}

// MARK: - Register, delete and update push token

extension ZMUserSession {

    public func setPushToken(_ pushToken: PushToken) {
        let syncMOC = managedObjectContext.zm_sync!

        syncMOC.performGroupedBlock {
            guard
                let selfClient = ZMUser.selfUser(in: syncMOC).selfClient(),
                let clientID = selfClient.remoteIdentifier else {
                    return
                }

            /// If there is no local token, or the local token's type is different from the new token,
            /// we must register a new token
            if pushToken.deviceToken != PushTokenStorage.pushToken?.deviceToken {
                let action = RegisterPushTokenAction(token: pushToken, clientID: clientID) { result in
                    switch result {
                    case .success:
                        PushTokenStorage.pushToken = pushToken
                    case .failure(let error):
                        Logging.push.safePublic("Failed to register push token with backend: \(error)")
                    }
                }

                action.send(in: syncMOC.notificationContext)
            }
        }
    }

    func deletePushToken(completion: (() -> Void)? = nil) {
        let syncMOC = managedObjectContext.zm_sync!

        syncMOC.performGroupedBlock {
            guard let pushToken = PushTokenStorage.pushToken else {
                completion?()
                return
            }

            let action = RemovePushTokenAction(deviceToken: pushToken.deviceTokenString) { result in
                switch result {
                case .success:
                    PushTokenStorage.pushToken = nil
                case .failure(let error):
                    switch error {
                    case .tokenDoesNotExist:
                        PushTokenStorage.pushToken = nil
                        Logging.push.safePublic("Failed to delete push token because it does not exist: \(error)")
                    default:
                        Logging.push.safePublic("Failed to delete push token: \(error)")
                    }
                }
                completion?()
            }
            action.send(in: syncMOC.notificationContext)
        }
    }

    /// Compares the push token registered on backend with the local one
    /// and re-registers it if they don't match.

    public func validatePushToken() {
        let syncContext = managedObjectContext.zm_sync!

        syncContext.performGroupedBlock {
            guard
                let selfClient = ZMUser.selfUser(in: syncContext).selfClient(),
                let clientID = selfClient.remoteIdentifier
            else {
                return
            }

            guard let localToken = PushTokenStorage.pushToken else {
                self.sessionManager?.updatePushToken(for: self)
                return
            }

            let action = GetPushTokensAction(clientID: clientID) { result in
                switch result {
                case let .success(tokens):
                    let matchingRemoteToken = tokens.first {
                        $0.deviceTokenString == localToken.deviceTokenString
                    }

                    guard matchingRemoteToken != nil else {
                        PushTokenStorage.pushToken = nil
                        self.sessionManager?.updatePushToken(for: self)
                        return
                    }

                    PushTokenStorage.pushToken = matchingRemoteToken

                case let .failure(error):
                    Logging.push.safePublic("Failed to validate push token: \(error)")
                }
            }

            action.send(in: syncContext.notificationContext)
        }
    }

}

extension ZMUserSession {

    public func receivedPushNotification(with payload: [AnyHashable: Any], completion: @escaping () -> Void) {
        Logging.network.debug("Received push notification with payload: \(payload)")

        syncManagedObjectContext.performGroupedBlock {
            let notAuthenticated = !self.isAuthenticated

            if notAuthenticated {
                Logging.push.safePublic("Not displaying notification because app is not authenticated")
                completion()
                return
            }

            self.operationLoop?.fetchEvents(fromPushChannelPayload: payload, completionHandler: completion)
        }
    }

}

// MARK: - UNUserNotificationCenterDelegate

/*
 * Note: Although ZMUserSession conforms to UNUserNotificationCenterDelegate,
 * it should not actually be assigned as the delegate of UNUserNotificationCenter.
 * Instead, the delegate should be the SessionManager, whose repsonsibility it is
 * to forward the method calls to the appropriate user session.
 */
extension ZMUserSession: UNUserNotificationCenterDelegate {

    // Called by the SessionManager when a notification is received while the app
    // is in the foreground.
    public func userNotificationCenter(_ center: UNUserNotificationCenter,
                                       willPresent notification: UNNotification,
                                       withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        Logging.push.safePublic("Notification center wants to present in-app notification: \(notification)")
        let categoryIdentifier = notification.request.content.categoryIdentifier

        handleInAppNotification(with: notification.userInfo,
                                categoryIdentifier: categoryIdentifier,
                                completionHandler: completionHandler)
    }

    // Called by the SessionManager when the user engages a notification action.
    public func userNotificationCenter(_ center: UNUserNotificationCenter,
                                       didReceive response: UNNotificationResponse,
                                       withCompletionHandler completionHandler: @escaping () -> Void) {
        Logging.push.safePublic("Did receive notification response: \(response)")
        let userText = (response as? UNTextInputNotificationResponse)?.userText
        let note = response.notification

        handleNotificationResponse(actionIdentifier: response.actionIdentifier,
                                   categoryIdentifier: note.request.content.categoryIdentifier,
                                   userInfo: note.userInfo,
                                   userText: userText,
                                   completionHandler: completionHandler)
    }

    // MARK: Abstractions

    /* The logic for handling notifications/actions is factored out of the
     * delegate methods because we cannot create `UNNotification` and
     * `UNNotificationResponse` objects in unit tests.
     */

    func handleInAppNotification(with userInfo: NotificationUserInfo,
                                 categoryIdentifier: String,
                                 completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        if categoryIdentifier == PushNotificationCategory.incomingCall.rawValue {
            self.handleTrackingOnCallNotification(with: userInfo)
        }

        // foreground notification responder exists on the UI context, so we
        // need to switch to that context
        self.managedObjectContext.perform {
            let responder = self.sessionManager?.foregroundNotificationResponder
            let shouldPresent = responder?.shouldPresentNotification(with: userInfo)

            var options = UNNotificationPresentationOptions()
            if shouldPresent ?? true { options = [.alert, .sound] }

            completionHandler(options)
        }
    }

    func handleNotificationResponse(actionIdentifier: String,
                                    categoryIdentifier: String,
                                    userInfo: NotificationUserInfo,
                                    userText: String? = nil,
                                    completionHandler: @escaping () -> Void) {
        switch actionIdentifier {
        case CallNotificationAction.ignore.rawValue:
            ignoreCall(with: userInfo, completionHandler: completionHandler)
        case CallNotificationAction.accept.rawValue:
            acceptCall(with: userInfo, completionHandler: completionHandler)
        case ConversationNotificationAction.mute.rawValue:
            muteConversation(with: userInfo, completionHandler: completionHandler)
        case ConversationNotificationAction.like.rawValue:
            likeMessage(with: userInfo, completionHandler: completionHandler)
        case ConversationNotificationAction.reply.rawValue:
            if let textInput = userText {
                reply(with: userInfo, message: textInput, completionHandler: completionHandler)
            }
        case ConversationNotificationAction.connect.rawValue:
            acceptConnectionRequest(with: userInfo, completionHandler: completionHandler)
        default:
            showContent(for: userInfo)
            completionHandler()
        }
    }

}

extension UNNotificationContent {
    override open var description: String {
        return "<\(type(of: self)); threadIdentifier: \(self.threadIdentifier); content: redacted>"
    }
}

extension PushToken {
    public init(deviceToken: Data, pushTokenType: TokenType) {
        let metadata = PushTokenMetadata.current(for: pushTokenType)
        self.init(deviceToken: deviceToken,
                  appIdentifier: metadata.appIdentifier,
                  transportType: metadata.transportType,
                  tokenType: pushTokenType)
    }

    public static func createVOIPToken(from deviceToken: Data) -> PushToken {
        return PushToken(deviceToken: deviceToken, pushTokenType: .voip)
    }

    public static func createAPNSToken(from deviceToken: Data) -> PushToken {
        return PushToken(deviceToken: deviceToken, pushTokenType: .standard)
    }
}
