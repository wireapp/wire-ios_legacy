//
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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
import WireCommonComponents

final class ZClientViewController: UIViewController {
    private(set) var conversationRootViewController: UIViewController?
    private(set) var currentConversation: ZMConversation?
    
    // TODO: This must be removed from here once we introduce VIPER
    weak var router: AuthenticatedRouterProtocol?
    
    var isComingFromRegistration = false
    var needToShowDataUsagePermissionDialog = false
    let wireSplitViewController: SplitViewController = SplitViewController()
    
    private(set) var mediaPlaybackManager: MediaPlaybackManager?
    let conversationListViewController: ConversationListViewController
    var proximityMonitorManager: ProximityMonitorManager?
    var legalHoldDisclosureController: LegalHoldDisclosureController?
    
    var userObserverToken: Any?
    
    private let topOverlayContainer: UIView = UIView()
    private var topOverlayViewController: UIViewController? 
    private var contentTopRegularConstraint: NSLayoutConstraint!
    private var contentTopCompactConstraint: NSLayoutConstraint!
    // init value = false which set to true, set to false after data usage permission dialog is displayed
    var dataUsagePermissionDialogDisplayed = false
    let backgroundViewController: BackgroundViewController

    private let colorSchemeController: ColorSchemeController = ColorSchemeController()
    private var incomingApnsObserver: Any?
    private var networkAvailabilityObserverToken: Any?
    private var pendingInitialStateRestore = false
    
    /// init method for testing allows injecting an Account object and self user
    ///
    /// - Parameters:
    ///   - account: an Account object
    ///   - selfUser: a SelfUserType object
    required init(account: Account,
                  selfUser: SelfUserType,
                  userSession: ZMUserSession? = ZMUserSession.shared()) {
        backgroundViewController = BackgroundViewController(user: selfUser, userSession: userSession)
        conversationListViewController = ConversationListViewController(account: account, selfUser: selfUser)
        
        super.init(nibName:nil, bundle:nil)
        
        proximityMonitorManager = ProximityMonitorManager()
        mediaPlaybackManager = MediaPlaybackManager(name: "conversationMedia")
        dataUsagePermissionDialogDisplayed = false
        needToShowDataUsagePermissionDialog = false
        
        AVSMediaManager.sharedInstance().register(mediaPlaybackManager, withOptions: [
            "media": "external "
            ])
        
        if let appGroupIdentifier = Bundle.main.appGroupIdentifier,
            let remoteIdentifier = ZMUser.selfUser().remoteIdentifier {
            let sharedContainerURL = FileManager.sharedContainerDirectory(for: appGroupIdentifier)
            
            let accountContainerURL = sharedContainerURL.appendingPathComponent("AccountData", isDirectory: true).appendingPathComponent(remoteIdentifier.uuidString, isDirectory: true)
        }
        
        NotificationCenter.default.post(name: NSNotification.Name.ZMUserSessionDidBecomeAvailable, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(contentSizeCategoryDidChange(_:)), name: UIContentSizeCategory.didChangeNotification, object: nil)
        
        setupAppearance()
        
        createLegalHoldDisclosureController()
    }
    
    
    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        AVSMediaManager.sharedInstance().unregisterMedia(mediaPlaybackManager)
    }

    private func restoreStartupState() {
        pendingInitialStateRestore = false
        attemptToPresentInitialConversation()
    }
    
    @discardableResult
    private func attemptToPresentInitialConversation() -> Bool {
        var stateRestored = false
        
        let lastViewedScreen: SettingsLastScreen? = Settings.shared[.lastViewedScreen]
        switch lastViewedScreen {
        case .list?:
            
            transitionToList(animated: false, completion: nil)
            
            // only attempt to show content vc if it would be visible
            if isConversationViewVisible {
                stateRestored = attemptToLoadLastViewedConversation(withFocus: false, animated: false)
            }
        case .conversation?:
            stateRestored = attemptToLoadLastViewedConversation(withFocus: true, animated: false)
        default:
            break
        }
        return stateRestored
    }

    // MARK: - Overloaded methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        pendingInitialStateRestore = true
        
        view.backgroundColor = .black
        
        wireSplitViewController.delegate = self
        addToSelf(wireSplitViewController)
        
        wireSplitViewController.view.translatesAutoresizingMaskIntoConstraints = false
        createTopViewConstraints()

        updateSplitViewTopConstraint()
        
        wireSplitViewController.view.backgroundColor = .clear
        
        createBackgroundViewController()
        
        if pendingInitialStateRestore {
            restoreStartupState()
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(colorSchemeControllerDidApplyChanges(_:)), name: NSNotification.colorSchemeControllerDidApplyColorSchemeChange, object: nil)
        
        if Bundle.developerModeEnabled {
            //better way of dealing with this?
            NotificationCenter.default.addObserver(self, selector: #selector(requestLoopNotification(_:)), name: NSNotification.Name(rawValue: ZMLoggingRequestLoopNotificationName), object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(inconsistentStateNotification(_:)), name: NSNotification.Name(rawValue: ZMLoggingInconsistentStateNotificationName), object: nil)
        }
        
        setupUserChangeInfoObserver()
    }
    
    private func createBackgroundViewController() {
        backgroundViewController.addToSelf(conversationListViewController)

        conversationListViewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        conversationListViewController.view.frame = backgroundViewController.view.bounds
        
        wireSplitViewController.leftViewController = backgroundViewController
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return wr_supportedInterfaceOrientations
    }
    

    override var shouldAutorotate: Bool {
        return presentedViewController?.shouldAutorotate ?? true
    }
    
    // MARK: Status bar
    private var child: UIViewController? {
        // for iOS 13, only child of this VC can be use for childForStatusBar
        if #available(iOS 13.0, *) {
            return topOverlayViewController ?? wireSplitViewController
        } else {
            if nil != topOverlayViewController {
                return topOverlayViewController
            } else if traitCollection.horizontalSizeClass == .compact {
                return presentedViewController ?? wireSplitViewController
            }
        }
        
        return nil
    }
    
    private var childForStatusBar: UIViewController? {
        // For iPad regular mode, there is a black bar area and we always use light style and non hidden status bar
        return isIPadRegular() ? nil : child
    }
    
    override var childForStatusBarStyle: UIViewController? {
        return childForStatusBar
    }
    
    override var childForStatusBarHidden: UIViewController? {
        return childForStatusBar
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    // MARK: trait

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        // if changing from compact width to regular width, make sure current conversation is loaded
        if previousTraitCollection?.horizontalSizeClass == .compact && traitCollection.horizontalSizeClass == .regular {
            if let currentConversation = currentConversation {
                select(conversation: currentConversation)
            } else {
                attemptToLoadLastViewedConversation(withFocus: false, animated: false)
            }
        }
        
        updateSplitViewTopConstraint()
        view.setNeedsLayout()
    }
    
    // MARK: - Singleton
    static var shared: ZClientViewController? {
        return AppDelegate.shared.appRootRouter?.rootViewController.children.first(where: {$0 is ZClientViewController}) as? ZClientViewController
    }
    
    /// Select the connection inbox and optionally move focus to it.
    ///
    /// - Parameter focus: focus or not
    func selectIncomingContactRequestsAndFocus(onView focus: Bool) {
        conversationListViewController.selectInboxAndFocusOnView(focus: focus)
    }
    
    /// Exit the connection inbox.  This contains special logic for reselecting another conversation etc when you
    /// have no more connection requests.
    ///
    /// - Parameter completion: completion handler
    func hideIncomingContactRequests(completion: Completion? = nil) {
        guard let userSession = ZMUserSession.shared() else { return }
        
        let conversationsList = ZMConversationList.conversations(inUserSession: userSession)
        if let conversation = (conversationsList as? [ZMConversation])?.first {
            select(conversation: conversation)
        }
        
        wireSplitViewController.setLeftViewControllerRevealed(true, animated: true, completion: completion)
    }
    
    @discardableResult
    private func pushContentViewController(_ viewController: UIViewController? = nil,
                                           focusOnView focus: Bool = false,
                                           animated: Bool = false,
                                           completion: Completion? = nil) -> Bool {
        conversationRootViewController = viewController
        wireSplitViewController.setRightViewController(conversationRootViewController, animated: animated, completion: completion)
        
        if focus {
            wireSplitViewController.setLeftViewControllerRevealed(false, animated: animated)
        }
        
        return true
    }

    func loadPlaceholderConversationController(animated: Bool) {
        loadPlaceholderConversationController(animated: animated) { }
    }
    
    func loadPlaceholderConversationController(animated: Bool, completion: @escaping Completion) {
        currentConversation = nil
        pushContentViewController(animated: animated, completion: completion)
    }
    
    /// Load and optionally show a conversation, but don't change the list selection.  This is the place to put
    /// stuff if you definitely need it to happen when a conversation is selected and/or presented
    ///
    /// This method should only be called when the list selection changes, or internally by other zclientviewcontroller
    ///
    /// - Parameters:
    ///   - conversation: conversation to load
    ///   - message: scroll to a specific message
    ///   - focus: focus on view or not
    ///   - animated: animated or not
    ///   - completion: optional completion handler
    func load(_ conversation: ZMConversation,
              scrollTo message: ZMConversationMessage?,
              focusOnView focus: Bool,
              animated: Bool,
              completion: Completion? = nil) {
        var conversationRootController: ConversationRootViewController? = nil
        if conversation === currentConversation,
           conversationRootController != nil {
            if let message = message {
                conversationRootController?.scroll(to: message)
            }
        } else {
            conversationRootController = ConversationRootViewController(conversation: conversation, message: message, clientViewController: self)
        }
        
        currentConversation = conversation
        conversationRootController?.conversationViewController?.isFocused = focus
        
        conversationListViewController.hideArchivedConversations()
        pushContentViewController(conversationRootController, focusOnView: focus, animated: animated, completion: completion)
    }
    
    func loadIncomingContactRequestsAndFocus(onView focus: Bool, animated: Bool) {
        currentConversation = nil
        
        let inbox = ConnectRequestsViewController()
        pushContentViewController(inbox, focusOnView: focus, animated: animated)
    }
    
    /// Open the user clients detail screen
    ///
    /// - Parameter conversation: conversation to open
    func openDetailScreen(for conversation: ZMConversation) {
        let controller = GroupDetailsViewController(conversation: conversation)
        let navController = controller.wrapInNavigationController()
        navController.modalPresentationStyle = .formSheet

        present(navController, animated: true)
    }
    
    @objc
    private func dismissClientListController(_ sender: Any?) {
        dismiss(animated: true)
    }
    
    // MARK: - Animated conversation switch
    func dismissAllModalControllers(callback: Completion?) {
        let dismissAction = {
            if let rightViewController = self.wireSplitViewController.rightViewController,
                rightViewController.presentedViewController != nil {
                rightViewController.dismiss(animated: false, completion: callback)
            } else if let presentedViewController = self.conversationListViewController.presentedViewController {
                // This is a workaround around the fact that the transitioningDelegate of the settings
                // view controller is not called when the transition is not being performed animated.
                // This sounds like a bug in UIKit (Radar incoming) as I would expect the custom animator
                // being called with `transitionContext.isAnimated == false`. As this is not the case
                // we have to restore the proper pre-presentation state here.
                let conversationView = self.conversationListViewController.view
                if let transform = conversationView?.layer.transform {
                    if !CATransform3DIsIdentity(transform) || 1 != conversationView?.alpha {
                        conversationView?.layer.transform = CATransform3DIdentity
                        conversationView?.alpha = 1
                    }
                }
                
                presentedViewController.dismiss(animated: false, completion: callback)
            } else if self.presentedViewController != nil {
                self.dismiss(animated: false, completion: callback)
            } else {
                callback?()
            }
        }
        
        let ringingCallConversation = ZMUserSession.shared()?.ringingCallConversation
        
        if ringingCallConversation != nil {
            dismissAction()
        } else {
            minimizeCallOverlay(animated: true, withCompletion: dismissAction)
        }
    }
    
    // MARK: - Getters/Setters
    
    var context: ZMUserSession? {
        return ZMUserSession.shared()
    }
    
    // MARK: - ColorSchemeControllerDidApplyChangesNotification
    private func reloadCurrentConversation() {
        guard let currentConversation = currentConversation else { return }

        let currentConversationViewController = ConversationRootViewController(conversation: currentConversation, message: nil, clientViewController: self)
        
        // Need to reload conversation to apply color scheme changes
        pushContentViewController(currentConversationViewController)
    }
    
    @objc
    private func colorSchemeControllerDidApplyChanges(_ notification: Notification?) {
        reloadCurrentConversation()
    }
    
    // MARK: - Debug logging notifications
    @objc
    private func requestLoopNotification(_ notification: Notification?) {
        guard let path = notification?.userInfo?["path"] as? String else { return }
        DebugAlert.showSendLogsMessage(message: "A request loop is going on at \(path)")
    }
    
    @objc
    private func inconsistentStateNotification(_ notification: Notification?) {
        if let userInfo = notification?.userInfo?[ZMLoggingDescriptionKey] {
            DebugAlert.showSendLogsMessage(message: "We detected an inconsistent state: \(userInfo)")
        }
    }
    
    /// Attempt to load the last viewed conversation associated with the current account.
    /// If no info is available, we attempt to load the first conversation in the list.
    ///
    ///
    /// - Parameters:
    ///   - focus: <#focus description#>
    ///   - animated: <#animated description#>
    /// - Returns: In the first case, YES is returned, otherwise NO.
    @discardableResult
    private func attemptToLoadLastViewedConversation(withFocus focus: Bool, animated: Bool) -> Bool {

        if let currentAccount = SessionManager.shared?.accountManager.selectedAccount {
            if let conversation = Settings.shared.lastViewedConversation(for: currentAccount) {
                select(conversation: conversation, focusOnView: focus, animated: animated)
            }
            
            // dispatch async here because it has to happen after the collection view has finished
            // laying out for the first time
            DispatchQueue.main.async(execute: {
                self.conversationListViewController.scrollToCurrentSelection(animated: false)
            })
            
            return true

        } else {
            selectListItemWhenNoPreviousItemSelected()
            return false
        }
    }
    
    /**
     * This handles the case where we have to select a list item on startup but there is no previous item saved
     */
    func selectListItemWhenNoPreviousItemSelected() {
        guard let userSession = ZMUserSession.shared() else { return }
        
        // check for conversations and pick the first one.. this can be tricky if there are pending updates and
        // we haven't synced yet, but for now we just pick the current first item
        let list = ZMConversationList.conversations(inUserSession: userSession) as? [ZMConversation]
        
        if let conversation = list?.first {
            // select the first conversation and don't focus on it
            select(conversation: conversation)
        } else {
            loadPlaceholderConversationController(animated: true)
        }
    }
    
    @objc
    func contentSizeCategoryDidChange(_ notification: Notification?) {
        reloadCurrentConversation()
    }

    private func setupAppearance() {
        GuestIndicator.appearance(whenContainedInInstancesOf: [StartUIView.self]).colorSchemeVariant = .dark
        UserCell.appearance(whenContainedInInstancesOf: [StartUIView.self]).colorSchemeVariant = .dark
        UserCell.appearance(whenContainedInInstancesOf: [StartUIView.self]).contentBackgroundColor = .clear
        SectionHeader.appearance(whenContainedInInstancesOf: [StartUIView.self]).colorSchemeVariant = .dark
        GroupConversationCell.appearance(whenContainedInInstancesOf: [StartUIView.self]).colorSchemeVariant = .dark
        GroupConversationCell.appearance(whenContainedInInstancesOf: [StartUIView.self]).contentBackgroundColor = .clear
        OpenServicesAdminCell.appearance(whenContainedInInstancesOf: [StartUIView.self]).colorSchemeVariant = .dark
        OpenServicesAdminCell.appearance(whenContainedInInstancesOf: [StartUIView.self]).contentBackgroundColor = .clear
        
        
        let labelColor: UIColor
        if #available(iOS 13.0, *) {
            labelColor = .label
        } else {
            labelColor = ColorScheme.default.color(named: .textForeground, variant: .light)
        }

        UIView.appearance(whenContainedInInstancesOf: [UIAlertController.self]).tintColor = labelColor
    }

    // MARK: - Setup methods
    
    func transitionToList(animated: Bool, completion: Completion?) {
        transitionToList(animated: animated,
                         leftViewControllerRevealed: true,
                         completion: completion)
    }

    func transitionToList(animated: Bool,
                          leftViewControllerRevealed: Bool = true,
                          completion: Completion?) {
        let action: Completion = { [weak self] in
            self?.wireSplitViewController.setLeftViewControllerRevealed(leftViewControllerRevealed, animated: animated, completion: completion)
        }
        
        if let presentedViewController = wireSplitViewController.rightViewController?.presentedViewController {
            presentedViewController.dismiss(animated: animated, completion: action)
        } else {
            action()
        }
        
    }


    func setTopOverlay(to viewController: UIViewController?, animated: Bool = true) {
        topOverlayViewController?.willMove(toParent: nil)
        
        if let previousViewController = topOverlayViewController, let viewController = viewController {
            addChild(viewController)
            viewController.view.frame = topOverlayContainer.bounds
            viewController.view.translatesAutoresizingMaskIntoConstraints = false
            
            if animated {
                transition(from: previousViewController,
                           to: viewController,
                           duration: 0.5,
                           options: .transitionCrossDissolve,
                           animations: { viewController.view.fitInSuperview() },
                           completion: { (finished) in
                            viewController.didMove(toParent: self)
                            previousViewController.removeFromParent()
                            self.topOverlayViewController = viewController
                            self.updateSplitViewTopConstraint()
                            })
            } else {
                topOverlayContainer.addSubview(viewController.view)
                viewController.view.fitInSuperview()
                viewController.didMove(toParent: self)
                topOverlayViewController = viewController
                updateSplitViewTopConstraint()
            }
        } else if let previousViewController = topOverlayViewController {
            if animated {
                let heightConstraint = topOverlayContainer.heightAnchor.constraint(equalToConstant: 0)
                
                UIView.animate(withDuration: 0.35, delay: 0, options: [.curveEaseIn, .beginFromCurrentState], animations: {
                    heightConstraint.isActive = true
                    
                    self.view.setNeedsLayout()
                    self.view.layoutIfNeeded()
                }) { _ in
                    heightConstraint.isActive = false
                    
                    self.topOverlayViewController?.removeFromParent()
                    previousViewController.view.removeFromSuperview()
                    self.topOverlayViewController = nil
                    self.updateSplitViewTopConstraint()
                }
            } else {
                self.topOverlayViewController?.removeFromParent()
                previousViewController.view.removeFromSuperview()
                self.topOverlayViewController = nil
                self.updateSplitViewTopConstraint()
            }
        } else if let viewController = viewController {
            addChild(viewController)
            viewController.view.frame = topOverlayContainer.bounds
            viewController.view.translatesAutoresizingMaskIntoConstraints = false
            topOverlayContainer.addSubview(viewController.view)
            viewController.view.fitInSuperview()
            
            viewController.didMove(toParent: self)
            
            let isRegularContainer = traitCollection.horizontalSizeClass == .regular
            
            if animated && !isRegularContainer {
                let heightConstraint = viewController.view.heightAnchor.constraint(equalToConstant: 0)
                heightConstraint.isActive = true
                
                self.topOverlayViewController = viewController
                self.updateSplitViewTopConstraint()
                
                UIView.animate(withDuration: 0.35, delay: 0, options: [.curveEaseOut, .beginFromCurrentState], animations: {
                    heightConstraint.isActive = false
                    self.view.layoutIfNeeded()
                })
            }
            else {
                topOverlayViewController = viewController
                updateSplitViewTopConstraint()
            }
        }
    }

    private func createLegalHoldDisclosureController() {
        legalHoldDisclosureController = LegalHoldDisclosureController(selfUser: ZMUser.selfUser(), userSession: ZMUserSession.shared(), presenter: { viewController, animated, completion in
            viewController.presentTopmost(animated: animated, completion: completion)
        })
    }
    
    private func createTopViewConstraints() {
        
        topOverlayContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(topOverlayContainer)

        contentTopRegularConstraint = topOverlayContainer.topAnchor.constraint(equalTo: safeTopAnchor)
        contentTopCompactConstraint = topOverlayContainer.topAnchor.constraint(equalTo: view.topAnchor)
        
        NSLayoutConstraint.activate([
            topOverlayContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topOverlayContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topOverlayContainer.bottomAnchor.constraint(equalTo: wireSplitViewController.view.topAnchor),
            wireSplitViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            wireSplitViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            wireSplitViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            ])

        let heightConstraint = topOverlayContainer.heightAnchor.constraint(equalToConstant: 0)
        heightConstraint.priority = UILayoutPriority.defaultLow
        heightConstraint.isActive = true
    }

    private func updateSplitViewTopConstraint() {

        let isRegularContainer = traitCollection.horizontalSizeClass == .regular
        
        if isRegularContainer && nil == topOverlayViewController {
            contentTopCompactConstraint.isActive = false
            contentTopRegularConstraint.isActive = true
        } else {
            contentTopRegularConstraint.isActive = false
            contentTopCompactConstraint.isActive = true
        }

    }


    /// Open the user client list screen
    ///
    /// - Parameter user: the UserType with client list to show
    
    func openClientListScreen(for user: UserType) {
        var viewController: UIViewController?

        if user.isSelfUser, let clients = user.allClients as? [UserClient] {
            let clientListViewController = ClientListViewController(clientsList: clients, credentials: nil, detailedView: true, showTemporary: true, variant: ColorScheme.default.variant)
            clientListViewController.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissClientListController(_:)))
            viewController = clientListViewController
        } else {
            let profileViewController = ProfileViewController(user: user, viewer: ZMUser.selfUser(), context: .deviceList)

            if let conversationViewController = (conversationRootViewController as? ConversationRootViewController)?.conversationViewController {
                profileViewController.delegate = conversationViewController

                profileViewController.viewControllerDismisser = conversationViewController
            }
            viewController = profileViewController
        }

        let navWrapperController: UINavigationController? = viewController?.wrapInNavigationController()
        navWrapperController?.modalPresentationStyle = .formSheet
        if let aController = navWrapperController {
            present(aController, animated: true)
        }
    }

    ///MARK: - select conversation

    /// Select a conversation and move the focus to the conversation view.
    ///
    /// - Parameters:
    ///   - conversation: the conversation to select
    ///   - message: scroll to  this message
    ///   - focus: focus on the view or not
    ///   - animated: perform animation or not
    ///   - completion: the completion block
    func select(conversation: ZMConversation,
                scrollTo message: ZMConversationMessage? = nil,
                focusOnView focus: Bool,
                animated: Bool,
                completion: Completion? = nil) {
        dismissAllModalControllers(callback: { [weak self] in
            self?.conversationListViewController.viewModel.select(conversation: conversation, scrollTo: message, focusOnView: focus, animated: animated, completion: completion)
        })
    }

    func select(conversation: ZMConversation) {
        conversationListViewController.viewModel.select(conversation: conversation)
    }

    var isConversationViewVisible: Bool {
        return wireSplitViewController.isConversationViewVisible
    }

    var isConversationListVisible: Bool {
        return (wireSplitViewController.layoutSize == .regularLandscape) ||
            (wireSplitViewController.isLeftViewControllerRevealed && conversationListViewController.presentedViewController == nil)
    }

    func minimizeCallOverlay(animated: Bool,
                             withCompletion completion: Completion?) {
        router?.minimizeCallOverlay(animated: animated, withCompletion: completion)
    }
}
