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

class CompositeMessageItemContentTests: BaseCompositeMessageTests {

    func testThatButtonTouchActionInsertsMessageInConversationIfNoneIsSelected() {
        // GIVEN
        let message = compositeMessage(with: compositeProto(items: compositeItemButton(), compositeItemText()))
        guard case .some(.button(let button)) = message.items.first else { return XCTFail() }
        let conversation = self.conversation(withMessage: message)

        // WHEN
        button.touchAction()
        _ = waitForAllGroupsToBeEmpty(withTimeout: 0.5)

        // THEN
        let hiddenMessage = conversation.hiddenMessages.first as? ZMClientMessage
        guard case .some(.buttonAction) = hiddenMessage?.underlyingMessage?.content else { return XCTFail() }
    }

    func testThatButtonTouchActionDoesNotInsertMessageInConversationIfAButtonIsSelected() {
        // GIVEN
        let buttonItem = compositeItemButton()
        let message = compositeMessage(with: compositeProto(items: buttonItem))
        guard case .some(.button(let button)) = message.items.first else { return XCTFail() }
        let conversation = self.conversation(withMessage: message)

        uiMOC.performAndWait {
            let buttonState = WireDataModel.ButtonState.insert(with: buttonItem.button.id, message: message, inContext: self.uiMOC)
            buttonState.state = .selected
            self.uiMOC.saveOrRollback()

            // WHEN
            button.touchAction()

            // THEN
            let lastmessage = conversation.hiddenMessages.first as? ZMClientMessage
            if case .some(.buttonAction) = lastmessage?.underlyingMessage?.content { XCTFail() }
        }
    }

    func testThatButtonTouchActionCreatesButtonStateIfNeeded() {
        // GIVEN
        let id = "123"
        let buttonItem = compositeItemButton(buttonID: id)
        let message = compositeMessage(with: compositeProto(items: buttonItem))
        guard case .some(.button(let button)) = message.items.first else { return XCTFail() }
        _ = conversation(withMessage: message)

        // WHEN
        button.touchAction()
        _ = waitForAllGroupsToBeEmpty(withTimeout: 0.5)

        // THEN
        let buttonState = message.buttonStates?.first(where: {$0.remoteIdentifier == id})
        XCTAssertNotNil(buttonState)
        XCTAssertEqual(WireDataModel.ButtonState.State.selected, buttonState?.state)
    }

    func testThatButtonTouchActionExpiresButtonStateAndDoesntInsertMessage_WhenSenderIsNotInConversation() {
        // GIVEN
        let id = "123"
        let buttonItem = compositeItemButton(buttonID: id)
        let message = compositeMessage(with: compositeProto(items: buttonItem))
        guard case .some(.button(let button)) = message.items.first else { return XCTFail() }
        let conversation = self.conversation(withMessage: message, addSender: false)

        // WHEN
        button.touchAction()
        _ = waitForAllGroupsToBeEmpty(withTimeout: 0.5)

        // THEN
        let buttonState = message.buttonStates?.first(where: {$0.remoteIdentifier == id})
        XCTAssertEqual(buttonState?.isExpired, true)
        XCTAssertEqual(buttonState?.state, WireDataModel.ButtonState.State.unselected)
        let lastmessage = conversation.hiddenMessages.first as? ZMClientMessage
        if case .some(.buttonAction) = lastmessage?.underlyingMessage?.content { XCTFail() }
    }
}
