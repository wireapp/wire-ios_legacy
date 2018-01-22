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
import Cartography


private let verifiedShieldImage = WireStyleKit.imageOfShieldverified()


final class ShareDestinationCell<D: ShareDestination>: UITableViewCell {
    let checkmarkSize: CGFloat = 24
    let avatarSize: CGFloat = 32
    
    let titleLabel = UILabel()
    let checkImageView = UIImageView()
    let avatarViewContainer = UIView()
    var avatarView : UIView?

    var destination: D? {
        didSet {
            self.titleLabel.text = destination?.displayName
            self.accessoryView = destination?.securityLevel == .secure ? UIImageView(image: verifiedShieldImage) : nil
            
            if let avatarView = destination?.avatarView {
                avatarView.frame = CGRect(x: 0, y: 0, width: avatarSize, height: avatarSize)
                self.avatarViewContainer.addSubview(avatarView)
                self.avatarView = avatarView
            }
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        avatarView?.removeFromSuperview()
    }

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.backgroundColor = .clear
        self.titleLabel.cas_styleClass = "normal-light"
        self.titleLabel.backgroundColor = .clear
        self.titleLabel.textColor = .white
        
        self.contentView.backgroundColor = .clear
        self.backgroundView = UIView()
        self.selectedBackgroundView = UIView()
        
        self.checkImageView.layer.borderColor = UIColor.white.cgColor
        self.checkImageView.layer.borderWidth = 2
        self.checkImageView.contentMode = .center
        self.checkImageView.layer.cornerRadius = self.checkmarkSize / 2.0
        
        self.contentView.addSubview(self.avatarViewContainer)
        self.contentView.addSubview(self.titleLabel)
        self.contentView.addSubview(self.checkImageView)
        
        constrain(self.contentView, self.avatarViewContainer, self.titleLabel, self.checkImageView) {
            contentView, avatarView, titleLabel, checkImageView in

            avatarView.left == contentView.left + 16
            avatarView.centerY == contentView.centerY
            avatarView.width == self.avatarSize
            avatarView.height == avatarView.width
            
            titleLabel.left == avatarView.right + 16
            titleLabel.centerY == contentView.centerY
            titleLabel.right <= checkImageView.left - 16
            
            checkImageView.centerY == contentView.centerY
            checkImageView.right == contentView.right - 16
            checkImageView.width == self.checkmarkSize
            checkImageView.height == checkImageView.width
         }
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        self.checkImageView.image = selected ? UIImage(for: .checkmark, iconSize: .like, color: .white) : nil
        self.checkImageView.backgroundColor = selected ? ColorScheme.default().color(withName: ColorSchemeColorAccent) : UIColor.clear
    }
}
