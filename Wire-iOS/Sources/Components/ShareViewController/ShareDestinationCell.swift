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
    let shieldSize: CGFloat = 20
    let margin: CGFloat = 16
    
    let titleLabel = UILabel()
    let checkImageView = UIImageView()
    let avatarViewContainer = UIView()
    var avatarView : UIView?
    var shieldView: UIImageView?

    var allowsMultipleSelection: Bool = true {
        didSet {
            self.checkImageView.isHidden = !allowsMultipleSelection
        }
    }
    
    var destination: D? {
        didSet {
            self.titleLabel.text = destination?.displayName
            self.shieldView = destination?.securityLevel == .secure ? UIImageView(image: verifiedShieldImage) : nil

            if let avatarView = destination?.avatarView {
                avatarView.frame = CGRect(x: 0, y: 0, width: avatarSize, height: avatarSize)
                self.avatarViewContainer.addSubview(avatarView)
                self.avatarView = avatarView
            }
            
            self.setShieldConstraintsIfNeeded()
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
        
        self.selectionStyle = .none
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

            avatarView.left == contentView.left + margin
            avatarView.centerY == contentView.centerY
            avatarView.width == self.avatarSize
            avatarView.height == avatarView.width
            
            titleLabel.left == avatarView.right + margin
            titleLabel.centerY == contentView.centerY
            titleLabel.right <= checkImageView.left - margin
            
            checkImageView.centerY == contentView.centerY
            checkImageView.right == contentView.right - margin
            checkImageView.width == self.checkmarkSize
            checkImageView.height == checkImageView.width
         }
    }
    
    private func setShieldConstraintsIfNeeded() {
        guard let shieldView = shieldView else { return }
        
        self.contentView.addSubview(shieldView)
        
        constrain(self.contentView, self.titleLabel, self.checkImageView, shieldView) {
            contentView, titleLabel, checkImageView, shieldView in
            titleLabel.right <= shieldView.left - margin
            shieldView.centerY == contentView.centerY
            shieldView.right == checkImageView.left - margin
            shieldView.width == self.shieldSize
            shieldView.height == shieldView.width
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
