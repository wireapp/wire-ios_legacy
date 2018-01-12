//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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

protocol TeamMemberInviteViewControllerDelegate: class {
    func teamInviteViewControllerDidFinish(_ controller: TeamMemberInviteViewController)
}

final class TeamMemberInviteViewController: UIViewController, TeamInviteTopbarDelegate {
    
    weak var delegate: TeamMemberInviteViewControllerDelegate?
    private let topBarSpacerView = UIView()
    private let topBar = TeamInviteTopBar()
    private let tableView = UpsideDownTableView() // So the insertion animation pushes content to the top.
    private let compactWidth: CGFloat = 375
    private let headerView = TeamMemberInviteHeaderView()
    private let footerTextFieldView = TeamInviteTextFieldFooterView()
    private var regularWidthConstraint: NSLayoutConstraint?, compactWidthConstraint: NSLayoutConstraint?
    private lazy var dataSource = ArrayDataSource<TeamMemberInviteTableViewCell, InviteResult>(for: self.tableView)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        createConstraints()
    }
    
    private func setupViews() {
        tableView.backgroundColor = .clear
        tableView.allowsSelection = false
        tableView.separatorStyle = .none
        tableView.rowHeight = 56
        [tableView, topBar, topBarSpacerView].forEach(view.addSubview)
        topBarSpacerView.backgroundColor = UIColor.Team.background
        topBar.delegate = self
        view.backgroundColor = UIColor.Team.background
        setupHeaderView()
        setupFooterView()
        updateScrollIndicatorInsets()
        tableView.clipsToBounds = false
        tableView.contentInset = UIEdgeInsets(top: 300, left: 0, bottom: 60, right: 0)
        dataSource.configure = { cell, content in cell.content = content }
    }
    
    private func createConstraints() {
        constrain(view, topBarSpacerView, topBar, tableView) { view, topBarSpacerView, topBar, tableView in
            topBarSpacerView.top == view.top
            topBarSpacerView.leading == view.leading
            topBarSpacerView.trailing == view.trailing
            topBarSpacerView.bottom == view.topMargin
            topBar.top == topBarSpacerView.bottom
            topBar.leading == view.leading
            topBar.trailing == view.trailing
            tableView.top == topBar.bottom
            tableView.bottom == view.bottom
            tableView.centerX == view.centerX
            if case .pad = traitCollection.userInterfaceIdiom {
                regularWidthConstraint = tableView.width == compactWidth
                compactWidthConstraint = tableView.width == view.width
            } else {
                tableView.width == view.width
            }
        }
    }
    
    private func setupHeaderView() {
        headerView.updateHeadlineLabelFont(forWidth: view.bounds.width)
        headerView.bottomSpacing = 60
        tableView.tableHeaderView = headerView.sized(fittingWidth: tableView.bounds.width)
    }
    
    private func setupFooterView() {
        footerTextFieldView.onConfirm = sendInvite
        footerTextFieldView.shouldConfirm = { [weak self] email in
            guard let `self` = self else { return true }
            return !self.dataSource.data.emails.contains(email)
        }
        footerTextFieldView.onAddFromAddressbook = {
            // TODO: Present address book picker
        }
        tableView.tableFooterView = footerTextFieldView.sized(fittingWidth: tableView.bounds.width)
    }
    
    private func sendInvite(to email: String) {
        guard let userSession = ZMUserSession.shared() else { return }
        showLoadingView = true
        
        ZMUser.selfUser().team?.invite(email: email, in: userSession) { [weak self] result in
            self?.handle(inviteResult: result, from:  .manualInput)
        }
    }
    
    private func handle(inviteResult result: InviteResult, from source: InviteSource) {
        switch source {
        case .manualInput: handleManualInputResult(result)
        case.addressBook: handleAddressBookResult(result)
        }
        
        showLoadingView = false
        topBar.mode = dataSource.data.count == 0 ? .skip : .done
    }
    
    private func handleManualInputResult(_ result: InviteResult) {
        switch result {
        case .success:
            dataSource.append(result)
            footerTextFieldView.clearInput()
        case let .failure(_, error: error):
            footerTextFieldView.errorMessage = error.localizedDescription
        }
    }
    
    private func handleAddressBookResult(_ result: InviteResult) {
        dataSource.append(result)
        footerTextFieldView.clearInput()
    }
        
    func teamInviteTopBarDidTapButton(_ topBar: TeamInviteTopBar) {
        // TODO: Tracking
        delegate?.teamInviteViewControllerDidFinish(self)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateMainViewWidthConstraint()
        setupHeaderView()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateScrollIndicatorInsets()
    }
    
    private func updateScrollIndicatorInsets() {
        let inset = -(view.bounds.width - tableView.bounds.width) / 2
        tableView.scrollIndicatorInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: inset)
    }
    
    private func updateMainViewWidthConstraint() {
        guard traitCollection.userInterfaceIdiom == .pad else { return }
        compactWidthConstraint?.isActive = traitCollection.horizontalSizeClass == .compact
        regularWidthConstraint?.isActive = traitCollection.horizontalSizeClass != .compact
    }
}
