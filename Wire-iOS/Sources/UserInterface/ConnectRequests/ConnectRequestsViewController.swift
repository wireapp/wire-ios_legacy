
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

private var ConnectionRequestCellIdentifier = "ConnectionRequestCell"

final class ConnectRequestsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    var connectionRequests: [ZMConversation] = []
    
    private var userObserverToken: Any?
    private var pendingConnectionsListObserverToken: Any?
    private let tableView: UITableView = UITableView(frame: .zero)
    private var lastLayoutBounds = CGRect.zero
    
    override func loadView() {
        view = tableView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(ConnectRequestCell.self, forCellReuseIdentifier: ConnectionRequestCellIdentifier)
        tableView.delegate = self
        tableView.dataSource = self
        
        if let userSession = ZMUserSession.shared() {
            let pendingConnectionsList = ZMConversationList.pendingConnectionConversations(inUserSession: userSession)
        
            pendingConnectionsListObserverToken = ConversationListChangeInfo.add(observer: self,
                                                                                 for: pendingConnectionsList,
                                                                                 userSession: userSession)
            
            userObserverToken = UserChangeInfo.add(observer: self, for: ZMUser.selfUser(), userSession: userSession)

            connectionRequests = pendingConnectionsList as? [ZMConversation] ?? []
        }
        
        reload()
        
        tableView.backgroundColor = UIColor.from(scheme: .background)
        tableView.separatorStyle = .singleLine
        tableView.separatorColor = UIColor.from(scheme: .separator)
        
        tableView.estimatedRowHeight = 0
        tableView.estimatedSectionHeaderHeight = 0
        tableView.estimatedSectionFooterHeight = 0
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UIApplication.shared.wr_updateStatusBarForCurrentControllerAnimated(true)
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
        coordinator.animate(alongsideTransition: { context in
            self.tableView.reloadData()
        }) { context in
        }
        
        super.viewWillTransition(to: size, with: coordinator)
    }
    
    // MARK: - UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return connectionRequests.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ConnectionRequestCellIdentifier) as? ConnectRequestCell else {
            fatal("Cannot create cell")
        }
        
        configureCell(cell, for: indexPath)
        return cell
    }
    
    // MARK: - UITableViewDelegate
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        /// if there are more than one request, reduce the cell height to give user a hint
        
        let inset: CGFloat = connectionRequests.count > 1 ? 48 : 0
        
        return max(0, view.safeAreaHeight - inset)
    }
    
    // MARK: - Helpers
    private func configureCell(_ cell: ConnectRequestCell, for indexPath: IndexPath) {
        /// get the user in reversed order, newer request is shown on top
        let request = connectionRequests[(connectionRequests.count - 1) - (indexPath.row)]
        
        let user = request.connectedUser
        cell.user = user
        cell.selectionStyle = .none
        cell.separatorInset = .zero
        cell.preservesSuperviewLayoutMargins = false
        cell.layoutMargins = UIEdgeInsets(top: 0, left: 0, bottom: 8, right: 0)
        
        cell.acceptBlock = { [weak self] in
            guard self?.connectionRequests.count == 0 else { return }

            ZClientViewController.shared?.hideIncomingContactRequests() {
                if let oneToOneConversation = user?.oneToOneConversation {
                    ZClientViewController.shared?.select(conversation: oneToOneConversation, focusOnView: true, animated: true)
                }
            }
        }
        
        cell.ignoreBlock = { [weak self] in
            self?.hideRequestsOrShowNextRequest()
        }
        
    }
    
    private func hideRequestsOrShowNextRequest(animated: Bool = true) {
        if connectionRequests.count == 0 {
            ZClientViewController.shared?.hideIncomingContactRequests(completion: nil)
        } else {
            // Scroll to bottom of inbox
            tableView.scrollToLastRow(animated: animated)
        }
    }
    
    func reload(animated: Bool = true) {
        if let userSession = ZMUserSession.shared() {
        let pendingConnectionsList = ZMConversationList.pendingConnectionConversations(inUserSession: userSession)
        
        connectionRequests = pendingConnectionsList as? [ZMConversation] ?? []
        }
        
        tableView.reloadData()
        hideRequestsOrShowNextRequest()
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
        tableView.reloadData() //may need a slightly different approach, like enumerating through table cells of type FirstTimeTableViewCell and setting their bgColor property
    }
}

extension UITableView {
    func scrollToLastRow(animated: Bool) {
        let rowCount = numberOfRows(inSection: numberOfSections - 1)
        scrollToRow(at: IndexPath(row: rowCount - 1, section: numberOfSections - 1), at: .bottom, animated: animated)
    }
}
