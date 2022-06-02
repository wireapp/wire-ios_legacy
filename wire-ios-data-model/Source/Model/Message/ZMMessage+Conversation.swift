//
// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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

extension ZMMessage {

    @objc(usersFromUpdateEvent:context:)
    static func users(from updateEvent: ZMUpdateEvent, context: NSManagedObjectContext) -> [ZMUser] {
        return updateEvent.users(in: context, createIfNeeded: true)
    }
}

extension ZMMessage {
    var isSenderInConversation: Bool {
        return conversation?.has(participantWithId: sender?.userId) ?? false
    }
}

extension ZMMessage {
    @objc(nonceFromPostPayload:)
    func nonce(fromPostPayload payload: [AnyHashable: Any]) -> UUID? {
        let eventType = ZMUpdateEvent.updateEventType(for: payload.optionalString(forKey: "type") ?? "")
        switch eventType {
        case .conversationMessageAdd,
             .conversationKnock:
            return payload.dictionary(forKey: "data")?["nonce"] as? UUID
        case .conversationClientMessageAdd,
             .conversationOtrMessageAdd:
            // if event is otr message then payload should be already decrypted and should contain generic message data
            let base64Content = payload.string(forKey: "data")
            let message = GenericMessage(withBase64String: base64Content)
            guard let  messageID = message?.messageID else {
                return nil
            }
            return UUID(uuidString: messageID)
        default:
            return nil
        }
    }
}
