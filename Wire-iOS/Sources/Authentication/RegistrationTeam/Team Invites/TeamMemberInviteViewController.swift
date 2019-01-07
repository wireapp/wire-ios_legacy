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

final class TeamMemberInviteViewController: AuthenticationStepViewController, TeamInviteTopbarDelegate {

    weak var authenticationCoordinator: AuthenticationCoordinator?

    private let topBarSpacerView = UIView()
    private let topBar = TeamInviteTopBar()
    private let tableView = UpsideDownTableView() // So the insertion animation pushes content to the top.
    private let compactWidth: CGFloat = 375, topOffset: CGFloat = 60, bottomOffset: CGFloat = 300
    private let headerView = TeamMemberInviteHeaderView()
    private let footerTextFieldView = TeamInviteTextFieldFooterView()
    private var regularWidthConstraint: NSLayoutConstraint?, compactWidthConstraint: NSLayoutConstraint?
    private lazy var dataSource = ArrayDataSource<TeamMemberInviteTableViewCell, InviteResult>(for: self.tableView)
    private var invitationsCount: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        createConstraints()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        footerTextFieldView.becomeFirstResponder()
    }
    
    private func setupViews() {
        [tableView, topBar, topBarSpacerView].forEach(view.addSubview)
        topBarSpacerView.backgroundColor = UIColor.Team.background
        topBar.delegate = self
        view.backgroundColor = UIColor.Team.background
        setupTableView()
        setupHeaderView()
        setupFooterView()
        updateScrollIndicatorInsets()
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
            regularWidthConstraint = tableView.width == compactWidth
            compactWidthConstraint = tableView.width == view.width
        }
        updateMainViewWidthConstraint()
    }
    
    private func setupTableView() {
        tableView.clipsToBounds = false
        tableView.alwaysBounceVertical = false
        tableView.backgroundColor = .clear
        tableView.allowsSelection = false
        tableView.separatorStyle = .none
        tableView.rowHeight = 56
        tableView.correctedContentInset = UIEdgeInsets(top: topOffset, left: 0, bottom: bottomOffset, right: 0)
    }
    
    private func setupHeaderView() {
        headerView.updateHeadlineLabelFont(forWidth: view.bounds.width)
        headerView.bottomSpacing = 60
        headerView.size(fittingWidth: tableView.bounds.width)
        tableView.tableHeaderView = headerView
    }
    
    private func setupFooterView() {
        footerTextFieldView.onConfirm = sendInvite
        footerTextFieldView.shouldConfirm = { [weak self] email in
            guard let `self` = self else { return true }
            return !self.dataSource.data.emails.contains(email)
        }
        footerTextFieldView.size(fittingWidth: tableView.bounds.width)
        tableView.tableFooterView = footerTextFieldView
    }
    
    private func sendInvite(to email: String) {
        if case .unreachable = NetworkStatus.shared().reachability() {
            return footerTextFieldView.errorMessage = "team.invite.error.no_internet".localized.uppercased()
        }
        
        guard let userSession = ZMUserSession.shared() else { return }
        Analytics.shared().tag(TeamInviteEvent.sentInvite(.teamCreation))
        footerTextFieldView.isLoading = true
        
        ZMUser.selfUser().team?.invite(email: email, in: userSession) { [weak self] result in
            self?.handle(inviteResult: result, from:  .manualInput)
        }
    }
    
    private func handle(inviteResult result: InviteResult, from source: InviteSource) {
        switch source {
        case .manualInput: handleManualInputResult(result)
        case .addressBook: handleAddressBookResult(result)
        }
        
        footerTextFieldView.isLoading = false
        topBar.mode = dataSource.data.count == 0 ? .skip : .done
        invitationsCount = invitationsCount + 1
    }
    
    private func handleManualInputResult(_ result: InviteResult) {
        switch result {
        case .success:
            dataSource.append(result)
            footerTextFieldView.clearInput()
        case let .failure(_, error: error):
            footerTextFieldView.errorMessage = error.errorDescription.uppercased()
            footerTextFieldView.errorButton.isHidden = error != .alreadyRegistered
        }
    }
    
    private func handleAddressBookResult(_ result: InviteResult) {
        dataSource.append(result)
        footerTextFieldView.clearInput()
    }
    
    func teamInviteTopBarDidTapButton(_ topBar: TeamInviteTopBar) {
        let inviteResult = invitationsCount == 0 ? Analytics.InviteResult.none : Analytics.InviteResult.invited(invitesCount: invitationsCount)
        
        Analytics.shared().tagTeamFinishedInviteStep(with: inviteResult)
        authenticationCoordinator?.teamInviteViewControllerDidFinish(self)
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
        tableView.correctedScrollIndicatorInsets.adjust(right: -(view.bounds.width - tableView.bounds.width) / 2)
    }
    
    private func updateMainViewWidthConstraint() {
        compactWidthConstraint?.isActive = traitCollection.horizontalSizeClass == .compact
        regularWidthConstraint?.isActive = traitCollection.horizontalSizeClass != .compact
    }
}
