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

final class InviteContactsViewController: ContactsViewController {
    init() {
        super.init(nibName: nil, bundle: nil)
        
        delegate = self
        contentDelegate = self
        dataSource = ContactsDataSource()
        dataSource?.searchQuery = ""
        
        title = "contacts_ui.title".localized.uppercased()
        
        setupStyle()
    }
    
    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func sharingContactsRequired() -> Bool {
        return true
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        ///hide titleLabel and cancel cross button, which is duplicated in the navi bar
        
        let subViewConstraints = [titleLabelHeightConstraint, titleLabelTopConstraint, titleLabelBottomConstraint, closeButtonTopConstraint, closeButtonBottomConstraint, searchHeaderTopConstraint]
        
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
                ZClientViewController.shared?.select(oneToOneConversation, focusOnView: true, animated: true)
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
            let alertController = invite(user.contact!, from: view)
            
            alertController?.presentInNotificationsWindow()
        }
    }
}

extension InviteContactsViewController: ContactsViewControllerContentDelegate {
    
    func contactsViewController(_ controller: ContactsViewController, shouldSelect user: ZMSearchUser) -> Bool {
        return true
    }

    func contactsViewController(_ controller: ContactsViewController, shouldDisplayActionButtonFor user: ZMSearchUser) -> Bool {
        return true
    }
    
    func actionButtonTitles(for controller: ContactsViewController) -> [String] {
        return ["contacts_ui.action_button.open".localized,
                "contacts_ui.action_button.invite".localized,
                "connection_request.send_button_title".localized]
    }
    
    func contactsViewController(_ controller: ContactsViewController,
                                actionButtonTitleIndexFor user: UserType?,
                                isIgnored: Bool) -> Int {
        guard let user = user else { return 1 }
        
        if user.isConnected ||
           ((user.isPendingApprovalByOtherUser ||
             user.isPendingApprovalBySelfUser) && isIgnored) {
            return 0
        } else if !isIgnored,
            !user.isPendingApprovalByOtherUser {
            return 2
        }
        
        return 1
    }
    
    func contactsViewController(_ controller: ContactsViewController, actionButton: UIButton, pressedFor user: ZMSearchUser) {
        invite(user: user, from: actionButton)
    }
    
    func contactsViewController(_ controller: ContactsViewController, didSelect cell: ContactsCell, for user: ZMSearchUser) {
        invite(user: user, from: cell)
    }
}

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
