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
    
    
    public func createTopBar() {

        let settingsButton = IconButton()
        
        settingsButton.setIcon(.gear, with: .tiny, for: UIControlState())
        settingsButton.addTarget(self, action: #selector(settingsButtonTapped(_:)), for: .touchUpInside)
        settingsButton.accessibilityIdentifier = "bottomBarSettingsButton"
        settingsButton.setIconColor(.white, for: .normal)
        
        if let imageView = settingsButton.imageView, let user = ZMUser.selfUser() {
            let newDevicesDot = NewDevicesDot(user: user)
            settingsButton.addSubview(newDevicesDot)
            
            constrain(newDevicesDot, imageView) { newDevicesDot, imageView in
                newDevicesDot.top == imageView.top - 3
                newDevicesDot.trailing == imageView.trailing + 3
                newDevicesDot.width == 8
                newDevicesDot.height == 8
            }
        }
        
        self.topBar = ConversationListTopBar()
        
        self.view.addSubview(self.topBar)
        
        if Space.enableSpaces {
            let spacesView = SpaceSelectorView(spaces: Space.spaces)
            self.topBar.middleView = spacesView
        }
        else {
            let titleLabel = UILabel()
            
            titleLabel.font = FontSpec(.medium, .semibold).font
            titleLabel.textColor = ColorScheme.default().color(withName: ColorSchemeColorTextForeground, variant: .dark)
            titleLabel.text = "list.title".localized.uppercased()
            
            self.topBar.middleView = titleLabel
        }

        self.topBar.rightView = settingsButton
    }
    
    @objc public func settingsButtonTapped(_ sender: AnyObject) {
        self.presentSettings()
    }
}
