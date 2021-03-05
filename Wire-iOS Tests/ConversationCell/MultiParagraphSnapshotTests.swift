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

final class MultiParagraphSnapshotTests: XCTestCase {
    func testThatLineHeightOfListIsConsistent_Chinese() {
        // swiftlint:disable:next line_length
        let messageText = "1. 子曰：「雍也，可使南面。」仲弓問子桑伯子。子曰：「可也，簡。」仲弓曰：「居敬而行簡，以臨其民，不亦可乎？居簡而行簡，無乃大簡乎？」子曰：「雍之言然。」\n2. 哀公問：「弟子孰爲好學？」孔子對曰：「有顏回者，好學；不遷怒，不貳過，不幸短命死矣！今也則亡，未聞好學者也。」\n3. 子華使於齊，冉子爲其母請粟。子曰：「與之釜。」請益，曰：「與之庾。」冉子與之粟五秉。子曰：「赤之適齊也，乘肥馬，衣輕裘；吾聞之也：君子周急不繼富。」原思爲之宰，與之粟九百，辭。子曰：「毋！以與爾鄰里鄉黨乎！」"

        let mockSelfUser = MockUserType.createDefaultSelfUser()

        let message = MockMessageFactory.textMessage(withText: messageText, sender: mockSelfUser, includingRichMedia: false)

        verify(message: message)
    }
}
