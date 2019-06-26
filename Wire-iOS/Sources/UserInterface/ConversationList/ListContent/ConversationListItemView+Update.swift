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
import FormatterKit

extension ConversationListItemView {
    @objc public func configureFont() {
        self.titleField.font = FontSpec(.normal, .light).font!
    }
    
    @objc func configure(with title: NSAttributedString?, subtitle: NSAttributedString?) {
        self.titleText = title
        self.subtitleAttributedText = subtitle
    }
    
    @objc func configure(with title: NSAttributedString?, subtitle: NSAttributedString?, users: [ZMUser]) {
        self.titleText = title
        self.subtitleAttributedText = subtitle
        self.rightAccessory.icon = .pendingConnection
        self.avatarView.conversation = .none
        self.avatarView.users = users
    }
    
    @objc(updateForConversation:)
    func update(for conversation: ZMConversation?) {
        self.conversation = conversation
        
        guard let conversation = conversation else {
            self.configure(with: nil, subtitle: nil)
            return
        }

        let status = conversation.status

        // Configure the subtitle
        var statusComponents: [String] = []
        let subtitle = status.description(for: conversation)
        let subtitleString = subtitle.string

        if !subtitleString.isEmpty {
            statusComponents.append(subtitleString)
        }

        // Configure the title and status
        let title: NSAttributedString?

        if ZMUser.selfUser().isTeamMember, let connectedUser = conversation.connectedUser {
            title = AvailabilityStringBuilder.string(for: connectedUser, with: .list)

            if connectedUser.availability != .none {
                statusComponents.append(connectedUser.availability.localizedName)
            }
        } else {
            title = conversation.displayName.attributedString
            accessibilityLabel = conversation.displayName
        }

        // Configure the avatar
        self.avatarView.conversation = conversation

        // Configure the accessory
        let statusIcon: ConversationStatusIcon?
        if let player = AppDelegate.shared().mediaPlaybackManager?.activeMediaPlayer,
            let message = player.sourceMessage,
            message.conversation == conversation {
            statusIcon = .playingMedia
        }
        else {
            statusIcon = status.icon(for: conversation)
        }
        self.rightAccessory.icon = statusIcon

        if case .silenced? = statusIcon {
            statusComponents.append("conversation.status.silenced".localized)
        }

        accessibilityValue = FormattedText.list(from: statusComponents)
        self.configure(with: title, subtitle: status.description(for: conversation))
    }
}
