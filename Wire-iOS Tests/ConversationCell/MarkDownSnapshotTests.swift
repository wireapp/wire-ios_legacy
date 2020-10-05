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

import Foundation

final class MarkDownSnapshotTests: ConversationCellSnapshotTestCase {

    func testMentionInFirstParagraph() {
        let messageText =
        """
@Bruno @Wire There was an old goat who had seven little kids, and loved them with all the love of a mother for her children. One day she wanted to go into the forest and fetch some food.
        So she called all seven to her and said: 'Dear children, I have to go into the forest, be on your guard against the wolf; if he comes in, he will devour you all, skin, hair, and everything.
The wretch often disguises himself, but you will know him at once by his rough voice and his black feet.' The kids said: 'Dear mother, we will take good care of ourselves; you may go away without any anxiety.' Then the old one bleated, and went on her way with an easy mind.
"""
        let mention = Mention(range: NSRange(location: 0, length: 12), user: otherUser)
        let message = try! otherUserConversation.appendText(content: messageText, mentions: [mention], fetchLinkPreview: false)


        verify(message: message)
    }

    ///compare with above tests, the line spacing should be the same for both case.
    func testNoMentrionParagraph() {
        let messageText =
        """
@Bruno @Wire There was an old goat who had seven little kids, and loved them with all the love of a mother for her children. One day she wanted to go into the forest and fetch some food.
        So she called all seven to her and said: 'Dear children, I have to go into the forest, be on your guard against the wolf; if he comes in, he will devour you all, skin, hair, and everything.
The wretch often disguises himself, but you will know him at once by his rough voice and his black feet.' The kids said: 'Dear mother, we will take good care of ourselves; you may go away without any anxiety.' Then the old one bleated, and went on her way with an easy mind.
"""
        let message = try! otherUserConversation.appendText(content: messageText, mentions: [], fetchLinkPreview: false)


        verify(message: message)
    }

}
