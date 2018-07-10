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

extension ConversationMessageWindowTableViewAdapter: UITableViewDataSource {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.messageWindow.messages.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let message = messageWindow.messages[indexPath.row] as? ZMConversationMessage  else {
            return UITableViewCell()
        }

        let cell = tableView.dequeueReusableCell(withIdentifier: message.cellIdentifier, for: indexPath)

        // Newly created cells will have a size of {320, 44}, which leads to layout problems when they contain `UICollectionViews`.
        // This is needed as long as `ParticipantsCell` contains a `UICollectionView`.
        var bounds = cell.bounds
        bounds.size.width = tableView.bounds.size.width
        cell.bounds = bounds

        guard let conversationCell = cell as? ConversationCell else { return cell }

        conversationCell.searchQueries = searchQueries
        conversationCell.delegate = conversationCellDelegate
        conversationCell.analyticsTracker = analyticsTracker
        // Configuration of the cell is not possible when `ZMUserSession` is not available.
        if let _ = ZMUserSession.shared() {
            configureConversationCell(conversationCell, with: message)
        }
        return conversationCell
    }
}

extension ZMConversationMessage {
    var cellIdentifier: String {
        var cellIdentifier = ConversationUnknownMessageCellId

        if isText {
            cellIdentifier = ConversationTextCellId
        } else if isVideo {
            cellIdentifier = ConversationVideoMessageCellId
        } else if isAudio {
            cellIdentifier = ConversationAudioMessageCellId
        } else if isLocation {
            cellIdentifier = ConversationLocationMessageCellId
        } else if isFile {
            cellIdentifier = ConversationFileTransferCellId
        } else if isImage {
            cellIdentifier = ConversationImageCellId
        } else if isKnock {
            cellIdentifier = ConversationPingCellId
        } else if isSystem, let systemMessageType = systemMessageData?.systemMessageType {
            switch systemMessageType {
            case .connectionRequest:
                cellIdentifier = ConversationConnectionRequestCellId
            case .connectionUpdate:
                break
            case .conversationNameChanged:
                cellIdentifier = ConversationNameChangedCellId
            case .missedCall:
                cellIdentifier = ConversationMissedCallCellId
            case .newClient, .usingNewDevice:
                cellIdentifier = ConversationNewDeviceCellId
            case .ignoredClient:
                cellIdentifier = ConversationIgnoredDeviceCellId
            case .conversationIsSecure:
                cellIdentifier = ConversationVerifiedCellId
            case .potentialGap, .reactivatedDevice:
                cellIdentifier = ConversationMissingMessagesCellId
            case .decryptionFailed, .decryptionFailed_RemoteIdentityChanged:
                cellIdentifier = ConversationCannotDecryptCellId
            case .participantsAdded, .participantsRemoved, .newConversation, .teamMemberLeave:
                cellIdentifier = ParticipantsCell.zm_reuseIdentifier
            case .messageDeletedForEveryone:
                cellIdentifier = ConversationMessageDeletedCellId
            case .performedCall:
                cellIdentifier = ConversationPerformedCallCellId
            case .messageTimerUpdate:
                cellIdentifier = ConversationMessageTimerUpdateCellId
            default:
                break
            }
        } else if let destructionDate = self.destructionDate,
            destructionDate.timeIntervalSinceNow <= 0,
            isObfuscated == false {
            cellIdentifier = ConversationExpiredMessageCellId
        } else {
            cellIdentifier = ConversationUnknownMessageCellId
        }
        
        return cellIdentifier
    }
}
