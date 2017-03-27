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
    @objc(updateForConversation:)
    public func update(for conversation: ZMConversation?) {
        guard let conversation = conversation else {
            self.titleText = ""
            self.subtitleAttributedText = "" && [:]
            self.rightAccessory.icon = .none
            return
        }
        
        self.titleText = conversation.displayName
        self.avatarView.conversation = conversation
        
        let status = conversation.status
        let statusIcon: ConversationStatusIcon
        if let player = AppDelegate.shared().mediaPlaybackManager.activeMediaPlayer,
            let message = player.sourceMessage,
            message.conversation == conversation {
            statusIcon = .playingMedia
        }
        else {
            statusIcon = status.icon(for: conversation)
        }
        self.rightAccessory.icon = statusIcon
        self.subtitleAttributedText = status.description(for: conversation)
    }
}


