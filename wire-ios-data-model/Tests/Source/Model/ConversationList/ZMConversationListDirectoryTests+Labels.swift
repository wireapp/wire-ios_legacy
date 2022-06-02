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

class ZMConversationListDirectoryTests_Labels: ZMBaseManagedObjectTest {

    func testThatItRefetchesAllFolders() {
        // given
        let sut = uiMOC.conversationListDirectory()
        XCTAssertEqual(sut.allFolders.count, 0)
        let folder = sut.createFolder("Folder A")!

        // when
        sut.refetchAllLists(in: uiMOC)

        // then
        XCTAssertEqual(sut.allFolders.count, 1)
        XCTAssertEqual(sut.allFolders.first as? Label, folder as? Label)
    }

    func testThatItRefetchesFoldersLists() {
        // given
        let conversation = createConversation(in: uiMOC)
        let sut = uiMOC.conversationListDirectory()
        let folder = sut.createFolder("Folder A")!
        conversation.moveToFolder(folder)
        XCTAssertEqual(sut.conversations(by: .folder(folder)).count, 0)

        // when
        sut.refetchAllLists(in: uiMOC)

        // then
        XCTAssertEqual(sut.conversations(by: .folder(folder)), [conversation])
    }

}
