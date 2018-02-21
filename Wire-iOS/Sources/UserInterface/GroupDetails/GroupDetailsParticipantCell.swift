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
import WireExtensionComponents

class GroupDetailsParticipantCell: UICollectionViewCell {
    
    var colorSchemeVariant : ColorSchemeVariant = ColorScheme.default().variant
    let avatar = UserImageView()
    let titleLabel = UILabel()
    let subtitleLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        setup()
    }
    
    fileprivate func setup() {
        backgroundColor = UIColor.wr_color(fromColorScheme: ColorSchemeColorContentBackground, variant: colorSchemeVariant)
        titleLabel.textColor = UIColor.wr_color(fromColorScheme: ColorSchemeColorTextForeground, variant: colorSchemeVariant)
        
        [avatar, titleLabel, subtitleLabel].forEach(contentView.addSubview)
        
        constrain(contentView, titleLabel) { container, titleLabel in
            titleLabel.left == container.left
            titleLabel.right == container.right
            titleLabel.centerY == container.centerY
        }
        
    }
    
    public func configure(with user: ZMUser) {
        avatar.user = user
        titleLabel.attributedText = user.nameIncludingAvailability
        subtitleLabel.text = user.handle
        

    }
    
}


extension ZMBareUser {
    
    var nameIncludingAvailability : NSAttributedString {
        if ZMUser.selfUser().isTeamMember, let user = self as? ZMUser {
            return AvailabilityStringBuilder.string(for: user, with: .list)
        } else {
            return NSAttributedString(string: name)
        }
    }
    
}
