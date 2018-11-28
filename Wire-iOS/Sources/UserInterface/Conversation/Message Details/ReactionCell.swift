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

public class ReactionCell: UICollectionViewCell {
    public let userImageView = UserImageView()
    public let userDisplayNameLabel: UILabel = {
        let label = UILabel()
        label.font = .normalFont
        label.textColor = .from(scheme: .textForeground)

        return label
    }()
    public let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = .smallSemiboldFont
        label.textColor = .from(scheme: .textDimmed)

        return label
    }()

    var displayNameVerticalConstraint: NSLayoutConstraint?
    var displayNameTopConstraint: NSLayoutConstraint?
    
    public var user: ZMUser? {
        didSet {
            guard let user = self.user else {
                self.userDisplayNameLabel.text = ""
                return
            }
            
            self.userImageView.user = user
            self.userDisplayNameLabel.text = user.name

            if let handle = user.handle {
                displayNameTopConstraint?.isActive = true
                displayNameVerticalConstraint?.isActive = false
            } else {
                displayNameTopConstraint?.isActive = false
                displayNameVerticalConstraint?.isActive = true
            }
        }
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.userImageView.userSession = ZMUserSession.shared()
        self.userImageView.initialsFont = UIFont.systemFont(ofSize: 11, weight: UIFont.Weight.light)
        
        self.contentView.addSubview(self.userDisplayNameLabel)
        self.contentView.addSubview(self.subtitleLabel)
        self.contentView.addSubview(self.userImageView)

        let verticalOffset: CGFloat = 3
        
        constrain(self.contentView, self.userImageView, self.userDisplayNameLabel, self.subtitleLabel) { contentView, userImageView, userDisplayNameLabel, subtitleLabel in
            userImageView.leading == contentView.leading + 24
            userImageView.width == userImageView.height
            userImageView.top == contentView.top + 8
            userImageView.bottom == contentView.bottom - 8
            
            userDisplayNameLabel.leading == userImageView.trailing + 24
            userDisplayNameLabel.trailing <= contentView.trailing - 24

            subtitleLabel.top == contentView.centerY + verticalOffset
            subtitleLabel.leading == userDisplayNameLabel.leading
            subtitleLabel.trailing <= contentView.trailing - 24

            displayNameTopConstraint = userDisplayNameLabel.bottom == contentView.centerY + verticalOffset
            displayNameVerticalConstraint = userDisplayNameLabel.centerY == userImageView.centerY
        }

        setupStyle()
    }

    func setupStyle() {
        contentView.backgroundColor = .from(scheme: .textBackground)
    }

    func configure(user: ZMUser, subtitle: String? = nil) {
        self.user = user
        self.subtitleLabel.text = subtitle
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func prepareForReuse() {
        super.prepareForReuse()
        self.user = .none
    }
}
