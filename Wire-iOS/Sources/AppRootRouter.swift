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

extension AppRootRouter {
    static let appStateDidTransition = Notification.Name(rawValue: "appStateDidTransition")
    static let appStateKey = "AppState"
}

// MARK: - AppRootRouter
public class AppRootRouter: NSObject {
    
    var callWindow = CallWindow(frame: UIScreen.main.bounds)
    
    // MARK: - Private Property
    private let navigator: NavigatorProtocol
    private var appStateCalculator = AppStateCalculator()
    private var urlActionRouter: URLActionRouter?
    private var switchingAccountRouter: SwitchingAccountRouter?
    private var sessionManagerLifeCycleObserver: SessionManagerLifeCycleObserver?
    private var authenticationCoordinator: AuthenticationCoordinator?
    private let foregroundNotificationFilter = ForegroundNotificationFilter()
    private var observerTokens: [NSObjectProtocol] = []
    private let teamMetadataRefresher = TeamMetadataRefresher()
    
    private weak var showContentDelegate: ShowContentDelegate? {
        didSet {
            if let delegate = showContentDelegate {
                performWhenShowContentDelegateIsAvailable?(delegate)
                performWhenShowContentDelegateIsAvailable = nil
            }
        }
    }

    fileprivate var performWhenShowContentDelegateIsAvailable: ((ShowContentDelegate)->())?
    
    // MARK: - Private Set Property
    private(set) var sessionManager: SessionManager? {
        didSet {
            guard let sessionManager = sessionManager else {
                return
            }
            
            urlActionRouter = URLActionRouter(viewController: rootViewController,
                                              sessionManager: sessionManager)
            switchingAccountRouter = SwitchingAccountRouter(sessionManager: sessionManager)
            sessionManagerLifeCycleObserver = SessionManagerLifeCycleObserver(sessionManager: sessionManager)
            
            sessionManager.foregroundNotificationResponder = foregroundNotificationFilter
            sessionManager.switchingDelegate = switchingAccountRouter
            sessionManager.urlActionDelegate = urlActionRouter
            sessionManager.showContentDelegate = self
            setCallingSettings(for: sessionManager)
            quickActionsManager = QuickActionsManager(sessionManager: sessionManager,
                                                      application: UIApplication.shared)
        }
    }

    private(set) var rootViewController: RootViewController //TO DO: This should be private
    private(set) var quickActionsManager: QuickActionsManager?
    
    // MARK: - Initialization
    
    init(viewController: RootViewController, navigator: NavigatorProtocol) {
        self.rootViewController = viewController
        self.navigator = navigator
        super.init()
        appStateCalculator.delegate = self
        
        configureAppearance()
        
        setupApplicationNotifications()
        setupContentSizeCategoryNotifications()
        setupAudioPermissionsNotifications()
        
        callWindow.makeKeyAndVisible()
        callWindow.isHidden = true
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
                              showContentDelegate: self,
                              application: UIApplication.shared,
                              environment: BackendEnvironment.shared,
                              configuration: configuration,
                              detector: jailbreakDetector) { sessionManager in
                self.sessionManager = sessionManager
                sessionManager.start(launchOptions: launchOptions)
        }
    }
    
    private func setCallingSettings(for sessionManager: SessionManager) {
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
        notifyTransition(for: appState)
    }
    
    private func notifyTransition(for appState: AppState) {
        NotificationCenter.default.post(name: AppRootRouter.appStateDidTransition,
                                        object: nil,
                                        userInfo: [AppRootRouter.appStateKey: appState])
    }
    
    private func transition(to appState: AppState, completion: @escaping () -> Void) {
        showContentDelegate = nil
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
            showAuthenticated(isComingFromRegistration: completedRegistration,
                              completion: completionBlock)
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
        
        showContentDelegate = clientViewController
        
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
}

// TO DO: THIS PART MUST BE CLENED UP
extension AppRootRouter {
    private func applicationWillTransition(to appState: AppState) {
        if case .authenticated = appState {
            if AppDelegate.shared.shouldConfigureSelfUserProvider {
                SelfUser.provider = ZMUserSession.shared()
            }
            callWindow.callController.transitionToLoggedInSession()
        }
        
        let colorScheme = ColorScheme.default
        colorScheme.accentColor = .accent()
        colorScheme.variant = Settings.shared.colorSchemeVariant
    }
    
    private func applicationDidTransition(to appState: AppState) {
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
    }
    
    private func presentAlertForDeletedAccount(_ reason: ZMAccountDeletedReason) {
        
        switch reason {
        case .sessionExpired:
            rootViewController.presentAlertWithOKButton(title: "account_deleted_session_expired_alert.title".localized,
                                                        message: "account_deleted_session_expired_alert.message".localized)
        default:
            break
        }
    }
}

// MARK: - ApplicationStateObserving
extension AppRootRouter: ApplicationStateObserving {
    func addObserverToken(_ token: NSObjectProtocol) {
        observerTokens.append(token)
    }
    
    func applicationDidBecomeActive() {
//        updateOverlayWindowFrame()
        teamMetadataRefresher.triggerRefreshIfNeeded()
    }
    
    func applicationDidEnterBackground() {
        let unreadConversations = sessionManager?.accountManager.totalUnreadCount ?? 0
        UIApplication.shared.applicationIconBadgeNumber = unreadConversations
    }
    
    func applicationWillEnterForeground() {
//        updateOverlayWindowFrame()
    }
}

// MARK: - ContentSizeCategoryObserving
extension AppRootRouter: ContentSizeCategoryObserving {
    func contentSizeCategoryDidChange() {
        NSAttributedString.invalidateParagraphStyle()
        NSAttributedString.invalidateMarkdownStyle()
        ConversationListCell.invalidateCachedCellSize()
        defaultFontScheme = FontScheme(contentSizeCategory: UIApplication.shared.preferredContentSizeCategory)
        configureAppearance()
    }
    
    private func configureAppearance() {
        let navigationBarTitleBaselineOffset: CGFloat = 2.5
        
        let attributes: [NSAttributedString.Key : Any] = [.font: UIFont.systemFont(ofSize: 11, weight: .semibold), .baselineOffset: navigationBarTitleBaselineOffset]
        let barButtonItemAppearance = UIBarButtonItem.appearance(whenContainedInInstancesOf: [DefaultNavigationBar.self])
        barButtonItemAppearance.setTitleTextAttributes(attributes, for: .normal)
        barButtonItemAppearance.setTitleTextAttributes(attributes, for: .highlighted)
        barButtonItemAppearance.setTitleTextAttributes(attributes, for: .disabled)
    }
}

// MARK: - AudioPermissionsObserving
extension AppRootRouter: AudioPermissionsObserving {
    func userDidGrantAudioPermissions() {
        sessionManager?.updateCallNotificationStyleFromSettings()
    }
}

// MARK: - ShowContentDelegate

extension AppRootRouter: ShowContentDelegate {
    public func showConnectionRequest(userId: UUID) {
        whenShowContentDelegateIsAvailable { delegate in
            delegate.showConnectionRequest(userId: userId)
        }
    }

    public func showUserProfile(user: UserType) {
        whenShowContentDelegateIsAvailable { delegate in
            delegate.showUserProfile(user: user)
        }
    }


    public func showConversation(_ conversation: ZMConversation, at message: ZMConversationMessage?) {
        whenShowContentDelegateIsAvailable { delegate in
            delegate.showConversation(conversation, at: message)
        }
    }
    
    public func showConversationList() {
        whenShowContentDelegateIsAvailable { delegate in
            delegate.showConversationList()
        }
    }
    
    public func whenShowContentDelegateIsAvailable(do closure: @escaping (ShowContentDelegate) -> ()) {
        if let delegate = showContentDelegate {
            closure(delegate)
        }
        else {
            performWhenShowContentDelegateIsAvailable = closure
        }
    }
}

// TO DO: Move out this code from here
final class SpinnerCapableNavigationController: UINavigationController, SpinnerCapable {
    var dismissSpinner: SpinnerCompletion?

    override var childForStatusBarStyle: UIViewController? {
        return topViewController
    }
    
}

extension UIApplication {
    @available(iOS 12.0, *)
    static var userInterfaceStyle: UIUserInterfaceStyle? {
            UIApplication.shared.keyWindow?.rootViewController?.traitCollection.userInterfaceStyle
    }
}

