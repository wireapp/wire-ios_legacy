//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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

extension ConversationListItemView {
    @objc public func configureFont() {
        self.titleField.font = FontSpec(.normal, .light).font!
    }
    
    internal func configure(with title: String, subtitle: NSAttributedString) {
        self.titleText = title
        self.subtitleAttributedText = subtitle
        self.accessibilityContentsDidChange()
    }
    
    internal func configure(with title: String, subtitle: NSAttributedString, users: [ZMUser]) {
        self.titleText = title
        self.subtitleAttributedText = subtitle
        self.rightAccessory.icon = .pendingConnection
        self.avatarView.conversation = .none
        self.avatarView.users = users
        self.accessibilityContentsDidChange()
    }
    
    @objc(updateForConversation:)
    internal func update(for conversation: ZMConversation?) {
        self.conversation = conversation
        
        guard let conversation = conversation else {
            self.configure(with: "", subtitle: "" && [:])
            return
        }
        
        let title = conversation.displayName
        self.avatarView.conversation = conversation
        
        let status = conversation.status
        let statusIcon: ConversationStatusIcon
        if let player = AppDelegate.shared().mediaPlaybackManager?.activeMediaPlayer,
            let message = player.sourceMessage,
            message.conversation == conversation {
            statusIcon = .playingMedia
        }
        else {
            statusIcon = status.icon(for: conversation)
        }
        self.rightAccessory.icon = statusIcon

        self.configure(with: title, subtitle: status.description(for: conversation))
    }
}


