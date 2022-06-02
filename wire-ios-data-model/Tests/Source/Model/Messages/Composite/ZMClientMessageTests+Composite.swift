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

class ZMClientMessageTests_Composite: BaseCompositeMessageTests {
    func testThatCompositeMessageDataIsReturned() {
        // GIVEN
        let expectedCompositeMessage = compositeProto(items: compositeItemButton(), compositeItemText())
        let message = compositeMessage(with: expectedCompositeMessage)

        // WHEN
        let compositeMessage = message.underlyingMessage?.composite

        // THEN
        XCTAssertEqual(compositeMessage, expectedCompositeMessage)
        XCTAssertEqual(compositeMessage?.items, expectedCompositeMessage.items)
    }

    func testThatItCreatesButtonStateIfNeeded_WhenReceivingButtonActionConfirmation() {
        // GIVEN
        let nonce = UUID()
        let message = compositeMessage(with: compositeProto(items: compositeItemButton()), nonce: nonce)
        let conversation = self.conversation(withMessage: message)

        let confirmation = ButtonActionConfirmation.with {
            $0.referenceMessageID = nonce.transportString()
            $0.buttonID = "1"
        }

        // WHEN
        uiMOC.performAndWait { [uiMOC] in
            ZMClientMessage.updateButtonStates(withConfirmation: confirmation, forConversation: conversation, inContext: uiMOC)
            uiMOC.saveOrRollback()
        }

        // THEN
        let buttonState = message.buttonStates?.first
        XCTAssertEqual(buttonState?.remoteIdentifier, "1")
    }

    func testThatItUpdatesButtonStates_WhenReceivingButtonActionConfirmation() {
        // GIVEN
        let nonce = UUID()
        let buttonItems = [
            compositeItemButton(buttonID: "1"),
            compositeItemButton(buttonID: "2"),
            compositeItemButton(buttonID: "3"),
            compositeItemButton(buttonID: "4")
        ]

        let message = compositeMessage(with: compositeProto(items: buttonItems[0], buttonItems[1], buttonItems[2], buttonItems[3]), nonce: nonce)

        let conversation = self.conversation(withMessage: message)

        var buttonStates: [WireDataModel.ButtonState]!

        uiMOC.performAndWait { [uiMOC] in
            buttonStates = buttonItems.map { buttonItem in
                return WireDataModel.ButtonState.insert(with: buttonItem.button.id, message: message, inContext: uiMOC)
            }

            buttonStates[0].state = .selected
            buttonStates[1].state = .confirmed
            buttonStates[2].state = .unselected
            buttonStates[3].state = .selected

            uiMOC.saveOrRollback()
        }

        let confirmation = ButtonActionConfirmation.with {
            $0.referenceMessageID = nonce.transportString()
            $0.buttonID = "1"
        }

        // WHEN
        uiMOC.performAndWait { [uiMOC] in
            ZMClientMessage.updateButtonStates(withConfirmation: confirmation, forConversation: conversation, inContext: uiMOC)
            uiMOC.saveOrRollback()
        }

        // THEN
        XCTAssertEqual(buttonStates[0].state, WireDataModel.ButtonState.State.confirmed)
        for buttonState in buttonStates[1...3] {
            XCTAssertEqual(buttonState.state, WireDataModel.ButtonState.State.unselected)
        }
    }

    func testThatItSetsIsExpiredAndUnselectsButtonState_WhenButtonActionMessageExpires() {
        // GIVEN
        let nonce = UUID()
        let message = compositeMessage(with: compositeProto(items: compositeItemButton(buttonID: "1")), nonce: nonce)
        let conversation = self.conversation(withMessage: message)

        var buttonState: WireDataModel.ButtonState!
        uiMOC.performAndWait { [uiMOC] in
            buttonState = WireDataModel.ButtonState.insert(with: "1", message: message, inContext: uiMOC)
            buttonState.state = .selected
            uiMOC.saveOrRollback()
        }

        let buttonAction = ButtonAction(buttonId: "1", referenceMessageId: nonce)

        // WHEN
        ZMClientMessage.expireButtonState(forButtonAction: buttonAction, forConversation: conversation, inContext: uiMOC)
        _ = waitForAllGroupsToBeEmpty(withTimeout: 0.5)

        // THEN
        XCTAssertEqual(buttonState.isExpired, true)
        XCTAssertEqual(buttonState.state, WireDataModel.ButtonState.State.unselected)
    }
}
