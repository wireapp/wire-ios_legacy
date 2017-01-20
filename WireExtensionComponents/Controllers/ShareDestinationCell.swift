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


final class ShareDestinationCell<D: ShareDestination>: UITableViewCell, Reusable {
    let checmarkSize: CGFloat = 24
    
    let titleLabel = UILabel()
    let checkImageView = UIImageView()

    var destination: D? {
        didSet {
            self.titleLabel.text = destination?.displayName
            self.accessoryView = destination?.securityLevel == .secure ? UIImageView(image: verifiedShieldImage) : nil
        }
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
        self.checkImageView.layer.cornerRadius = self.checmarkSize / 2.0

        self.contentView.addSubview(self.titleLabel)
        self.contentView.addSubview(self.checkImageView)
        
        constrain(self.contentView, self.titleLabel, self.checkImageView) { contentView, titleLabel, checkImageView in
            checkImageView.centerY == contentView.centerY
            checkImageView.left == contentView.left + 16
            checkImageView.width == self.checmarkSize
            checkImageView.height == checkImageView.width
            
            titleLabel.left == checkImageView.right + 24
            titleLabel.centerY == contentView.centerY
            titleLabel.right <= contentView.right - 16
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
