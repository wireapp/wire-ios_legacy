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
import UIKit
import WireSyncEngine
import WireCommonComponents

final class ConnectRequestsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    var connectionRequests: [ConversationLike] = []

    private var userObserverToken: Any?
    private var pendingConnectionsListObserverToken: Any?
    private let tableView: UITableView = UITableView(frame: .zero)
    private var lastLayoutBounds = CGRect.zero
    private var isAccepting = false
    private var isIgnoring = false

    override func loadView() {
        view = tableView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        ConnectRequestCell.register(in: tableView)
        tableView.delegate = self
        tableView.dataSource = self

        if let userSession = ZMUserSession.shared() {
            let pendingConnectionsList = ZMConversationList.pendingConnectionConversations(inUserSession: userSession)

            pendingConnectionsListObserverToken = ConversationListChangeInfo.add(observer: self,
                                                                                 for: pendingConnectionsList,
                                                                                 userSession: userSession)

            userObserverToken = UserChangeInfo.add(observer: self, for: userSession.selfUser, in: userSession)

            connectionRequests = pendingConnectionsList as? [ConversationLike] ?? []
        }

        reload()

        tableView.backgroundColor = SemanticColors.View.backgroundDefault
        tableView.separatorStyle = .singleLine
        tableView.separatorColor = SemanticColors.View.backgroundSeparatorCell

        tableView.estimatedRowHeight = 0
        tableView.estimatedSectionHeaderHeight = 0
        tableView.estimatedSectionFooterHeight = 0
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        setupNavigationBar()
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }

    override func viewDidLayoutSubviews() {
        if !lastLayoutBounds.size.equalTo(view.bounds.size) {
            lastLayoutBounds = view.bounds
            tableView.reloadData()
            let yPos = tableView.contentSize.height - tableView.bounds.size.height + UIScreen.safeArea.bottom
            tableView.contentOffset = CGPoint(x: 0, y: yPos)
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animate(alongsideTransition: { _ in
            self.tableView.reloadData()
        }, completion: nil)

        super.viewWillTransition(to: size, with: coordinator)
    }

    private func setupNavigationBar() {
        navigationItem.setupNavigationBarTitle(title: L10n.Localizable.Inbox.title.capitalized)
        let button = AuthenticationNavigationBar.makeBackButton(isLegacy: false)
        button.addTarget(self, action: #selector(onBackButtonPressed), for: .touchUpInside)
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: button)
    }

    // MARK: - UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return connectionRequests.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(ofType: ConnectRequestCell.self, for: indexPath)

        configureCell(cell, for: indexPath)
        return cell
    }

    // MARK: - UITableViewDelegate
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        /// if there are more than one request, reduce the cell height to give user a hint

        let inset: CGFloat = connectionRequests.count > 1 ? 48 : 0

        return max(0, view.safeAreaLayoutGuideOrFallback.layoutFrame.size.height - inset)
    }

    // MARK: - Helpers

    @objc
    func onBackButtonPressed() {
        ZClientViewController.shared?.showConversationList()
    }

    private func configureCell(_ cell: ConnectRequestCell, for indexPath: IndexPath) {
        /// get the user in reversed order, newer request is shown on top
        let request = connectionRequests[(connectionRequests.count - 1) - (indexPath.row)]

        let user = request.connectedUserType
        cell.user = user
        cell.selectionStyle = .none
        cell.separatorInset = .zero
        cell.preservesSuperviewLayoutMargins = false
        cell.layoutMargins = UIEdgeInsets(top: 0, left: 0, bottom: 8, right: 0)

        cell.acceptBlock = { [weak self] in
            self?.acceptConnectionRequest(from: cell.user)
        }

        cell.ignoreBlock = { [weak self] in
            self?.ignoreConnectionRequest(from: cell.user)
        }

    }

    private func acceptConnectionRequest(from user: UserType) {
        isAccepting = true
        user.accept { [weak self] error in
            self?.isAccepting = false
            if let error = error as? LocalizedError {
                self?.presentLocalizedErrorAlert(error)
            } else {
                guard self?.connectionRequests.isEmpty == true else { return }

                ZClientViewController.shared?.hideIncomingContactRequests {
                    if let oneToOneConversation = user.oneToOneConversation {
                        ZClientViewController.shared?.select(conversation: oneToOneConversation, focusOnView: true, animated: true)
                    }
                }
            }
        }
    }

    private func ignoreConnectionRequest(from user: UserType) {
        isIgnoring = true
        user.ignore { [weak self] error in
            self?.isIgnoring = false
            if let error = error as? LocalizedError {
                self?.presentLocalizedErrorAlert(error)
            } else {
                self?.hideRequestsOrShowNextRequest()
            }
        }
    }

    private func hideRequestsOrShowNextRequest(animated: Bool = true) {
        if connectionRequests.isEmpty {
            ZClientViewController.shared?.hideIncomingContactRequests()
        } else {
            // scroll to bottom to show the next request
            let indexPath = IndexPath(row: connectionRequests.count - 1, section: 0)
            tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
        }
    }

    func reload(animated: Bool = true) {
        if let userSession = ZMUserSession.shared() {
            let pendingConnectionsList = ZMConversationList.pendingConnectionConversations(inUserSession: userSession)

            connectionRequests = pendingConnectionsList as? [ConversationLike] ?? []
        }

        tableView.reloadData()

        if !isAccepting && !isIgnoring {
            hideRequestsOrShowNextRequest()
        }
    }
}

// MARK: - ZMConversationListObserver

extension ConnectRequestsViewController: ZMConversationListObserver {
    func conversationListDidChange(_ change: ConversationListChangeInfo) {
        reload()
    }
}

// MARK: - ZMUserObserver

extension ConnectRequestsViewController: ZMUserObserver {
    func userDidChange(_ change: UserChangeInfo) {
        tableView.reloadData() // may need a slightly different approach, like enumerating through table cells of type FirstTimeTableViewCell and setting their bgColor property
    }
}
