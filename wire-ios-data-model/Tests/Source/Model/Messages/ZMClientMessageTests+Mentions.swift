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

import XCTest
@testable import WireDataModel

class ZMClientMessageTests_Mentions: BaseZMClientMessageTests {

    func createMessage(text: String, mentions: [ Mention]) -> ZMClientMessage {
        let text = Text(content: text, mentions: mentions, linkPreviews: [])
        let message = ZMClientMessage(nonce: UUID(), managedObjectContext: uiMOC)

        do {
            try message.setUnderlyingMessage(GenericMessage(content: text))
        } catch {
            XCTFail()
        }

        return message
    }

    func testMentionsAreReturned() {
        // given
        let text = "@john hello"
        let mention = Mention(range: NSRange(location: 0, length: 5), user: user1)
        let message = createMessage(text: text, mentions: [mention])

        // when
        let mentions = message.mentions

        // then
        XCTAssertEqual(mentions, [mention])
    }

    func testMentionsWithMultiplePartCharactersAreReturned() {
        // given
        let text = "@🙅‍♂️"
        let mention = Mention(range: NSRange(location: 0, length: 6), user: user1)

        let message = createMessage(text: text, mentions: [mention])

        // when
        let mentions = message.mentions

        // then
        XCTAssertEqual(mentions, [mention])
    }

    func testMentionsWithOverlappingRangesAreDiscarded() {
        // given
        let text = "@john hello"
        let mention = Mention(range: NSRange(location: 0, length: 5), user: user1)
        let mentionOverlapping = Mention(range: NSRange(location: 4, length: 5), user: user2)

        let message = createMessage(text: text, mentions: [mention, mentionOverlapping])

        // when
        let mentions = message.mentions

        // then
        XCTAssertEqual(mentions, [mention])
    }

    func testMentionsWithRangesOutsideTextAreDiscarded() {
        // given
        let text = "@john hello"
        let mention = Mention(range: NSRange(location: 0, length: 5), user: user1)
        let mentionOutsideText = Mention(range: NSRange(location: 6, length: 10), user: user2)

        let message = createMessage(text: text, mentions: [mention, mentionOutsideText])

        // when
        let mentions = message.mentions

        // then
        XCTAssertEqual(mentions, [mention])
    }

    func testMentionsIsCapppedAt500() {
        // given
        let text = String(repeating: "@", count: 501)
        let tooManyMentions = (0...500).map({ index in
            return Mention(range: NSRange(location: index, length: 1), user: user1)
        })
        let message = createMessage(text: text, mentions: tooManyMentions)

        // when
        let mentions = message.mentions

        // then
        XCTAssertEqual(mentions.count, 500)
        XCTAssertEqual(mentions, mentions)
        XCTAssertEqual(mentions, Array(tooManyMentions.prefix(500)))
    }

}
