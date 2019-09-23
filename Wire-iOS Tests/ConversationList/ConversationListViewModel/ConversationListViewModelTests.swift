
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

final class ConversationListViewModelTests: XCTestCase {
    
    var sut: ConversationListViewModel!

    override func setUp() {
        super.setUp()
        sut = ConversationListViewModel()
    }
    
    override func tearDown() {
        sut = nil

        super.tearDown()
    }

    func fillDummyConversations(mockConversation: ZMConversation) {

        sut.updateSection(section: .group, withItems: [mockConversation])
        sut.updateSection(section: .contacts, withItems: [ZMConversation()])
    }

    func testForNumberOfItems() {
        ///GIVEN
        sut.folderEnabled = true

        let mockConversation = ZMConversation()

        fillDummyConversations(mockConversation: mockConversation)

        ///WHEN

        ///THEN
        XCTAssertEqual(sut.numberOfItems(inSection: 0), 0)
        XCTAssertEqual(sut.numberOfItems(inSection: 1), 1)
        XCTAssertEqual(sut.numberOfItems(inSection: 2), 1)
        XCTAssertEqual(sut.numberOfItems(inSection: 100), 0)
    }

    func testForIndexPathOfItemAndItemForIndexPath() {
        ///GIVEN
        sut.folderEnabled = true

        let mockConversation = ZMConversation()

        fillDummyConversations(mockConversation: mockConversation)

        ///WHEN
        guard let indexPath = sut.indexPath(for: mockConversation) else { XCTFail("indexPath is nil ")
            return
        }

        let item = sut.item(for: indexPath)

        ///THEN
        XCTAssertEqual(item, mockConversation)
    }

    func testThatOutOfBoundIndexPathReturnsNilItem() {
        ///GIVEN & WHEN
        let mockConversation = ZMConversation()
        fillDummyConversations(mockConversation: mockConversation)

        ///THEN
        XCTAssertNil(sut.item(for: IndexPath(item: 1000, section: 1000)))
    }

    func testThatNonExistConversationHasNilIndexPath() {
        ///GIVEN & WHEN

        ///THEN
        XCTAssertNil(sut.indexPath(for: ZMConversation()))
    }

    func testForSectionCount() {
        ///GIVEN

        ///WHEN
        sut.folderEnabled = true

        ///THEN
        XCTAssertEqual(sut.sectionCount, 3)

        ///WHEN
        sut.folderEnabled = false
        XCTAssertEqual(sut.sectionCount, 2)
    }

    func testForSectionAtIndex() {
        ///GIVEN
        sut.folderEnabled = true

        let mockConversation = ZMConversation()

        fillDummyConversations(mockConversation: mockConversation)

        ///WHEN

        ///THEN
        XCTAssertEqual(sut.section(at: 1), [mockConversation])

        XCTAssertNil(sut.section(at: 100))
    }
}
