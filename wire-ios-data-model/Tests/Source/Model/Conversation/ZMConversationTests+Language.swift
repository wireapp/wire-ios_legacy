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

import Foundation
@testable import WireDataModel

class ZMConversationTests_Language: BaseZMMessageTests {

    func testThatItAllowsSettingLanguageOnConversation() {
        // given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        let germanLanguage = "de-DE"

        let uuid = UUID.create()
        conversation.remoteIdentifier = uuid
        conversation.language = germanLanguage

        XCTAssert(uiMOC.saveOrRollback())
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.1))

        // when
        let conversationFetched = ZMConversation.fetch(with: uuid, in: uiMOC)

        // then
        XCTAssertEqual(conversationFetched?.language, germanLanguage)
    }

}
