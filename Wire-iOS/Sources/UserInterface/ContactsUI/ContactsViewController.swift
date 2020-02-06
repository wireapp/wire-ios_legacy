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

class ContactsViewController: UIViewController {

    let dataSource = ContactsDataSource()

    weak var delegate: ContactsViewControllerDelegate?

    var bottomContainerView = UIView()
    var bottomContainerSeparatorView = UIView()
    var noContactsLabel = UILabel()
    var searchHeaderViewController: SearchHeaderViewController!
    var separatorView = UIView()
    var tableView = UITableView()
    var inviteOthersButton: Button!
    var emptyResultsView = ContactsEmptyResultView()

    var bottomEdgeConstraint: NSLayoutConstraint!
    var bottomContainerBottomConstraint: NSLayoutConstraint!
    var emptyResultsBottomConstraint: NSLayoutConstraint!

    var actionButtonTitles = [
        "contacts_ui.action_button.open",
        "contacts_ui.action_button.invite",
        "connection_request.send_button_title"
    ].map(\.localized)

    // MARK: - Life Cycle

    init() {
        super.init(nibName: nil, bundle: nil)

        setupViews()
        setupLayout()
        setupStyle()

        dataSource.delegate = self
        tableView.dataSource = dataSource

        observeKeyboardFrame()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        presentShareContactsViewControllerIfNeeded()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UIApplication.shared.wr_updateStatusBarForCurrentControllerAnimated(true)
        showKeyboardIfNeeded()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        searchHeaderViewController.tokenField.resignFirstResponder()
    }

    // MARK: - Setup

    private func setupViews() {
        title = "contacts_ui.title".localized.uppercased()
        view.backgroundColor = ColorScheme.default.color(named: .background)

        setupSearchHeader()

        view.addSubview(separatorView)

        setupTableView()
        setupEmptyResultsView()
        setupNoContactsLabel()
        setupBottomContainer()
    }

    private func setupTableView() {
        tableView.dataSource = dataSource
        tableView.delegate = self
        tableView.allowsSelection = false
        tableView.rowHeight = 52
        tableView.keyboardDismissMode = .onDrag
        tableView.sectionIndexMinimumDisplayRowCount = Int(ContactsDataSource.MinimumNumberOfContactsToDisplaySections)
        ContactsCell.register(in: tableView)
        ContactsSectionHeaderView.register(in: tableView)

        let bottomContainerHeight: CGFloat = 56.0 + UIScreen.safeArea.bottom
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: bottomContainerHeight, right: 0)
        view.addSubview(tableView)
    }

    private func setupEmptyResultsView() {
        emptyResultsView.messageLabel.text = "peoplepicker.no_matching_results_after_address_book_upload_title".localized
        emptyResultsView.actionButton.setTitle("peoplepicker.no_matching_results.action.send_invite".localized, for: .normal)
        emptyResultsView.actionButton.addTarget(self, action: #selector(sendIndirectInvite), for: .touchUpInside)
        view.addSubview(emptyResultsView)
    }

    private func setupNoContactsLabel() {
        noContactsLabel.text = "peoplepicker.no_contacts_title".localized
        view.addSubview(noContactsLabel)
    }

    private func setupBottomContainer() {
        view.addSubview(bottomContainerView)
        bottomContainerView.addSubview(bottomContainerSeparatorView)

        inviteOthersButton = Button(style: .empty, variant: ColorScheme.default.variant)
        inviteOthersButton.addTarget(self, action: #selector(sendIndirectInvite), for: .touchUpInside)
        inviteOthersButton.setTitle("contacts_ui.invite_others".localized, for: .normal)
        bottomContainerView.addSubview(inviteOthersButton)
    }

    // MARK: - Methods

    private func showKeyboardIfNeeded() {
        if tableView.numberOfTotalRows() > StartUIViewController.InitiallyShowsKeyboardConversationThreshold {
            searchHeaderViewController.tokenField.becomeFirstResponder()
        }
    }

    func updateEmptyResults(hasResults: Bool) {
        let searchQueryExist = !dataSource.searchQuery.isEmpty
        noContactsLabel.isHidden = hasResults || searchQueryExist
        bottomContainerView.isHidden = !hasResults || searchQueryExist
        setEmptyResultsHidden(hasResults)
    }

    private func setEmptyResultsHidden(_ hidden: Bool) {
        let completion: (Bool) -> Void = { finished in
            self.emptyResultsView.isHidden = hidden
            self.tableView.isHidden = !hidden
        }

        UIView.animate(withDuration: 0.25,
                       delay: 0,
                       options: .beginFromCurrentState,
                       animations: { self.emptyResultsView.alpha = hidden ? 0 : 1 },
                       completion: completion)
    }

    private func presentShareContactsViewControllerIfNeeded() {
        let shouldSkip = AutomationHelper.sharedHelper.skipFirstLoginAlerts || ZMUser.selfUser().hasTeam

        if !AddressBookHelper.sharedHelper.isAddressBookAccessGranted && !shouldSkip {
            presentShareContactsViewController()
        }
    }

    private func presentShareContactsViewController() {
        let shareContactsViewController = ShareContactsViewController()
        shareContactsViewController.delegate = self

        addToSelf(shareContactsViewController)
    }

    // MARK: - Keyboard Observation

    private func observeKeyboardFrame() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardFrameWillChange),
                                               name: UIResponder.keyboardWillChangeFrameNotification,
                                               object: nil)
    }

    @objc
    func keyboardFrameWillChange(_ notification: Notification) {
        guard
            let userInfo = notification.userInfo,
            let beginFrame = userInfo[UIResponder.keyboardFrameBeginUserInfoKey] as? CGRect,
            let endFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect
            else { return }

        let willAppear = (beginFrame.minY - endFrame.minY) > 0
        let padding: CGFloat = 12

        UIView.animate(withKeyboardNotification: notification, in: view, animations: { [weak self] keyboardFrame in
            guard let weakSelf = self else { return }
            weakSelf.bottomContainerBottomConstraint.constant = -(willAppear ? keyboardFrame.height : 0)
            weakSelf.bottomEdgeConstraint.constant = -padding - (willAppear ? 0 : UIScreen.safeArea.bottom)
            weakSelf.view.layoutIfNeeded()
        })
    }

    // MARK: - Invite

    private let canInviteByEmail = ZMAddressBookContact.canInviteLocallyWithEmail()
    private let canInviteByPhone = ZMAddressBookContact.canInviteLocallyWithPhoneNumber()

    @objc
    func sendIndirectInvite(_ sender: UIView) {
        let shareItemProvider = ShareItemProvider(placeholderItem: "")
        let activityController = UIActivityViewController(activityItems: [shareItemProvider], applicationActivities: nil)
        activityController.excludedActivityTypes = [UIActivity.ActivityType.airDrop]
        activityController.configPopover(pointToView: sender)
        present(activityController, animated: true)
    }

    func invite(user: ZMSearchUser, from view: UIView) {
        // FIXME: The following code smoothens the transition when opening a conversation, but prevents the
        // invite alerts / screens from opening. We need to distinguish between these two types of actions.

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
                if let contact = user.contact {
                    try invite(contact: contact, from: view)
                }
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
