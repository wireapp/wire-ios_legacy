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

import Foundation
import UIKit
import Cartography
import WireSyncEngine

final class AccountSelectorController: UIViewController {
    private var accountsView = AccountSelectorView()
    private var applicationDidBecomeActiveToken: NSObjectProtocol!

    init() {
        super.init(nibName: nil, bundle: nil)

        applicationDidBecomeActiveToken = NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: nil, using: { [weak self] _ in
            guard let `self` = self else {
                return
            }
            self.updateShowAccountsIfNeeded()
        })

        accountsView.delegate = self
        self.view.addSubview(accountsView)
        constrain(self.view, accountsView) { selfView, accountsView in
            accountsView.edges == selfView.edges
        }

        setShowAccounts(to: SessionManager.shared?.accountManager.accounts.count > 1)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var showAccounts: Bool = false

    func updateShowAccountsIfNeeded() {
        let showAccounts = SessionManager.shared?.accountManager.accounts.count > 1
        guard showAccounts != self.showAccounts else { return }
        setShowAccounts(to: showAccounts)
    }

    private func setShowAccounts(to showAccounts: Bool) {
        self.showAccounts = showAccounts
        accountsView.isHidden = !showAccounts
        self.view.frame.size = accountsView.frame.size
    }
}

extension AccountSelectorController: AccountSelectorViewDelegate {

    func accountSelectorDidSelect(account: Account) {
        guard
            account != SessionManager.shared?.accountManager.selectedAccount,
            ZClientViewController.shared?.conversationListViewController.presentedViewController != nil
        else {
            return
        }

        ZClientViewController.shared?.conversationListViewController.dismiss(animated: true,
                                                                             completion: {
            AppDelegate.shared.mediaPlaybackManager?.stop()
            SessionManager.shared?.select(account)
        })
    }
}

