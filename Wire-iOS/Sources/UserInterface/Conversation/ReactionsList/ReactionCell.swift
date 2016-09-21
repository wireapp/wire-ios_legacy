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
import zmessaging
import Cartography
import Classy

@objc public class ReactionCell: UICollectionViewCell {
    public let userImageView = UserImageView(magicPrefix: "people_picker.search_results_mode")
    public let userNameLabel = UILabel()
    
    public var user: ZMUser? {
        didSet {
            guard let user = self.user else {
                self.userNameLabel.text = ""
                return
            }
            
            self.userImageView.user = user
            self.userNameLabel.text = user.displayName
        }
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.contentView.addSubview(self.userNameLabel)
        self.contentView.addSubview(self.userImageView)
        
        constrain(self.contentView, self.userImageView, self.userNameLabel) { contentView, userImageView, userNameLabel in
            userImageView.left == contentView.left + 24
            userImageView.width == userImageView.height
            userImageView.top == contentView.top + 8
            userImageView.bottom == contentView.bottom - 8
            
            userNameLabel.left == userImageView.right + 24
            userNameLabel.centerY == userImageView.centerY
            userNameLabel.right <= contentView.right - 24
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
    
    static var reuseIdentifier: String {
        return "\(self)"
    }
    
    override public var reuseIdentifier: String? {
        return type(of: self).reuseIdentifier
    }
}
