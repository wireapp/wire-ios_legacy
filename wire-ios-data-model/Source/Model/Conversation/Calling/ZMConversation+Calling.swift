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

public extension ZMConversation {

    @discardableResult
    @objc func appendMissedCallMessage(fromUser user: ZMUser, at timestamp: Date, relevantForStatus: Bool = true) -> ZMSystemMessage {
        let associatedMessage = associatedSystemMessage(of: .missedCall, sender: user)

        let message = appendSystemMessage(
            type: .missedCall,
            sender: user,
            users: [user],
            clients: nil,
            timestamp: timestamp,
            relevantForStatus: relevantForStatus
        )

        if isArchived && mutedMessageTypes == .none {
            isArchived = false
        }

        associatedMessage?.addChild(message)

        managedObjectContext?.enqueueDelayedSave()
        return message
    }

    @discardableResult
    @objc func appendPerformedCallMessage(with duration: TimeInterval, caller: ZMUser) -> ZMSystemMessage {
        let associatedMessage = associatedSystemMessage(of: .performedCall, sender: caller)

        let message = appendSystemMessage(
            type: .performedCall,
            sender: caller,
            users: [caller],
            clients: nil,
            timestamp: Date(),
            duration: duration
        )

        if isArchived && mutedMessageTypes == .none {
            isArchived = false
        }

        associatedMessage?.addChild(message)

        managedObjectContext?.enqueueDelayedSave()
        return message
    }

    private func associatedSystemMessage(of type: ZMSystemMessageType, sender: ZMUser) -> ZMSystemMessage? {
        guard let lastMessage = lastMessage as? ZMSystemMessage,
              lastMessage.systemMessageType == type,
              lastMessage.sender == sender
        else { return nil }

        return lastMessage
    }

}

public extension ZMSystemMessage {

    func addChild(_ message: ZMSystemMessage) {
        mutableSetValue(forKey: #keyPath(ZMSystemMessage.childMessages)).add(message)
        message.visibleInConversation = nil
        message.hiddenInConversation = conversation

        managedObjectContext?.processPendingChanges()
    }

}
