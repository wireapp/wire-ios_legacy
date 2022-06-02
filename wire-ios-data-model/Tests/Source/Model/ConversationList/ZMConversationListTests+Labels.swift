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
@testable import WireDataModel

final class ZMConversationListTests_Labels: ZMBaseManagedObjectTest {

    var dispatcher: NotificationDispatcher!

    override func setUp() {
        super.setUp()
        dispatcher = NotificationDispatcher(managedObjectContext: uiMOC)
    }

    override func tearDown() {
        dispatcher.tearDown()
        dispatcher = nil
        super.tearDown()
    }

    func testThatAddingAConversationToFavoritesMovesItToFavoriteConversationList() {
        // given
        let favoriteList = uiMOC.conversationListDirectory().favoriteConversations
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.conversationType = .oneOnOne
        conversation.lastModifiedDate = Date()
        XCTAssertTrue(uiMOC.saveOrRollback())
        XCTAssertEqual(favoriteList.count, 0)

        // when
        conversation.isFavorite = true
        XCTAssertTrue(uiMOC.saveOrRollback())

        // then
        XCTAssertEqual(favoriteList.count, 1)
    }

    func testThatRemovingAConversationFromFavoritesRemovesItFromFavoriteConversationList() {
        // given
        let favoriteList = uiMOC.conversationListDirectory().favoriteConversations
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.conversationType = .oneOnOne
        conversation.lastModifiedDate = Date()
        conversation.isFavorite = true
        XCTAssertTrue(uiMOC.saveOrRollback())
        XCTAssertEqual(favoriteList.count, 1)

        // when
        conversation.isFavorite = false
        XCTAssertTrue(uiMOC.saveOrRollback())

        // then
        XCTAssertEqual(favoriteList.count, 0)
    }

    func testThatAddingAConversationToFolderMovesItToFolderConversationList() {
        // given
        let folder = uiMOC.conversationListDirectory().createFolder("folder 1")!
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.conversationType = .oneOnOne
        conversation.lastModifiedDate = Date()
        XCTAssertTrue(uiMOC.saveOrRollback())
        XCTAssertEqual(uiMOC.conversationListDirectory().conversations(by: .folder(folder)).count, 0)

        // when
        conversation.moveToFolder(folder)
        XCTAssertTrue(uiMOC.saveOrRollback())

        // then
        XCTAssertEqual(uiMOC.conversationListDirectory().conversations(by: .folder(folder)).count, 1)
    }

    func testThatRemovingAConversationFromAFolderRemovesItFromTheFolderConversationList() {
        // given
        let folder = uiMOC.conversationListDirectory().createFolder("folder 1")!
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.conversationType = .oneOnOne
        conversation.lastModifiedDate = Date()
        conversation.moveToFolder(folder)
        XCTAssertTrue(uiMOC.saveOrRollback())
        XCTAssertEqual(uiMOC.conversationListDirectory().conversations(by: .folder(folder)).count, 1)

        // when
        conversation.removeFromFolder()
        XCTAssertTrue(uiMOC.saveOrRollback())

        // then
        XCTAssertEqual(uiMOC.conversationListDirectory().conversations(by: .folder(folder)).count, 0)
    }

}
