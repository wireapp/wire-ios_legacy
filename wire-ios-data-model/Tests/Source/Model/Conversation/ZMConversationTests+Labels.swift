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

class ZMConversationTests_Labels: ZMConversationTestsBase {

    func createFolder(name: String) -> Label {
        var created: Bool = false
        let label = Label.fetchOrCreate(remoteIdentifier: UUID(), create: true, in: uiMOC, created: &created)!
        XCTAssertTrue(created)

        label.kind = .folder
        label.name = name

        return label
    }

    // MARK: Favorites

    func testThatConversationCanBeAddedToFavorites() {
        // GIVEN
        let sut = createConversation(in: uiMOC)

        // WHEN
        sut.isFavorite = true

        // THEN
        XCTAssertTrue(sut.isFavorite)
    }

    func testThatConversationCanBeRemovedFromFavorites() {
        // GIVEN
        let sut = createConversation(in: uiMOC)
        sut.isFavorite = true

        // WHEN
        sut.isFavorite = false

        // THEN
        XCTAssertFalse(sut.isFavorite)
    }

    // MARK: Folders

    func testThatConversationCanBeMovedToFolder() {
        // GIVEN
        let sut = createConversation(in: uiMOC)
        let folder = createFolder(name: "folder1")

        // WHEN
        sut.moveToFolder(folder)

        // THEN
        XCTAssertEqual(sut.labels, Set(arrayLiteral: folder))
    }

    func testThatConversationIsRemovedFromPreviousFolder_WhenMovedToFolder() {
        // GIVEN
        let sut = createConversation(in: uiMOC)
        let folder1 = createFolder(name: "folder1")
        let folder2 = createFolder(name: "folder2")
        sut.moveToFolder(folder1)

        // WHEN
        sut.moveToFolder(folder2)

        // THEN
        XCTAssertEqual(sut.labels, Set(arrayLiteral: folder2))
    }

    func testThatConversationIsNotRemovedFromFavorites_WhenMovedToFolder() {
        // GIVEN
        let sut = createConversation(in: uiMOC)
        let folder = createFolder(name: "folder1")
        sut.isFavorite = true

        // WHEN
        sut.moveToFolder(folder)

        // THEN
        XCTAssertTrue(sut.isFavorite)
    }

    func testThatConversationCanBeRemovedFromFolder() {
        // GIVEN
        let sut = createConversation(in: uiMOC)
        let folder = createFolder(name: "folder1")
        sut.moveToFolder(folder)

        // WHEN
        sut.removeFromFolder()

        // THEN
        XCTAssertTrue(sut.labels.isEmpty)
    }

    func testThatFolderIsMarkedForDeletion_WhenLastConversationIsRemoved() {
        // GIVEN
        let sut = createConversation(in: uiMOC)
        let folder = createFolder(name: "folder1")
        sut.moveToFolder(folder)

        // WHEN
        sut.removeFromFolder()

        // THEN
        XCTAssertTrue(folder.markedForDeletion)
    }

    func testThatFolderIsNotMarkedForDeletion_WhenSecondToLastConversationIsRemoved() {
        // GIVEN
        let conversation1 = createConversation(in: uiMOC)
        let conversation2 = createConversation(in: uiMOC)
        let folder = createFolder(name: "folder1")
        conversation1.moveToFolder(folder)
        conversation2.moveToFolder(folder)

        // WHEN
        conversation1.removeFromFolder()

        // THEN
        XCTAssertFalse(folder.markedForDeletion)
    }

}
