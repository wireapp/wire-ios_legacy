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
        
        self.topBar = ConversationListTopBar()
        
        self.view.addSubview(self.topBar)
        
        let titleLabel = UILabel()
        titleLabel.font = UIFont(magicIdentifier: "style.text.small.font_spec")
        titleLabel.textColor = ColorScheme.default().color(withName: ColorSchemeColorTextForeground, variant: .dark)
        titleLabel.text = "list.title".localized.uppercased()
        
        self.topBar.middleView = titleLabel
        self.topBar.rightView = settingsButton
    }
    
    @objc public func settingsButtonTapped(_ sender: AnyObject) {
        self.presentSettings()
    }
}
