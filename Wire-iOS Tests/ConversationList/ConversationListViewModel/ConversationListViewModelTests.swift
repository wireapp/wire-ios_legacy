
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

final class MockConversationListViewModelDelegate: NSObject, ConversationListViewModelDelegate {
    func listViewModelShouldBeReloaded() {
        //no-op
    }

    func listViewModel(_ model: ConversationListViewModel?, didUpdateSectionForReload section: UInt) {
        //no-op
    }

    func listViewModel(_ model: ConversationListViewModel?, didUpdateSection section: UInt, usingBlock updateBlock: () -> (), with changedIndexes: ZMChangedIndexes?) {
        //no-op
        updateBlock()
    }

    func listViewModel(_ model: ConversationListViewModel?, didSelectItem item: Any?) {
        //no-op
    }

    func listViewModel(_ model: ConversationListViewModel?, didUpdateConversationWithChange change: ConversationChangeInfo?) {
        //no-op
    }
}

final class ConversationListViewModelTests: XCTestCase {
    
    var sut: ConversationListViewModel!
    var mockUserSession: MockZMUserSession!
    var mockConversationListViewModelDelegate: MockConversationListViewModelDelegate!
    var mockBar: MockBar!

    override func setUp() {
        super.setUp()
        mockBar = MockBar()
        mockUserSession = MockZMUserSession()
        sut = ConversationListViewModel(userSession: mockUserSession)
        mockConversationListViewModelDelegate = MockConversationListViewModelDelegate()
        sut.delegate = mockConversationListViewModelDelegate
    }
    
    override func tearDown() {
        sut = nil
        mockUserSession = nil
        mockConversationListViewModelDelegate = nil
        mockBar = nil

        super.tearDown()
    }

    // folders with 2 group conversations and 1 contact. First group conversation is mock conversation
    func fillDummyConversations(mockConversation: ZMConversation) {
        let info = ConversationDirectoryChangeInfo(reloaded: false, updatedLists: [.groups, .contacts])

        mockUserSession.mockGroupConversations = [mockConversation, ZMConversation()]
        mockUserSession.mockContactsConversations = [ZMConversation()]

        sut.conversationDirectoryDidChange(info)
    }

    func testForNumberOfItems() {
        ///GIVEN
        sut.folderEnabled = true

        let mockConversation = ZMConversation()

        fillDummyConversations(mockConversation: mockConversation)

        ///WHEN

        ///THEN
        XCTAssertEqual(sut.numberOfItems(inSection: 0), 0)
        XCTAssertEqual(sut.numberOfItems(inSection: 1), 2)
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
        XCTAssertEqual(sut.section(at: 1)?.first, mockConversation)

        XCTAssertNil(sut.section(at: 100))
    }

    func testForItemAfter() {
        ///GIVEN
        sut.folderEnabled = true

        let mockConversation = ZMConversation()

        fillDummyConversations(mockConversation: mockConversation)

        ///WHEN

        ///THEN
        XCTAssertEqual(sut.item(after: 0, section: 1), IndexPath(item: 1, section: 1))

        XCTAssertEqual(sut.item(after: 1, section: 1), IndexPath(item: 0, section: 2))

        XCTAssertEqual(sut.item(after: 0, section: 2), nil)
    }

    func testForItemPervious() {
        ///GIVEN
        sut.folderEnabled = true

        let mockConversation = ZMConversation()

        fillDummyConversations(mockConversation: mockConversation)

        ///WHEN

        ///THEN
        XCTAssertEqual(sut.itemPrevious(to: 0, section: 1), nil)

        XCTAssertEqual(sut.itemPrevious(to: 1, section: 1), IndexPath(item: 0, section: 1))

        XCTAssertEqual(sut.itemPrevious(to: 0, section: 2), IndexPath(item: 1, section: 1))
    }

    func testForSelectItem() {
        sut.folderEnabled = true

        let mockConversation = ZMConversation()

        fillDummyConversations(mockConversation: mockConversation)

        ///WHEN & THEN
        XCTAssert(sut.select(itemToSelect: mockConversation))

        ///THEN
        XCTAssertEqual(sut.selectedItem, mockConversation)
    }

    func testThatSelectItemAtIndexReturnCorrectConversation() {
        /// GIVEN
        sut.folderEnabled = true

        let mockConversation = ZMConversation()

        fillDummyConversations(mockConversation: mockConversation)

        ///WHEN
        let indexPath = sut.indexPath(for: mockConversation)!

        ///THEN
        XCTAssertEqual(sut.selectItem(at: indexPath), mockConversation)
    }

    // MARK: - state
    func testThatCollapseStateCanBeRestoredAfterFolderDisabled() {
        sut.folderEnabled = true

        let mockConversation = ZMConversation()

        fillDummyConversations(mockConversation: mockConversation)

        XCTAssertFalse(sut.collapsed(at: 1))

        ///WHEN
        sut.setCollapsed(sectionIndex: 1, collapsed: true, presistent: true)

        ///THEN
        XCTAssert(sut.collapsed(at: 1))

        ///WHEN

        /// all folder are not collapsed when folder disabled
        sut.folderEnabled = false

        ///THEN
        XCTAssertFalse(sut.collapsed(at: 1))

        ///WHEN
        sut.folderEnabled = true

        ///THEN

        ///collapsed state is restored
        XCTAssert(sut.collapsed(at: 1))
    }

    func testThatStateJsonFormatIsCorrect() {
        /// GIVEN

        /// state is initial value when first run
        XCTAssertEqual(sut.jsonString, #"{"folderEnabled":false,"sections":[{"kind":"contactRequests","collapsed":false},{"kind":"conversations","collapsed":false}]}"#)

        sut.folderEnabled = true

        let mockConversation = ZMConversation()

        fillDummyConversations(mockConversation: mockConversation)

        /// WHEN
        sut.setCollapsed(sectionIndex: 1, collapsed: true, presistent: true)

        /// THEN
        XCTAssertEqual(sut.jsonString, "{\"folderEnabled\":true,\"sections\":[{\"kind\":\"contactRequests\",\"collapsed\":false},{\"kind\":\"group\",\"collapsed\":true},{\"kind\":\"contacts\",\"collapsed\":false}]}")
    }

    func testForRestorationDelegateMethodCalledOnceAfterItIsSet() {
        /// GIVEN
        sut.folderEnabled = true
        let mockConversation = ZMConversation()
        fillDummyConversations(mockConversation: mockConversation)
        sut.setCollapsed(sectionIndex: 1, collapsed: true)
        XCTAssertFalse(mockBar.folderEnabled)

        /// WHEN
        sut.restorationDelegate = mockBar

        /// THEN
        XCTAssert(mockBar.folderEnabled)
    }

}

final class MockBar: ConversationListViewModelRestorationDelegate {
    var folderEnabled: Bool = false

    func listViewModel(_ model: ConversationListViewModel?, didRestoreFolderEnabled enabled: Bool) {
        folderEnabled = enabled
    }
}
