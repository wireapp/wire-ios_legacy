
// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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

enum ConversationListState {
    case conversationList
    case peoplePicker
    case archived
}

final class ConversationListViewController: UIViewController {
    /// internal View Model
    var state: ConversationListState = .conversationList
    var selectedConversation: ZMConversation?

    /// private
    private var viewDidAppearCalled = false
    private let contentControllerBottomInset: CGFloat = 16

    /// for NetworkStatusViewDelegate
    var shouldAnimateNetworkStatusView = false

    var isComingFromSetUsername = false
    var startCallToken: Any?
    var account: Account! ///TODO: optional?

    var noConversationLabel: UILabel!
    var actionsController: ConversationActionController?
    //@property (readwrite, nonatomic, nonnull) UIView *contentContainer; ///TODO: private set

    /// oberser Tokens which are assigned when viewDidLoad
    var userObserverToken: Any?
    var allConversationsObserverToken: Any?
    var connectionRequestsObserverToken: Any?
    var initialSyncObserverToken: Any?
    var userProfileObserverToken: Any?

    weak var userProfile: UserProfile? = ZMUserSession.shared()?.userProfile

    var pushPermissionDeniedViewController: PermissionDeniedViewController?
    var usernameTakeoverViewController: UserNameTakeOverViewController?
    ///TODO: non-optional
    let contentContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .clear

        return view
    }()

    var listContentController: ConversationListContentController!
    var bottomBarController: ConversationListBottomBarController!
    var topBarViewController: ConversationListTopBarViewController?
    var networkStatusViewController: NetworkStatusViewController!

    var conversationListContainer: UIView?
    var bottomBarBottomOffset: NSLayoutConstraint?
    var bottomBarToolTipConstraint: NSLayoutConstraint?

    var onboardingHint: ConversationListOnboardingHint?

    init() {
        super.init(nibName:nil, bundle:nil)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        removeUserProfileObserver()
    }

    override func loadView() {
        view = PassthroughTouchesView(frame: UIScreen.main.bounds)
        view.backgroundColor = .clear
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        definesPresentationContext = true

        view.addSubview(contentContainer)

        let onboardingHint = ConversationListOnboardingHint()
        contentContainer.addSubview(onboardingHint)
        self.onboardingHint = onboardingHint

        let conversationListContainer = UIView()
        conversationListContainer.backgroundColor = .clear
        contentContainer.addSubview(conversationListContainer)
        self.conversationListContainer = conversationListContainer

        createNoConversationLabel()
        createListContentController()
        createBottomBarController()
        createTopBar()
        createNetworkStatusBar()

        createViewConstraints()
        listContentController.collectionView.scrollRectToVisible(CGRect(x: 0, y: 0, width: view.bounds.size.width, height: 1), animated: false)

        topBarViewController?.didMove(toParent: self)

        hideNoContactLabel(animated: false)
        updateNoConversationVisibility()
        updateArchiveButtonVisibility()

        updateObserverTokensForActiveTeam()
        showPushPermissionDeniedDialogIfNeeded()

        noConversationLabel.backgroundColor = .clear

        setupObservers()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        ZMUserSession.shared()?.enqueueChanges({
            self.selectedConversation?.savePendingLastRead()
        })

        requestSuggestedHandlesIfNeeded()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if !isIPadRegular() {
            Settings.shared().lastViewedScreen = SettingsLastScreen.list
        }

        state = .conversationList

        updateBottomBarSeparatorVisibility(with: listContentController)
        closePushPermissionDialogIfNotNeeded()

        shouldAnimateNetworkStatusView = true

        if !viewDidAppearCalled {
            viewDidAppearCalled = true
            ZClientViewController.shared()?.showDataUsagePermissionDialogIfNeeded()
            ZClientViewController.shared()?.showAvailabilityBehaviourChangeAlertIfNeeded()
        }
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        if let presentedViewController = presentedViewController,
            presentedViewController is UIAlertController {
            return presentedViewController.preferredStatusBarStyle
        }

        return .lightContent
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animate(alongsideTransition: { context in
            // we reload on rotation to make sure that the list cells lay themselves out correctly for the new
            // orientation
            self.listContentController.reload()
        })

        super.viewWillTransition(to: size, with: coordinator)
    }

    override var shouldAutorotate: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }

    // MARK: - setup UI

    func setupObservers() {
        if let userSession = ZMUserSession.shared(),
            let selfUser = ZMUser.selfUser() {
            userObserverToken = UserChangeInfo.add(observer: self, for: selfUser, userSession: userSession) as Any

            initialSyncObserverToken = ZMUserSession.addInitialSyncCompletionObserver(self, userSession: userSession)
        }
    }

    func createNoConversationLabel() {
        noConversationLabel = UILabel()
        noConversationLabel.attributedText = NSAttributedString.attributedTextForNoConversationLabel
        noConversationLabel.numberOfLines = 0
        contentContainer.addSubview(noConversationLabel)
    }

    func createBottomBarController() {
        bottomBarController = ConversationListBottomBarController(delegate: self)
        bottomBarController.showArchived = true
        addChild(bottomBarController)
        conversationListContainer?.addSubview(bottomBarController.view)
        bottomBarController.didMove(toParent: self)
    }

    func createListContentController() {
        listContentController = ConversationListContentController()
        listContentController.collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: contentControllerBottomInset, right: 0)
        listContentController.contentDelegate = self

        addChild(listContentController)
        conversationListContainer?.addSubview(listContentController.view)
        listContentController.didMove(toParent: self)
    }

    func createArchivedListViewController() -> ArchivedListViewController {
        let archivedViewController = ArchivedListViewController()
        archivedViewController.delegate = self
        return archivedViewController
    }

    func setBackgroundColorPreference(_ color: UIColor?) {
        UIView.animate(withDuration: 0.4, animations: {
            self.view.backgroundColor = color
            self.listContentController.view.backgroundColor = color
        })
    }

    func showNoContactLabel() {
        if state == .conversationList {
            UIView.animate(withDuration: 0.20, animations: {
                self.noConversationLabel.alpha = self.hasArchivedConversations ? 1.0 : 0.0
                self.onboardingHint?.alpha = self.hasArchivedConversations ? 0.0 : 1.0
            })
        }
    }

    func hideNoContactLabel(animated: Bool) {
        UIView.animate(withDuration: animated ? 0.20 : 0.0, animations: {
            self.noConversationLabel.alpha = 0.0
            self.onboardingHint?.alpha = 0.0
        })
    }

    func updateNoConversationVisibility() {
        if !hasConversations {
            showNoContactLabel()
        } else {
            hideNoContactLabel(animated: true)
        }
    }

    var hasConversations: Bool {
        guard let session = ZMUserSession.shared() else { return false }

        let conversationsCount = ZMConversationList.conversations(inUserSession: session).count + ZMConversationList.pendingConnectionConversations(inUserSession: session).count
        return conversationsCount > 0
    }

    var hasArchivedConversations: Bool {
        guard let session = ZMUserSession.shared() else { return false }

        return ZMConversationList.archivedConversations(inUserSession: session).count > 0
    }

    func updateBottomBarSeparatorVisibility(with controller: ConversationListContentController) {
        let controllerHeight = controller.view.bounds.height
        let contentHeight = controller.collectionView.contentSize.height
        let offsetY = controller.collectionView.contentOffset.y
        let showSeparator = contentHeight - offsetY + contentControllerBottomInset > controllerHeight

        if bottomBarController.showSeparator != showSeparator {
            bottomBarController.showSeparator = showSeparator
        }
    }

}
