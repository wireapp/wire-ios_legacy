//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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
import WireSyncEngine
import Cartography
import Classy

@objc public class ReactionCell: UICollectionViewCell, Reusable {
    public let userImageView = UserImageView(magicPrefix: "people_picker.search_results_mode")
    public let userDisplayNameLabel = UILabel()
    public let usernameLabel = UILabel()

    var displayNameVerticalConstraint: NSLayoutConstraint?
    var displayNameTopConstraint: NSLayoutConstraint?
    
    public var user: ZMUser? {
        didSet {
            guard let user = self.user else {
                self.userDisplayNameLabel.text = ""
                self.usernameLabel.text = ""
                return
            }
            
            self.userImageView.user = user
            self.userDisplayNameLabel.text = user.name

            if let handle = user.handle {
                displayNameTopConstraint?.isActive = true
                displayNameVerticalConstraint?.isActive = false
                usernameLabel.text = "@" + handle
            } else {
                displayNameTopConstraint?.isActive = false
                displayNameVerticalConstraint?.isActive = true
                usernameLabel.text = ""
            }
        }
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.userImageView.userSession = ZMUserSession.shared()
        
        self.contentView.addSubview(self.userDisplayNameLabel)
        self.contentView.addSubview(self.usernameLabel)
        self.contentView.addSubview(self.userImageView)

        let verticalOffset: CGFloat = 3
        
        constrain(self.contentView, self.userImageView, self.userDisplayNameLabel, self.usernameLabel) { contentView, userImageView, userDisplayNameLabel, usernameLabel in
            userImageView.leading == contentView.leading + 24
            userImageView.width == userImageView.height
            userImageView.top == contentView.top + 8
            userImageView.bottom == contentView.bottom - 8
            
            userDisplayNameLabel.leading == userImageView.trailing + 24
            userDisplayNameLabel.trailing <= contentView.trailing - 24

            usernameLabel.top == contentView.centerY + verticalOffset
            usernameLabel.leading == userDisplayNameLabel.leading
            usernameLabel.trailing <= contentView.trailing - 24

            displayNameTopConstraint = userDisplayNameLabel.bottom == contentView.centerY + verticalOffset
            displayNameVerticalConstraint = userDisplayNameLabel.centerY == userImageView.centerY
        }
        
        CASStyler.default().styleItem(self)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func prepareForReuse() {
        super.prepareForReuse()
        self.user = .none
    }
}
