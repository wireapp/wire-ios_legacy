
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
    private var connectionRequests: ZMConversationList?
    
    private var userObserverToken: Any?
    private var pendingConnectionsListObserverToken: Any?
    private let tableView: UITableView = UITableView(frame: CGRect.zero)
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

            connectionRequests = pendingConnectionsList
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
        return connectionRequests?.count ?? 0
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
        if tableView.bounds.size.height <= 0 {
            return UIScreen.main.bounds.size.height
        }
        return tableView.bounds.size.height - 48
    }
    
    // MARK: - Helpers
    private func configureCell(_ cell: ConnectRequestCell, for indexPath: IndexPath) {
        guard let count = connectionRequests?.count,
              let request = connectionRequests?[(count - 1) - (indexPath.row)] as? ZMConversation else { return }
        
        let user = request.connectedUser
        cell.user = user
        cell.selectionStyle = UITableViewCell.SelectionStyle.none
        cell.separatorInset = UIEdgeInsets.zero
        cell.preservesSuperviewLayoutMargins = false
        cell.layoutMargins = UIEdgeInsets(top: 0, left: 0, bottom: 8, right: 0)
        
        cell.acceptBlock = { [weak self] in
            if self?.connectionRequests?.count == 0 {
                ZClientViewController.shared?.hideIncomingContactRequests(withCompletion: {
                    if let oneToOneConversation = user?.oneToOneConversation {
                        ZClientViewController.shared?.select(oneToOneConversation, focusOnView: true, animated: true)
                    }
                })
            }
        }
        
        cell.ignoreBlock = { [weak self] in
            if self?.connectionRequests?.count == 0 {
                ZClientViewController.shared?.hideIncomingContactRequests(withCompletion: nil)
            }
        }
        
    }
    
    private func reload() {
        tableView.reloadData()
        
        if let count = connectionRequests?.count,
            count != 0 {
            // Scroll to bottom of inbox
            tableView.scrollToRow(at: IndexPath(row: count - 1, section: 0), at: .bottom, animated: true)
        } else {
            ZClientViewController.shared?.hideIncomingContactRequests(withCompletion: nil)
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
        tableView.reloadData() //may need a slightly different approach, like enumerating through table cells of type FirstTimeTableViewCell and setting their bgColor property
    }
}
