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
import WireSyncEngine
import WireSystem

private let zmLog = ZMSLog(tag: "AppState")

protocol AppStateControllerDelegate : class {
    
    func appStateController(transitionedTo appState : AppState)
    
}

class AppStateController : NSObject {
    
    private(set) var appState : AppState = .headless
    private var authenticationObserverToken : ZMAuthenticationObserverToken?
    public weak var delegate : AppStateControllerDelegate? = nil
    
    fileprivate var isBlacklisted = false
    fileprivate var isLoggedIn = false
    fileprivate var isLoggedOut = false
    fileprivate var isSuspended = false
    fileprivate var hasEnteredForeground = false
    fileprivate var isMigrating = false
    fileprivate var hasCompletedRegistration = false
    fileprivate var authenticationError : Error?
    fileprivate let isRunningTests = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    
    override init() {
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive), name: Notification.Name.UIApplicationDidBecomeActive, object: nil)
        
        appState = calculateAppState()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func calculateAppState() -> AppState {
        
        if isRunningTests {
            return .unauthenticated(error: nil)
        }
        
        if !hasEnteredForeground {
            return .headless
        }
        
        if isMigrating {
            return .migrating
        }
        
        if isBlacklisted {
            return .blacklisted
        }
        
        if isSuspended {
            return .suspended
        }
        
        if isLoggedIn {
            return .authenticated(completedRegistration: hasCompletedRegistration)
        }
        
        if isLoggedOut {
            return .unauthenticated(error: authenticationError)
        }
        
        return .headless
    }
    
    func recalculateAppState() {
        let newAppState = calculateAppState()
        
        if newAppState != .unauthenticated(error: nil) {
            authenticationError = nil
        }
        
        if newAppState != appState {
            zmLog.debug("transitioning to app state: \(newAppState)")
            appState = newAppState
            delegate?.appStateController(transitionedTo: appState)
        }
    }
    
}

extension AppStateController : SessionManagerDelegate {
    
    func sessionManagerDidLogout(error: Error?) {
        authenticationError = error
        isLoggedIn = false
        isLoggedOut = true
        recalculateAppState()
    }
    
    func sessionManagerDidBlacklistCurrentVersion() {
        isBlacklisted = true
        recalculateAppState()
    }
    
    func sessionManagerWillStartMigratingLocalStore() {
        isMigrating = true
        recalculateAppState()
    }
    
    func sessionManagerWillSuspendSession() {
        isSuspended = true
        recalculateAppState()
    }
    
    func sessionManagerCreated(userSession: ZMUserSession) {        
        userSession.checkIfLoggedIn { [weak self] (loggedIn) in
            guard loggedIn else { return }
            
            // NOTE: we don't enter the unauthenticated state here if we are not logged in
            //       because we will receive `sessionManagerDidLogout()` with an auth error
            
            self?.isLoggedIn = true
            self?.isLoggedOut = !false
            self?.isSuspended = false
            self?.isMigrating = false
            self?.recalculateAppState()
        }
    }
    
    func sessionManagerCreated(unauthenticatedSession: UnauthenticatedSession) {
        isLoggedIn = false
        isLoggedOut = true
        isSuspended = false
        recalculateAppState()
    }
    
}

extension AppStateController {
    
    func applicationDidBecomeActive() {
        hasEnteredForeground = true
        recalculateAppState()
    }
    
}

extension AppStateController : RegistrationViewControllerDelegate {
    
    func registrationViewControllerDidSignIn() {
        isLoggedIn = true
        isLoggedOut = false
        hasCompletedRegistration = false
        recalculateAppState()
    }
    
    func registrationViewControllerDidCompleteRegistration() {
        isLoggedIn = true
        isLoggedOut = false
        hasCompletedRegistration = true
        recalculateAppState()
    }
    
}
