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

@objcMembers open class ReactionsView: UIView {
    let avatarStackView: UIStackView
    let avatars: [UserImageView]
    let elipsis: UIImageView
    
    var likers: [ZMUser] = [] {
        didSet {
            let maxAvatarsDisplayed = 3
            let visibleLikers: [ZMUser]
            
            if likers.count > maxAvatarsDisplayed {
                elipsis.isHidden = false
                visibleLikers = Array(likers.prefix(maxAvatarsDisplayed - 1))
            } else {
                elipsis.isHidden = true
                visibleLikers = likers
            }
            
            avatars.forEach({ $0.isHidden = true })
            
            for (user, userImage) in zip(visibleLikers, avatars) {
                userImage.user = user
                userImage.isHidden = false
            }
        }
    }
    
    public override init(frame: CGRect) {
        
        elipsis = UIImageView(image: UIImage(for: .ellipsis, iconSize: .like, color:UIColor.from(scheme: .textForeground)))
        elipsis.contentMode = .center
        elipsis.isHidden = true
        
        avatars = (1...3).map({ index in
            let userImage = UserImageView(size: .tiny)
            userImage.userSession = ZMUserSession.shared()
            userImage.initialsFont = UIFont.systemFont(ofSize: 8, weight: UIFont.Weight.light)
            userImage.isHidden = true
            
            constrain(userImage) { userImage in
                userImage.width == userImage.height
                userImage.width == 16
            }
            
            return userImage
        })
        
        avatarStackView = UIStackView(arrangedSubviews: [avatars[0], avatars[1], avatars[2], elipsis])
        
        super.init(frame: frame)
        
        avatarStackView.axis = .horizontal
        avatarStackView.spacing = 4
        avatarStackView.distribution = .fill
        avatarStackView.alignment = .center
        avatarStackView.translatesAutoresizingMaskIntoConstraints = false
        avatarStackView.setContentHuggingPriority(.required, for: .horizontal)
        
        addSubview(avatarStackView)
        
        constrain(self, avatarStackView) { selfView, avatarStackView in
            avatarStackView.edges == selfView.edges
        }
        
        constrain(elipsis) { elipsis in
            elipsis.width == elipsis.height
            elipsis.width == 16
        }
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
