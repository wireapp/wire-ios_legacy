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
import SafariServices

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
    fileprivate let fileBackupExcluder: FileBackupExcluder
    fileprivate let avsLogObserver: AVSLogObserver
    fileprivate var authenticatedBlocks : [() -> Void] = []
    fileprivate let transitionQueue: DispatchQueue = DispatchQueue(label: "transitionQueue")
    fileprivate let mediaManagerLoader = MediaManagerLoader()

    var authenticationCoordinator: AuthenticationCoordinator?

    weak var presentedPopover: UIPopoverPresentationController?
    weak var popoverPointToView: UIView?


    fileprivate weak var showContentDelegate: ShowContentDelegate? {
        didSet {
            if let delegate = showContentDelegate {
                performWhenShowContentDelegateIsAvailable?(delegate)
                performWhenShowContentDelegateIsAvailable = nil
            }
        }
    }

    fileprivate var performWhenShowContentDelegateIsAvailable: ((ShowContentDelegate)->())?

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

        NotificationCenter.default.addObserver(self, selector: #selector(onContentSizeCategoryChange), name: UIContentSizeCategory.didChangeNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
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

        SessionManager.clearPreviousBackups()

        SessionManager.create(
            appVersion: appVersion!,
            mediaManager: mediaManager!,
            analytics: analytics,
            delegate: appStateController,
            application: UIApplication.shared,
            environment: BackendEnvironment.shared,
            blacklistDownloadInterval: Settings.shared().blacklistDownloadInterval) { sessionManager in
            self.sessionManager = sessionManager
            self.sessionManagerCreatedSessionObserverToken = sessionManager.addSessionManagerCreatedSessionObserver(self)
            self.sessionManagerDestroyedSessionObserverToken = sessionManager.addSessionManagerDestroyedSessionObserver(self)
            self.sessionManager?.foregroundNotificationResponder = self
            self.sessionManager?.showContentDelegate = self
            self.sessionManager?.switchingDelegate = self
            sessionManager.updateCallNotificationStyleFromSettings()
            sessionManager.useConstantBitRateAudio = Settings.shared().callingConstantBitRate
            sessionManager.start(launchOptions: launchOptions)
                
            self.quickActionsManager = QuickActionsManager(sessionManager: sessionManager,
                                                           application: UIApplication.shared)
                
            sessionManager.urlHandler.delegate = self
            if let url = launchOptions[UIApplication.LaunchOptionsKey.url] as? URL {
                sessionManager.urlHandler.openURL(url, options: [:])
            }
        }
    }

    func enqueueTransition(to appState: AppState, completion: (() -> Void)? = nil) {

        transitionQueue.async {

            let transitionGroup = DispatchGroup()
            transitionGroup.enter()

            DispatchQueue.main.async {
                self.applicationWillTransition(to: appState)
                transitionGroup.leave()
            }

            transitionGroup.wait()
        }

        transitionQueue.async {

            let transitionGroup = DispatchGroup()
            transitionGroup.enter()

            DispatchQueue.main.async {
                self.transition(to: appState, completionHandler: {
                    transitionGroup.leave()
                    self.applicationDidTransition(to: appState)
                    completion?()
                })
            }

            transitionGroup.wait()
        }
    }

    func transition(to appState: AppState, completionHandler: (() -> Void)? = nil) {
        var viewController: UIViewController? = nil
        showContentDelegate = nil

        resetAuthenticationCoordinatorIfNeeded(for: appState)

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

            // Only execute handle events if there is no current flow
            guard authenticationCoordinator == nil else {
                break
            }

            let navigationController = NavigationController()
            navigationController.backButtonEnabled = false
            navigationController.logoEnabled = false
            navigationController.isNavigationBarHidden = true

            authenticationCoordinator = AuthenticationCoordinator(presenter: navigationController,
                                                                  unauthenticatedSession: UnauthenticatedSession.sharedSession!,
                                                                  sessionManager: SessionManager.shared!)

            authenticationCoordinator!.delegate = appStateController
            authenticationCoordinator!.startAuthentication(with: error, numberOfAccounts: SessionManager.numberOfAccounts)

            viewController = KeyboardAvoidingViewController(viewController: navigationController)

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
                self.showContentDelegate = viewController as? ShowContentDelegate
                completionHandler?()
            }
        } else {
            completionHandler?()
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

    private func dismissModalsFromAllChildren(of viewController: UIViewController?) {
        guard let viewController = viewController else { return }
        for child in viewController.children {
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
        visibleViewController?.willMove(toParent: nil)

        if let previousViewController = visibleViewController, animated {

            addChild(viewController)
            transition(from: previousViewController,
                       to: viewController,
                       duration: 0.5,
                       options: .transitionCrossDissolve,
                       animations: nil,
                       completion: { (finished) in
                    viewController.didMove(toParent: self)
                    previousViewController.removeFromParent()
                    self.visibleViewController = viewController
                    UIApplication.shared.wr_updateStatusBarForCurrentControllerAnimated(true)
                    completionHandler?()
            })
        } else {
            UIView.performWithoutAnimation {
                visibleViewController?.removeFromParent()
                addChild(viewController)
                viewController.view.frame = view.bounds
                viewController.view.autoresizingMask = [.flexibleHeight, .flexibleWidth]
                view.addSubview(viewController.view)
                viewController.didMove(toParent: self)
                visibleViewController = viewController
                UIApplication.shared.wr_updateStatusBarForCurrentControllerAnimated(false)
            }
            completionHandler?()
        }
    }

    func applicationWillTransition(to appState: AppState) {

        if appState == .authenticated(completedRegistration: false) {
            callWindow.callController.transitionToLoggedInSession()
        } else {
            overlayWindow.rootViewController = NotificationWindowRootViewController()
        }

        let colorScheme = ColorScheme.default
        colorScheme.accentColor = .accent()
        colorScheme.variant = ColorSchemeVariant(rawValue: Settings.shared().colorScheme.rawValue) ?? .light
    }
    
    func applicationDidTransition(to appState: AppState) {
        if appState == .authenticated(completedRegistration: false) {
            callWindow.callController.presentCallCurrentlyInProgress()
        }
    }

    func configureMediaManager() {
        self.mediaManagerLoader.send(message: .appStart)
    }

    @objc func onContentSizeCategoryChange() {
        NSAttributedString.invalidateParagraphStyle()
        NSAttributedString.invalidateMarkdownStyle()
        ConversationListCell.invalidateCachedCellSize()
        defaultFontScheme = FontScheme(contentSizeCategory: UIApplication.shared.preferredContentSizeCategory)
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

// MARK: - ShowContentDelegate

extension AppRootViewController: ShowContentDelegate {

    func showConversation(_ conversation: ZMConversation, at message: ZMConversationMessage?) {
        whenShowContentDelegateIsAvailable { delegate in
            delegate.showConversation(conversation, at: message)
        }
    }
    
    func showConversationList() {
        whenShowContentDelegateIsAvailable { delegate in
            delegate.showConversationList()
        }
    }
    
    internal func whenShowContentDelegateIsAvailable(do closure: @escaping (ShowContentDelegate) -> ()) {
        if let delegate = showContentDelegate {
            closure(delegate)
        }
        else {
            self.performWhenShowContentDelegateIsAvailable = closure
        }
    }
}

// MARK: - Foreground Notification Responder

extension AppRootViewController: ForegroundNotificationResponder {
    func shouldPresentNotification(with userInfo: NotificationUserInfo) -> Bool {
        // user wants to see fg notifications
        guard !(Settings.shared()?.chatHeadsDisabled ?? false) else {
            return false
        }
        
        // the concerned account is active
        guard
            let selfUserID = userInfo.selfUserID,
            selfUserID == sessionManager?.accountManager.selectedAccount?.userIdentifier
            else { return true }
        
        guard let clientVC = ZClientViewController.shared() else {
            return true
        }

        if clientVC.isConversationListVisible {
            return false
        }
        
        guard clientVC.isConversationViewVisible else {
            return true
        }
        
        // conversation view is visible for another conversation
        guard
            let convID = userInfo.conversationID,
            convID != clientVC.currentConversation.remoteIdentifier
            else { return false }
        
        return true
    }
}

// MARK: - Application Icon Badge Number

extension AppRootViewController {

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

// MARK: - Ask user if they want want switch account if there's an ongoing call

extension AppRootViewController: SessionManagerSwitchingDelegate {
    
    func confirmSwitchingAccount(completion: @escaping (Bool) -> Void) {
        
        guard let session = ZMUserSession.shared(), session.isCallOngoing else { return completion(true) }
        guard let topmostController = UIApplication.shared.wr_topmostController() else { return completion(false) }
        
        let alert = UIAlertController(title: "call.alert.ongoing.alert_title".localized,
                                      message: "self.settings.switch_account.message".localized,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "self.settings.switch_account.action".localized,
                                      style: .default,
                                      handler: { [weak self] (action) in
            self?.sessionManager?.activeUserSession?.callCenter?.endAllCalls()
            completion(true)
        }))
        alert.addAction(.cancel { completion(false) })

        topmostController.present(alert, animated: true, completion: nil)
    }
    
}

extension AppRootViewController: PopoverPresenter { }

public extension SessionManager {

    @objc(firstAuthenticatedAccountExcludingCredentials:)
    func firstAuthenticatedAccount(excludingCredentials credentials: LoginCredentials?) -> Account? {
        if let selectedAccount = accountManager.selectedAccount {
            if BackendEnvironment.shared.isAuthenticated(selectedAccount) && selectedAccount.loginCredentials != credentials {
                return selectedAccount
            }
        }

        for account in accountManager.accounts {
            if BackendEnvironment.shared.isAuthenticated(account) && account != accountManager.selectedAccount && account.loginCredentials != credentials {
                return account
            }
        }

        return nil
    }

    @objc var firstAuthenticatedAccount: Account? {
        return firstAuthenticatedAccount(excludingCredentials: nil)
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

        case .companyLoginFailure(let error):
            defer {
                authenticationCoordinator?.cancelCompanyLogin()
                notifyCompanyLoginCompletion()
            }
            
            guard case .unauthenticated = appStateController.appState else {
                callback(false)
                return
            }

            let message = "login.sso.error.alert.message".localized(args: error.displayCode)

            let alert = UIAlertController(title: "general.failure".localized,
                                          message: message,
                                          preferredStyle: .alert)

            alert.addAction(.ok { callback(false) })

            let presentAlert = {
                self.present(alert, animated: true)
            }

            if let topmostViewController = UIApplication.shared.wr_topmostController() as? SFSafariViewController {
                topmostViewController.dismiss(animated: true, completion: presentAlert)
            } else {
                presentAlert()
            }

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
