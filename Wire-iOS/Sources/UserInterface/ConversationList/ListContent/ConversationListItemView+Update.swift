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


    /// configure without a conversation, i.e. when displaying a pending user
    ///
    /// - Parameters:
    ///   - title: title of the cell
    ///   - subtitle: subtitle of the cell
    ///   - users: the pending user(s) waiting for self user to accept connection request
    func configure(with title: NSAttributedString?, subtitle: NSAttributedString?, users: [ZMUser]) {
        self.titleText = title
        self.subtitleAttributedText = subtitle
        self.rightAccessory.icon = .pendingConnection
        avatarView.configure(context: .connect(users: users))
        
        labelsStack.accessibilityLabel = title?.string
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
            labelsStack.accessibilityLabel = title?.string
        } else {
            /// outgoing request
            title = conversation.displayName.attributedString
            labelsStack.accessibilityLabel = conversation.displayName
        }

        // Configure the avatar
        avatarView.configure(context: .conversation(conversation: conversation))

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

        if let statusIconAccessibilityValue = rightAccessory.accessibilityValue {
            statusComponents.append(statusIconAccessibilityValue)
        }

        if conversation.activeParticipants.first?.isPendingApproval == true {
            statusComponents.append("pending approval")
        }

        labelsStack.accessibilityValue = FormattedText.list(from: statusComponents)
        configure(with: title, subtitle: status.description(for: conversation))
    }
}
