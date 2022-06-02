//
// Wire
// Copyright (C) 2021 Wire Swiss GmbH
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

extension ZMMessageTests {
    @objc(mockEventOfType:forConversation:sender:data:)
    func mockEvent(of type: ZMUpdateEventType,
                   for conversation: ZMConversation?,
                   sender senderID: UUID?,
                   data: [AnyHashable: Any]?) -> ZMUpdateEvent {
        let updateEvent = ZMUpdateEvent()
        updateEvent.type = type

        let serverTimeStamp: Date = conversation?.lastServerTimeStamp?.addingTimeInterval(5) ??
            Date()

        let from = senderID ?? UUID()

        if let remoteIdentifier = conversation?.remoteIdentifier?.transportString(),
           let data = data {

            updateEvent.payload = [
                "conversation": remoteIdentifier,
                "time": serverTimeStamp.transportString(),
                "from": from.transportString(),
                "data": data
            ]
        }

        return updateEvent
    }

    func testThatSpecialKeysAreNotPartOfTheLocallyModifiedKeysForClientMessages() {
        // when
        let message = ZMClientMessage(nonce: NSUUID.create(), managedObjectContext: uiMOC)

        // then
        let keysThatShouldBeTracked = Set<AnyHashable>(["dataSet", "linkPreviewState"])
        XCTAssertEqual(message.keysTrackedForLocalModifications(), keysThatShouldBeTracked)
    }

    func testThatFlagIsNotSetWhenSenderIsNotTheOnlyUser() {
        // given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.remoteIdentifier = UUID()
        conversation.conversationType = .group
        XCTAssertNotNil(conversation)

        let user = ZMUser.insertNewObject(in: uiMOC)
        user.remoteIdentifier = UUID()

        let sender = ZMUser.insertNewObject(in: uiMOC)
        sender.remoteIdentifier = UUID()

        // add selfUser to the conversation
        let userIDs: [ZMTransportEncoding] = [sender.remoteIdentifier as NSUUID,
                                              user.remoteIdentifier as NSUUID]
        var message: ZMSystemMessage?
        performPretendingUiMocIsSyncMoc { [weak self] in
            message = self?.createSystemMessage(from: .conversationMemberJoin, in: conversation, withUsersIDs: userIDs, senderID: sender.remoteIdentifier)
        }

        uiMOC.saveOrRollback()
        _ = waitForAllGroupsToBeEmpty(withTimeout: 0.5)

        // then
        XCTAssertFalse(message!.userIsTheSender)
    }

}
