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

import Foundation

class ZMConversationVoiceChannelTests: MessagingTest {

    private var oneToOneconversation: ZMConversation!
    private var groupConversation: ZMConversation!

    override func setUp() {
        super.setUp()

        oneToOneconversation = ZMConversation.insertNewObject(in: self.syncMOC)
        oneToOneconversation?.remoteIdentifier = UUID.create()
        oneToOneconversation.conversationType = .oneOnOne

        groupConversation = ZMConversation.insertNewObject(in: self.syncMOC)
        groupConversation?.remoteIdentifier = UUID.create()
        groupConversation.conversationType = .group
    }

    override func tearDown() {
        super.tearDown()
    }

    func testThatItReturnsAVoiceChannelForAOneOnOneConversations() {
        // when
        let voiceChannel = oneToOneconversation.voiceChannel

        // then
        XCTAssertNotNil(voiceChannel)
        XCTAssertEqual(voiceChannel?.conversation, oneToOneconversation)
    }

    func testThatItReturnsAVoiceChannelForAGroupConversation() {
        // when
        let voiceChannel = groupConversation.voiceChannel

        // then
        XCTAssertNotNil(voiceChannel)
        XCTAssertEqual(voiceChannel?.conversation, groupConversation)
    }

    func testThatItAlwaysReturnsTheSameVoiceChannelForAOneOnOneConversations() {
        // when
        let voiceChannel = oneToOneconversation.voiceChannel

        // then
        XCTAssertTrue(oneToOneconversation.voiceChannel === voiceChannel)
    }

}
