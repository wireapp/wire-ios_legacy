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

final class AccountSelectorController: UIViewController {
    private var accountsView = AccountSelectorView()
    private var selfUserObserverToken: NSObjectProtocol!
    private var applicationDidBecomeActiveToken: NSObjectProtocol!

    init() {
        super.init(nibName: nil, bundle: nil)
        selfUserObserverToken = UserChangeInfo.add(observer: self, forBareUser: ZMUser.selfUser())
        applicationDidBecomeActiveToken = NotificationCenter.default.addObserver(forName: Notification.Name.UIApplicationDidBecomeActive, object: nil, queue: nil, using: { [weak self] _ in
            guard let `self` = self else {
                return
            }
            self.updateShowTeamsIfNeeded()
        })
        
        self.view.addSubview(accountsView)
        constrain(self.view, accountsView) { selfView, accountsView in
            accountsView.edges == selfView.edges
        }
        
        setShowTeams(to: SessionManager.shared?.accountManager.accounts.count > 1)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private var showTeams: Bool = false
    
    internal func updateShowTeamsIfNeeded() {
        let showTeams = SessionManager.shared?.accountManager.accounts.count > 1
        guard showTeams != self.showTeams else { return }
        setShowTeams(to: showTeams)
    }
    
    private func setShowTeams(to showTeams: Bool) {
        self.showTeams = showTeams
        accountsView.isHidden = !showTeams
    }
}

extension AccountSelectorController: ZMUserObserver {
    public func userDidChange(_ changeInfo: UserChangeInfo) {
        guard changeInfo.teamsChanged else {
            return
        }
        updateShowTeamsIfNeeded()
    }
}

