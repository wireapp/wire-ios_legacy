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


public extension ConversationCell {

    public func createLikeButton() {
        self.likeButton = LikeButton()
        self.likeButton.translatesAutoresizingMaskIntoConstraints = false
        self.likeButton.accessibilityIdentifier = "likeButton"
        self.likeButton.addTarget(self, action: #selector(ConversationCell.likeMessage(_:)), forControlEvents: .TouchUpInside)
        self.likeButton.setIcon(.Liked, withSize: .Like, forState: .Normal)
        self.likeButton.setIconColor(ColorScheme.defaultColorScheme().colorWithName(ColorSchemeColorTextDimmed), forState: .Normal)
        self.likeButton.setIcon(.Liked, withSize: .Like, forState: .Selected)
        self.likeButton.setIconColor(UIColor(forZMAccentColor: .VividRed), forState: .Selected)
        self.likeButton.hitAreaPadding = CGSizeMake(20, 20)
        self.addSubview(self.likeButton)
    }
    
    @objc public func configureReactionsForMessage(message: ZMMessage) {
        self.likeButton.setSelected(message.liked, animated: false)
    }
    
    @objc public func likeMessage(button: AnyObject!) {
        guard message.canBeLiked else { return }
        self.messageToolboxView.forceShowTimestamp = false

        ZMUserSession.sharedSession().performChanges {
            self.message.liked = !self.message.liked
            self.likeButton.setSelected(self.message.liked, animated: true)
            self.messageToolboxView.configureForMessage(self.message, animated: true)
        }
    }
    
}
