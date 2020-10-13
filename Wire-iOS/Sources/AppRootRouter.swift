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

import UIKit
import WireSyncEngine
import avs

// MARK: - AppRootRouter
public class AppRootRouter: NSObject {
    
    // MARK: - Private Property
    private let navigator: NavigatorProtocol
    private var appStateCalculator = AppStateCalculator()
    private var authenticationCoordinator: AuthenticationCoordinator?
    private var observerTokens: [Any?] = []
    private let sessionManagerLifeCycleObserver = SessionManagerLifeCycleObserver()
    private let foregroundNotificationFilter = ForegroundNotificationFilter()
    
    // MARK: - Private Set Property
    private(set) var sessionManager: SessionManager?
    private(set) var rootViewController: RootViewController //TO DO: This should be private
    
    // MARK: - Initialization
    
    init(viewController: RootViewController, navigator: NavigatorProtocol) {
        self.rootViewController = viewController
        self.navigator = navigator
        super.init()
        appStateCalculator.delegate = self
    }
    
    // MARK: - Public implementation
    
    public func start(launchOptions: LaunchOptions) {
        transition(to: .headless, completion: { })
        createAndStartSessionManager(launchOptions: launchOptions)
    }
    
    // MARK: - Private implementation
    
    private func createAndStartSessionManager(launchOptions: LaunchOptions) {
        guard
            let appVersion = Bundle.main.infoDictionary?[kCFBundleVersionKey as String] as? String,
            let url = Bundle.main.url(forResource: "session_manager", withExtension: "json"),
            let configuration = SessionManagerConfiguration.load(from: url),
            let mediaManager = AVSMediaManager.sharedInstance()
        else {
            return
        }
        
        configuration.blacklistDownloadInterval = Settings.shared.blacklistDownloadInterval
        let jailbreakDetector = JailbreakDetector()
        
        SessionManager.clearPreviousBackups()
        SessionManager.create(appVersion: appVersion,
                              mediaManager: mediaManager,
                              analytics: Analytics.shared,
                              delegate: appStateCalculator,
                              showContentDelegate: nil, //TO DO: We must set it
                              application: UIApplication.shared,
                              environment: BackendEnvironment.shared,
                              configuration: configuration,
                              detector: jailbreakDetector) { sessionManager in
                self.sessionManager = sessionManager
                self.createLifeCycleObeserverTokens(for: sessionManager)
                self.sessionManager?.foregroundNotificationResponder = self.foregroundNotificationFilter
                /* TO DO: Add all this delegation
                self.sessionManager?.showContentDelegate = self
                self.sessionManager?.switchingDelegate = self
                self.sessionManager?.urlActionDelegate = self
                */
                self.setCallingSettting(for: sessionManager)
                sessionManager.start(launchOptions: launchOptions)
        }
    }
    
    private func createLifeCycleObeserverTokens(for sessionManager: SessionManager) {
        let createdSessionObserverToken = sessionManager.addSessionManagerCreatedSessionObserver(sessionManagerLifeCycleObserver)
        observerTokens.append(createdSessionObserverToken)
                    
        let destroyedSessionObserverToken = sessionManager.addSessionManagerDestroyedSessionObserver(sessionManagerLifeCycleObserver)
        observerTokens.append(destroyedSessionObserverToken)
    }
    
    private func setCallingSettting(for sessionManager: SessionManager) {
        sessionManager.updateCallNotificationStyleFromSettings()
        sessionManager.useConstantBitRateAudio = SecurityFlags.forceConstantBitRateCalls.isEnabled
            ? true
            : Settings.shared[.callingConstantBitRate] ?? false
        sessionManager.useConferenceCalling = true
    }
}

// MARK: - AppStateCalculatorDelegate
extension AppRootRouter: AppStateCalculatorDelegate {
    func appStateCalculator(_: AppStateCalculator,
                            didCalculate appState: AppState,
                            completion: @escaping () -> Void) {
        applicationWillTransition(to: appState)
        transition(to: appState, completion: completion)
    }
    
    private func transition(to appState: AppState, completion: @escaping () -> Void) {
        //        showContentDelegate = nil
        //        resetAuthenticationCoordinatorIfNeeded(for: appState)
        
        let completionBlock = { [weak self] in
            self?.applicationDidTransition(to: appState)
            completion()
        }
        
        switch appState {
        case .blacklisted:
            showBlacklisted(completion: completionBlock)
        case .jailbroken:
            showJailbroken(completion: completionBlock)
        case .migrating:
            showLaunchScreen(isLoading: true, completion: completionBlock)
        case .unauthenticated(error: let error):
//            mainWindow.tintColor = .black
            AccessoryTextField.appearance(whenContainedInInstancesOf: [AuthenticationStepController.self]).tintColor = UIColor.Team.activeButton
            
            showUnauthenticatedFlow(error: error, completion: completionBlock)
            
        case .authenticated(completedRegistration: let completedRegistration, databaseIsLocked: _):
//            UIColor.setAccentOverride(.undefined)
//            mainWindow.tintColor = UIColor.accent()
//            executeAuthenticatedBlocks()
//            showAuthenticated(isComingFromRegistration: completedRegistration,
//                              completion: completionBlock)
            
            // TO DO: Show Authenticated Case
            showTempController(completion: completionBlock)
            
        case .headless:
            showLaunchScreen(completion: completionBlock)
        case .loading(account: let toAccount, from: let fromAccount):
            showSkeleton(fromAccount: fromAccount,
                         toAccount: toAccount,
                         completion: completionBlock)
        }
    }
}

// MARK: - Navigation Helper
extension AppRootRouter {
    private func showBlacklisted(completion: @escaping () -> Void) {
        let blockerViewController = BlockerViewController(context: .blacklist)
        rootViewController.set(childViewController: blockerViewController,
                               completion: completion)
    }
    
    private func showJailbroken(completion: @escaping () -> Void) {
        let blockerViewController = BlockerViewController(context: .jailbroken)
        rootViewController.set(childViewController: blockerViewController,
                               completion: completion)
    }
    
    private func showLaunchScreen(isLoading: Bool = false, completion: @escaping () -> Void) {
        let launchViewController = LaunchImageViewController()
        isLoading
            ? launchViewController.showLoadingScreen()
            : ()
        rootViewController.set(childViewController: launchViewController,
                               completion: completion)
    }
    
    private func showUnauthenticatedFlow(error: NSError?, completion: @escaping () -> Void) {
        // Only execute handle events if there is no current flow
        guard
            self.authenticationCoordinator == nil ||
                error?.userSessionErrorCode == .addAccountRequested ||
                error?.userSessionErrorCode == .accountDeleted,
            let sessionManager = SessionManager.shared
        else {
            return
        }
        
        let navigationController = SpinnerCapableNavigationController(navigationBarClass: AuthenticationNavigationBar.self,
                                                                      toolbarClass: nil)
        
        authenticationCoordinator = AuthenticationCoordinator(presenter: navigationController,
                                                              sessionManager: sessionManager,
                                                              featureProvider: BuildSettingAuthenticationFeatureProvider(),
                                                              statusProvider: AuthenticationStatusProvider())
        
        guard let authenticationCoordinator = authenticationCoordinator else {
            return
        }
        
        authenticationCoordinator.delegate = appStateCalculator
        authenticationCoordinator.startAuthentication(with: error,
                                                      numberOfAccounts: SessionManager.numberOfAccounts)
        
        rootViewController.set(childViewController: navigationController,
                               completion: completion)
    }
    
    private func showAuthenticated(isComingFromRegistration: Bool, completion: @escaping () -> Void) {
        guard let selectedAccount = SessionManager.shared?.accountManager.selectedAccount else {
            return
        }
        
        let clientViewController = ZClientViewController(account: selectedAccount,
                                                         selfUser: ZMUser.selfUser())
        clientViewController.isComingFromRegistration = isComingFromRegistration
        
        /// show the dialog only when lastAppState is .unauthenticated and the user is not a team member, i.e. the user not in a team login to a new device
        clientViewController.needToShowDataUsagePermissionDialog = false
        
        if case .unauthenticated(_) = self.appStateCalculator.previousAppState {
            if SelfUser.current.isTeamMember {
                TrackingManager.shared.disableCrashSharing = true
                TrackingManager.shared.disableAnalyticsSharing = false
            } else {
                clientViewController.needToShowDataUsagePermissionDialog = true
            }
        }
        
        Analytics.shared.selfUser = SelfUser.current
        
        rootViewController.set(childViewController: clientViewController,
                               completion: completion)
    }
    
    private func showSkeleton(fromAccount: Account?, toAccount: Account, completion: @escaping () -> Void) {
        let skeletonViewController = SkeletonViewController(from: fromAccount, to: toAccount)
        rootViewController.set(childViewController: skeletonViewController,
                               completion: completion)
    }
    
    private func showTempController(completion: @escaping () -> Void) {
        let viewController = UIViewController()
        viewController.view.frame = UIScreen.main.bounds
        viewController.view.backgroundColor = .red
        rootViewController.set(childViewController: viewController,
                               completion: completion)
    }
}

// TO DO: THIS PART MUST BE CLENED UP
extension AppRootRouter {
    private func applicationWillTransition(to appState: AppState) {
        /*
        if case .authenticated = appState {
            if AppDelegate.shared.shouldConfigureSelfUserProvider {
                SelfUser.provider = ZMUserSession.shared()
            }
            callWindow.callController.transitionToLoggedInSession()
        }

        let colorScheme = ColorScheme.default
        colorScheme.accentColor = .accent()
        colorScheme.variant = Settings.shared.colorSchemeVariant
        */
    }
    
    private func applicationDidTransition(to appState: AppState) {
        /*
        if case .authenticated = appState {
            callWindow.callController.presentCallCurrentlyInProgress()
            ZClientViewController.shared?.legalHoldDisclosureController?.discloseCurrentState(cause: .appOpen)
        } else if AppDelegate.shared.shouldConfigureSelfUserProvider {
            SelfUser.provider = nil
        }
        
        guard
            case .unauthenticated(let error) = appState,
            error?.userSessionErrorCode == .accountDeleted,
            let reason = error?.userInfo[ZMAccountDeletedReasonKey] as? ZMAccountDeletedReason
        else {
            return
        }
        
        presentAlertForDeletedAccount(reason)
        */
    }
    
    private func presentAlertForDeletedAccount(_ reason: ZMAccountDeletedReason) {
        /*
        switch reason {
        case .sessionExpired:
            presentAlertWithOKButton(title: "account_deleted_session_expired_alert.title".localized,
                                     message: "account_deleted_session_expired_alert.message".localized)
        default:
            break
        }
        */
    }
}
