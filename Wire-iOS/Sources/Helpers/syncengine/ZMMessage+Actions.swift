//
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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

extension ZMConversationMessage {

    /// Whether the message can be copied.
    var canBeCopied: Bool {
        return !isEphemeral && (isText || isImage || isLocation)
    }
    
    /// Whether the message can be edited.
    var canBeEdited: Bool {
        guard let conversation = self.conversation,
              let sender = self.sender else {
            return false
        }
        return !isEphemeral &&
               isText &&
               conversation.isSelfAnActiveMember &&
               sender.isSelfUser &&
               deliveryState.isOne(of: [.delivered, .sent])
    }
    
    /// Whether the message can be quoted.
    var canBeQuoted: Bool {
        guard let conversation = self.conversation else {
            return false
        }

        let isSent = deliveryState.isOne(of: [.delivered, .sent])
        return !isEphemeral && conversation.isSelfAnActiveMember && isSent && (isText || isImage || isLocation || isFile)
    }

    /// Wether it is possible to download the message content.
    var canBeDownloaded: Bool {
        guard let fileMessageData = self.fileMessageData else {
            return false
        }
        return isFile && fileMessageData.transferState.isOne(of: .uploaded, .failedDownload)
    }

    var canCancelDownload: Bool {
        guard let fileMessageData = self.fileMessageData else {
            return false
        }
        return isFile && fileMessageData.transferState == .downloading
    }
    
    /// Wether the content of the message can be saved to the disk.
    var canBeSaved: Bool {
        if isEphemeral {
            return false
        }
        
        if isImage {
            return true
        }
        else if isVideo {
            return videoCanBeSavedToCameraRoll()
        }
        else if isAudio {
            return audioCanBeSaved()
        }
        else if isFile, let fileMessageData = self.fileMessageData {
            return fileMessageData.fileURL != nil
        }
        else {
            return false
        }
    }
    
    /// Wether it should be possible to forward given message to another conversation.
    var canBeForwarded: Bool {
        if isEphemeral {
            return false
        }

        if isFile, let fileMessageData = self.fileMessageData {
            return fileMessageData.fileURL != nil
        }
        else {
            return (isText || isImage || isLocation || isFile)
        }
    }

    /// Wether the message sending failed in the past and we can attempt to resend the message.
    var canBeResent: Bool {
        guard let conversation = self.conversation,
              let sender = self.sender else {
            return false
        }
        
        return conversation.isSelfAnActiveMember &&
               sender.isSelfUser &&
               (isText || isImage || isLocation || isFile) &&
               deliveryState == .failedToSend
    }
}
