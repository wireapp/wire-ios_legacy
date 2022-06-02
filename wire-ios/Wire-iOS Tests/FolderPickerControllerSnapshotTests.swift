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

import SnapshotTesting
import XCTest
@testable import Wire

final class FolderPickerControllerSnapshotTests: XCTestCase {

    var directory: MockConversationDirectory!
    var mockConversation: MockConversation!

    override func setUp() {
        super.setUp()

        mockConversation = MockConversation.groupConversation()
        directory = MockConversationDirectory()
        accentColor = .violet
    }

    override func tearDown() {
        directory = nil
        mockConversation = nil
        super.tearDown()
    }

    func testWithNoExistingFolders() {
        // given
        directory.allFolders = []

        // when
        let sut = FolderPickerViewController(conversation: mockConversation.convertToRegularConversation(), directory: directory)

        // then
        verify(matching: sut)
    }

    func testWithExistingFolders() {
        // given
        directory.allFolders = [MockLabel(name: "Folder A"), MockLabel(name: "Folder B"), MockLabel(name: "Folder C")]

        // when
        let sut = FolderPickerViewController(conversation: mockConversation.convertToRegularConversation(), directory: directory)

        // then
        verify(matching: sut)
    }
}
