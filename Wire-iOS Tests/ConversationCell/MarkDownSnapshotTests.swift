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

    override func setUp() {
        super.setUp()

        recordMode = true
    }

    func testThatLineHeightOfListIsConsistent_Chinese() {
        let messageText = "1. 子曰：「雍也，可使南面。」仲弓問子桑伯子。子曰：「可也，簡。」仲弓曰：「居敬而行簡，以臨其民，不亦可乎？居簡而行簡，無乃大簡乎？」子曰：「雍之言然。」\n2. 哀公問：「弟子孰爲好學？」孔子對曰：「有顏回者，好學；不遷怒，不貳過，不幸短命死矣！今也則亡，未聞好學者也。」\n3. 子華使於齊，冉子爲其母請粟。子曰：「與之釜。」請益，曰：「與之庾。」冉子與之粟五秉。子曰：「赤之適齊也，乘肥馬，衣輕裘；吾聞之也：君子周急不繼富。」原思爲之宰，與之粟九百，辭。子曰：「毋！以與爾鄰里鄉黨乎！」"
        let message = otherUserConversation.append(text: messageText, mentions: [], fetchLinkPreview: false)!

        verify(message: message, waitForTextViewToLoad: true)
    }

    func testMentionInFirstParagraph() {
        let messageText =
        """
@Bruno @Wire There was an old goat who had seven little kids, and loved them with all the love of a mother for her children. One day she wanted to go into the forest and fetch some food.
        So she called all seven to her and said: 'Dear children, I have to go into the forest, be on your guard against the wolf; if he comes in, he will devour you all, skin, hair, and everything.
The wretch often disguises himself, but you will know him at once by his rough voice and his black feet.' The kids said: 'Dear mother, we will take good care of ourselves; you may go away without any anxiety.' Then the old one bleated, and went on her way with an easy mind.
"""
        let mention = Mention(range: NSRange(location: 0, length: 12), user: otherUser)
        let message = otherUserConversation.append(text: messageText, mentions: [mention], fetchLinkPreview: false)!


        verify(message: message, waitForTextViewToLoad: true)
    }

    ///compare with above tests, the line spacing should be the same for both case.
    func testNoMentrionParagraph() {
        let messageText =
        """
@Bruno @Wire There was an old goat who had seven little kids, and loved them with all the love of a mother for her children. One day she wanted to go into the forest and fetch some food.
        So she called all seven to her and said: 'Dear children, I have to go into the forest, be on your guard against the wolf; if he comes in, he will devour you all, skin, hair, and everything.
The wretch often disguises himself, but you will know him at once by his rough voice and his black feet.' The kids said: 'Dear mother, we will take good care of ourselves; you may go away without any anxiety.' Then the old one bleated, and went on her way with an easy mind.
"""
        let message = otherUserConversation.append(text: messageText, mentions: [], fetchLinkPreview: false)!


        verify(message: message, waitForTextViewToLoad: true)
    }

}
