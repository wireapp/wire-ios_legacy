
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
    ///internal
    var state: ConversationListState?

    var selectedConversation: ZMConversation? ///TODO: private
    var isComingFromSetUsername = false
    var startCallToken: Any?
    var account: Account! ///TODO: optional?

    var noConversationLabel: UILabel!
    var actionsController: ConversationActionController?
    var viewDidAppearCalled = false
    //@property (readwrite, nonatomic, nonnull) UIView *contentContainer; ///TODO: private set

    /// oberser Tokens which are assigned when viewDidLoad
    var userObserverToken: Any?
    var allConversationsObserverToken: Any?
    var connectionRequestsObserverToken: Any?
    var initialSyncObserverToken: Any?
    var userProfileObserverToken: NSObject?

    weak var userProfile: UserProfile?

    var pushPermissionDeniedViewController: PermissionDeniedViewController?
    var usernameTakeoverViewController: UserNameTakeOverViewController?
    ///TODO: non-optional
    var contentContainer: UIView!
    var listContentController: ConversationListContentController!
    var bottomBarController: ConversationListBottomBarController!
    var topBarViewController: ConversationListTopBarViewController!
    var networkStatusViewController: NetworkStatusViewController!

    /// for NetworkStatusViewDelegate
    var shouldAnimateNetworkStatusView = false
    var conversationListContainer: UIView?
    var bottomBarBottomOffset: NSLayoutConstraint?
    var bottomBarToolTipConstraint: NSLayoutConstraint?
    var contentControllerBottomInset: CGFloat = 0.0

    var onboardingHint: ConversationListOnboardingHint?

    func setSelectedConversation(_ conversation: ZMConversation) {
        selectedConversation = conversation
    }

    ///TODO: rm
    func setStateValue(_ newState: ConversationListState) {
        state = newState
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
        viewDidAppearCalled = false
        definesPresentationContext = true

        contentControllerBottomInset = 16
        shouldAnimateNetworkStatusView = false

        contentContainer = UIView()
        contentContainer.backgroundColor = .clear
        view.addSubview(contentContainer)

        userProfile = ZMUserSession.shared()?.userProfile

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

        topBarViewController.didMove(toParent: self)

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

        setStateValue(.conversationList)

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

}
