//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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

import XCTest
@testable import WireDataModel

class ZMOTRMessage_SelfConversationUpdateEventTests: BaseZMClientMessageTests {

    func testThatWeIgnoreClearedEventNotSentFromSelfUser() {

        syncMOC.performGroupedBlockAndWait {
            // given
            let nonce = UUID()
            let clearedDate = Date()
            let selfConversation = ZMConversation.selfConversation(in: self.syncMOC)
            let message = GenericMessage(content: Cleared(timestamp: clearedDate, conversationID: self.syncConversation.remoteIdentifier!), nonce: nonce)
            let event = self.createUpdateEvent(nonce, conversationID: selfConversation.remoteIdentifier!, timestamp: Date(), genericMessage: message, senderID: UUID(), eventSource: ZMUpdateEventSource.download)

            // when
            ZMOTRMessage.createOrUpdate(from: event, in: self.syncMOC, prefetchResult: nil)

            // then
            XCTAssertNil(self.syncConversation.clearedTimeStamp)
        }

    }

    func testThatWeIgnoreLastReadEventNotSentFromSelfUser() {

        syncMOC.performGroupedBlockAndWait {
            // given
            let nonce = UUID()
            let lastReadDate = Date()
            let selfConversation = ZMConversation.selfConversation(in: self.syncMOC)
            let message = GenericMessage(content: LastRead(conversationID: self.syncConversation.remoteIdentifier!, lastReadTimestamp: lastReadDate), nonce: nonce)
            let event = self.createUpdateEvent(nonce, conversationID: selfConversation.remoteIdentifier!, timestamp: Date(), genericMessage: message, senderID: UUID(), eventSource: ZMUpdateEventSource.download)
            self.syncConversation.lastReadServerTimeStamp = nil

            // when
            ZMOTRMessage.createOrUpdate(from: event, in: self.syncMOC, prefetchResult: nil)

            // then
            XCTAssertNil(self.syncConversation.lastReadServerTimeStamp)
        }

    }

    func testThatWeIgnoreHideMessageEventNotSentFromSelfUser() {

        syncMOC.performGroupedBlockAndWait {
            // given
            let nonce = UUID()
            let selfConversation = ZMConversation.selfConversation(in: self.syncMOC)
            let toBehiddenMessage = try! self.syncConversation.appendText(content: "hello") as! ZMClientMessage
            let hideMessage = MessageHide(conversationId: self.syncConversation.remoteIdentifier!, messageId: toBehiddenMessage.nonce!)
            let message = GenericMessage(content: hideMessage, nonce: nonce)
            let event = self.createUpdateEvent(nonce, conversationID: selfConversation.remoteIdentifier!, timestamp: Date(), genericMessage: message, senderID: UUID(), eventSource: ZMUpdateEventSource.download)

            // when
            ZMOTRMessage.createOrUpdate(from: event, in: self.syncMOC, prefetchResult: nil)

            // then
            XCTAssertFalse(toBehiddenMessage.hasBeenDeleted)
        }

    }

    // MARK: - Analytics Data Transfer

    func test_AfterProcessingDataTransferMessage_ContainingTrackingIdentifier_SelfUserIsUpdated() {
        syncMOC.performGroupedBlockAndWait {
            // Given
            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            let team = self.createTeam(in: self.syncMOC)
            self.createMembership(in: self.syncMOC, user: selfUser, team: team)
            selfUser.analyticsIdentifier = "foo"

            let trackingIdentifier = UUID.create()

            let event = self.createUpdateEvent(
                trackingIdentifier: trackingIdentifier,
                conversation: .selfConversation(in: self.syncMOC),
                sender: selfUser
            )

            // When
            ZMOTRMessage.createOrUpdate(from: event, in: self.syncMOC, prefetchResult: nil)

            // Then
            XCTAssertEqual(selfUser.analyticsIdentifier, trackingIdentifier.transportString())
        }
    }

    func test_WeIgnoreDataTransferMessage_IfNotSentFromSelfUser() {
        syncMOC.performGroupedBlockAndWait {
            // Given
            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            let team = self.createTeam(in: self.syncMOC)
            self.createMembership(in: self.syncMOC, user: selfUser, team: team)
            selfUser.analyticsIdentifier = "foo"

            let event = self.createUpdateEvent(
                trackingIdentifier: .create(),
                conversation: .selfConversation(in: self.syncMOC),
                sender: self.createUser(in: self.syncMOC)
            )

            // When
            ZMOTRMessage.createOrUpdate(from: event, in: self.syncMOC, prefetchResult: nil)

            // Then
            XCTAssertEqual(selfUser.analyticsIdentifier, "foo")
        }
    }

    func test_WeIgnoreDataTransferMessage_IfNotSentInSelfConversation() {
        syncMOC.performGroupedBlockAndWait {
            // Given
            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            let team = self.createTeam(in: self.syncMOC)
            self.createMembership(in: self.syncMOC, user: selfUser, team: team)
            selfUser.analyticsIdentifier = "foo"

            let event = self.createUpdateEvent(
                trackingIdentifier: .create(),
                conversation: self.conversation,
                sender: self.createUser(in: self.syncMOC)
            )

            // When
            ZMOTRMessage.createOrUpdate(from: event, in: self.syncMOC, prefetchResult: nil)

            // Then
            XCTAssertEqual(selfUser.analyticsIdentifier, "foo")
        }
    }

    private func createUpdateEvent(trackingIdentifier: UUID, conversation: ZMConversation, sender: ZMUser) -> ZMUpdateEvent {
        let message = GenericMessage(content: DataTransfer(trackingIdentifier: trackingIdentifier))
        let nonce = UUID.create()

        return createUpdateEvent(
            nonce,
            conversationID: conversation.remoteIdentifier!,
            timestamp: Date(),
            genericMessage: message,
            senderID: sender.remoteIdentifier!,
            eventSource: ZMUpdateEventSource.download
        )
    }

}
