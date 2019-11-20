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

protocol ProfileViewControllerDelegate: class {
    func suggestedBackButtonTitle(for controller: ProfileViewController?) -> String?
    func profileViewController(_ controller: ProfileViewController?, wantsToNavigateTo conversation: ZMConversation)
    func profileViewController(_ controller: ProfileViewController?, wantsToCreateConversationWithName name: String?, users: Set<ZMUser>)
}

final class ProfileViewController: UIViewController {
    let viewModel: ProfileViewControllerViewModel
    weak var viewControllerDismisser: ViewControllerDismisser?
    weak var navigationControllerDelegate: UINavigationControllerDelegate?
    
    private let profileFooterView: ProfileFooterView = ProfileFooterView()
    private let incomingRequestFooter: IncomingRequestFooterView = IncomingRequestFooterView()
    private let usernameDetailsView: UserNameDetailView = UserNameDetailView()

    private let profileTitleView: ProfileTitleView = ProfileTitleView()

    private var tabsController: TabBarController?
    
    var delegate: ProfileViewControllerDelegate? {
        get {
            return viewModel.delegate
        }
        set {
            viewModel.delegate = delegate
        }
    }

    // MARK: - init

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

    convenience init(user: UserType,
                     viewer: UserType,
                     conversation: ZMConversation? = nil,
                     context: ProfileViewControllerContext? = nil) {
        let profileViewControllerContext: ProfileViewControllerContext
        
        if let context = context {
            profileViewControllerContext = context
        } else {
            if conversation?.conversationType == .group {
                profileViewControllerContext = .groupConversation
            } else {
                profileViewControllerContext = .oneToOneConversation
            }
        }

        let viewModel = ProfileViewControllerViewModel(bareUser: user,
                                                       conversation: conversation,
                                                       viewer: viewer,
                                                       context: profileViewControllerContext)
        
        self.init(viewModel: viewModel)

        setupKeyboardFrameNotification()
    }
    
    required init(viewModel: ProfileViewControllerViewModel) {
        self.viewModel = viewModel
        super.init(nibName:nil, bundle:nil)
    }
    
    
    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func requestDismissal(withCompletion completion: @escaping () -> ()) {
        viewControllerDismisser?.dismiss(viewController: self, completion: completion)
    }
    
    // MARK: - Header
    private func setupHeader() {
        let userNameDetailViewModel = viewModel.makeUserNameDetailViewModel()
        usernameDetailsView.configure(with: userNameDetailViewModel)
        view.addSubview(usernameDetailsView)
        
        profileTitleView.configure(with: userNameDetailViewModel)
        
        profileTitleView.translatesAutoresizingMaskIntoConstraints = false
        if #available(iOS 11, *) {
            navigationItem.titleView = profileTitleView
        } else {
            profileTitleView.setNeedsLayout()
            profileTitleView.layoutIfNeeded()
            profileTitleView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            profileTitleView.translatesAutoresizingMaskIntoConstraints = true
        }
        
        navigationItem.titleView = profileTitleView
    }
    
    // MARK: - Actions
    private func bringUpConversationCreationFlow() {

        let controller = ConversationCreationController(preSelectedParticipants: viewModel.fullUserSet)
        controller.delegate = self
        
        let wrappedController = controller.wrapInNavigationController()
        wrappedController.modalPresentationStyle = .formSheet
        present(wrappedController, animated: true)
    }
    
    private func bringUpCancelConnectionRequestSheet(from targetView: UIView) {
        guard let fullUser = viewModel.fullUser else { return }
        
        let controller = UIAlertController.cancelConnectionRequest(for: fullUser) { canceled in
            if !canceled {
                self.viewModel.cancelConnectionRequest() {
                    self.returnToPreviousScreen()
                }
            }
        }
        
        presentAlert(controller, targetView: targetView)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return ColorScheme.default.statusBarStyle
    }
    
    override func loadView() {
        super.loadView()
        
        viewModel.viewModelDelegate = self
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(profileFooterView)
        view.addSubview(incomingRequestFooter)
        
        view.backgroundColor = UIColor.from(scheme: .barBackground)
                
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
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return wr_supportedInterfaceOrientations
    }
    
    private func setupProfileDetailsViewController() -> ProfileDetailsViewController {
        ///TODO: pass the whole view Model/stuct/context
        let profileDetailsViewController = ProfileDetailsViewController(user: viewModel.bareUser,
                                                                        viewer: viewModel.viewer,
                                                                        conversation: viewModel.conversation,
                                                                        context: viewModel.context)
        profileDetailsViewController.title = "profile.details.title".localized
        
        return profileDetailsViewController
    }
    
    private func setupTabsController() {
        var viewControllers = [UIViewController]()
        
        let profileDetailsViewController = setupProfileDetailsViewController()
        viewControllers.append(profileDetailsViewController)
        
        if viewModel.hasUserClientListTab,
            let fullUser = viewModel.fullUser {
            let userClientListViewController = UserClientListViewController(user: fullUser)
            viewControllers.append(userClientListViewController)
        }
        
        tabsController = TabBarController(viewControllers: viewControllers) ///TODO: move to closure
        tabsController?.delegate = self
        
        if viewModel.context == .deviceList, tabsController?.viewControllers.count > 1 {
            tabsController?.selectIndex(ProfileViewControllerTabBarIndex.devices.rawValue, animated: false)
        }
        
        addToSelf(tabsController!)
    }
    
    // MARK : - constraints
    
    private func setupConstraints() {
        usernameDetailsView.translatesAutoresizingMaskIntoConstraints = false
        tabsController?.view.translatesAutoresizingMaskIntoConstraints = false
        profileFooterView.translatesAutoresizingMaskIntoConstraints = false
        
        usernameDetailsView.fitInSuperview(exclude: [.bottom]) ///TODO: clean up and activate in one batch
        tabsController?.view?.topAnchor.constraint(equalTo: usernameDetailsView.bottomAnchor).isActive = true
        tabsController?.view.fitInSuperview(exclude: [.top])
        profileFooterView.fitInSuperview(exclude: [.top])
        
        incomingRequestFooter.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            (incomingRequestFooter.bottomAnchor.constraint(equalTo: profileFooterView.topAnchor)),
            (incomingRequestFooter.leadingAnchor.constraint(equalTo: view.leadingAnchor)),
            (incomingRequestFooter.trailingAnchor.constraint(equalTo: view.trailingAnchor))
            ])
    }
}

extension ProfileViewController: ViewControllerDismisser {
    func dismiss(viewController: UIViewController, completion: (() -> ())?) {
        navigationController?.popViewController(animated: true)
    }
}

// MARK: - Footer View

extension ProfileViewController: ProfileFooterViewDelegate, IncomingRequestFooterViewDelegate {
    
    func footerView(_ footerView: IncomingRequestFooterView, didRespondToRequestWithAction action: IncomingConnectionAction) {
        switch action {
        case .accept:
            viewModel.acceptConnectionRequest()
        case .ignore:
            viewModel.ignoreConnectionRequest()
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
    
    private func performAction(_ action: ProfileAction,
                       targetView: UIView) {
        switch action {
        case .createGroup:
            bringUpConversationCreationFlow()
        case .mute(let isMuted):
            viewModel.updateMute(enableNotifications: isMuted)
        case .manageNotifications:
            presentNotificationsOptions(from: targetView)
        case .archive:
            viewModel.archiveConversation()
        case .deleteContents:
            presentDeleteConfirmationPrompt(from: targetView)
        case .block:
            presentBlockRequest(from: targetView)
        case .openOneToOne:
            viewModel.openOneToOneConversation()
        case .removeFromGroup:
            presentRemoveUserMenuSheetController(from: targetView)
        case .connect:
            viewModel.sendConnectionRequest()
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
            self?.viewModel.transitionToListAndEnqueue(leftViewControllerRevealed: leftViewControllerRevealed) {
                ZClientViewController.shared()?.conversationListViewController.topBarViewController.presentSettings()
            }
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
        guard let user = viewModel.fullUser else { return }
        
        LegalHoldDetailsViewController.present(in: self, user: user)
    }
    
    
    // MARK: Block
    
    private func presentBlockRequest(from targetView: UIView) {
        
        let controller = UIAlertController(title: viewModel.blockTitle, message: nil, preferredStyle: .actionSheet)
        viewModel.allBockResult.map { $0.action(handleBlockResult) }.forEach(controller.addAction)
        presentAlert(controller, targetView: targetView)
    }
    
    private func handleBlockResult(_ result: BlockResult) {
        guard case .block = result else { return }
        
        let updateClosure = {
            self.viewModel.toggleBlocked()
            self.updateFooterViews()
        }
        
        switch viewModel.context {
        case .search:
            /// stay on this VC and let user to decise what to do next
            updateClosure()
        default:
            viewModel.transitionToListAndEnqueue {
                updateClosure()
            }
        }
    }
    
    // MARK: Notifications
    
    private func presentNotificationsOptions(from targetView: UIView) {
        guard let conversation = viewModel.conversation else { return }
        
        let title = "\(conversation.displayName) • \(NotificationResult.title)"
        let controller = UIAlertController(title: title, message: nil, preferredStyle: .actionSheet)
        NotificationResult.allCases.map { $0.action(for: conversation, handler: viewModel.handleNotificationResult) }.forEach(controller.addAction)
        presentAlert(controller, targetView: targetView)
    }
    
    // MARK: Delete Contents
    
    private func presentDeleteConfirmationPrompt(from targetView: UIView) {
        guard let conversation = viewModel.conversation else { return }
        
        let controller = UIAlertController(title: ClearContentResult.title, message: nil, preferredStyle: .actionSheet)
        ClearContentResult.options(for: conversation) .map { $0.action(viewModel.handleDeleteResult) }.forEach(controller.addAction)
        presentAlert(controller, targetView: targetView)
    }
    
    
    // MARK: Remove User
    
    private func presentRemoveUserMenuSheetController(from view: UIView) {
        guard let otherUser = viewModel.fullUser else {
            return
        }
        
        let controller = UIAlertController(
            title: "profile.remove_dialog_message".localized(args: otherUser.displayName),
            message: nil,
            preferredStyle: .actionSheet
        )
        
        let removeAction = UIAlertAction(title: "profile.remove_dialog_button_remove_confirm".localized, style: .destructive) { _ in
            self.viewModel.conversation?.removeOrShowError(participnant: otherUser) { result in
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

///TODO: mv to VM
extension ProfileViewController: ProfileViewControllerDelegate {
    
    func profileViewController(_ controller: ProfileViewController?, wantsToNavigateTo conversation: ZMConversation) {
        delegate?.profileViewController(controller, wantsToNavigateTo: conversation)
    }
    
    func suggestedBackButtonTitle(for controller: ProfileViewController?) -> String? {
        return viewModel.bareUser.displayName.uppercasedWithCurrentLocale
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

extension ProfileViewController: ProfileViewControllerViewModelDelegate {
    func updateShowVerifiedShield() {
        profileTitleView.showVerifiedShield = viewModel.showVerifiedShield && tabsController?.selectedIndex != ProfileViewControllerTabBarIndex.devices.rawValue
    }

    func setupNavigationItems() {
        let legalHoldItem: UIBarButtonItem? = viewModel.hasLegalHoldItem ? legalholdItem : nil
        
        if navigationController?.viewControllers.count == 1 {
            navigationItem.rightBarButtonItem = navigationController?.closeItem()
            navigationItem.leftBarButtonItem = legalHoldItem
        } else {
            navigationItem.rightBarButtonItem = legalHoldItem
        }
    }
    
    func updateFooterViews() {
        // Actions
        let factory = viewModel.profileActionsFactory
        let actions = factory.makeActionsList()
        
        profileFooterView.delegate = self
        profileFooterView.isHidden = actions.isEmpty
        profileFooterView.configure(with: actions)
        view.bringSubviewToFront(profileFooterView)
        
        // Incoming Request Footer
        incomingRequestFooter.isHidden = viewModel.incomingRequestFooterHidden
        incomingRequestFooter.delegate = self
        view.bringSubviewToFront(incomingRequestFooter)
    }
    
    func returnToPreviousScreen() {
        if let navigationController = self.navigationController, navigationController.viewControllers.first != self {
            navigationController.popViewController(animated: true)
        } else {
            self.dismiss(animated: true, completion: nil)
        }
    }
}
