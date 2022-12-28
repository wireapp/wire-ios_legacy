//
// Wire
// Copyright (C) 2022 Wire Swiss GmbH
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
import WireDataModel

extension ZMConversationMessage {

    typealias ConversationAnnouncement = L10n.Accessibility.ConversationAnnouncement

    /// A notification should be posted when an announcement needs to be sent to VoiceOver.
    func postAnnouncementIfNeeded() {
        if let announcement = announcementText() {
            UIAccessibility.post(notification: .announcement, argument: announcement)
        }
    }

    private func announcementText() -> String? {
        if isKnock {
            return ConversationAnnouncement.Ping.description(senderName)
        } else if isText, let textMessageData = textMessageData {
            let messageText = NSAttributedString.format(message: textMessageData, isObfuscated: isObfuscated)
            return "\(ConversationAnnouncement.Text.description(senderName)), \(messageText.string)"
        } else if isImage {
            return ConversationAnnouncement.Picture.description(senderName)
        } else if isLocation {
            return ConversationAnnouncement.Location.description(senderName)
        } else if isAudio {
            return ConversationAnnouncement.Audio.description(senderName)
        } else if isVideo {
            return ConversationAnnouncement.Video.description(senderName)
        } else if isFile {
            return ConversationAnnouncement.File.description((filename ?? ""), senderName)
        } else if isSystem, let cellDescription = ConversationSystemMessageCellDescription.cells(for: self).first {
            return cellDescription.cellAccessibilityLabel
        }
        return nil
    }

}
