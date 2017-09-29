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

extension ConversationListViewController {
    
    func currentAccountView() -> BaseAccountView {
        guard let currentAccount = SessionManager.shared?.accountManager.selectedAccount else {
            fatal("No account available")
        }
        let currentAccountView = AccountViewFactory.viewFor(account: currentAccount,
                                                            user: ZMUser.selfUser(inUserSession: ZMUserSession.shared()!))
        currentAccountView.invertUnreadMessagesCount = true
        return currentAccountView
    }
    
    public func createTopBar() {
        let profileAccountView = self.currentAccountView()
        profileAccountView.selected = false
        profileAccountView.autoupdateSelection = false
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(presentSettings))
        profileAccountView.addGestureRecognizer(tapGestureRecognizer)
        
        profileAccountView.accessibilityTraits = UIAccessibilityTraitButton
        profileAccountView.accessibilityIdentifier = "bottomBarSettingsButton"
        profileAccountView.accessibilityLabel = "self.voiceover.label".localized
        profileAccountView.accessibilityHint = "self.voiceover.hint".localized
        
        if let user = ZMUser.selfUser() {
            if user.clientsRequiringUserAttention.count > 0 {
                profileAccountView.accessibilityLabel = "self.new-device.voiceover.label".localized
            }
        }
        
        self.topBar = ConversationListTopBar()
        self.topBar.layoutMargins = UIEdgeInsetsMake(0, 9, 0, 16)
        self.contentContainer.addSubview(self.topBar)
        self.topBar.leftView = profileAccountView
    }
}
