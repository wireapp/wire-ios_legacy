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
@testable import WireDataModel

class BaseCompositeMessageTests: BaseZMMessageTests {
    func compositeItemButton(buttonID: String = "1") -> Composite.Item {
        return Composite.Item.with { $0.button = Button.with {
            $0.text = "Button text"
            $0.id = buttonID
            }}
    }

    func compositeItemText() -> Composite.Item {
        return Composite.Item.with { $0.text = Text.with { $0.content = "Text" } }
    }

    func compositeProto(items: Composite.Item...) -> Composite {
        return Composite.with { $0.items = items }
    }

    func compositeMessage(with proto: Composite, nonce: UUID = UUID()) -> ZMClientMessage {
        let genericMessage = GenericMessage.with {
            $0.composite = proto
            $0.messageID = nonce.transportString()
        }
        let message = ZMClientMessage(nonce: nonce, managedObjectContext: uiMOC)

        do {
            try message.setUnderlyingMessage(genericMessage)
        } catch {
            XCTFail()
        }

        return message
    }

    func conversation(withMessage message: ZMClientMessage, addSender: Bool = true) -> ZMConversation {
        let user = ZMUser.insertNewObject(in: uiMOC)
        user.remoteIdentifier = UUID()
        message.sender = user

        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.append(message)

        guard addSender else { return conversation }

        let participantRole = ParticipantRole.insertNewObject(in: uiMOC)
        participantRole.user = user
        conversation.participantRoles = Set([participantRole])

        return conversation
    }
}
