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

    override open var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
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
        setupSearchHeader()
        view.addSubview(separatorView)
        setupTableView()
        setupEmptyResultsView()
        setupNoContactsLabel()
        setupBottomContainer()
    }

    private func setupSearchHeader() {
        searchHeaderViewController = SearchHeaderViewController(userSelection: .init(), variant: .dark)
        searchHeaderViewController.delegate = self
        searchHeaderViewController.allowsMultipleSelection = false
        searchHeaderViewController.view.backgroundColor = UIColor.from(scheme: .searchBarBackground, variant: .dark)
        addToSelf(searchHeaderViewController)
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

    private func setupStyle() {
        title = "contacts_ui.title".localized.uppercased()
        view.backgroundColor = .clear

        noContactsLabel.font = .normalLightFont
        noContactsLabel.textColor = UIColor.from(scheme: .textForeground, variant: .dark)

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.sectionIndexBackgroundColor = .clear
        tableView.sectionIndexColor = .accent()

        bottomContainerSeparatorView.backgroundColor = UIColor.from(scheme: .separator, variant: .dark)
        bottomContainerView.backgroundColor = UIColor.from(scheme: .searchBarBackground, variant: .dark)
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

}
