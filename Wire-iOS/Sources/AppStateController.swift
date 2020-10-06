//
// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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
//import WireSystem

private let zmLog = ZMSLog(tag: "AppState")

extension AppStateController {
    static let appStateDidTransition = Notification.Name(rawValue: "AppStateDidTransitionNotification")
    static let appStateKey = "AppState"
}

protocol AppStateControllerDelegate: class {
    func appStateController(transitionedTo appState: AppState,
                            transitionCompleted: @escaping () -> Void)
}

final class AppStateController : NSObject {
    
    // MARK - Public Property
    weak var delegate: AppStateControllerDelegate?
    
    // MARK - Private Set Property
    private(set) var sessinManagerObeserver = AppStateSessionManagerObserver()
    private(set) var appState: AppState = .headless {
        willSet {
            lastAppState = appState
        }
    }
    private(set) var lastAppState: AppState = .headless
    
    // MARK - Test Property (??????)
    private var isRunningTests = ProcessInfo.processInfo.isRunningTests {
        didSet {
            appState = !isRunningTests
                ? .headless
                : .unauthenticated(error: nil)
        }
    }
    var isRunningSelfUnitTest = false {
        didSet {
            appState = isRunningSelfUnitTest
                ? .headless
                : .unauthenticated(error: nil)
        }
    }
    
    // MARK - Init
    override init() {
        super.init()
        sessinManagerObeserver.delegate = self
    }
}

// MARK - AppStateSessionManagerObserverDelegate
extension AppStateController: AppStateSessionManagerObserverDelegate {
    func sessionManagerObserver(_: AppStateSessionManagerObserver,
                                willTransitionTo appState: AppState,
                                completion: (() -> Void)?) {
        transition(to: appState, completion: completion)
    }
    
    // MARK - Private Helpers
    
    private func transition(to appState: AppState,
                            completion: (() -> Void)? = nil) {
        self.appState = appState
        if lastAppState != appState {
            zmLog.debug("transitioning to app state: \(appState)")
            delegate?.appStateController(transitionedTo: appState) {
                completion?()
            }
            notifyTransition()
        } else {
            completion?()
        }
    }
    
    private func notifyTransition() {
        NotificationCenter.default.post(name: AppStateController.appStateDidTransition,
                                        object: nil,
                                        userInfo: [AppStateController.appStateKey: appState])
    }
}

// TO DO: Ask why AuthenticationCoordinatorDelegate implements AuthenticationStatusProvider. For the scope of knowing the appState it is not necessary. We could get rid off all the AuthenticationStatusProvider properties

// MARK - AuthenticationCoordinatorDelegate

extension AppStateController: AuthenticationCoordinatorDelegate {

    var authenticatedUserWasRegisteredOnThisDevice: Bool {
        return ZMUserSession.shared()?.registeredOnThisDevice == true
    }

    var authenticatedUserNeedsEmailCredentials: Bool {
        guard let emailAddress = selfUser?.emailAddress else { return false }
        return emailAddress.isEmpty
    }

    var sharedUserSession: ZMUserSession? {
        return ZMUserSession.shared()
    }

    var selfUserProfile: UserProfileUpdateStatus? {
        return sharedUserSession?.userProfile as? UserProfileUpdateStatus
    }

    var selfUser: UserType? {
        return ZMUserSession.shared()?.selfUser
    }

    var numberOfAccounts: Int {
        return SessionManager.numberOfAccounts
    }

    func userAuthenticationDidComplete(addedAccount: Bool) {
        let databaseIsLocked = ZMUserSession.shared()?.isDatabaseLocked ?? false
        let appState: AppState = .authenticated(completedRegistration: addedAccount,
                                                databaseIsLocked: databaseIsLocked)
        transition(to: appState)
    }
}
