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


import Foundation

final class ZClientViewController: UIViewController {
    private(set) var conversationRootViewController: UIViewController?
    private(set) var currentConversation: ZMConversation?
    var isComingFromRegistration = false
    var needToShowDataUsagePermissionDialog = false
    private(set) var splitViewController: SplitViewController?
    private(set) var mediaPlaybackManager: MediaPlaybackManager?
    private(set) var conversationListViewController: ConversationListViewController?
    var proximityMonitorManager: ProximityMonitorManager?
    var legalHoldDisclosureController: LegalHoldDisclosureController?
    
    var userObserverToken: Any?
    
    private var topOverlayContainer: UIView!
    private var topOverlayViewController: UIViewController?
    private var contentTopRegularConstraint: NSLayoutConstraint?
    private var contentTopCompactConstraint: NSLayoutConstraint?
    // init value = false which set to true, set to false after data usage permission dialog is displayed
    private var dataUsagePermissionDialogDisplayed = false
    private var backgroundViewController: BackgroundViewController?
    private var colorSchemeController: ColorSchemeController?
    private var analyticsEventPersistence: ShareExtensionAnalyticsPersistence?
    private var incomingApnsObserver: Any?
    private var networkAvailabilityObserverToken: Any?
    private var pendingInitialStateRestore = false
    
    func restoreStartupState() {
        pendingInitialStateRestore = false
        attemptToPresentInitialConversation()
    }
    
    func attemptToPresentInitialConversation() -> Bool {
        var stateRestored = false
        
        let lastViewedScreen = Settings.shared().lastViewedScreen
        switch lastViewedScreen {
        case SettingsLastScreenList:
            
            transitionToList(animated: false, completion: nil)
            
            // only attempt to show content vc if it would be visible
            if isConversationViewVisible {
                stateRestored = attemptToLoadLastViewedConversation(withFocus: false, animated: false)
            }
        case SettingsLastScreenConversation:
            
            stateRestored = attemptToLoadLastViewedConversation(withFocus: true, animated: false)
        default:
            // If there's no previously selected screen
            if isConversationViewVisible {
                selectListItemWhenNoPreviousItemSelected()
            }
        }
        return stateRestored
    }

    // MARK: - Overloaded methods
    deinit {
        AVSMediaManager.sharedInstance.unregisterMedia(mediaPlaybackManager)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        colorSchemeController = ColorSchemeController()
        pendingInitialStateRestore = true
        
        view.backgroundColor = UIColor.black
        
        conversationListViewController.view()
        
        splitViewController = SplitViewController()
        splitViewController.delegate = self
        addChildViewController(splitViewController)
        
        splitViewController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(splitViewController.view)
        
        createTopViewConstraints()
        splitViewController.didMove(toParent: self)
        updateSplitViewTopConstraint()
        
        splitViewController.view.backgroundColor = UIColor.clear
        
        createBackgroundViewController()
        
        if pendingInitialStateRestore {
            restoreStartupState()
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(colorSchemeControllerDidApplyChanges(_:)), name: NSNotification.colorSchemeControllerDidApplyColorSchemeChange, object: nil)
        
        if DeveloperMenuState.developerMenuEnabled() {
            //better way of dealing with this?
            NotificationCenter.default.addObserver(self, selector: #selector(requestLoopNotification(_:)), name: ZMLoggingRequestLoopNotificationName, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(inconsistentStateNotification(_:)), name: ZMLoggingInconsistentStateNotificationName, object: nil)
        }
        
        setupUserChangeInfoObserver()
    }

    private func reloadCurrentConversation() {
    }
    
    /**
     * Load and optionally show a conversation, but don't change the list selection.  This is the place to put
     * stuff if you definitely need it to happen when a conversation is selected and/or presented
     *
     * This method should only be called when the list selection changes, or internally by other zclientviewcontroller
     * methods.
     *
     * @return YES if it actually switched views, NO if nothing changed (ie: we were already looking at the conversation)
     */
    func load(_ conversation: ZMConversation?, scrollTo message: ZMConversationMessage?, focusOnView focus: Bool, animated: Bool) -> Bool {
    }
    
    func load(_ conversation: ZMConversation?, scrollTo message: ZMConversationMessage?, focusOnView focus: Bool, animated: Bool, completion: () -> ()? = nil) -> Bool {
    }
    
    func loadPlaceholderConversationController(animated: Bool) {
    }
    
    func loadPlaceholderConversationController(animated: Bool, completion: () -> ()? = nil) {
    }
    
    func loadIncomingContactRequestsAndFocus(onView focus: Bool, animated: Bool) {
    }
    
    func dismissClientListController(_ sender: Any?) {
    }

    class func shared() -> Self? {
    }
    
    /**
     * Select a conversation and move the focus to the conversation view.
     *
     * @return YES if it will actually switch, NO if the conversation is already selected.
     */
    func select(_ conversation: ZMConversation?, focusOnView focus: Bool, animated: Bool) {
    }
    
    /**
     * Open the user clients detail screen
     */
    func openDetailScreen(for conversation: ZMConversation?) {
    }
    
    /**
     * Select the connection inbox and optionally move focus to it.
     */
    func selectIncomingContactRequestsAndFocus(onView focus: Bool) {
    }
    
    /**
     * Exit the connection inbox.  This contains special logic for reselecting another conversation etc when you
     * have no more connection requests.
     */
    func hideIncomingContactRequests(withCompletion completion: () -> ()? = nil) {
    }
    
    func dismissAllModalControllers(withCallback callback: () -> ()? = nil) {
    }
    
    
    /// init method for testing allows injecting an Account object and self user
    ///
    /// - Parameters:
    ///   - account: an Account object
    ///   - selfUser: a SelfUserType object
    public convenience init(account: Account,
                            selfUser: SelfUserType) {
        self.init(nibName:nil, bundle:nil)
        
        proximityMonitorManager = ProximityMonitorManager()
        mediaPlaybackManager = MediaPlaybackManager(name: "conversationMedia")
        dataUsagePermissionDialogDisplayed = false
        needToShowDataUsagePermissionDialog = false
        
        AVSMediaManager.sharedInstance().register(mediaPlaybackManager, withOptions: [
            "media": "external "
            ])
        
        
        setupAddressBookHelper()
        
        if let appGroupIdentifier = Bundle.main.appGroupIdentifier,            
            let remoteIdentifier = ZMUser.selfUser().remoteIdentifier {
            let sharedContainerURL = FileManager.sharedContainerDirectory(for: appGroupIdentifier)
            
            let accountContainerURL = sharedContainerURL.appendingPathComponent("AccountData", isDirectory: true).appendingPathComponent(remoteIdentifier.uuidString, isDirectory: true)
            analyticsEventPersistence = ShareExtensionAnalyticsPersistence(accountContainer: accountContainerURL)
        }
        
        if let userSession = ZMUserSession.shared() {
            networkAvailabilityObserverToken = ZMNetworkAvailabilityChangeNotification.addNetworkAvailabilityObserver(self, userSession: userSession)
        }
        
        NotificationCenter.default.post(name: NSNotification.Name.ZMUserSessionDidBecomeAvailable, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(contentSizeCategoryDidChange(_:)), name: UIContentSizeCategory.didChangeNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillEnterForeground(_:)), name: UIApplication.willEnterForegroundNotification, object: nil)
        
        setupAppearance()
        
        createLegalHoldDisclosureController()
        setupConversationListViewController(account: account, selfUser: selfUser)
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
        UIView.appearance(whenContainedInInstancesOf: [UIAlertController.self]).tintColor = ColorScheme.default.color(named: .textForeground, variant: .light)
    }
    
    // MARK: - Adressbook Upload
    
    private func uploadAddressBookIfNeeded() {
        // We should not even try to access address book when in a team
        guard ZMUser.selfUser().hasTeam == false else { return }
        
        let addressBookDidBecomeGranted = AddressBookHelper.sharedHelper.accessStatusDidChangeToGranted
        AddressBookHelper.sharedHelper.startRemoteSearch(!addressBookDidBecomeGranted)
        AddressBookHelper.sharedHelper.persistCurrentAccessStatus()
    }

    // MARK: - Setup methods
    
    private func setupAddressBookHelper() {
        AddressBookHelper.sharedHelper.configuration = AutomationHelper.sharedHelper
    }

    private func setupConversationListViewController(account: Account, selfUser: SelfUserType) {
        conversationListViewController = ConversationListViewController(account: account, selfUser: selfUser)
    }

    override open var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return wr_supportedInterfaceOrientations
    }

    @objc(transitionToListAnimated:completion:)
    func transitionToList(animated: Bool, completion: (() -> ())?) {
        transitionToList(animated: animated,
                         leftViewControllerRevealed: true,
                         completion: completion)
    }

    func transitionToList(animated: Bool,
                          leftViewControllerRevealed: Bool = true,
                          completion: (() -> ())?) {
        if let presentedViewController = splitViewController.rightViewController?.presentedViewController {
            presentedViewController.dismiss(animated: animated) {
                self.splitViewController.setLeftViewControllerRevealed(leftViewControllerRevealed, animated: animated, completion: completion)
            }
        } else {
            splitViewController.setLeftViewControllerRevealed(leftViewControllerRevealed, animated: animated, completion: completion)
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
                            UIApplication.shared.wr_updateStatusBarForCurrentControllerAnimated(true)
                })
            } else {
                topOverlayContainer.addSubview(viewController.view)
                viewController.view.fitInSuperview()
                viewController.didMove(toParent: self)
                topOverlayViewController = viewController
                UIApplication.shared.wr_updateStatusBarForCurrentControllerAnimated(animated)
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
                
                self.view.setNeedsLayout()
                self.view.layoutIfNeeded()
                
                UIView.animate(withDuration: 0.35, delay: 0, options: [.curveEaseOut, .beginFromCurrentState], animations: {
                    heightConstraint.isActive = false
                    self.view.setNeedsLayout()
                    self.view.layoutIfNeeded()
                }) { _ in
                    UIApplication.shared.wr_updateStatusBarForCurrentControllerAnimated(animated)
                }
            }
            else {
                UIApplication.shared.wr_updateStatusBarForCurrentControllerAnimated(animated)
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
    
    @objc
    func createTopViewConstraints() {
        topOverlayContainer = UIView()
        topOverlayContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(topOverlayContainer)

        contentTopRegularConstraint = topOverlayContainer.topAnchor.constraint(equalTo: safeTopAnchor)
        contentTopCompactConstraint = topOverlayContainer.topAnchor.constraint(equalTo: view.topAnchor)
        
        NSLayoutConstraint.activate([
            topOverlayContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topOverlayContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topOverlayContainer.bottomAnchor.constraint(equalTo: splitViewController.view.topAnchor),
            splitViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            splitViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            splitViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            ])

        let heightConstraint = topOverlayContainer.heightAnchor.constraint(equalToConstant: 0)
        heightConstraint.priority = UILayoutPriority.defaultLow
        heightConstraint.isActive = true
    }

    @objc func updateSplitViewTopConstraint() {

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
    /// - Parameter user: the ZMUser with client list to show
    @objc(openClientListScreenForUser:)
    func openClientListScreen(for user: ZMUser) {
        var viewController: UIViewController?

        if user.isSelfUser {
            let clientListViewController = ClientListViewController(clientsList: Array(user.clients), credentials: nil, detailedView: true, showTemporary: true, variant: ColorScheme.default.variant)
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
    @objc(selectConversation:scrollToMessage:focusOnView:animated:completion:)
    func select(_ conversation: ZMConversation,
                scrollTo message: ZMConversationMessage?,
                focusOnView focus: Bool,
                animated: Bool,
                completion: Completion?) {
        dismissAllModalControllers(callback: { [weak self] in
            self?.conversationListViewController.viewModel.select(conversation, scrollTo: message, focusOnView: focus, animated: animated, completion: completion)
        })
    }

    @objc(selectConversation:)
    func select(_ conversation: ZMConversation) {
        conversationListViewController.viewModel.select(conversation)
    }

    @objc
    var isConversationViewVisible: Bool {
        return splitViewController.isConversationViewVisible
    }

    var isConversationListVisible: Bool {
        return (splitViewController.layoutSize == .regularLandscape) || (splitViewController.isLeftViewControllerRevealed && conversationListViewController.presentedViewController == nil)
    }

    @objc
    func minimizeCallOverlay(animated: Bool,
                             withCompletion completion: Completion?) {
        AppDelegate.shared().callWindowRootViewController?.minimizeOverlay(animated: animated, completion: completion)
    }

    // MARK: - Application State
    @objc
    private func applicationWillEnterForeground(_ notification: Notification?) {
        uploadAddressBookIfNeeded()
        trackShareExtensionEventsIfNeeded()
    }
    
    // MARK: -  Share extension analytics
    private func trackShareExtensionEventsIfNeeded() {
        let events: [StorableTrackingEvent] = analyticsEventPersistence.storedTrackingEvents.map { $0 }
        analyticsEventPersistence.clear()
        
        for event in events {
            Analytics.shared().tag(event)
        }
    }

}

//MARK: - ZMNetworkAvailabilityObserver

extension ZClientViewController: ZMNetworkAvailabilityObserver {
    public func didChangeAvailability(newState: ZMNetworkState) {
        if newState == .online && UIApplication.shared.applicationState == .active {
            uploadAddressBookIfNeeded()
        }
    }
}
