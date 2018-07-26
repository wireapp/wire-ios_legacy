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
import UIKit
import Classy

var defaultFontScheme: FontScheme = FontScheme(contentSizeCategory: UIApplication.shared.preferredContentSizeCategory)

@objcMembers class AppRootViewController: UIViewController {

    public let mainWindow: UIWindow
    public let callWindow: CallWindow
    public let overlayWindow: NotificationWindow

    public fileprivate(set) var sessionManager: SessionManager?
    public fileprivate(set) var quickActionsManager: QuickActionsManager?
    
    fileprivate var sessionManagerCreatedSessionObserverToken: Any?
    fileprivate var sessionManagerDestroyedSessionObserverToken: Any?
    fileprivate var soundEventListeners = [UUID : SoundEventListener]()

    public fileprivate(set) var visibleViewController: UIViewController?
    fileprivate let appStateController: AppStateController
    fileprivate lazy var classyCache: ClassyCache = {
        return ClassyCache()
    }()
    fileprivate let fileBackupExcluder: FileBackupExcluder
    fileprivate let avsLogObserver: AVSLogObserver
    fileprivate var authenticatedBlocks : [() -> Void] = []
    fileprivate let transitionQueue: DispatchQueue = DispatchQueue(label: "transitionQueue")
    fileprivate var isClassyInitialized = false
    fileprivate let mediaManagerLoader = MediaManagerLoader()

    var flowController: TeamCreationFlowController!

    fileprivate weak var requestToOpenViewDelegate: ZMRequestsToOpenViewsDelegate? {
        didSet {
            if let delegate = requestToOpenViewDelegate {
                performWhenRequestsToOpenViewsDelegateAvailable?(delegate)
                performWhenRequestsToOpenViewsDelegateAvailable = nil
            }
        }
    }

    fileprivate var performWhenRequestsToOpenViewsDelegateAvailable: ((ZMRequestsToOpenViewsDelegate)->())?

    func updateOverlayWindowFrame() {
        self.overlayWindow.frame = UIApplication.shared.keyWindow?.frame ?? UIScreen.main.bounds
    }

    override public func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        mainWindow.frame.size = size

        coordinator.animate(alongsideTransition: nil, completion: { _ in
            self.updateOverlayWindowFrame()
        })
    }

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        appStateController = AppStateController()
        fileBackupExcluder = FileBackupExcluder()
        avsLogObserver = AVSLogObserver()

        mainWindow = UIWindow(frame: UIScreen.main.bounds)
        mainWindow.accessibilityIdentifier = "ZClientMainWindow"
        
        callWindow = CallWindow(frame: UIScreen.main.bounds)
        overlayWindow = NotificationWindow(frame: UIScreen.main.bounds)

        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)

        AutomationHelper.sharedHelper.installDebugDataIfNeeded()

        appStateController.delegate = self
        
        // Notification window has to be on top, so must be made visible last.  Changing the window level is
        // not possible because it has to be below the status bar.
        mainWindow.rootViewController = self
        mainWindow.makeKeyAndVisible()
        callWindow.makeKeyAndVisible()
        overlayWindow.makeKeyAndVisible()
        mainWindow.makeKey()

        type(of: self).configureAppearance()
        configureMediaManager()

        if let appGroupIdentifier = Bundle.main.appGroupIdentifier {
            let sharedContainerURL = FileManager.sharedContainerDirectory(for: appGroupIdentifier)
            fileBackupExcluder.excludeLibraryFolderInSharedContainer(sharedContainerURL: sharedContainerURL)
        }

        NotificationCenter.default.addObserver(self, selector: #selector(onContentSizeCategoryChange), name: Notification.Name.UIContentSizeCategoryDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillEnterForeground), name: Notification.Name.UIApplicationWillEnterForeground, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidEnterBackground), name: Notification.Name.UIApplicationDidEnterBackground, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive), name: Notification.Name.UIApplicationDidBecomeActive, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onUserGrantedAudioPermissions), name: Notification.Name.UserGrantedAudioPermissions, object: nil)

        transition(to: .headless)

        enqueueTransition(to: appStateController.appState)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.frame = mainWindow.bounds
    }

    public func launch(with launchOptions: LaunchOptions) {
        let bundle = Bundle.main
        let appVersion = bundle.infoDictionary?[kCFBundleVersionKey as String] as? String
        let mediaManager = AVSMediaManager.sharedInstance()
        let analytics = Analytics.shared()
        let sessionManagerAnalytics: AnalyticsType
        
        CallQualityScoreProvider.shared.nextProvider = analytics
        sessionManagerAnalytics = CallQualityScoreProvider.shared
        SessionManager.clearPreviousBackups()

        SessionManager.create(
            appVersion: appVersion!,
            mediaManager: mediaManager!,
            analytics: sessionManagerAnalytics,
            delegate: appStateController,
            application: UIApplication.shared,
            blacklistDownloadInterval: Settings.shared().blacklistDownloadInterval) { sessionManager in
            self.sessionManager = sessionManager
            self.sessionManagerCreatedSessionObserverToken = sessionManager.addSessionManagerCreatedSessionObserver(self)
            self.sessionManagerDestroyedSessionObserverToken = sessionManager.addSessionManagerDestroyedSessionObserver(self)
            self.sessionManager?.localNotificationResponder = self
            self.sessionManager?.requestToOpenViewDelegate = self
            self.sessionManager?.switchingDelegate = self
            sessionManager.updateCallNotificationStyleFromSettings()
            sessionManager.useConstantBitRateAudio = Settings.shared().callingConstantBitRate
            sessionManager.start(launchOptions: launchOptions)
                
            self.quickActionsManager = QuickActionsManager(sessionManager: sessionManager,
                                                           application: UIApplication.shared)
                
            sessionManager.urlHandler.delegate = self
            if let url = launchOptions[UIApplicationLaunchOptionsKey.url] as? URL {
                sessionManager.urlHandler.openURL(url, options: [:])
            }
        }
    }

    func enqueueTransition(to appState: AppState, completion: (() -> Void)? = nil) {

        transitionQueue.async {

            let transitionGroup = DispatchGroup()
            transitionGroup.enter()

            DispatchQueue.main.async {
                self.prepare(for: appState, completionHandler: {
                    transitionGroup.leave()
                })
            }

            transitionGroup.wait()
        }

        transitionQueue.async {

            let transitionGroup = DispatchGroup()
            transitionGroup.enter()

            DispatchQueue.main.async {
                self.transition(to: appState, completionHandler: {
                    transitionGroup.leave()
                    completion?()
                })
            }

            transitionGroup.wait()
        }
    }

    func transition(to appState: AppState, completionHandler: (() -> Void)? = nil) {
        var viewController: UIViewController? = nil
        requestToOpenViewDelegate = nil

        switch appState {
        case .blacklisted:
            viewController = BlacklistViewController()
        case .migrating:
            let launchImageViewController = LaunchImageViewController()
            launchImageViewController.showLoadingScreen()
            viewController = launchImageViewController
        case .unauthenticated(error: let error):
            UIColor.setAccentOverride(ZMUser.pickRandomAcceptableAccentColor())
            mainWindow.tintColor = UIColor.accent()

            // check if needs to reauthenticate
            var needsToReauthenticate = false
            var addingNewAccount = (SessionManager.shared?.accountManager.accounts.count == 0)
            if let error = error {
                let errorCode = (error as NSError).userSessionErrorCode
                needsToReauthenticate = [ZMUserSessionErrorCode.clientDeletedRemotely,
                    .accessTokenExpired,
                    .needsPasswordToRegisterClient,
                    .needsToRegisterEmailToRegisterClient,
                ].contains(errorCode)

                addingNewAccount = [
                    ZMUserSessionErrorCode.addAccountRequested
                    ].contains(errorCode)
            }
            
            if needsToReauthenticate {
                let registrationViewController = RegistrationViewController()
                registrationViewController.delegate = appStateController
                registrationViewController.shouldHideCancelButton = SessionManager.numberOfAccounts <= 1
                registrationViewController.signInError = error
                viewController = registrationViewController
            }
            else if addingNewAccount {
                // When we show the landing controller we want it to be nested in navigation controller
                let landingViewController = LandingViewController()
                landingViewController.delegate = self
                TrackingManager.shared.disableCrashAndAnalyticsSharing = true
                
                let navigationController = NavigationController(rootViewController: landingViewController)
                navigationController.backButtonEnabled = false
                navigationController.logoEnabled = false
                navigationController.isNavigationBarHidden = true
                
                guard let registrationStatus = SessionManager.shared?.unauthenticatedSession?.registrationStatus else { fatal("Could not get registration status") }
                
                flowController = TeamCreationFlowController(navigationController: navigationController, registrationStatus: registrationStatus)
                flowController.registrationDelegate = appStateController
                viewController = navigationController
            }

        case .authenticated(completedRegistration: let completedRegistration):
            UIColor.setAccentOverride(.undefined)
            mainWindow.tintColor = UIColor.accent()
            executeAuthenticatedBlocks()
            let clientViewController = ZClientViewController()
            clientViewController.isComingFromRegistration = completedRegistration

            /// show the dialog only when lastAppState is .unauthenticated, i.e. the user login to a new device
            clientViewController.needToShowDataUsagePermissionDialog = false
            if case .unauthenticated(_) = appStateController.lastAppState {
                clientViewController.needToShowDataUsagePermissionDialog = true
            }

            Analytics.shared().team = ZMUser.selfUser().team

            viewController = clientViewController
        case .headless:
            viewController = LaunchImageViewController()
        case .loading(account: let toAccount, from: let fromAccount):
            viewController = SkeletonViewController(from: fromAccount, to: toAccount)
        }

        if let viewController = viewController {
            transition(to: viewController, animated: true) {
                self.requestToOpenViewDelegate = viewController as? ZMRequestsToOpenViewsDelegate
                completionHandler?()
            }
        } else {
            completionHandler?()
        }
    }

    private func dismissModalsFromAllChildren(of viewController: UIViewController?) {
        guard let viewController = viewController else { return }
        for child in viewController.childViewControllers {
            if child.presentedViewController != nil {
                child.dismiss(animated: false, completion: nil)
            }
            dismissModalsFromAllChildren(of: child)
        }
    }

    func transition(to viewController: UIViewController, animated: Bool = true, completionHandler: (() -> Void)? = nil) {

        // If we have some modal view controllers presented in any of the (grand)children
        // of this controller they stay in memory and leak on iOS 10.
        dismissModalsFromAllChildren(of: visibleViewController)
        visibleViewController?.willMove(toParentViewController: nil)

        if let previousViewController = visibleViewController, animated {

            addChildViewController(viewController)
            transition(from: previousViewController,
                       to: viewController,
                       duration: 0.5,
                       options: .transitionCrossDissolve,
                       animations: nil,
                       completion: { (finished) in
                    viewController.didMove(toParentViewController: self)
                    previousViewController.removeFromParentViewController()
                    self.visibleViewController = viewController
                    UIApplication.shared.wr_updateStatusBarForCurrentControllerAnimated(true)
                    completionHandler?()
            })
        } else {
            UIView.performWithoutAnimation {
                visibleViewController?.removeFromParentViewController()
                addChildViewController(viewController)
                viewController.view.frame = view.bounds
                viewController.view.autoresizingMask = [.flexibleHeight, .flexibleWidth]
                view.addSubview(viewController.view)
                viewController.didMove(toParentViewController: self)
                visibleViewController = viewController
                UIApplication.shared.wr_updateStatusBarForCurrentControllerAnimated(false)
            }
            completionHandler?()
        }
    }

    func prepare(for appState: AppState, completionHandler: @escaping () -> Void) {

        if appState == .authenticated(completedRegistration: false) {
            callWindow.callController.transitionToLoggedInSession()
        } else {
            overlayWindow.rootViewController = NotificationWindowRootViewController()
        }

        if !isClassyInitialized && isClassyRequired(for: appState) {
            isClassyInitialized = true

            let windows = [mainWindow, callWindow, overlayWindow]
            DispatchQueue.main.async {
                self.setupClassy(with: windows)
                completionHandler()
            }
        } else {
            completionHandler()
        }
    }

    func isClassyRequired(for appState: AppState) -> Bool {
        switch appState {
        case .authenticated, .unauthenticated, .loading:
            return true
        default:
            return false
        }
    }

    func configureMediaManager() {
        self.mediaManagerLoader.send(message: .appStart)
    }

    func setupClassy(with windows: [UIWindow]) {

        let colorScheme = ColorScheme.default
        colorScheme.accentColor = UIColor.accent()
        colorScheme.variant = ColorSchemeVariant(rawValue: Settings.shared().colorScheme.rawValue) ?? .light

        CASStyler.default().cache = classyCache
        CASStyler.bootstrapClassy(withTargetWindows: windows)
        CASStyler.default().apply(colorScheme)
        CASStyler.default().apply(fontScheme: defaultFontScheme)
    }

    @objc func onContentSizeCategoryChange() {
        Message.invalidateMarkdownStyle()
        NSAttributedString.wr_flushCellParagraphStyleCache()
        ConversationListCell.invalidateCachedCellSize()
        defaultFontScheme = FontScheme(contentSizeCategory: UIApplication.shared.preferredContentSizeCategory)
        CASStyler.default().apply(fontScheme: defaultFontScheme)
        type(of: self).configureAppearance()
    }

    public func performWhenAuthenticated(_ block : @escaping () -> Void) {
        if appStateController.appState == .authenticated(completedRegistration: false) {
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
        enqueueTransition(to: .headless)
        enqueueTransition(to: self.appStateController.appState)
    }

}

// MARK: - Status Bar / Supported Orientations

extension AppRootViewController {

    override var shouldAutorotate: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return wr_supportedInterfaceOrientations
    }

    override var prefersStatusBarHidden: Bool {
        return visibleViewController?.prefersStatusBarHidden ?? false
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return visibleViewController?.preferredStatusBarStyle ?? .default
    }

}

extension AppRootViewController: AppStateControllerDelegate {

    func appStateController(transitionedTo appState: AppState, transitionCompleted: @escaping () -> Void) {
        enqueueTransition(to: appState, completion: transitionCompleted)
    }

}

// MARK: - RequestToOpenViewsDelegate

extension AppRootViewController: ZMRequestsToOpenViewsDelegate {

    public func showConversationList(for userSession: ZMUserSession!) {
        whenRequestsToOpenViewsDelegateAvailable(do: { delegate in
            delegate.showConversationList(for: userSession)
        })
    }

    public func userSession(_ userSession: ZMUserSession!, show conversation: ZMConversation!) {
        whenRequestsToOpenViewsDelegateAvailable(do: { delegate in
            delegate.userSession(userSession, show: conversation)
        })
    }

    public func userSession(_ userSession: ZMUserSession!, show message: ZMMessage!, in conversation: ZMConversation!) {
        whenRequestsToOpenViewsDelegateAvailable(do: { delegate in
            delegate.userSession(userSession, show: message, in: conversation)
        })
    }

    internal func whenRequestsToOpenViewsDelegateAvailable(do closure: @escaping (ZMRequestsToOpenViewsDelegate) -> ()) {
        if let delegate = self.requestToOpenViewDelegate {
            closure(delegate)
        }
        else {
            self.performWhenRequestsToOpenViewsDelegateAvailable = closure
        }
    }
}

// MARK: - Application Icon Badge Number

extension AppRootViewController: LocalNotificationResponder {

    func processLocal(_ notification: ZMLocalNotification, forSession session: ZMUserSession) {
        (self.overlayWindow.rootViewController as! NotificationWindowRootViewController).show(notification)
    }

    @objc fileprivate func applicationWillEnterForeground() {
        updateOverlayWindowFrame()
    }

    @objc fileprivate func applicationDidEnterBackground() {
        let unreadConversations = sessionManager?.accountManager.totalUnreadCount ?? 0
        UIApplication.shared.applicationIconBadgeNumber = unreadConversations
    }

    @objc fileprivate func applicationDidBecomeActive() {
        updateOverlayWindowFrame()
    }
}

// MARK: - Session Manager Observer

extension AppRootViewController: SessionManagerCreatedSessionObserver, SessionManagerDestroyedSessionObserver {

    func sessionManagerCreated(userSession: ZMUserSession) {
        for (accountId, session) in sessionManager?.backgroundUserSessions ?? [:] {
            if session == userSession {
                soundEventListeners[accountId] = SoundEventListener(userSession: userSession)
            }
        }
    }

    func sessionManagerDestroyedUserSession(for accountId: UUID) {
        soundEventListeners[accountId] = nil
    }
}

// MARK: - Audio Permissions granted

extension AppRootViewController {

    @objc func onUserGrantedAudioPermissions() {
        sessionManager?.updateCallNotificationStyleFromSettings()
    }
}

// MARK: - Transition form LandingViewController to RegistrationViewController

extension AppRootViewController: LandingViewControllerDelegate {
    func landingViewControllerDidChooseCreateTeam() {
        flowController.startFlow()
    }

    func landingViewControllerDidChooseLogin() {
        if let navigationController = self.visibleViewController as? NavigationController {
            let loginViewController = RegistrationViewController(authenticationFlow: .onlyLogin)
            loginViewController.delegate = appStateController
            loginViewController.shouldHideCancelButton = true
            navigationController.pushViewController(loginViewController, animated: true)
        }
    }

    func landingViewControllerDidChooseCreateAccount() {
        if let navigationController = self.visibleViewController as? NavigationController {
            let registrationViewController = RegistrationViewController(authenticationFlow: .onlyRegistration)
            registrationViewController.delegate = appStateController
            registrationViewController.shouldHideCancelButton = true
            navigationController.pushViewController(registrationViewController, animated: true)
        }
    }
}

// MARK: - Ask user if they want want switch account if there's an ongoing call

extension AppRootViewController: SessionManagerSwitchingDelegate {
    
    func confirmSwitchingAccount(completion: @escaping (Bool) -> Void) {
        
        guard let session = ZMUserSession.shared(), session.isCallOngoing else { return completion(true) }
        guard let topmostController = UIApplication.shared.wr_topmostController() else { return completion(false) }
        
        let alert = UIAlertController(title: "self.settings.switch_account.title".localized, message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "self.settings.switch_account.action".localized, style: .default, handler: { [weak self] (action) in
            self?.sessionManager?.activeUserSession?.callCenter?.endAllCalls()
            completion(true)
        }))
        alert.addAction(.cancel { completion(false) })

        topmostController.present(alert, animated: true, completion: nil)
    }
    
}

public extension SessionManager {
    
    @objc var firstAuthenticatedAccount: Account? {
        
        if let selectedAccount = accountManager.selectedAccount {
            if selectedAccount.isAuthenticated {
                return selectedAccount
            }
        }
        
        for account in accountManager.accounts {
            if account.isAuthenticated && account != accountManager.selectedAccount {
                return account
            }
        }
        
        return nil
    }

    @objc static var numberOfAccounts: Int {
        return SessionManager.shared?.accountManager.accounts.count ?? 0
    }

}

extension AppRootViewController: SessionManagerURLHandlerDelegate {
    func sessionManagerShouldExecuteURLAction(_ action: URLAction, callback: @escaping (Bool) -> Void) {
        switch action {
        case .connectBot:
            guard let _ = ZMUser.selfUser().team else {
                callback(false)
                return
            }
            
            let alert = UIAlertController(title: "url_action.title".localized,
                                          message: "url_action.connect_to_bot.message".localized,
                                          preferredStyle: .alert)
            
            let agreeAction = UIAlertAction(title: "url_action.confirm".localized,
                                            style: .default) { _ in
                                                callback(true)
            }
            
            alert.addAction(agreeAction)
            
            let cancelAction = UIAlertAction(title: "general.cancel".localized,
                                             style: .cancel) { _ in
                                                callback(false)
            }
            
            alert.addAction(cancelAction)
            
            self.present(alert, animated: true, completion: nil)

        case .companyLoginFailure(let label):
            defer {
                notifyCompanyLoginCompletion()
            }
            
            guard case .unauthenticated = appStateController.appState else {
                callback(false)
                return
            }

            let message = "login.sso.error.alert.message".localized(args: label)

            let alert = UIAlertController(title: "general.failure".localized,
                                          message: message,
                                          preferredStyle: .alert)

            alert.addAction(.ok { callback(false) })
            self.present(alert, animated: true, completion: nil)

        case .companyLoginSuccess:
            defer {
                notifyCompanyLoginCompletion()
            }

            guard case .unauthenticated = appStateController.appState else {
                callback(false)
                return
            }

            callback(true)
        }
    }

    private func notifyCompanyLoginCompletion() {
        NotificationCenter.default.post(name: .companyLoginDidFinish, object: self)
    }
}

extension Notification.Name {
    static let companyLoginDidFinish = Notification.Name("Wire.CompanyLoginDidFinish")
}
