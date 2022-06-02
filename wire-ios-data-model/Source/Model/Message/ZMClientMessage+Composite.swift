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

// MARK: - ConversationCompositeMessage

extension ZMClientMessage: ConversationCompositeMessage {
    public var compositeMessageData: CompositeMessageData? {
        guard case .some(.composite) = underlyingMessage?.content else {
            return nil
        }
        return self
    }
}

// MARK: - CompositeMessageData
extension ZMClientMessage: CompositeMessageData {
    public var items: [CompositeMessageItem] {
        guard let message = underlyingMessage, case .some(.composite) = message.content else {
            return []
        }
        var items = [CompositeMessageItem]()
        for protoItem in message.composite.items {
            guard let compositeMessageItem = CompositeMessageItem(with: protoItem, message: self) else { continue }
            items += [compositeMessageItem]
        }
        return items
    }
}

// MARK: - ButtonStates Interface
extension ZMClientMessage {
    static func updateButtonStates(withConfirmation confirmation: ButtonActionConfirmation,
                                   forConversation conversation: ZMConversation,
                                   inContext moc: NSManagedObjectContext) {
        let nonce = UUID(uuidString: confirmation.referenceMessageID)
        let message = ZMClientMessage.fetch(withNonce: nonce, for: conversation, in: moc)
        message?.updateButtonStates(withConfirmation: confirmation)
    }

    static func expireButtonState(forButtonAction buttonAction: ButtonAction,
                                  forConversation conversation: ZMConversation,
                                  inContext moc: NSManagedObjectContext) {
        let nonce = UUID(uuidString: buttonAction.referenceMessageID)
        let message = ZMClientMessage.fetch(withNonce: nonce, for: conversation, in: moc)
        message?.expireButtonState(withButtonAction: buttonAction)
    }
}

// MARK: - ButtonStates Helpers
extension ZMClientMessage {
    private func updateButtonStates(withConfirmation confirmation: ButtonActionConfirmation) {
        guard let moc = managedObjectContext else { return }

        if !containsButtonState(withId: confirmation.buttonID) {
            ButtonState.insert(with: confirmation.buttonID, message: self, inContext: moc)
        }
        buttonStates?.confirmButtonState(withId: confirmation.buttonID)
    }

    private func containsButtonState(withId buttonId: String) -> Bool {
        return buttonStates?.contains(where: { $0.remoteIdentifier == buttonId }) ?? false
    }

    private func expireButtonState(withButtonAction buttonAction: ButtonAction) {
        let state = buttonStates?.first(where: { $0.remoteIdentifier == buttonAction.buttonID })
        managedObjectContext?.performGroupedBlock { [managedObjectContext] in
            state?.isExpired = true
            state?.state = .unselected
            managedObjectContext?.saveOrRollback()
        }
    }
}
