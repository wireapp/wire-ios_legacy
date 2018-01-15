//
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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
import Cartography

class InviteTeamMemberCell : UICollectionViewCell, Reusable {
    
    let iconView : UIImageView  = UIImageView()
    let titleLabel : UILabel = UILabel()
    
    override init(frame: CGRect) {
        
        super.init(frame: frame)
        
        iconView.image = UIImage.init(for: .envelope, iconSize: .tiny, color: .white)
        iconView.contentMode = .center
        
        titleLabel.text = "peoplepicker.invite_team_members".localized
        titleLabel.font = FontSpec(.normal, .medium).font
        titleLabel.textColor = .white
        [iconView, titleLabel].forEach(contentView.addSubview)
        
        createConstraints()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func createConstraints() {
        let iconSize : CGFloat = 32.0
        
        constrain(contentView, iconView, titleLabel) { container, iconView, titleLabel in
            iconView.width == iconSize
            iconView.height == iconSize
            iconView.leading == container.leading + 16
            iconView.centerY == container.centerY
            
            titleLabel.leading == container.leading + 64
            titleLabel.trailing == container.trailing
            titleLabel.top == container.top
            titleLabel.bottom == container.bottom
        }
    }
    
}
