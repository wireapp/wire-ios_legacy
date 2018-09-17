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

extension ConversationListViewController: NetworkStatusBarDelegate {
    var bottomMargin: CGFloat {
        return CGFloat.NetworkStatusBar.bottomMargin
    }

    func showInIPad(networkStatusViewController: NetworkStatusViewController, with orientation: UIInterfaceOrientation) -> Bool {
        // do not show on iPad for any orientation in regular mode
        return false
    }
}

extension ConversationListViewController {
    
    func currentAccountView() -> BaseAccountView {
        guard let currentAccount = self.account else {
            fatal("No account available")
        }

        let session = ZMUserSession.shared() ?? nil
        let user = session == nil ? nil : ZMUser.selfUser(inUserSession: session!)
        let currentAccountView = AccountViewFactory.viewFor(account: currentAccount,
                                                            user: user)
        currentAccountView.unreadCountStyle = .others
        return currentAccountView
    }

    @objc func createTopBar() {
        let profileAccountView = self.currentAccountView()
        profileAccountView.selected = false
        profileAccountView.autoUpdateSelection = false
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(presentSettings))
        profileAccountView.addGestureRecognizer(tapGestureRecognizer)
        
        profileAccountView.accessibilityTraits = .button
        profileAccountView.accessibilityIdentifier = "bottomBarSettingsButton"
        profileAccountView.accessibilityLabel = "self.voiceover.label".localized
        profileAccountView.accessibilityHint = "self.voiceover.hint".localized
        
        if let user = ZMUser.selfUser() {
            if user.clientsRequiringUserAttention.count > 0 {
                profileAccountView.accessibilityLabel = "self.new-device.voiceover.label".localized
            }
        }
        
        self.topBar = ConversationListTopBar()
        self.topBar.layoutMargins = UIEdgeInsets(top: 0, left: 9, bottom: 0, right: 16)
        self.contentContainer.addSubview(self.topBar)
        self.topBar.leftView = profileAccountView
    }

    @objc func createNetworkStatusBar() {
        self.networkStatusViewController = NetworkStatusViewController()
        networkStatusViewController.delegate = self
        self.addToSelf(networkStatusViewController)
    }
}
