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

extension ZMConversation {

    @NSManaged dynamic public var hasReadReceiptsEnabled: Bool

    /// Confirm unread received messages as read.
    ///
    /// - Parameters:
    ///     - range: Unread messages received within this date range will be confirmed as read.

    @discardableResult
    func confirmUnreadMessagesAsRead(in range: ClosedRange<Date>) -> [ZMClientMessage] {
        let unreadMessagesNeedingConfirmation = unreadMessages(in: range).filter(\.needsReadConfirmation)
        var confirmationMessages: [ZMClientMessage] = []

        for messages in unreadMessagesNeedingConfirmation.partition(by: \.sender).values {
            guard
                !messages.isEmpty,
                let confirmation = Confirmation(messageIds: messages.compactMap(\.nonce), type: .read)
            else {
                continue
            }

            do {
                let confirmationMessage = try appendClientMessage(with: GenericMessage(content: confirmation), expires: false, hidden: true)
                confirmationMessages.append(confirmationMessage)
            } catch {
                Logging.messageProcessing.warn("Failed to append confirmation. Reason: \(error.localizedDescription)")
            }

        }

        return confirmationMessages
    }

    @discardableResult @objc
    public func appendMessageReceiptModeChangedMessage(fromUser user: ZMUser, timestamp: Date, enabled: Bool) -> ZMSystemMessage {
        let message = appendSystemMessage(
            type: enabled ? .readReceiptsEnabled : .readReceiptsDisabled,
            sender: user,
            users: [],
            clients: nil,
            timestamp: timestamp
        )

        if isArchived && mutedMessageTypes == .none {
            isArchived = false
        }

        return message
    }

    @discardableResult @objc
    public func appendMessageReceiptModeIsOnMessage(timestamp: Date) -> ZMSystemMessage {
        let message = appendSystemMessage(
            type: .readReceiptsOn,
            sender: creator,
            users: [],
            clients: nil,
            timestamp: timestamp
        )

        return message
    }

}
