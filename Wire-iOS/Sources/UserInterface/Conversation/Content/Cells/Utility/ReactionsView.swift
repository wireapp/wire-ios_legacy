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

@objc public class ReactionsView: UIView {
    let avatarStack = StackView()
    static let maxAvatarsDisplayed = 2
    
    var likers: [ZMUser] = [] {
        didSet {
            self.avatarStack.subviews.forEach { $0.removeFromSuperview() }
            
            let likersToDisplay: [ZMUser]
            let shouldDisplayEllipsis: Bool
            
            if likers.count > self.dynamicType.maxAvatarsDisplayed + 1 {
                likersToDisplay = Array<ZMUser>(likers.prefix(self.dynamicType.maxAvatarsDisplayed))
                shouldDisplayEllipsis = true
            }
            else {
                likersToDisplay = likers
                shouldDisplayEllipsis = false
            }
            
            for user in likersToDisplay {
                let userImage = UserImageView(magicPrefix: "content.reaction")
                userImage.user = user
                constrain(userImage) { userImage in
                    userImage.width == userImage.height
                    userImage.width == 16
                }
                self.avatarStack.addSubview(userImage)
            }
            
            if shouldDisplayEllipsis {
                let iconColor = ColorScheme.defaultColorScheme().colorWithName(ColorSchemeColorTextForeground)
                let imageView = UIImageView(image: UIImage(forIcon: .Elipsis, iconSize: .Like, color:iconColor))
                imageView.contentMode = .Center
                constrain(imageView) { imageView in
                    imageView.width == imageView.height
                    imageView.width == 16
                }
                self.avatarStack.addSubview(imageView)
            }
        }
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.avatarStack.direction = .Horizontal
        self.avatarStack.spacing = 4
        self.addSubview(self.avatarStack)
        constrain(self, self.avatarStack) { selfView, avatarStack in
            avatarStack.edges == selfView.edges
        }
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
