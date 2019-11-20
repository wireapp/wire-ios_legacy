//
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

import UIKit

private let zmLog = ZMSLog(tag: "ProfileViewController")

enum ProfileViewControllerTabBarIndex : Int {
    case details = 0
    case devices
}

enum ProfileViewControllerContext : Int {
    case search
    case groupConversation
    case oneToOneConversation
    case deviceList
    /// when opening from a URL scheme, not linked to a specific conversation
    case profileViewer
}

protocol ProfileViewControllerDelegate: class {
    func suggestedBackButtonTitle(for controller: ProfileViewController?) -> String?
    func profileViewController(_ controller: ProfileViewController?, wantsToNavigateTo conversation: ZMConversation)
    func profileViewController(_ controller: ProfileViewController?, wantsToCreateConversationWithName name: String?, users: Set<ZMUser>)
}

final class ProfileViewController: UIViewController {
    
    private let bareUser: UserType
    private(set) var viewer: UserType
    weak var delegate: ProfileViewControllerDelegate?
    weak var viewControllerDismisser: ViewControllerDismisser?
    weak var navigationControllerDelegate: UINavigationControllerDelegate?
    
    private var context: ProfileViewControllerContext
    private var conversation: ZMConversation?
    private var profileFooterView: ProfileFooterView?
    private var incomingRequestFooter: IncomingRequestFooterView? ///TODO: create here
    private var usernameDetailsView: UserNameDetailView?
    private var profileTitleView: ProfileTitleView?
    private var tabsController: TabBarController?
    
    private var observerToken: Any?
    
    convenience init(user: UserType, viewer: UserType, context: ProfileViewControllerContext) {
        self.init(user: user, viewer: viewer, conversation: nil, context: context)
    }
    
    convenience init(user: UserType, viewer: UserType, conversation: ZMConversation?) {
        let context: ProfileViewControllerContext
        if conversation?.conversationType == .group {
            context = .groupConversation
        } else {
            context = .oneToOneConversation
        }
        
        self.init(user: user, viewer: viewer, conversation: conversation, context: context)
    }
    
    convenience init(user: UserType, viewer: UserType, conversation: ZMConversation?, viewControllerDismisser: ViewControllerDismisser) {
        self.init(user: user, viewer: viewer, conversation: conversation)
        self.viewControllerDismisser = viewControllerDismisser
    }

    init(user: UserType, viewer: UserType, conversation: ZMConversation?, context: ProfileViewControllerContext) {
        bareUser = user
        self.viewer = viewer
        self.conversation = conversation
        self.context = context

        super.init(nibName: nil, bundle: nil)

        setupKeyboardFrameNotification()
    }
    
    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func dismissButtonClicked() { ///TODO: remove
        requestDismissal(withCompletion: { })
    }
    
    private func requestDismissal(withCompletion completion: @escaping () -> ()) {
        viewControllerDismisser?.dismiss(viewController: self, completion: completion)
    }
    
    private func setupNavigationItems() {
        let legalHoldItem: UIBarButtonItem?
        if bareUser.isUnderLegalHold || conversation?.isUnderLegalHold == true {
            legalHoldItem = legalholdItem
        } else {
            legalHoldItem = nil
        }
        
        if navigationController?.viewControllers.count == 1 {
            navigationItem.rightBarButtonItem = navigationController?.closeItem()
            navigationItem.leftBarButtonItem = legalHoldItem
        } else {
            navigationItem.rightBarButtonItem = legalHoldItem
        }
    }
    
    // MARK: - Header
    private func setupHeader() {
        let viewModel = makeUserNameDetailViewModel()
        let usernameDetailsView = UserNameDetailView()
        usernameDetailsView.configure(with: viewModel)
        view.addSubview(usernameDetailsView)
        self.usernameDetailsView = usernameDetailsView
        
        let titleView = ProfileTitleView()
        titleView.configure(with: viewModel)
        
        titleView.translatesAutoresizingMaskIntoConstraints = false
        if #available(iOS 11, *) {
            navigationItem.titleView = titleView
        } else {
            titleView.setNeedsLayout()
            titleView.layoutIfNeeded()
            titleView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            titleView.translatesAutoresizingMaskIntoConstraints = true
        }
        
        navigationItem.titleView = titleView
        profileTitleView = titleView
    }
    
    private func updateShowVerifiedShield() {
        if let user = bareUser.zmUser {
            let showShield = user.trusted() &&
                !user.clients.isEmpty &&
                context != .deviceList &&
                tabsController?.selectedIndex != ProfileViewControllerTabBarIndex.devices.rawValue && ZMUser.selfUser().trusted()
            
            profileTitleView?.showVerifiedShield = showShield
        } else {
            profileTitleView?.showVerifiedShield = false
        }
    }
    
    private var fullUser: ZMUser? {
        return bareUser.zmUser
    }
    
    // MARK: - Actions
    private func bringUpConversationCreationFlow() {
        let users: Set<ZMUser>
        if let fullUser = fullUser {
            users = Set<ZMUser>([fullUser])
        } else {
            users = Set<ZMUser>()
        }

        let controller = ConversationCreationController(preSelectedParticipants: users)
        controller.delegate = self
        
        let wrappedController = controller.wrapInNavigationController()
        wrappedController.modalPresentationStyle = .formSheet
        present(wrappedController, animated: true)
    }
    
    private func bringUpCancelConnectionRequestSheet(from targetView: UIView) {
        guard let fullUser = fullUser else { return }
        
        let controller = UIAlertController.cancelConnectionRequest(for: fullUser) { canceled in
            if !canceled {
                self.cancelConnectionRequest()
            }
        }
        
        presentAlert(controller, targetView: targetView)
    }
    
    private func cancelConnectionRequest() {
        let user = fullUser
        ZMUserSession.shared()?.enqueueChanges({
            user?.cancelConnectionRequest()
            self.returnToPreviousScreen()
        })
    }
    
    private func openOneToOneConversation() {
        guard let fullUser = fullUser else {
            zmLog.error("No user to open conversation with")
            return
        }
        var conversation: ZMConversation! = nil
        
        ZMUserSession.shared()?.enqueueChanges({
            conversation = fullUser.oneToOneConversation
        }, completionHandler: {
            self.delegate?.profileViewController(self, wantsToNavigateTo: conversation)
        })
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return ColorScheme.default.statusBarStyle
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        profileFooterView = ProfileFooterView()
        view.addSubview(profileFooterView!)
        
        incomingRequestFooter = IncomingRequestFooterView()
        view.addSubview(incomingRequestFooter!)
        
        view.backgroundColor = UIColor.from(scheme: .barBackground)
        
        if let fullUser = fullUser,
           let userSession = ZMUserSession.shared() {
            observerToken = UserChangeInfo.add(observer: self, for: fullUser, userSession: userSession)
        }
        
        setupNavigationItems()
        setupHeader()
        setupTabsController()
        setupConstraints()
        updateFooterViews()
        updateShowVerifiedShield()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UIApplication.shared.wr_updateStatusBarForCurrentControllerAnimated(animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UIApplication.shared.wr_updateStatusBarForCurrentControllerAnimated(animated)
        UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged, argument: navigationItem.titleView)
    }
    
    // MARK: - Keyboard frame observer
    
    private func setupKeyboardFrameNotification() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardFrameDidChange(notification:)),
                                               name: UIResponder.keyboardDidChangeFrameNotification,
                                               object: nil)
        
    }
    
    @objc
    private func keyboardFrameDidChange(notification: Notification) {
        updatePopoverFrame()
    }
    
    // MARK: - init
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return wr_supportedInterfaceOrientations
    }
    
    private func setupProfileDetailsViewController() -> ProfileDetailsViewController {
        let profileDetailsViewController = ProfileDetailsViewController(user: bareUser,
                                                                        viewer: viewer,
                                                                        conversation: conversation,
                                                                        context: context)
        profileDetailsViewController.title = "profile.details.title".localized
        
        return profileDetailsViewController
    }
    
    private func setupTabsController() {
        var viewControllers = [UIViewController]()
        
        let profileDetailsViewController = setupProfileDetailsViewController()
        viewControllers.append(profileDetailsViewController)
        
        if let fullUser = self.fullUser, context != .search && context != .profileViewer {
            let userClientListViewController = UserClientListViewController(user: fullUser)
            viewControllers.append(userClientListViewController)
        }
        
        tabsController = TabBarController(viewControllers: viewControllers) ///TODO: move to closure
        tabsController?.delegate = self
        
        if context == .deviceList, tabsController?.viewControllers.count > 1 {
            tabsController?.selectIndex(ProfileViewControllerTabBarIndex.devices.rawValue, animated: false)
        }
        
        addToSelf(tabsController!)
    }
    
    // MARK : - constraints
    
    private func setupConstraints() {
        usernameDetailsView?.translatesAutoresizingMaskIntoConstraints = false
        tabsController?.view.translatesAutoresizingMaskIntoConstraints = false
        profileFooterView?.translatesAutoresizingMaskIntoConstraints = false
        
        usernameDetailsView?.fitInSuperview(exclude: [.bottom]) ///TODO: clean up
        tabsController?.view?.topAnchor.constraint(equalTo: usernameDetailsView!.bottomAnchor).isActive = true
        tabsController?.view.fitInSuperview(exclude: [.top])
        profileFooterView?.fitInSuperview(exclude: [.top])
        
        incomingRequestFooter?.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            (incomingRequestFooter?.bottomAnchor.constraint(equalTo: profileFooterView!.topAnchor))!,
            (incomingRequestFooter?.leadingAnchor.constraint(equalTo: view.leadingAnchor))!,
            (incomingRequestFooter?.trailingAnchor.constraint(equalTo: view.trailingAnchor))!
            ])
    }
    
    // MARK: - Factories
    
    private func makeUserNameDetailViewModel() -> UserNameDetailViewModel {
        return UserNameDetailViewModel(user: bareUser, fallbackName: bareUser.displayName, addressBookName: fullUser?.addressBookEntry?.cachedName)
    }
    
}

extension ProfileViewController: ViewControllerDismisser {
    func dismiss(viewController: UIViewController, completion: (() -> ())?) {
        navigationController?.popViewController(animated: true)
    }
}

// MARK: - Footer View

extension ProfileViewController: ProfileFooterViewDelegate, IncomingRequestFooterViewDelegate {
    
    @objc
    func updateFooterViews() {
        // Actions
        let factory = ProfileActionsFactory(user: bareUser, viewer: viewer, conversation: conversation, context: context)
        let actions = factory.makeActionsList()
        
        profileFooterView?.delegate = self
        profileFooterView?.isHidden = actions.isEmpty
        profileFooterView?.configure(with: actions)
        view.bringSubviewToFront(profileFooterView!)
        
        // Incoming Request Footer
        incomingRequestFooter?.isHidden = !bareUser.isPendingApprovalBySelfUser
        incomingRequestFooter?.delegate = self
        view.bringSubviewToFront(incomingRequestFooter!)
    }
    
    func footerView(_ footerView: IncomingRequestFooterView, didRespondToRequestWithAction action: IncomingConnectionAction) {
        switch action {
        case .accept:
            acceptConnectionRequest()
        case .ignore:
            ignoreConnectionRequest()
        }
        
    }
    
    func footerView(_ footerView: ProfileFooterView, shouldPerformAction action: ProfileAction) {
        performAction(action, targetView: footerView.leftButton)
    }
    
    func footerView(_ footerView: ProfileFooterView, shouldPresentMenuWithActions actions: [ProfileAction]) {
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        for action in actions {
            let sheetAction = UIAlertAction(title: action.buttonText, style: .default) { _ in
                self.performAction(action, targetView: footerView)
            }
            
            actionSheet.addAction(sheetAction)
        }
        
        actionSheet.addAction(.cancel())
        presentAlert(actionSheet, targetView: footerView)
    }
    
    func performAction(_ action: ProfileAction, targetView: UIView) {
        switch action {
        case .createGroup:
            bringUpConversationCreationFlow()
        case .mute(let isMuted):
            updateMute(enableNotifications: isMuted)
        case .manageNotifications:
            presentNotificationsOptions(from: targetView)
        case .archive:
            archiveConversation()
        case .deleteContents:
            presentDeleteConfirmationPrompt(from: targetView)
        case .block:
            presentBlockRequest(from: targetView)
        case .openOneToOne:
            openOneToOneConversation()
        case .removeFromGroup:
            presentRemoveUserMenuSheetController(from: targetView)
        case .connect:
            sendConnectionRequest()
        case .cancelConnectionRequest:
            bringUpCancelConnectionRequestSheet(from: targetView)
        case .openSelfProfile:
            openSelfProfile()
        }
    }
    
    private func openSelfProfile() {
        ///do not reveal list view for iPad regular mode
        let leftViewControllerRevealed: Bool
        if let presentingViewController = presentingViewController {
            leftViewControllerRevealed = !presentingViewController.isIPadRegular(device: UIDevice.current)
        } else {
            leftViewControllerRevealed = true
        }
        
        dismiss(animated: true){ [weak self] in
            self?.transitionToListAndEnqueue(leftViewControllerRevealed: leftViewControllerRevealed) {
                ZClientViewController.shared()?.conversationListViewController.topBarViewController.presentSettings()
            }
        }
    }
    
    // MARK: - Helpers
    
    private func transitionToListAndEnqueue(leftViewControllerRevealed: Bool = true, _ block: @escaping () -> Void) {
        ZClientViewController.shared()?.transitionToList(animated: true,
                                                         leftViewControllerRevealed: leftViewControllerRevealed) {
                                                            ZMUserSession.shared()?.enqueueChanges(block)
        }
    }
    
    private func returnToPreviousScreen() {
        if let navigationController = self.navigationController, navigationController.viewControllers.first != self {
            navigationController.popViewController(animated: true)
        } else {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    /// Presents an alert as a popover if needed.
    private func presentAlert(_ alert: UIAlertController, targetView: UIView) {
        alert.popoverPresentationController?.sourceView = targetView
        alert.popoverPresentationController?.sourceRect = targetView.bounds.insetBy(dx: 8, dy: 8)
        alert.popoverPresentationController?.permittedArrowDirections = .down
        present(alert, animated: true)
    }
    
    
    // MARK: Legal Hold
    
    private var legalholdItem: UIBarButtonItem {
        let item = UIBarButtonItem(icon: .legalholdactive, target: self, action: #selector(presentLegalHoldDetails))
        item.setLegalHoldAccessibility()
        item.tintColor = .vividRed
        return item
    }
    
    @objc
    private func presentLegalHoldDetails() {
        guard let user = fullUser else { return }
        LegalHoldDetailsViewController.present(in: self, user: user)
    }
    
    // MARK: - Action Handlers
    
    private func archiveConversation() {
        transitionToListAndEnqueue {
            self.conversation?.isArchived.toggle()
        }
    }
    
    // MARK: Connect
    
    private func sendConnectionRequest() {
        let connect: (String) -> Void = {
            if let user = self.fullUser {
                user.connect(message: $0)
            } else if let searchUser = self.bareUser as? ZMSearchUser {
                searchUser.connect(message: $0)
            }
        }
        
        ZMUserSession.shared()?.enqueueChanges {
            let messageText = "missive.connection_request.default_message".localized(args: self.bareUser.displayName, self.viewer.name ?? "")
            connect(messageText)
            // update the footer view to display the cancel request button
            self.updateFooterViews()
        }
    }
    
    private func acceptConnectionRequest() {
        guard let user = self.fullUser else { return }
        ZMUserSession.shared()?.enqueueChanges {
            user.accept()
            user.refreshData()
            self.updateFooterViews()
        }
    }
    
    private func ignoreConnectionRequest() {
        guard let user = self.fullUser else { return }
        ZMUserSession.shared()?.enqueueChanges {
            user.ignore()
            self.returnToPreviousScreen()
        }
    }
    
    // MARK: Block
    
    private func presentBlockRequest(from targetView: UIView) {
        
        let controller = UIAlertController(title: BlockResult.title(for: bareUser), message: nil, preferredStyle: .actionSheet)
        BlockResult.all(isBlocked: bareUser.isBlocked).map { $0.action(handleBlockResult) }.forEach(controller.addAction)
        presentAlert(controller, targetView: targetView)
    }
    
    private func handleBlockResult(_ result: BlockResult) {
        guard case .block = result else { return }
        
        let updateClosure = {
            self.fullUser?.toggleBlocked()
            self.updateFooterViews()
        }
        
        switch context {
        case .search:
            /// stay on this VC and let user to decise what to do next
            updateClosure()
        default:
            transitionToListAndEnqueue {
                updateClosure()
            }
        }
    }
    
    // MARK: Notifications
    
    private func updateMute(enableNotifications: Bool) {
        ZMUserSession.shared()?.enqueueChanges {
            self.conversation?.mutedMessageTypes = enableNotifications ? .none : .all
            // update the footer view to display the correct mute/unmute button
            self.updateFooterViews()
        }
    }
    
    private func presentNotificationsOptions(from targetView: UIView) {
        guard let conversation = self.conversation else { return }
        let title = "\(conversation.displayName) • \(NotificationResult.title)"
        let controller = UIAlertController(title: title, message: nil, preferredStyle: .actionSheet)
        NotificationResult.allCases.map { $0.action(for: conversation, handler: handleNotificationResult) }.forEach(controller.addAction)
        presentAlert(controller, targetView: targetView)
    }
    
    private func handleNotificationResult(_ result: NotificationResult) {
        if let mutedMessageTypes = result.mutedMessageTypes {
            ZMUserSession.shared()?.performChanges {
                self.conversation?.mutedMessageTypes = mutedMessageTypes
            }
        }
    }
    
    // MARK: Delete Contents
    
    private func presentDeleteConfirmationPrompt(from targetView: UIView) {
        guard let conversation = self.conversation else { return }
        let controller = UIAlertController(title: ClearContentResult.title, message: nil, preferredStyle: .actionSheet)
        ClearContentResult.options(for: conversation) .map { $0.action(handleDeleteResult) }.forEach(controller.addAction)
        presentAlert(controller, targetView: targetView)
    }
    
    private func handleDeleteResult(_ result: ClearContentResult) {
        guard case .delete(leave: let leave) = result else { return }
        transitionToListAndEnqueue {
            self.conversation?.clearMessageHistory()
            if leave {
                self.conversation?.removeOrShowError(participnant: .selfUser())
            }
        }
    }
    
    // MARK: Remove User
    
    private func presentRemoveUserMenuSheetController(from view: UIView) {
        guard let otherUser = fullUser else {
            return
        }
        
        let controller = UIAlertController(
            title: "profile.remove_dialog_message".localized(args: otherUser.displayName),
            message: nil,
            preferredStyle: .actionSheet
        )
        
        let removeAction = UIAlertAction(title: "profile.remove_dialog_button_remove_confirm".localized, style: .destructive) { _ in
            self.conversation?.removeOrShowError(participnant: otherUser) { result in
                switch result {
                case .success:
                    self.returnToPreviousScreen()
                case .failure(_):
                    break
                }
            }
        }
        
        controller.addAction(removeAction)
        controller.addAction(.cancel())
        
        presentAlert(controller, targetView: view)
    }
}

extension ProfileViewController: ZMUserObserver {
    func userDidChange(_ note: UserChangeInfo) {
        if note.trustLevelChanged {
            updateShowVerifiedShield()
        }
        
        if note.legalHoldStatusChanged {
            setupNavigationItems()
        }
    }
}

extension ProfileViewController: ProfileViewControllerDelegate {
    
    func profileViewController(_ controller: ProfileViewController?, wantsToNavigateTo conversation: ZMConversation) {
        delegate?.profileViewController(controller, wantsToNavigateTo: conversation)
    }
    
    func suggestedBackButtonTitle(for controller: ProfileViewController?) -> String? {
        return bareUser.displayName.uppercasedWithCurrentLocale
    }
    
    func profileViewController(_ controller: ProfileViewController?, wantsToCreateConversationWithName name: String?, users: Set<ZMUser>) {
        // no-op
    }

}

extension ProfileViewController: ConversationCreationControllerDelegate {
    func conversationCreationController(
        _ controller: ConversationCreationController,
        didSelectName name: String,
        participants: Set<ZMUser>,
        allowGuests: Bool,
        enableReceipts: Bool
        ) {
        controller.dismiss(animated: true) { [weak self] in
            self?.delegate?.profileViewController(self, wantsToCreateConversationWithName: name, users: participants)
        }
    }
}

extension ProfileViewController: TabBarControllerDelegate {
    func tabBarController(_ controller: TabBarController, tabBarDidSelectIndex: Int) {
        updateShowVerifiedShield()
    }
}
