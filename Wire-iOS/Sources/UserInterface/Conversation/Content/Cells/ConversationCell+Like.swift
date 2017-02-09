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

import UIKit


public extension ConversationCell {

    public func createLikeButton() {
        self.likeButton = LikeButton()
        self.likeButton.translatesAutoresizingMaskIntoConstraints = false
        self.likeButton.accessibilityIdentifier = "likeButton"
        self.likeButton.accessibilityLabel = "likeButton"
        self.likeButton.addTarget(self, action: #selector(ConversationCell.likeMessage(_:)), for: .touchUpInside)
        self.likeButton.setIcon(.liked, with: .like, for: .normal)
        self.likeButton.setIconColor(ColorScheme.default().color(withName: ColorSchemeColorTextDimmed), for: .normal)
        self.likeButton.setIcon(.liked, with: .like, for: .selected)
        self.likeButton.setIconColor(UIColor(for: .vividRed), for: .selected)
        self.likeButton.hitAreaPadding = CGSize(width: 20, height: 20)
        self.contentView.addSubview(self.likeButton)
    }
    
    @objc public func configureLikeButtonForMessage(_ message: ZMConversationMessage) {
        self.likeButton.setSelected(message.liked, animated: false)
    }
    
    @objc public func didDoubleTapMessage(_ sender: AnyObject!) {
        self.likeMessage(sender)
    }
    
    @objc public func likeMessage(_ sender: AnyObject!) {
        guard message.canBeLiked else { return }

        Settings.shared().likeTutorialCompleted = true
        
        let reactionType : ReactionType = message.liked ? .unlike : .like
        trackReaction(sender, reaction: reactionType)

        self.likeButton.setSelected(!self.message.liked, animated: true)
        delegate.conversationCell!(self, didSelect: .like)
    }
    
    func trackReaction(_ sender: AnyObject, reaction: ReactionType){
        var interactionMethod = InteractionMethod.undefined
        if sender is LikeButton {
            interactionMethod = .button
        }
        if sender is UIMenuController {
            interactionMethod = .menu
        }
        if sender is UITapGestureRecognizer {
            interactionMethod = .doubleTap
        }
        Analytics.shared()?.tagReactedOnMessage(message, reactionType:reaction, method: interactionMethod)
    }
}
