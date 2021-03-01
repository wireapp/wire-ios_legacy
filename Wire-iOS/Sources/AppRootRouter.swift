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

    // MARK: - Public Property
    let screenCurtain = ScreenCurtain()

    // MARK: - Private Property
    private let navigator: NavigatorProtocol
    private var appStateCalculator: AppStateCalculator
    private var urlActionRouter: URLActionRouter
    private var deepLinkURL: URL?

    private var authenticationCoordinator: AuthenticationCoordinator?
    private var switchingAccountRouter: SwitchingAccountRouter
    private var sessionManagerLifeCycleObserver: SessionManagerLifeCycleObserver
    private let foregroundNotificationFilter: ForegroundNotificationFilter
    private var quickActionsManager: QuickActionsManager
    private var authenticatedRouter: AuthenticatedRouter? {
        didSet {
            setupAnalyticsSharing()
        }
    }

    private var observerTokens: [NSObjectProtocol] = []
    private var authenticatedBlocks: [() -> Void] = []
    private let teamMetadataRefresher = TeamMetadataRefresher()

    // MARK: - Private Set Property
    private(set) var sessionManager: SessionManager

    // TO DO: This should be private
    private(set) var rootViewController: RootViewController

    // MARK: - Initialization

    init(viewController: RootViewController,
         navigator: NavigatorProtocol,
         sessionManager: SessionManager,
         appStateCalculator: AppStateCalculator,
         deepLinkURL: URL? = nil) {
        self.rootViewController = viewController
        self.navigator = navigator
        self.sessionManager = sessionManager
        self.appStateCalculator = appStateCalculator
        self.deepLinkURL = deepLinkURL
        self.urlActionRouter = URLActionRouter(viewController: viewController,
                                               url: deepLinkURL)
        self.switchingAccountRouter = SwitchingAccountRouter()
        self.quickActionsManager = QuickActionsManager()
        self.foregroundNotificationFilter = ForegroundNotificationFilter()
        self.sessionManagerLifeCycleObserver = SessionManagerLifeCycleObserver()

        urlActionRouter.sessionManager = sessionManager
        sessionManagerLifeCycleObserver.sessionManager = sessionManager
        foregroundNotificationFilter.sessionManager = sessionManager
        quickActionsManager.sessionManager = sessionManager

        sessionManager.foregroundNotificationResponder = foregroundNotificationFilter
        sessionManager.switchingDelegate = switchingAccountRouter
        sessionManager.presentationDelegate = urlActionRouter

        super.init()

        setupAppStateCalculator()
        setupURLActionRouter()
        setupNotifications()
        setupAdditionalWindows()

        AppRootRouter.configureAppearance()

        createLifeCycleObserverTokens()
        setCallingSettings()
    }

    // MARK: - Public implementation

    public func start(launchOptions: LaunchOptions) {
        guard let deepLinkURL = deepLinkURL else {
            showInitial(launchOptions: launchOptions)
            return
        }

        guard
            let action = try? URLAction(url: deepLinkURL),
            action.requiresAuthentication == true
        else {
            return
        }
        showInitial(launchOptions: launchOptions)
    }

    public func openDeepLinkURL(_ deepLinkURL: URL?) -> Bool {
        guard let url = deepLinkURL else { return false }
        return urlActionRouter.open(url: url)
    }

    public func performQuickAction(for shortcutItem: UIApplicationShortcutItem,
                                   completionHandler: ((Bool)->())?) {
        quickActionsManager.performAction(for: shortcutItem,
                                          completionHandler: completionHandler)
    }

    // MARK: - Private implementation
    private func setupAppStateCalculator() {
        appStateCalculator.delegate = self
    }

    private func setupURLActionRouter() {
        urlActionRouter.delegate = self
    }

    private func setupNotifications() {
        setupApplicationNotifications()
        setupContentSizeCategoryNotifications()
        setupAudioPermissionsNotifications()
    }

    private func setupAdditionalWindows() {
        screenCurtain.makeKeyAndVisible()
        screenCurtain.isHidden = true
    }

    private func createLifeCycleObserverTokens() {
        sessionManagerLifeCycleObserver.createLifeCycleObserverTokens()
    }

    private func setCallingSettings() {
        sessionManager.updateCallNotificationStyleFromSettings()
        sessionManager.useConstantBitRateAudio = SecurityFlags.forceConstantBitRateCalls.isEnabled
            ? true
            : Settings.shared[.callingConstantBitRate] ?? false
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
        resetAuthenticationCoordinatorIfNeeded(for: appState)

        let completionBlock = { [weak self] in
            completion()
            self?.applicationDidTransition(to: appState)
        }

        switch appState {
        case .blacklisted:
            showBlacklisted(completion: completionBlock)
        case .jailbroken:
            showJailbroken(completion: completionBlock)
        case .migrating:
            showLaunchScreen(isLoading: true, completion: completionBlock)
        case .unauthenticated(error: let error):
            screenCurtain.delegate = nil
            configureUnauthenticatedAppearance()
            showUnauthenticatedFlow(error: error, completion: completionBlock)
        case .authenticated(completedRegistration: let completedRegistration):
            configureAuthenticatedAppearance()
            executeAuthenticatedBlocks()
            // TODO: [John] Avoid singleton.
            screenCurtain.delegate = ZMUserSession.shared()
            showAuthenticated(isComingFromRegistration: completedRegistration,
                              completion: completionBlock)
        case .headless:
            showLaunchScreen(completion: completionBlock)
        case .loading(account: let toAccount, from: let fromAccount):
            showSkeleton(fromAccount: fromAccount,
                         toAccount: toAccount,
                         completion: completionBlock)
        case .locked:
            // TODO: [John] Avoid singleton.
            screenCurtain.delegate = ZMUserSession.shared()
            showAppLock()
        }
    }

    private func resetAuthenticationCoordinatorIfNeeded(for state: AppState) {
        switch state {
        case .unauthenticated:
            break // do not reset the authentication coordinator for unauthenticated state
        default:
            authenticationCoordinator = nil // reset the authentication coordinator when we no longer need it
        }
    }

    func performWhenAuthenticated(_ block : @escaping () -> Void) {
        if case .authenticated = appStateCalculator.appState {
            block()
        } else {
            authenticatedBlocks.append(block)
        }
    }

    func executeAuthenticatedBlocks() {
        while !authenticatedBlocks.isEmpty {
            authenticatedBlocks.removeFirst()()
        }
    }

    func reload() {
        transition(to: .headless, completion: { })
        transition(to: appStateCalculator.appState, completion: { })
    }
}

extension AppRootRouter {
    // MARK: - Navigation Helpers
    private func showInitial(launchOptions: LaunchOptions) {
        transition(to: .headless, completion: { [weak self] in
            Analytics.shared.tagEvent("app.open")
            self?.sessionManager.start(launchOptions: launchOptions)
        })
    }

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

        presentAlertForDeletedAccountIfNeeded(error)
    }

    private func showAuthenticated(isComingFromRegistration: Bool, completion: @escaping () -> Void) {
        guard
            let selectedAccount = SessionManager.shared?.accountManager.selectedAccount,
            let authenticatedRouter = buildAuthenticatedRouter(account: selectedAccount,
                                                               isComingFromRegistration: isComingFromRegistration)
        else {
            return
        }

        self.authenticatedRouter = authenticatedRouter

        rootViewController.set(childViewController: authenticatedRouter.viewController,
                               completion: completion)
    }

    private func showSkeleton(fromAccount: Account?, toAccount: Account, completion: @escaping () -> Void) {
        let skeletonViewController = SkeletonViewController(from: fromAccount, to: toAccount)
        rootViewController.set(childViewController: skeletonViewController,
                               completion: completion)
    }

    private func showAppLock() {
        guard let session = ZMUserSession.shared() else { fatalError() }
        rootViewController.set(childViewController: AppLockModule.build(session: session))
    }

    // MARK: - Helpers
    private func configureUnauthenticatedAppearance() {
        rootViewController.view.window?.tintColor = UIColor.Wire.primaryLabel
        ValidatedTextField.appearance(whenContainedInInstancesOf: [AuthenticationStepController.self]).tintColor = UIColor.Team.activeButton
    }

    private func configureAuthenticatedAppearance() {
        rootViewController.view.window?.tintColor = .accent()
        UIColor.setAccentOverride(.undefined)
    }

    private func setupAnalyticsSharing() {
        Analytics.shared.selfUser = SelfUser.current

        guard
            appStateCalculator.wasUnauthenticated,
            Analytics.shared.selfUser?.isTeamMember ?? false
        else {
            return
        }

        TrackingManager.shared.disableCrashSharing = true
        TrackingManager.shared.disableAnalyticsSharing = false
    }

    private func buildAuthenticatedRouter(account: Account,
                                           isComingFromRegistration: Bool) -> AuthenticatedRouter? {

        let needToShowDataUsagePermissionDialog = appStateCalculator.wasUnauthenticated
                                                    && !SelfUser.current.isTeamMember

        return AuthenticatedRouter(rootViewController: rootViewController,
                                   account: account,
                                   selfUser: ZMUser.selfUser(),
                                   isComingFromRegistration: isComingFromRegistration,
                                   needToShowDataUsagePermissionDialog: needToShowDataUsagePermissionDialog)
    }
}

// TO DO: THIS PART MUST BE CLENED UP
extension AppRootRouter {
    private func applicationWillTransition(to appState: AppState) {
        if case .authenticated = appState {
            if AppDelegate.shared.shouldConfigureSelfUserProvider {
                SelfUser.provider = ZMUserSession.shared()
            }
        }

        let colorScheme = ColorScheme.default
        colorScheme.accentColor = .accent()
        colorScheme.variant = Settings.shared.colorSchemeVariant
    }

    private func applicationDidTransition(to appState: AppState) {
        if case .authenticated = appState {
            authenticatedRouter?.updateActiveCallPresentationState()
            urlActionRouter.openDeepLink(needsAuthentication: true)

            ZClientViewController.shared?.legalHoldDisclosureController?.discloseCurrentState(cause: .appOpen)
        } else if AppDelegate.shared.shouldConfigureSelfUserProvider {
            SelfUser.provider = nil
        }
    }

    private func presentAlertForDeletedAccountIfNeeded(_ error: NSError?) {
        guard
            error?.userSessionErrorCode == .accountDeleted,
            let reason = error?.userInfo[ZMAccountDeletedReasonKey] as? ZMAccountDeletedReason
        else {
            return
        }

        switch reason {
        case .sessionExpired:
            rootViewController.presentAlertWithOKButton(title: "account_deleted_session_expired_alert.title".localized,
                                                        message: "account_deleted_session_expired_alert.message".localized)

        case .databaseWiped:
            let wipeCompletionViewController = WipeCompletionViewController()
            wipeCompletionViewController.modalPresentationStyle = .fullScreen
            rootViewController.present(wipeCompletionViewController, animated: true)

        default:
            break
        }
    }
}

// MARK: - URLActionRouterDelegete
extension AppRootRouter: URLActionRouterDelegete {
    func urlActionRouterWillShowCompanyLoginError() {
        authenticationCoordinator?.cancelCompanyLogin()
    }
}

// MARK: - ApplicationStateObserving
extension AppRootRouter: ApplicationStateObserving {
    func addObserverToken(_ token: NSObjectProtocol) {
        observerTokens.append(token)
    }

    func applicationDidBecomeActive() {
        updateOverlayWindowFrame()
        teamMetadataRefresher.triggerRefreshIfNeeded()
    }

    func applicationDidEnterBackground() {
        let unreadConversations = sessionManager.accountManager.totalUnreadCount
        UIApplication.shared.applicationIconBadgeNumber = unreadConversations
    }

    func applicationWillEnterForeground() {
        updateOverlayWindowFrame()
    }

    func updateOverlayWindowFrame(size: CGSize? = nil) {
        if let size = size {
            screenCurtain.frame.size = size
        } else {
            screenCurtain.frame = UIApplication.shared.keyWindow?.frame ?? UIScreen.main.bounds
        }
    }
}

// MARK: - ContentSizeCategoryObserving
extension AppRootRouter: ContentSizeCategoryObserving {
    func contentSizeCategoryDidChange() {
        NSAttributedString.invalidateParagraphStyle()
        NSAttributedString.invalidateMarkdownStyle()
        ConversationListCell.invalidateCachedCellSize()
        defaultFontScheme = FontScheme(contentSizeCategory: UIApplication.shared.preferredContentSizeCategory)
        AppRootRouter.configureAppearance()
    }

    public static func configureAppearance() {
        let navigationBarTitleBaselineOffset: CGFloat = 2.5

        let attributes: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 11, weight: .semibold), .baselineOffset: navigationBarTitleBaselineOffset]
        let barButtonItemAppearance = UIBarButtonItem.appearance(whenContainedInInstancesOf: [DefaultNavigationBar.self])
        barButtonItemAppearance.setTitleTextAttributes(attributes, for: .normal)
        barButtonItemAppearance.setTitleTextAttributes(attributes, for: .highlighted)
        barButtonItemAppearance.setTitleTextAttributes(attributes, for: .disabled)
    }
}

// MARK: - AudioPermissionsObserving
extension AppRootRouter: AudioPermissionsObserving {
    func userDidGrantAudioPermissions() {
        sessionManager.updateCallNotificationStyleFromSettings()

    }
}
