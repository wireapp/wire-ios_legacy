//
// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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
@testable import Wire

final class MarkDownSnapshotTests: XCTestCase {
    var mockOtherUser: MockUserType!
    var mockSelfUser: MockUserType!

    override func setUp() {
        super.setUp()

        mockOtherUser = MockUserType.createUser(name: "Bruno")
        UIColor.setAccentOverride(.vividRed)

        mockSelfUser = MockUserType.createDefaultSelfUser()
    }

    override func tearDown() {
        mockOtherUser = nil
        mockSelfUser = nil

        super.tearDown()
    }

    func testMentionInFirstParagraph() {
        // swiftlint:disable line_length
        let messageText =
        """
        @Bruno @Wire There was an old goat who had seven little kids, and loved them with all the love of a mother for her children. One day she wanted to go into the forest and fetch some food.
        So she called all seven to her and said: 'Dear children, I have to go into the forest, be on your guard against the wolf; if he comes in, he will devour you all, skin, hair, and everything.
        The wretch often disguises himself, but you will know him at once by his rough voice and his black feet.' The kids said: 'Dear mother, we will take good care of ourselves; you may go away without any anxiety.' Then the old one bleated, and went on her way with an easy mind.
        """
        // swiftlint:enable line_length

        let mention = Mention(range: NSRange(location: 0, length: 12), user: mockOtherUser)
        let message = MockMessageFactory.messageTemplate(sender: mockSelfUser)
        let textMessageData = MockTextMessageData()
        textMessageData.messageText = messageText
        message.backingTextMessageData = textMessageData

        textMessageData.mentions = [mention]

        verify(message: message)
    }

    /// compare with above tests, the line spacing should be the same for both case.
    func testNoMentrionParagraph() {
        // swiftlint:disable line_length
        let messageText =
        """
        @Bruno @Wire There was an old goat who had seven little kids, and loved them with all the love of a mother for her children. One day she wanted to go into the forest and fetch some food.
        So she called all seven to her and said: 'Dear children, I have to go into the forest, be on your guard against the wolf; if he comes in, he will devour you all, skin, hair, and everything.
        The wretch often disguises himself, but you will know him at once by his rough voice and his black feet.' The kids said: 'Dear mother, we will take good care of ourselves; you may go away without any anxiety.' Then the old one bleated, and went on her way with an easy mind.
        """
        // swiftlint:enable line_length

        let message = MockMessageFactory.textMessage(withText: messageText, sender: mockSelfUser, includingRichMedia: false)

        verify(message: message)
    }

}
