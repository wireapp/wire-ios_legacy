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
import WireUtilities

public protocol UnauthenticatedSessionDelegate: AnyObject {
    /// Update credentials for the corresponding user session. Returns true if the credentials were accepted.
    func session(session: UnauthenticatedSession, updatedCredentials credentials: ZMCredentials) -> Bool
    func session(session: UnauthenticatedSession, updatedProfileImage imageData: Data)
    func session(session: UnauthenticatedSession, createdAccount account: Account)
    func session(session: UnauthenticatedSession, isExistingAccount account: Account) -> Bool
    func sessionIsAllowedToCreateNewAccount(_ session: UnauthenticatedSession) -> Bool
}

@objc public protocol UserInfoParser: AnyObject {
    @objc(accountExistsLocallyFromUserInfo:)
    func accountExistsLocally(from userInfo: UserInfo) -> Bool
    @objc(upgradeToAuthenticatedSessionWithUserInfo:)
    func upgradeToAuthenticatedSession(with userInfo: UserInfo)
}

private let log = ZMSLog(tag: "UnauthenticatedSession")

@objcMembers
public class UnauthenticatedSession: NSObject {

    /// **accountId** will be set if the unauthenticated session is associated with an existing account
    public internal(set) var accountId: UUID?
    public let groupQueue: DispatchGroupQueue
    private(set) public var authenticationStatus: ZMAuthenticationStatus!
    public let registrationStatus: RegistrationStatus
    let reachability: ReachabilityProvider
    private(set) var operationLoop: UnauthenticatedOperationLoop!
    private let transportSession: UnauthenticatedTransportSessionProtocol
    fileprivate var urlActionProcessors: [URLActionProcessor] = []
    fileprivate var tornDown = false

    weak var delegate: UnauthenticatedSessionDelegate?

    init(transportSession: UnauthenticatedTransportSessionProtocol,
         reachability: ReachabilityProvider,
         delegate: UnauthenticatedSessionDelegate?,
         authenticationStatusDelegate: ZMAuthenticationStatusDelegate?) {
        self.delegate = delegate
        self.groupQueue = DispatchGroupQueue(queue: .main)
        self.registrationStatus = RegistrationStatus()
        self.transportSession = transportSession
        self.reachability = reachability
        super.init()

        self.authenticationStatus = ZMAuthenticationStatus(delegate: authenticationStatusDelegate,
                                                           groupQueue: groupQueue,
                                                           userInfoParser: self)
        self.urlActionProcessors = [CompanyLoginURLActionProcessor(delegate: self,
                                                                   authenticationStatus: authenticationStatus),
                                    StartLoginURLActionProcessor(delegate: self,
                                                                 authenticationStatus: authenticationStatus)
        ]
        self.operationLoop = UnauthenticatedOperationLoop(
            transportSession: transportSession,
            operationQueue: groupQueue,
            requestStrategies: [
                ZMLoginTranscoder(groupQueue: groupQueue, authenticationStatus: authenticationStatus),
                ZMLoginCodeRequestTranscoder(groupQueue: groupQueue, authenticationStatus: authenticationStatus)!,
                RegistationCredentialVerificationStrategy(groupQueue: groupQueue, status: registrationStatus),
                RegistrationStrategy(groupQueue: groupQueue, status: registrationStatus, userInfoParser: self)
            ]
        )
    }

    deinit {
        precondition(tornDown, "Need to call tearDown before deinit")
    }

    func authenticationErrorIfNotReachable(_ block: () -> Void) {
        if self.reachability.mayBeReachable {
            block()
        } else {
            let error = NSError(code: .networkError, userInfo: nil)
            authenticationStatus.notifyAuthenticationDidFail(error)
        }
    }
}

extension UnauthenticatedSession: UnauthenticatedSessionStatusDelegate {

    var isAllowedToCreateNewAccount: Bool {
        return delegate?.sessionIsAllowedToCreateNewAccount(self) ?? false
    }

}

extension UnauthenticatedSession: URLActionProcessor {

    func process(urlAction: URLAction, delegate: PresentationDelegate?) {
        urlActionProcessors.forEach({ $0.process(urlAction: urlAction, delegate: delegate) })
    }

}

extension UnauthenticatedSession: TearDownCapable {
    public func tearDown() {
        operationLoop.tearDown()
        tornDown = true
    }
}

// MARK: - UserInfoParser

extension UnauthenticatedSession: UserInfoParser {

    public func accountExistsLocally(from info: UserInfo) -> Bool {
        let account = Account(userName: "", userIdentifier: info.identifier)
        guard let delegate = delegate else { return false }
        return delegate.session(session: self, isExistingAccount: account)
    }

    public func upgradeToAuthenticatedSession(with userInfo: UserInfo) {
        let account = Account(userName: "", userIdentifier: userInfo.identifier)
        let cookieStorage = transportSession.environment.cookieStorage(for: account)
        cookieStorage.authenticationCookieData = userInfo.cookieData
        self.authenticationStatus.authenticationCookieData = userInfo.cookieData
        self.delegate?.session(session: self, createdAccount: account)
    }

}
