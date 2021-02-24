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
import UIKit
import WireCommonComponents

private let verifiedShieldImage = WireStyleKit.imageOfShieldverified


final class ShareDestinationCell<D: ShareDestination>: UITableViewCell {
    let checkmarkSize: CGFloat = 24
    let avatarSize: CGFloat = 32
    let shieldSize: CGFloat = 20
    let margin: CGFloat = 16
    
    let stackView = UIStackView(axis: .horizontal)
    let titleLabel = UILabel()
    let checkImageView = UIImageView()
    let avatarViewContainer = UIView()
    var avatarView: UIView?
    private let shieldView: UIImageView = {
        let imageView = UIImageView(image: verifiedShieldImage)
        imageView.accessibilityIdentifier = "verifiedShield"
        imageView.isAccessibilityElement = true

        return imageView
    }()

    private let guestUserIcon: UIImageView = {
        let imageView = UIImageView(image: StyleKitIcon.guest.makeImage(size: .tiny, color: UIColor(white: 1.0, alpha: 0.64)))
        imageView.accessibilityIdentifier = "guestUserIcon"
        imageView.isAccessibilityElement = true

        return imageView
    }()
    
    private let legalHoldIcon: UIImageView = {
        let imageView = UIImageView()
        imageView.setIcon(.legalholdactive, size: .tiny, color: .vividRed)
        imageView.accessibilityIdentifier = "legalHoldIcon"
        imageView.isAccessibilityElement = true
        
        return imageView
    }()

    var allowsMultipleSelection: Bool = true {
        didSet {
            self.checkImageView.isHidden = !allowsMultipleSelection
        }
    }
    
    var destination: D? {
        didSet {
            
            guard let destination = destination else { return }
            
            self.titleLabel.text = destination.displayName
            self.shieldView.isHidden = destination.securityLevel != .secure
            self.guestUserIcon.isHidden = !destination.showsGuestIcon
            self.legalHoldIcon.isHidden = !destination.isUnderLegalHold

            if let avatarView = destination.avatarView {
                avatarView.frame = CGRect(x: 0, y: 0, width: avatarSize, height: avatarSize)
                self.avatarViewContainer.addSubview(avatarView)
                self.avatarView = avatarView
            }
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()

        UIView.performWithoutAnimation {
            self.avatarView?.removeFromSuperview()
            self.guestUserIcon.isHidden = true
            self.legalHoldIcon.isHidden = true
            self.shieldView.isHidden = true
            self.checkImageView.isHidden = true
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.backgroundColor = .clear
        
        self.selectionStyle = .none
        self.contentView.backgroundColor = .clear
        self.stackView.backgroundColor = .clear
        self.stackView.spacing = margin
        self.stackView.alignment = .center
        self.backgroundView = UIView()
        self.selectedBackgroundView = UIView()
        
        self.contentView.addSubview(self.stackView)
        
        self.stackView.addArrangedSubview(avatarViewContainer)
        constrain(self.contentView, self.avatarViewContainer) { contentView, avatarView in
            avatarView.centerY == contentView.centerY
            avatarView.width == self.avatarSize
            avatarView.height == self.avatarSize
        }
        
        self.titleLabel.backgroundColor = .clear
        self.titleLabel.textColor = .white
        titleLabel.font = .normalLightFont
        self.titleLabel.setContentCompressionResistancePriority(UILayoutPriority.defaultLow, for: .horizontal)
        
        self.stackView.addArrangedSubview(self.titleLabel)
        
        self.stackView.addArrangedSubview(self.shieldView)
        
        constrain(shieldView) { shieldView in
            shieldView.width == self.shieldSize
            shieldView.height == self.shieldSize
        }
        
        self.stackView.addArrangedSubview(self.guestUserIcon)
        
        constrain(self.guestUserIcon) { guestUserIcon in
            guestUserIcon.width == self.shieldSize
            guestUserIcon.height == self.shieldSize
        }
        
        self.stackView.addArrangedSubview(self.legalHoldIcon)
        
        constrain(self.legalHoldIcon) { legalHoldIcon in
            legalHoldIcon.width == self.shieldSize
            legalHoldIcon.height == self.shieldSize
        }
        
        self.checkImageView.layer.borderColor = UIColor.white.cgColor
        self.checkImageView.layer.borderWidth = 2
        self.checkImageView.contentMode = .center
        self.checkImageView.layer.cornerRadius = self.checkmarkSize / 2.0
        
        self.stackView.addArrangedSubview(self.checkImageView)
        
        constrain(self.contentView, self.stackView, self.titleLabel, self.checkImageView) {
            contentView, stackView, titleLabel, checkImageView in

            stackView.left == contentView.left + margin
            stackView.right == contentView.right - margin
            stackView.top == contentView.top
            stackView.bottom == contentView.bottom
            
            titleLabel.height == 44
            titleLabel.centerY == contentView.centerY
            
            checkImageView.centerY == contentView.centerY
            checkImageView.width == self.checkmarkSize
            checkImageView.height == self.checkmarkSize
         }
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        self.checkImageView.image = selected ? StyleKitIcon.checkmark.makeImage(size: 12, color: .white) : nil
        self.checkImageView.backgroundColor = selected ? .accent() : .clear
    }
}
