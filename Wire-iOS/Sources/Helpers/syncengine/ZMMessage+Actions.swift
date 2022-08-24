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
import WireSyncEngine
import WireDataModel

extension ZMConversationMessage {

    /// Whether the message can be digitally signed in.
    var canBeDigitallySigned: Bool {
        guard
            let selfUser = SelfUser.provider?.selfUser,
            selfUser.phoneNumber != nil,
            selfUser.isTeamMember,
            selfUser.hasDigitalSignatureEnabled
        else {
            return false
        }
        return isPDF
    }

    /// Whether the message can be copied.
    var canBeCopied: Bool {
        guard canBeShared else {
            return false
        }
        return MediaShareRestrictionManager(sessionRestriction: ZMUserSession.shared()).canUseClipboard &&
               !isEphemeral &&
               (isText || isImage || isLocation)
    }

    /// Whether the message can be edited.
    var canBeEdited: Bool {
        guard let conversation = conversationLike,
              let sender = senderUser else {
            return false
        }
        return !isEphemeral &&
               isText &&
               conversation.isSelfAnActiveMember &&
               sender.isSelfUser &&
               deliveryState.isOne(of: .delivered, .sent, .read)
    }

    /// Whether the message can be quoted.
    var canBeQuoted: Bool {
        guard let conversation = conversationLike else {
            return false
        }

        return !isEphemeral && conversation.isSelfAnActiveMember && isSent && (isText || isImage || isLocation || isFile)
    }

    /// Whether message details are available for this message.
    var areMessageDetailsAvailable: Bool {
        guard let conversation = conversationLike else {
            return false
        }

        // Do not show the details of the message if it was not sent
        guard isSent else {
            return false
        }

        // There is no message details view in 1:1s.
        guard conversation.conversationType == .group else {
            return false
        }

        // Show the message details in Team groups.
        if conversation.teamRemoteIdentifier != nil {
            return canBeLiked || isSentBySelfUser
        } else {
            return canBeLiked
        }
    }

    /// Whether the user can see the read receipts details for this message.
    var areReadReceiptsDetailsAvailable: Bool {
        // Do not show read receipts if details are not available.
        guard areMessageDetailsAvailable else {
            return false
        }

        // Read receipts are only available in team groups
        guard conversationLike?.teamRemoteIdentifier != nil else {
            return false
        }

        // Only the sender of a message can see read receipts for their messages.
        return isSentBySelfUser
    }

    /// Whether it is possible to download the message content.
    var canBeDownloaded: Bool {
        guard let fileMessageData = self.fileMessageData,
              canBeShared,
              MediaShareRestrictionManager(sessionRestriction: ZMUserSession.shared()).canDownloadMedia else {
            return false
        }
        return isFile && fileMessageData.transferState == .uploaded
    }

    var canCancelDownload: Bool {
        guard let fileMessageData = self.fileMessageData else {
            return false
        }
        return isFile && fileMessageData.downloadState == .downloading
    }

    /// Whether the content of the message can be saved to the disk.
    var canBeSaved: Bool {
        guard canBeShared,
              !isEphemeral,
              MediaShareRestrictionManager(sessionRestriction: ZMUserSession.shared()).canDownloadMedia else {
                  return false
              }

        if isImage {
            return true
        } else if isVideo {
            return videoCanBeSavedToCameraRoll()
        } else if isAudio {
            return audioCanBeSaved()
        } else if isFile, let fileMessageData = self.fileMessageData {
            return fileMessageData.fileURL != nil
        } else {
            return false
        }
    }

    /// Whether it should be possible to forward given message to another conversation.
    var canBeForwarded: Bool {
        if isEphemeral || !canBeShared {
            return false
        }

        if isFile, let fileMessageData = self.fileMessageData {
            return fileMessageData.fileURL != nil
        } else {
            return (isText || isImage || isLocation || isFile)
        }
    }

    /// Whether the message sending failed in the past and we can attempt to resend the message.
    var canBeResent: Bool {
        guard let conversation = conversationLike,
              let sender = senderUser else {
            return false
        }

        return conversation.isSelfAnActiveMember &&
               sender.isSelfUser &&
               (isText || isImage || isLocation || isFile) &&
               deliveryState == .failedToSend
    }

    /// Whether the message can be sent or received.
    var canBeShared: Bool {
        return !isRestricted
    }

}
