//
// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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

extension ZMUserSession {

    /// Whether the user completed the registration on this device

    @objc
    public var registeredOnThisDevice: Bool {
        return managedObjectContext.registeredOnThisDevice
    }

    @objc(setEmailCredentials:)
    func setEmailCredentials(_ emailCredentials: ZMEmailCredentials?) {
        applicationStatusDirectory?.clientRegistrationStatus.emailCredentials = emailCredentials
    }

    /// `True` if the session is ready to be used.
    ///
    /// NOTE: This property should only be called on the main queue.

    public var isLoggedIn: Bool { // TODO jacob we don't want this to be public
        let needsToRegisterClient = ZMClientRegistrationStatus.needsToRegisterClient(in: managedObjectContext)

        return isAuthenticated && !needsToRegisterClient
    }

    /// `True` if the session has a valid authentication cookie

    var isAuthenticated: Bool {
        return transportSession.cookieStorage.isAuthenticated
    }

    /// This will delete user data stored by WireSyncEngine in the keychain.

    func deleteUserKeychainItems() {
        transportSession.cookieStorage.deleteKeychainItems()
    }

    /// Logout the current user
    ///
    /// - parameter deleteCookie: If set to true the cookies associated with the session will be deleted

    @objc(closeAndDeleteCookie:)
    func close(deleteCookie: Bool) {
        UserDefaults.standard.synchronize()
        UserDefaults.shared()?.synchronize()

        // Clear all notifications associated with the account from the notification center
        syncManagedObjectContext.performGroupedBlock {
            self.localNotificationDispatcher?.cancelAllNotifications()
        }

        if deleteCookie {
            deleteUserKeychainItems()
        }

        let uiMOC = managedObjectContext
        let syncMOC = syncManagedObjectContext

        uiMOC.performGroupedBlockAndWait {}
        syncMOC.performGroupedBlockAndWait {}

        tearDown()

        uiMOC.performGroupedBlockAndWait {}
        syncMOC.performGroupedBlockAndWait {}
    }

    public func logout(credentials: ZMEmailCredentials, _ completion: @escaping (VoidResult) -> Void) {
        guard
            let accountID = ZMUser.selfUser(inUserSession: self).remoteIdentifier,
            let selfClientIdentifier = ZMUser.selfUser(inUserSession: self).selfClient()?.remoteIdentifier,
            let apiVersion = APIVersion.current
        else {
            return
        }

        let payload: [String: Any]
        if let password = credentials.password, !password.isEmpty {
            payload = ["password": password]
        } else {
            payload = [:]
        }

        let request = ZMTransportRequest(path: "/clients/\(selfClientIdentifier)", method: .methodDELETE, payload: payload as ZMTransportData, apiVersion: apiVersion.rawValue)

        request.add(ZMCompletionHandler(on: managedObjectContext, block: { [weak self] (response) in
            guard let strongSelf = self else { return }

            if response.httpStatus == 200 {
                self?.delegate?.userDidLogout(accountId: accountID)
                completion(.success)
            } else {
                completion(.failure(strongSelf.errorFromFailedDeleteResponse(response)))
            }
        }))

        transportSession.enqueueOneTime(request)
    }

    func errorFromFailedDeleteResponse(_ response: ZMTransportResponse!) -> NSError {

        var errorCode: ZMUserSessionErrorCode
        switch response.result {
        case .permanentError:
                switch response.payload?.asDictionary()?["label"] as? String {
                case "client-not-found":
                    errorCode = .clientDeletedRemotely
                case "invalid-credentials",
                     "missing-auth",
                     "bad-request": // in case the password not matching password format requirement
                    errorCode = .invalidCredentials
                default:
                    errorCode = .unknownError
                }
        case .temporaryError, .tryAgainLater, .expired:
            errorCode = .networkError
        default:
            errorCode = .unknownError
        }

        var userInfo: [String: Any]?
        if let transportSessionError = response.transportSessionError {
            userInfo = [NSUnderlyingErrorKey: transportSessionError]
        }

        return NSError(code: errorCode, userInfo: userInfo)
    }

}
