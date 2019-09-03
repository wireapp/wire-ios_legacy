
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
    let account: Account

    /// private
    private var viewDidAppearCalled = false
    private static let contentControllerBottomInset: CGFloat = 16

    /// for NetworkStatusViewDelegate
    var shouldAnimateNetworkStatusView = false

    var isComingFromSetUsername = false
    var startCallToken: Any?

    var actionsController: ConversationActionController?

    /// observer tokens which are assigned when viewDidLoad
    var userObserverToken: Any?
    var allConversationsObserverToken: Any?
    var connectionRequestsObserverToken: Any?
    var initialSyncObserverToken: Any?
    var userProfileObserverToken: Any?

    weak var userProfile: UserProfile? = ZMUserSession.shared()?.userProfile

    var pushPermissionDeniedViewController: PermissionDeniedViewController?
    var usernameTakeoverViewController: UserNameTakeOverViewController?

    private let noConversationLabel: UILabel = {
        let label = UILabel()
        label.attributedText = NSAttributedString.attributedTextForNoConversationLabel
        label.numberOfLines = 0
        label.backgroundColor = .clear
        
        return label
    }()

    let contentContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .clear

        return view
    }()

    let listContentController: ConversationListContentController = {
        let conversationListContentController = ConversationListContentController()
        conversationListContentController.collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: ConversationListViewController.contentControllerBottomInset, right: 0)

        return conversationListContentController
    }()

    let bottomBarController: ConversationListBottomBarController = {
        let conversationListBottomBarController = ConversationListBottomBarController()
        conversationListBottomBarController.showArchived = true

        return conversationListBottomBarController
    }()

    let topBarViewController: ConversationListTopBarViewController
    let networkStatusViewController: NetworkStatusViewController = {
        let viewController = NetworkStatusViewController()
        return viewController
    }()

    let conversationListContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .clear

        return view
    }()

    var bottomBarBottomOffset: NSLayoutConstraint?
    var bottomBarToolTipConstraint: NSLayoutConstraint?

    let onboardingHint: ConversationListOnboardingHint = {
        let conversationListOnboardingHint = ConversationListOnboardingHint()
        return conversationListOnboardingHint
    }()

    required init(account: Account,
                  selfUser: SelfUserType = ZMUser.selfUser()) {
        self.account = account
        topBarViewController = ConversationListTopBarViewController(account: account, selfUser: selfUser)

        super.init(nibName:nil, bundle:nil)

        definesPresentationContext = true

        /// setup UI
        view.addSubview(contentContainer)

        contentContainer.addSubview(onboardingHint)
        contentContainer.addSubview(conversationListContainer)

        setupNoConversationLabel()
        setupListContentController()
        setupBottomBarController()
        setupTopBar()
        setupNetworkStatusBar()

        createViewConstraints()
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

        /// update
        hideNoContactLabel(animated: false)
        updateNoConversationVisibility()
        updateArchiveButtonVisibility()
        updateObserverTokensForActiveTeam()
        showPushPermissionDeniedDialogIfNeeded()

        setupObservers()

        listContentController.collectionView.scrollRectToVisible(CGRect(x: 0, y: 0, width: view.bounds.size.width, height: 1), animated: false)
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

    fileprivate func setupObservers() {
        if let userSession = ZMUserSession.shared(),
            let selfUser = ZMUser.selfUser() {
            userObserverToken = UserChangeInfo.add(observer: self, for: selfUser, userSession: userSession) as Any

            initialSyncObserverToken = ZMUserSession.addInitialSyncCompletionObserver(self, userSession: userSession)
        }
    }

    fileprivate func setupNoConversationLabel() {
        contentContainer.addSubview(noConversationLabel)
    }

    fileprivate func setupBottomBarController() {
        bottomBarController.delegate = self
        addChild(bottomBarController)
        conversationListContainer.addSubview(bottomBarController.view)
        bottomBarController.didMove(toParent: self)
    }

    fileprivate func setupListContentController() {
        listContentController.contentDelegate = self

        addChild(listContentController)
        conversationListContainer.addSubview(listContentController.view)
        listContentController.didMove(toParent: self)
    }
    
    fileprivate func setupTopBar() {
        addChild(topBarViewController)
        contentContainer.addSubview(topBarViewController.view)
        topBarViewController.didMove(toParent: self)
    }
    
    fileprivate func setupNetworkStatusBar() {
        networkStatusViewController.delegate = self
        addToSelf(networkStatusViewController)
    }

    fileprivate func createViewConstraints() {
        guard let bottomBar = bottomBarController.view,
            let listContent = listContentController.view,
            let topBarView = topBarViewController.view else { return }
        
        [conversationListContainer,
         bottomBar,
         networkStatusViewController.view,
         topBarView,
         contentContainer,
         noConversationLabel,
         onboardingHint,
         listContent].forEach() { $0?.translatesAutoresizingMaskIntoConstraints = false }
        
        let bottomBarBottomOffset = bottomBar.bottomAnchor.constraint(equalTo: bottomBar.superview!.bottomAnchor)
        
        let constraints: [NSLayoutConstraint] = [
            conversationListContainer.bottomAnchor.constraint(equalTo: conversationListContainer.superview!.bottomAnchor),
            conversationListContainer.leadingAnchor.constraint(equalTo: conversationListContainer.superview!.leadingAnchor),
            conversationListContainer.trailingAnchor.constraint(equalTo: conversationListContainer.superview!.trailingAnchor),
            
            bottomBar.leftAnchor.constraint(equalTo: bottomBar.superview!.leftAnchor),
            bottomBar.rightAnchor.constraint(equalTo: bottomBar.superview!.rightAnchor),
            bottomBarBottomOffset,
            
            topBarView.leftAnchor.constraint(equalTo: topBarView.superview!.leftAnchor),
            topBarView.rightAnchor.constraint(equalTo: topBarView.superview!.rightAnchor),
            topBarView.bottomAnchor.constraint(equalTo: conversationListContainer.topAnchor),
            
            contentContainer.bottomAnchor.constraint(equalTo: safeBottomAnchor),
            contentContainer.topAnchor.constraint(equalTo: safeTopAnchor),
            contentContainer.leadingAnchor.constraint(equalTo: view.safeLeadingAnchor),
            contentContainer.trailingAnchor.constraint(equalTo: view.safeTrailingAnchor),
            
            noConversationLabel.centerXAnchor.constraint(equalTo: noConversationLabel.superview!.centerXAnchor),
            noConversationLabel.centerYAnchor.constraint(equalTo: noConversationLabel.superview!.centerYAnchor),
            noConversationLabel.heightAnchor.constraint(equalToConstant: 120),
            noConversationLabel.widthAnchor.constraint(equalToConstant: 240),
            
            onboardingHint.bottomAnchor.constraint(equalTo: bottomBar.topAnchor),
            onboardingHint.leftAnchor.constraint(equalTo: onboardingHint.superview!.leftAnchor),
            onboardingHint.rightAnchor.constraint(equalTo: onboardingHint.superview!.rightAnchor),
            
            listContent.topAnchor.constraint(equalTo: listContent.superview!.topAnchor),
            listContent.leadingAnchor.constraint(equalTo: listContent.superview!.leadingAnchor),
            listContent.trailingAnchor.constraint(equalTo: listContent.superview!.trailingAnchor),
            listContent.bottomAnchor.constraint(equalTo: bottomBar.topAnchor)
        ]
        
        self.bottomBarBottomOffset = bottomBarBottomOffset
        
        ///TODO: merge this method and activate the constraints in a batch
        networkStatusViewController.createConstraintsInParentController(bottomView: topBarView, controller: self)
        
        NSLayoutConstraint.activate(constraints)
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
                self.noConversationLabel.alpha = ZMConversationList.hasArchivedConversations ? 1.0 : 0.0
                self.onboardingHint.alpha = ZMConversationList.hasArchivedConversations ? 0.0 : 1.0
            })
        }
    }

    func hideNoContactLabel(animated: Bool) {
        UIView.animate(withDuration: animated ? 0.20 : 0.0, animations: {
            self.noConversationLabel.alpha = 0.0
            self.onboardingHint.alpha = 0.0
        })
    }

    func updateNoConversationVisibility() {
        if !ZMConversationList.hasConversations {
            showNoContactLabel()
        } else {
            hideNoContactLabel(animated: true)
        }
    }

    func updateBottomBarSeparatorVisibility(with controller: ConversationListContentController) {
        let controllerHeight = controller.view.bounds.height
        let contentHeight = controller.collectionView.contentSize.height
        let offsetY = controller.collectionView.contentOffset.y
        let showSeparator = contentHeight - offsetY + ConversationListViewController.contentControllerBottomInset > controllerHeight

        if bottomBarController.showSeparator != showSeparator {
            bottomBarController.showSeparator = showSeparator
        }
    }

}

extension ZMConversationList {
    static var hasConversations: Bool {
        guard let session = ZMUserSession.shared() else { return false }
        
        let conversationsCount = ZMConversationList.conversations(inUserSession: session).count + ZMConversationList.pendingConnectionConversations(inUserSession: session).count
        return conversationsCount > 0
    }
    
    static var hasArchivedConversations: Bool {
        guard let session = ZMUserSession.shared() else { return false }
        
        return ZMConversationList.archivedConversations(inUserSession: session).count > 0
    }

}

fileprivate extension NSAttributedString {
    static var attributedTextForNoConversationLabel: NSAttributedString? {
        guard let paragraphStyle = NSParagraphStyle.default as? NSMutableParagraphStyle else { return nil }
        paragraphStyle.paragraphSpacing = 10
        paragraphStyle.alignment = .center
        
        let titleAttributes: [NSAttributedString.Key : Any] = [
            NSAttributedString.Key.foregroundColor: UIColor.white,
            NSAttributedString.Key.font: UIFont.smallMediumFont,
            NSAttributedString.Key.paragraphStyle: paragraphStyle
        ]
        
        paragraphStyle.paragraphSpacing = 4
        
        let titleString = "conversation_list.empty.all_archived.message".localized
        
        let attributedString = NSAttributedString(string: titleString.uppercased(), attributes: titleAttributes)
        
        return attributedString
    }
}
