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
import Cartography

@objcMembers class GroupDetailsViewController: UIViewController, ZMConversationObserver, GroupDetailsFooterViewDelegate {
    
    fileprivate let collectionViewController: SectionCollectionViewController
    fileprivate let conversation: ZMConversation
    fileprivate let footerView = GroupDetailsFooterView()
    fileprivate let bottomSpacer = UIView()
    fileprivate var token: NSObjectProtocol?
    var actionController: ConversationActionController?
    fileprivate var renameGroupSectionController: RenameGroupSectionController?
    private var syncObserver: InitialSyncObserver!

    var didCompleteInitialSync = false {
        didSet {
            collectionViewController.sections = computeVisibleSections()
        }
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return wr_supportedInterfaceOrientations
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return ColorScheme.default.statusBarStyle
    }
    
    public init(conversation: ZMConversation) {
        self.conversation = conversation
        collectionViewController = SectionCollectionViewController()
        super.init(nibName: nil, bundle: nil)
        token = ConversationChangeInfo.add(observer: self, for: conversation)

        createSubviews()

        if let session = ZMUserSession.shared() {
            syncObserver = InitialSyncObserver(in: session) { [weak self] completed in
                self?.didCompleteInitialSync = completed
            }
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func createSubviews() {
        let collectionView = UICollectionView(forUserList: ())

        if #available(iOS 11.0, *) {
            collectionView.contentInsetAdjustmentBehavior = .never
        }

        [collectionView, footerView, bottomSpacer].forEach(view.addSubview)
        bottomSpacer.backgroundColor = UIColor.from(scheme: .barBackground)

        constrain(view, collectionView, footerView, bottomSpacer) { container, collectionView, footerView, bottomSpacer in
            collectionView.top == container.top
            collectionView.leading == container.leading
            collectionView.trailing == container.trailing
            collectionView.bottom == footerView.top
            footerView.leading == container.leading
            footerView.trailing == container.trailing
            footerView.bottom == bottomSpacer.top

            if #available(iOS 11, *) {
                bottomSpacer.top == container.safeAreaLayoutGuide.bottom
            } else {
                bottomSpacer.top == container.bottom
            }

            bottomSpacer.bottom == container.bottom
            bottomSpacer.leading == container.leading
            bottomSpacer.trailing == container.trailing
        }

        collectionViewController.collectionView = collectionView
        footerView.delegate = self
        footerView.update(for: conversation)
        collectionViewController.sections = computeVisibleSections()

    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "participants.title".localized.uppercased()
        view.backgroundColor = UIColor.from(scheme: .contentBackground)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationItem.rightBarButtonItem = navigationController?.closeItem()
        collectionViewController.collectionView?.reloadData()
    }

    func computeVisibleSections() -> [CollectionViewSectionController] {
        var sections = [CollectionViewSectionController]()
        let renameGroupSectionController = RenameGroupSectionController(conversation: conversation)
        sections.append(renameGroupSectionController)
        self.renameGroupSectionController = renameGroupSectionController
        
        let optionsSectionController = GroupOptionsSectionController(conversation: conversation, delegate: self, syncCompleted: didCompleteInitialSync)
        if optionsSectionController.hasOptions {
            sections.append(optionsSectionController)            
        }

        if let selfUser = ZMUser.selfUser(), selfUser.isTeamMember, conversation.team == selfUser.team {
            let receiptOptionsSectionController = ReceiptOptionsSectionController(conversation: conversation,
                                                                                  syncCompleted: didCompleteInitialSync,
                                                                                  collectionView: self.collectionViewController.collectionView!,
                                                                                  presentingViewController: self)
            sections.append(receiptOptionsSectionController)
        }

        let (participants, serviceUsers) = (conversation.sortedOtherParticipants, conversation.sortedServiceUsers)
        if !participants.isEmpty {
            let participantsSectionController = ParticipantsSectionController(participants: participants, conversation: conversation, delegate: self)
            sections.append(participantsSectionController)
        }
        if !serviceUsers.isEmpty {
            let servicesSection = ServicesSectionController(serviceUsers: serviceUsers, conversation: conversation, delegate: self)
            sections.append(servicesSection)
        }
        
        return sections
    }
    
    func conversationDidChange(_ changeInfo: ConversationChangeInfo) {
        guard
            changeInfo.participantsChanged ||
            changeInfo.nameChanged ||
            changeInfo.allowGuestsChanged ||
            changeInfo.destructionTimeoutChanged ||
            changeInfo.mutedMessageTypesChanged
            else { return }
        
        collectionViewController.sections = computeVisibleSections()
        footerView.update(for: conversation)
    }
    
    func detailsView(_ view: GroupDetailsFooterView, performAction action: GroupDetailsFooterView.Action) {
        switch action {
        case .invite:
            let addParticipantsViewController = AddParticipantsViewController(conversation: conversation)
            let navigationController = addParticipantsViewController.wrapInNavigationController()
            navigationController.modalPresentationStyle = .currentContext
            present(navigationController, animated: true)
        case .more:
            actionController = ConversationActionController(conversation: conversation, target: self)
            actionController?.presentMenu(from: view, showConverationNameInMenuTitle: false)
        }
    }
    
    @objc(presentParticipantsDetailsWithUsers:selectedUsers:animated:)
    func presentParticipantsDetails(with users: [UserType], selectedUsers: [UserType], animated: Bool) {
        let detailsViewController = GroupParticipantsDetailViewController(
            participants: users,
            selectedParticipants: selectedUsers,
            conversation: conversation
        )

        detailsViewController.delegate = self
        navigationController?.pushViewController(detailsViewController, animated: animated)
    }
    
    func dismissButtonTapped() {
        dismiss(animated: true)
    }
    
}

extension GroupDetailsViewController: ViewControllerDismisser, ProfileViewControllerDelegate {
    
    func dismiss(viewController: UIViewController, completion: (() -> ())?) {
        navigationController?.popViewController(animated: true, completion: completion)
    }
    
    func profileViewController(_ controller: ProfileViewController?, wantsToNavigateTo conversation: ZMConversation) {
        dismiss(animated: true) {
            ZClientViewController.shared()?.load(conversation, scrollTo: nil, focusOnView: true, animated: true)
        }
    }
    
}

extension GroupDetailsViewController: GroupDetailsSectionControllerDelegate, GroupOptionsSectionControllerDelegate {

    func presentDetails(for user: ZMUser) {
        let viewController = UserDetailViewControllerFactory.createUserDetailViewController(
            user: user,
            conversation: conversation,
            profileViewControllerDelegate: self,
            viewControllerDismisser: self
        )

        navigationController?.pushViewController(viewController, animated: true)
    }
    
    func presentFullParticipantsList(for users: [UserType], in conversation: ZMConversation) {
        presentParticipantsDetails(with: users, selectedUsers: [], animated: true)
    }
    
    @objc(presentGuestOptionsAnimated:)
    func presentGuestOptions(animated: Bool) {
        let menu = ConversationOptionsViewController(conversation: conversation, userSession: .shared()!)
        navigationController?.pushViewController(menu, animated: animated)
    }

    func presentTimeoutOptions(animated: Bool) {
        let menu = ConversationTimeoutOptionsViewController(conversation: conversation, userSession: .shared()!)
        menu.dismisser = self
        navigationController?.pushViewController(menu, animated: animated)
    }
    
    func presentNotificationsOptions(animated: Bool) {
        let menu = ConversationNotificationOptionsViewController(conversation: conversation, userSession: .shared()!)
        menu.dismisser = self
        navigationController?.pushViewController(menu, animated: animated)
    }
    
}
