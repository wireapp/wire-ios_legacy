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
    
    public func updateSpaces() {
        self.topBar.contentScrollView = self.listContentController.collectionView
        self.topBar.setShowSpaces(to: Space.spaces.count > 0)
    }
    
    public func createTopBar() {
        let profileButton = IconButton()
        
        profileButton.setIcon(.selfProfile, with: .tiny, for: UIControlState())
        profileButton.addTarget(self, action: #selector(presentSettings), for: .touchUpInside)
        profileButton.accessibilityIdentifier = "bottomBarSettingsButton"
        profileButton.setIconColor(.white, for: .normal)
        
        if let imageView = profileButton.imageView, let user = ZMUser.selfUser() {
            let newDevicesDot = NewDevicesDot(user: user)
            profileButton.addSubview(newDevicesDot)
            
            constrain(newDevicesDot, imageView) { newDevicesDot, imageView in
                newDevicesDot.top == imageView.top - 3
                newDevicesDot.trailing == imageView.trailing + 3
                newDevicesDot.width == 8
                newDevicesDot.height == 8
            }
        }
        
        self.topBar = ConversationListTopBar()
        
        self.contentContainer.addSubview(self.topBar)
        self.updateSpaces()
        self.topBar.leftView = profileButton
    }
}
