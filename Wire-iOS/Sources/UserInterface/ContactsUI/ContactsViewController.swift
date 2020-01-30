//
// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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

private let zmLog = ZMSLog(tag: "UI")

class ContactsViewController: UIViewController {

    let dataSource = ContactsDataSource()

    weak var delegate: ContactsViewControllerDelegate?

    weak var contentDelegate: ContactsViewControllerContentDelegate? {
        didSet {
            updateActionButtonTitles()
        }
    }

    /// Button displayed at the bottom of the screen. If nil a default button is displayed.
    var bottomButton: Button? {
        didSet {
            guard let bottomButton = bottomButton else { return }
            oldValue?.removeFromSuperview()
            bottomContainerView.addSubview(bottomButton)
            createBottomButtonConstraints()
        }
    }

    override var title: String? {
        didSet {
            titleLabel.text = title
            titleLabelHeightConstraint.isActive = titleLabel.text != nil
            closeButtonTopConstraint.isActive = !(titleLabel.text?.isEmpty ?? true)
        }
    }

    func setEmptyResultsHidden(_ hidden: Bool, animated: Bool) {
        let hiddenBlock: (Bool) -> Void = {
            self.emptyResultsView.isHidden = $0
            self.tableView.isHidden = !$0
        }

        if hidden {
            hiddenBlock(false)
        }

        let animationBlock: () -> Void = {
            self.emptyResultsView.alpha = hidden ? 0 : 1
        }

        let completion: (_ finished: Bool) -> Void = { finished in
            if hidden {
                hiddenBlock(true)
            }
        }

        if animated {
            UIView.animate(withDuration: 0.25,
                           delay: 0,
                           options: .beginFromCurrentState,
                           animations: animationBlock,
                           completion: completion)
        } else {
            animationBlock()
            completion(true)
        }
    }

    var shouldShowShareContactsViewController = true // What's this?

    let ContactsViewControllerCellID = "ContactsCell"
    let ContactsViewControllerSectionHeaderID = "ContactsSectionHeaderView"

    var searchResultsReceived = false

    var titleLabel: TransformLabel!
    var bottomContainerView: UIView!
    var bottomContainerSeparatorView: UIView!
    var noContactsLabel: UILabel!
    var cancelButton: IconButton!
    var searchHeaderViewController: SearchHeaderViewController!
    var topContainerView: UIView!
    var separatorView: UIView!
    var tableView: UITableView!
    var inviteOthersButton: Button!
    var emptyResultsView: ContactsEmptyResultView!

    var titleLabelHeightConstraint: NSLayoutConstraint!
    var titleLabelTopConstraint: NSLayoutConstraint!
    var titleLabelBottomConstraint: NSLayoutConstraint!
    var closeButtonHeightConstraint: NSLayoutConstraint!
    var closeButtonTopConstraint: NSLayoutConstraint!
    var closeButtonBottomConstraint: NSLayoutConstraint!
    var topContainerHeightConstraint: NSLayoutConstraint!
    var searchHeaderTopConstraint: NSLayoutConstraint!
    var searchHeaderWithNavigatorBarTopConstraint: NSLayoutConstraint!
    var bottomEdgeConstraint: NSLayoutConstraint!
    var bottomContainerBottomConstraint: NSLayoutConstraint!
    var emptyResultsBottomConstraint: NSLayoutConstraint!

    var actionButtonTitles = [String]()


    init() {
        super.init(nibName: nil, bundle: nil)

        setupViews()
        setupLayout()
        setupStyle()

        dataSource.delegate = self
        tableView.dataSource = dataSource

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardFrameWillChange),
                                               name: UIResponder.keyboardWillChangeFrameNotification,
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardFrameDidChange),
                                               name: UIResponder.keyboardDidChangeFrameNotification,
                                               object: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // What's this about?
    /// If sharingContactsRequired is true the user will be prompted to share his address book
    /// if he/she hasn't already done so. Override this property in subclasses to override
    /// the default behaviour which is false.
    var sharingContactsRequired: Bool {
        return false
    }

    open override var prefersStatusBarHidden: Bool {
        return false
    }

    @objc
    func setupViews() {
        let colorScheme = ColorScheme.default

        view.backgroundColor = colorScheme.color(named: .background)

        // Top views
        topContainerView = UIView()
        topContainerView.backgroundColor = .clear
        view.addSubview(topContainerView)

        titleLabel = TransformLabel()
        titleLabel.numberOfLines = 1
        titleLabel.text = title
        titleLabel.textColor = colorScheme.color(named: .textForeground)
        topContainerView.addSubview(titleLabel)

        createSearchHeader()

        cancelButton = IconButton()
        cancelButton.setIcon(.cross, size: .custom(14), for: .normal)
        cancelButton.accessibilityIdentifier = "ContactsViewCloseButton"
        cancelButton.addTarget(self, action: #selector(cancelPressed), for: .touchUpInside)
        topContainerView.addSubview(cancelButton)

        // Separator
        separatorView = UIView()
        view.addSubview(separatorView)

        // Table view
        tableView = UITableView()
        tableView.dataSource = dataSource
        tableView.delegate = self
        tableView.allowsMultipleSelection = true
        tableView.rowHeight = 52
        tableView.keyboardDismissMode = .onDrag
        tableView.sectionIndexMinimumDisplayRowCount = 15 // FIXME: ContactsDataSource.MinimumNumberOfContactsToDisplaySections
        tableView.register(ContactsCell.self, forCellReuseIdentifier: ContactsViewControllerCellID) // FIXME: id in cell
        tableView.register(ContactsSectionHeaderView.self, forHeaderFooterViewReuseIdentifier: ContactsViewControllerSectionHeaderID) // FIXME: id in header
        view.addSubview(tableView)

        setupTableView()

        // Empty results view
        emptyResultsView = ContactsEmptyResultView()
        emptyResultsView.messageLabel.text = "peoplepicker.no_matching_results_after_address_book_upload_title".localized
        emptyResultsView.actionButton.setTitle("peoplepicker.no_matching_results.action.send_invite".localized, for: .normal)
        emptyResultsView.actionButton.addTarget(self, action: #selector(sendIndirectInvite), for: .touchUpInside) // TODO: What is this?
        view.addSubview(emptyResultsView)

        // No contacts label
        noContactsLabel = UILabel()
        noContactsLabel.text = "peoplepicker.no_contacts_title".localized
        view.addSubview(noContactsLabel)

        // Bottom views
        bottomContainerView = UIView()
        view.addSubview(bottomContainerView)

        bottomContainerSeparatorView = UIView()
        bottomContainerView.addSubview(bottomContainerSeparatorView)

        inviteOthersButton = Button(style: .empty, variant: colorScheme.variant)
        inviteOthersButton.addTarget(self, action: #selector(sendIndirectInvite), for: .touchUpInside)
        inviteOthersButton.setTitle("contacts_ui.invite_others".localized, for: .normal)
        bottomContainerView.addSubview(inviteOthersButton)

        updateEmptyResults()
    }

    @objc
    func cancelPressed() {
        delegate?.contactsViewControllerDidCancel(self)
    }

    @objc
    func updateActionButtonTitles() {
        actionButtonTitles = contentDelegate?.actionButtonTitles(for: self) ?? []
    }
    
    @objc
    func keyboardFrameDidChange(_ notification: Notification) {
        UIView.animate(withKeyboardNotification: notification, in: view, animations: { [weak self] keyboardFrameInView in
            guard let weakSelf = self else { return }

            let offset = weakSelf.isInsidePopover ? 0.0 : -keyboardFrameInView.size.height
            weakSelf.bottomContainerBottomConstraint.constant = offset
            weakSelf.emptyResultsBottomConstraint.constant = offset
            weakSelf.view.layoutIfNeeded()
        })
    }

    func invite(contact: ZMAddressBookContact, from view: UIView) -> UIAlertController? {
        if contact.contactDetails.count == 1 {
            if contact.emailAddresses.count == 1 && ZMAddressBookContact.canInviteLocallyWithEmail() {
                contact.inviteLocallyWithEmail(contact.emailAddresses[0])
                return nil
            } else if contact.rawPhoneNumbers.count == 1 && ZMAddressBookContact.canInviteLocallyWithPhoneNumber() {
                contact.inviteLocallyWithPhoneNumber(contact.rawPhoneNumbers[0])
                return nil
            } else {
                // Cannot invite
                if contact.emailAddresses.count == 1 && !ZMAddressBookContact.canInviteLocallyWithEmail() {
                    zmLog.error("Cannot invite person: email is not configured")

                    let unableToSendController = UIAlertController(title: nil,
                                                                   message: "error.invite.no_email_provider".localized,
                                                                   preferredStyle: .alert)

                    let okAction = UIAlertAction(title: "general.ok".localized, style: .cancel) { action in
                        unableToSendController.dismiss(animated: true)
                    }

                    unableToSendController.addAction(okAction)
                    return unableToSendController
                } else if contact.rawPhoneNumbers.count == 1 && !ZMAddressBookContact.canInviteLocallyWithPhoneNumber() {
                    zmLog.error("Cannot invite person: phone is not configured")

                    let unableToSendController = UIAlertController(title: nil,
                                                                   message: "error.invite.no_messaging_provider".localized,
                                                                   preferredStyle: .alert)

                    let okAction = UIAlertAction(title: "general.ok".localized, style: .cancel) { action in
                        unableToSendController.dismiss(animated: true)
                    }

                    unableToSendController.addAction(okAction)
                    return unableToSendController
                }
            }
        } else {
            if !ZMAddressBookContact.canInviteLocallyWithEmail() && !ZMAddressBookContact.canInviteLocallyWithPhoneNumber() {
                let unableToSendController = UIAlertController(title: nil,
                                                               message: "error.invite.no_email_provider".localized,
                                                               preferredStyle: .alert)

                let okAction = UIAlertAction(title: "general.ok".localized, style: .cancel) { action in
                    unableToSendController.dismiss(animated: true)
                }

                unableToSendController.addAction(okAction)
                return unableToSendController
            }

            let chooseContactDetailController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            let presentationController = chooseContactDetailController.popoverPresentationController
            presentationController?.sourceView = view
            presentationController?.sourceRect = view.bounds

            if ZMAddressBookContact.canInviteLocallyWithEmail() {
                for contactEmail in contact.emailAddresses {
                    let action = UIAlertAction(title: contactEmail, style: .default) { action in
                        contact.inviteLocallyWithEmail(contactEmail)
                        chooseContactDetailController.dismiss(animated: true)
                    }
                    chooseContactDetailController.addAction(action)
                }
            }

            if ZMAddressBookContact.canInviteLocallyWithPhoneNumber() {
                for contactPhone in contact.rawPhoneNumbers {
                    let action = UIAlertAction(title: contactPhone, style: .default) { action in
                        contact.inviteLocallyWithPhoneNumber(contactPhone)
                        chooseContactDetailController.dismiss(animated: true)
                    }
                    chooseContactDetailController.addAction(action)
                }
            }

            let cancelAction = UIAlertAction(title: "contacts_ui.invite_sheet.cancel_button_title".localized, style: .cancel) { action in
                chooseContactDetailController.dismiss(animated: true)
            }

            chooseContactDetailController.addAction(cancelAction)
            return chooseContactDetailController
        }

        return nil
    }
}
