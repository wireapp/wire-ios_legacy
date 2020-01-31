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

    var shouldShowShareContactsViewController = true

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


    /// If sharingContactsRequired is true the user will be prompted to share his address book
    /// if he/she hasn't already done so. Override this property in subclasses to override
    /// the default behaviour which is false.
    var sharingContactsRequired: Bool {
        return false
    }

    override var prefersStatusBarHidden: Bool {
        return false
    }

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
        tableView.allowsSelection = false
        tableView.rowHeight = 52
        tableView.keyboardDismissMode = .onDrag
        tableView.sectionIndexMinimumDisplayRowCount = Int(ContactsDataSource.MinimumNumberOfContactsToDisplaySections)
        tableView.register(ContactsCell.self, forCellReuseIdentifier: ContactsViewControllerCellID)
        tableView.register(ContactsSectionHeaderView.self, forHeaderFooterViewReuseIdentifier: ContactsViewControllerSectionHeaderID)
        view.addSubview(tableView)

        setupTableView()

        // Empty results view
        emptyResultsView = ContactsEmptyResultView()
        emptyResultsView.messageLabel.text = "peoplepicker.no_matching_results_after_address_book_upload_title".localized
        emptyResultsView.actionButton.setTitle("peoplepicker.no_matching_results.action.send_invite".localized, for: .normal)
        emptyResultsView.actionButton.addTarget(self, action: #selector(sendIndirectInvite), for: .touchUpInside)
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

    // MARK: - Actions

    @objc
    func cancelPressed() {
        delegate?.contactsViewControllerDidCancel(self)
    }

    // MARK: - Methods

    func updateActionButtonTitles() {
        actionButtonTitles = contentDelegate?.actionButtonTitles(for: self) ?? []
    }

    func setEmptyResultsHidden(_ hidden: Bool, animated: Bool) {
        let hiddenBlock: (Bool) -> Void = {
            self.emptyResultsView.isHidden = $0
            self.tableView.isHidden = !$0
        }

        if !hidden {
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

    private func presentShareContactsViewControllerIfNeeded() {
        let shouldSkip: Bool = AutomationHelper.sharedHelper.skipFirstLoginAlerts || ZMUser.selfUser().hasTeam
        if sharingContactsRequired &&
            !AddressBookHelper.sharedHelper.isAddressBookAccessGranted &&
            !shouldSkip &&
            shouldShowShareContactsViewController {
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

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardFrameDidChange),
                                               name: UIResponder.keyboardDidChangeFrameNotification,
                                               object: nil)
    }

    @objc
    func keyboardFrameWillChange(_ notification: Notification) {
        guard
            let userInfo = notification.userInfo,
            let beginFrame = userInfo[UIResponder.keyboardFrameBeginUserInfoKey] as? CGRect,
            let endFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect
            else { return }

        let beginY = beginFrame.origin.y
        let endY = endFrame.origin.y

        let diff = beginY - endY
        let padding: CGFloat = 12

        UIView.animate(withKeyboardNotification: notification, in: view, animations: { [weak self] keyboardFrame in
            guard let weakSelf = self else { return }
            weakSelf.bottomEdgeConstraint.constant = -padding - (diff > 0 ? 0 : UIScreen.safeArea.bottom)
            weakSelf.view.layoutIfNeeded()
        })
    }

    @objc
    func keyboardFrameDidChange(_ notification: Notification) {
        UIView.animate(withKeyboardNotification: notification, in: view, animations: { [weak self] keyboardFrame in
            guard let weakSelf = self else { return }
            let offset = weakSelf.isInsidePopover ? 0 : -keyboardFrame.size.height
            weakSelf.bottomContainerBottomConstraint.constant = offset
            weakSelf.emptyResultsBottomConstraint.constant = offset
            weakSelf.view.layoutIfNeeded()
        })
    }
}
