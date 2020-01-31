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

private enum InvitationError: Error {

    case missingClient(Client)
    case noContactInformation

    enum Client {

        case email, phone, both

        var messageKey: String {
            switch self {
            case .email, .both:
                return "error.invite.no_email_provider"
            case .phone:
                return "error.invite.no_messaging_provider"
            }
        }
    }
}

final class InviteContactsViewController: ContactsViewController {

    private let canInviteByEmail = ZMAddressBookContact.canInviteLocallyWithEmail()
    private let canInviteByPhone = ZMAddressBookContact.canInviteLocallyWithPhoneNumber()

    override init() {
        super.init()
        
        delegate = self
        contentDelegate = self
        dataSource.searchQuery = ""
        
        title = "contacts_ui.title".localized.uppercased()
        
        setupStyle()
    }
    
    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var sharingContactsRequired: Bool {
        return true
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        ///hide titleLabel and cancel cross button, which is duplicated in the navi bar
        
        let subViewConstraints: [NSLayoutConstraint] = [titleLabelHeightConstraint, titleLabelTopConstraint, titleLabelBottomConstraint, closeButtonTopConstraint, closeButtonBottomConstraint, searchHeaderTopConstraint]
        
        if navigationController != nil {
            titleLabel.isHidden = true
            
            cancelButton.isHidden = true
            closeButtonHeightConstraint.constant = 0
            subViewConstraints.forEach(){ $0.isActive = false }
            
            topContainerHeightConstraint.isActive = true
            searchHeaderWithNavigatorBarTopConstraint.isActive = true
        } else {
            titleLabel.isHidden = false
            
            cancelButton.isHidden = false
            
            closeButtonHeightConstraint.constant = 16
            topContainerHeightConstraint.isActive = false
            searchHeaderWithNavigatorBarTopConstraint.isActive = false
            
            subViewConstraints.forEach(){ $0.isActive = true }
        }
        
        view.layoutIfNeeded()
    }
    
    override func setupStyle() {
        super.setupStyle()
        
        view.backgroundColor = .clear
        
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.sectionIndexBackgroundColor = .clear
        tableView.sectionIndexColor = .accent()
        
        bottomContainerSeparatorView.backgroundColor = UIColor.from(scheme: .separator, variant: .dark)
        bottomContainerView.backgroundColor = UIColor.from(scheme: .searchBarBackground, variant: .dark)
        
        titleLabel.textColor = UIColor.from(scheme: .textForeground, variant: .dark)
    }
    
    private func invite(user: ZMSearchUser, from view: UIView) {
        // FIXME: This code prevents the alert from appearing.
        // Prevent the overlapped visual artifact when opening a conversation
        if let navigationController = self.navigationController, self == navigationController.topViewController && navigationController.viewControllers.count >= 2 {
            navigationController.popToRootViewController(animated: false) {
                self.inviteUserOrOpenConversation(user, from:view)
            }
        } else {
            inviteUserOrOpenConversation(user, from:view)
        }
    }
    
    private func inviteUserOrOpenConversation(_ user: ZMSearchUser, from view: UIView) {
        let searchUser: ZMUser? = user.user
        let isIgnored: Bool? = searchUser?.isIgnored
        
        let selectOneToOneConversation: Completion = {
            if let oneToOneConversation = searchUser?.oneToOneConversation {
                ZClientViewController.shared?.select(conversation: oneToOneConversation, focusOnView: true, animated: true)
            }
        }
        
        if user.isConnected {
            selectOneToOneConversation()
        } else if searchUser?.isPendingApprovalBySelfUser == true &&
            isIgnored == false {
            ZClientViewController.shared?.selectIncomingContactRequestsAndFocus(onView: true)
        } else if searchUser?.isPendingApprovalByOtherUser == true &&
            isIgnored == false {
            selectOneToOneConversation()
        } else if let unwrappedSearchUser = searchUser,
                !unwrappedSearchUser.isIgnored &&
                !unwrappedSearchUser.isPendingApprovalByOtherUser {
            let displayName = unwrappedSearchUser.displayName
            let messageText = String(format: "missive.connection_request.default_message".localized, displayName, ZMUser.selfUser().name ?? "")
            
            ZMUserSession.shared()?.enqueueChanges({
                user.connect(message: messageText)
            }, completionHandler: {
                self.tableView.reloadData()
            })
        } else {
            do {
                try invite(contact: user.contact!, from: view) // FIXME: Force unwrap
            } catch InvitationError.missingClient(let client) {
                present(unableToSendController(client: client), animated: true)
            } catch {
                // log
            }
        }
    }

    private func invite(contact: ZMAddressBookContact, from view: UIView) throws {
        switch contact.contactDetails.count {
        case 1:
            try inviteWithSingleAddress(for: contact)
        case 2...:
            let actionSheet = try addressActionSheet(for: contact, in: view)
            present(actionSheet, animated: true)
        default:
            throw InvitationError.noContactInformation
        }
    }

    private func inviteWithSingleAddress(for contact: ZMAddressBookContact) throws {
        if let emailAddress = contact.emailAddresses.first {
            guard canInviteByEmail else { throw InvitationError.missingClient(.email) }
            contact.inviteLocallyWithEmail(emailAddress)

        } else if let phoneNumber = contact.rawPhoneNumbers.first {
            guard canInviteByPhone else { throw InvitationError.missingClient(.phone) }
            contact.inviteLocallyWithPhoneNumber(phoneNumber)

        } else {
            throw InvitationError.noContactInformation
        }
    }

    private func addressActionSheet(for contact: ZMAddressBookContact, in view: UIView) throws -> UIAlertController {
        guard canInviteByEmail || canInviteByPhone else { throw InvitationError.missingClient(.both) }

        let chooseContactDetailController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        let presentationController = chooseContactDetailController.popoverPresentationController
        presentationController?.sourceView = view
        presentationController?.sourceRect = view.bounds

        var actions = [UIAlertAction]()

        if canInviteByEmail {
            actions.append(contentsOf: contact.emailAddresses.map { address in
                UIAlertAction(title: address, style: .default) { _ in
                    contact.inviteLocallyWithEmail(address)
                    chooseContactDetailController.dismiss(animated: true)
                }
            })
        }

        if canInviteByPhone {
            actions.append(contentsOf: contact.rawPhoneNumbers.map { number in
                UIAlertAction(title: number, style: .default) { _ in
                    contact.inviteLocallyWithPhoneNumber(number)
                    chooseContactDetailController.dismiss(animated: true)
                }
            })
        }

        actions.append(UIAlertAction(title: "contacts_ui.invite_sheet.cancel_button_title".localized, style: .cancel) { action in
            chooseContactDetailController.dismiss(animated: true)
        })

        actions.forEach(chooseContactDetailController.addAction)
        return chooseContactDetailController
    }

    private func unableToSendController(client: InvitationError.Client) -> UIAlertController {
        let unableToSendController = UIAlertController(title: nil, message: client.messageKey.localized, preferredStyle: .alert)

        let okAction = UIAlertAction(title: "general.ok".localized, style: .cancel) { action in
            unableToSendController.dismiss(animated: true)
        }

        unableToSendController.addAction(okAction)
        return unableToSendController
    }
}

// MARK: - Contacts View Controller Content Delegate

extension InviteContactsViewController: ContactsViewControllerContentDelegate {
    
    func contactsViewController(_ controller: ContactsViewController, shouldSelect user: ZMSearchUser) -> Bool {
        return true
    }

    var shouldDisplayActionButton: Bool {
        return true
    }
    
    func actionButtonTitles(for controller: ContactsViewController) -> [String] {
        return ["contacts_ui.action_button.open",
                "contacts_ui.action_button.invite",
                "connection_request.send_button_title"].map(\.localized)
    }
    
    func contactsViewController(_ controller: ContactsViewController,
                                actionButtonTitleIndexFor user: UserType?,
                                isIgnored: Bool) -> Int {

        guard let user = user else { return 1 }

        if user.isConnected || user.isPendingApproval && isIgnored {
            return 0
        } else if !isIgnored && !user.isPendingApprovalByOtherUser {
            return 2
        } else {
            return 1
        }
    }
    
    func contactsViewController(_ controller: ContactsViewController, actionButton: UIButton, pressedFor user: ZMSearchUser) {
        invite(user: user, from: actionButton)
    }
    
    func contactsViewController(_ controller: ContactsViewController, didSelect cell: ContactsCell, for user: ZMSearchUser) {
        invite(user: user, from: cell)
    }
}

// MARK: - Contacts View Controller Delegate

extension InviteContactsViewController: ContactsViewControllerDelegate {
    func contactsViewControllerDidCancel(_ controller: ContactsViewController) {
        controller.dismiss(animated: true)
    }
    
    func contactsViewControllerDidNotShareContacts(_ controller: ContactsViewController) {
        controller.dismiss(animated: true)
    }

    func contactsViewControllerDidConfirmSelection(_ controller: ContactsViewController) {
        //no-op
    }
}
