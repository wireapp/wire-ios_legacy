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
import WireSyncEngine

final class GroupDetailsViewController: UIViewController, ZMConversationObserver, GroupDetailsFooterViewDelegate {
    
    fileprivate let collectionViewController: SectionCollectionViewController
    fileprivate let conversation: ZMConversation
    fileprivate let footerView = GroupDetailsFooterView()
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

    init(conversation: ZMConversation) {
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
        let collectionView = UICollectionView(forGroupedSections: ())
        collectionView.accessibilityIdentifier = "group_details.list"

        if #available(iOS 11.0, *) {
            collectionView.contentInsetAdjustmentBehavior = .never
        }

        [collectionView, footerView].forEach(view.addSubview)

        constrain(view, collectionView, footerView) { container, collectionView, footerView in
            collectionView.top == container.top
            collectionView.leading == container.leading
            collectionView.trailing == container.trailing
            collectionView.bottom == footerView.top
            footerView.leading == container.leading
            footerView.trailing == container.trailing
            footerView.bottom == container.bottom
        }

        collectionViewController.collectionView = collectionView
        footerView.delegate = self
        footerView.update(for: conversation)
        collectionViewController.sections = computeVisibleSections()

    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "participants.title".localized(uppercased: true)
        view.backgroundColor = UIColor.from(scheme: .contentBackground)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        updateLegalHoldIndicator()
        navigationItem.rightBarButtonItem = navigationController?.closeItem()
        collectionViewController.collectionView?.reloadData()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animate(alongsideTransition: { (context) in
            self.collectionViewController.collectionView?.collectionViewLayout.invalidateLayout()
        })
    }

    func updateLegalHoldIndicator() {
        navigationItem.leftBarButtonItem = conversation.isUnderLegalHold ? legalholdItem : nil
    }
    
   

    func computeVisibleSections() -> [CollectionViewSectionController] {
        var sections = [CollectionViewSectionController]()
        let renameGroupSectionController = RenameGroupSectionController(conversation: conversation)
        sections.append(renameGroupSectionController)
        self.renameGroupSectionController = renameGroupSectionController
        
        let (participants, serviceUsers) = (conversation.sortedOtherParticipants, conversation.sortedServiceUsers)
        if !participants.isEmpty {
            
            let admins = participants.filter({$0.isGroupAdmin(in: conversation)})
            let members = participants.filter({!$0.isGroupAdmin(in: conversation)})
            
            if admins.count <= Int.ConversationParticipants.maxNumberWithoutTruncation || admins.isEmpty {
                if admins.count >= Int.ConversationParticipants.maxNumberOfDisplayed && (participants.count > Int.ConversationParticipants.maxNumberWithoutTruncation) { // Dispay the ShowAll button after the first section
                    let adminSection = ParticipantsSectionController(participants: admins,
                                                                     conversationRole: .admin, conversation: conversation,
                                                                     delegate: self, totalParticipantsCount: participants.count, clipSection: true, maxParticipants: admins.count - 1, maxDisplayedParticipants: Int.ConversationParticipants.maxNumberOfDisplayed)
                    sections.append(adminSection)
                } else {
                    let adminSection = ParticipantsSectionController(participants: admins,
                                                                     conversationRole: .admin, conversation: conversation,
                                                                     delegate: self, totalParticipantsCount: participants.count, clipSection: false)
                    sections.append(adminSection)
                    if members.count <= (Int.ConversationParticipants.maxNumberWithoutTruncation - admins.count) { // Don't display the ShowAll button
                        if !members.isEmpty {
                            let memberSection = ParticipantsSectionController(participants: members,
                                                                              conversationRole: .member, conversation: conversation,
                                                                              delegate: self, totalParticipantsCount: participants.count, clipSection: false)
                            sections.append(memberSection)
                        }
                    } else { // Display the ShowAll button after the second section
                        let memberSection = ParticipantsSectionController(participants: members,
                                                                          conversationRole: .member, conversation: conversation,
                                                                          delegate: self, totalParticipantsCount: participants.count, clipSection: true, maxParticipants: (Int.ConversationParticipants.maxNumberWithoutTruncation - admins.count), maxDisplayedParticipants: (Int.ConversationParticipants.maxNumberWithoutTruncation - admins.count) - 2)
                        sections.append(memberSection)
                    }
                }
            } else { // Display only one section without the ShowAll button
                let adminSection = ParticipantsSectionController(participants: admins,
                                                                 conversationRole: .admin, conversation: conversation,
                                                                 delegate: self, totalParticipantsCount: participants.count, clipSection: true)
                sections.append(adminSection)
            }
        }

        // MARK: options sections
        let optionsSectionController = GroupOptionsSectionController(conversation: conversation, delegate: self, syncCompleted: didCompleteInitialSync)
        if optionsSectionController.hasOptions {
            sections.append(optionsSectionController)
        }
        
        if conversation.teamRemoteIdentifier != nil && SelfUser.current.canModifyReadReceiptSettings(in: conversation) {
            let receiptOptionsSectionController = ReceiptOptionsSectionController(conversation: conversation,
                                                                                  syncCompleted: didCompleteInitialSync,
                                                                                  collectionView: self.collectionViewController.collectionView!,
                                                                                  presentingViewController: self)
            sections.append(receiptOptionsSectionController)
        }
        
        // MARK: services sections
        
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
            changeInfo.mutedMessageTypesChanged ||
            changeInfo.legalHoldStatusChanged
            else { return }
        
        updateLegalHoldIndicator()
        collectionViewController.sections = computeVisibleSections()
        footerView.update(for: conversation)
        
        if changeInfo.participantsChanged, !conversation.isSelfAnActiveMember {
           navigationController?.popToRootViewController(animated: true)
        }
    }
    
    func footerView(_ view: GroupDetailsFooterView, shouldPerformAction action: GroupDetailsFooterView.Action) {
        switch action {
        case .invite:
            let addParticipantsViewController = AddParticipantsViewController(conversation: conversation)
            let navigationController = addParticipantsViewController.wrapInNavigationController()
            navigationController.modalPresentationStyle = .currentContext
            present(navigationController, animated: true)
        case .more:
            actionController = ConversationActionController(conversation: conversation, target: self)
            actionController?.presentMenu(from: view, context: .details)
        }
    }
    
    func presentParticipantsDetails(with users: [UserType], selectedUsers: [UserType], animated: Bool) {
        let detailsViewController = GroupParticipantsDetailViewController(
            selectedParticipants: selectedUsers,
            conversation: conversation
        )

        detailsViewController.delegate = self
        navigationController?.pushViewController(detailsViewController, animated: animated)
    }
}

extension GroupDetailsViewController {
    
    fileprivate var legalholdItem: UIBarButtonItem {
        let item = UIBarButtonItem(icon: .legalholdactive, target: self, action: #selector(presentLegalHoldDetails))
        item.setLegalHoldAccessibility()
        item.tintColor = .vividRed
        return item
    }

    @objc
    func presentLegalHoldDetails() {
        LegalHoldDetailsViewController.present(in: self, conversation: conversation)
    }
    
}

extension GroupDetailsViewController: ViewControllerDismisser {
    func dismiss(viewController: UIViewController, completion: (() -> ())?) {
        navigationController?.popViewController(animated: true, completion: completion)
    }
}

extension GroupDetailsViewController: ProfileViewControllerDelegate {    
    func profileViewController(_ controller: ProfileViewController?, wantsToNavigateTo conversation: ZMConversation) {
        dismiss(animated: true) {
            ZClientViewController.shared?.load(conversation, scrollTo: nil, focusOnView: true, animated: true)
        }
    }
    
    func profileViewController(_ controller: ProfileViewController?, wantsToCreateConversationWithName name: String?, users: UserSet) {
        //no-op
    }
}

extension GroupDetailsViewController: GroupDetailsSectionControllerDelegate, GroupOptionsSectionControllerDelegate {

    func presentDetails(for user: UserType) {
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
    
    func presentGuestOptions(animated: Bool) {
        let menu = ConversationOptionsViewController(conversation: conversation, userSession: ZMUserSession.shared()!)
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
