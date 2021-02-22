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
import DifferenceKit


final class MockConversationListViewModelDelegate: NSObject, ConversationListViewModelDelegate {
    func listViewModel(_ model: ConversationListViewModel?, didUpdateSection section: Int) {
        //no-op
    }

    func listViewModel(_ model: ConversationListViewModel?, didUpdateSectionForReload section: Int, animated: Bool) {
        //no-op
    }

    func listViewModel(_ model: ConversationListViewModel?, didChangeFolderEnabled folderEnabled: Bool) {
        //no-op
    }
    
    func reload<C>(
        using stagedChangeset: StagedChangeset<C>,
        interrupt: ((Changeset<C>) -> Bool)?,
        setData: (C?) -> Void
        ) {
        setData(stagedChangeset.first?.data)
    }
    
    func listViewModelShouldBeReloaded() {
        //no-op
    }

    func listViewModel(_ model: ConversationListViewModel?, didSelectItem item: ConversationListItem?) {
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

    /// constants
    let sectionGroups: Int = 2
    let sectionContacts: Int = 3

    override func setUp() {
        super.setUp()
        removeViewModelState()
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
    
    func removeViewModelState() {
        guard let persistentURL = ConversationListViewModel.persistentURL else { return }
        
        try? FileManager.default.removeItem(at: persistentURL)
    }

    // folders with 2 group conversations and 1 contact. First group conversation is mock conversation
    func fillDummyConversations(mockConversation: ZMConversation) {
        let info = ConversationDirectoryChangeInfo(reloaded: false, updatedLists: [.groups, .contacts], updatedFolders: false)

        mockUserSession.mockConversationDirectory.mockGroupConversations = [mockConversation, ZMConversation()]
        mockUserSession.mockConversationDirectory.mockContactsConversations = [ZMConversation()]

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
        XCTAssertEqual(sut.numberOfItems(inSection: Int(sectionGroups)), 2)
        XCTAssertEqual(sut.numberOfItems(inSection: Int(sectionContacts)), 1)
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
        XCTAssertEqual(item as? AnyHashable, mockConversation)
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
        XCTAssertEqual(sut.sectionCount, 4)

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
        XCTAssertEqual(sut.section(at: Int(sectionGroups))?.first as? AnyHashable, mockConversation)

        XCTAssertNil(sut.section(at: 100))
    }

    func testForItemAfter() {
        ///GIVEN
        sut.folderEnabled = true

        let mockConversation = ZMConversation()

        fillDummyConversations(mockConversation: mockConversation)

        ///WHEN

        ///THEN
        XCTAssertEqual(sut.item(after: 0, section: sectionGroups), IndexPath(item: 1, section: Int(sectionGroups)))
        XCTAssertEqual(sut.item(after: 1, section: 1), IndexPath(item: 0, section: 2))
        XCTAssertEqual(sut.item(after: 0, section: sectionContacts), nil)
    }

    func testForItemPervious() {
        ///GIVEN
        sut.folderEnabled = true

        let mockConversation = ZMConversation()

        fillDummyConversations(mockConversation: mockConversation)

        ///WHEN

        ///THEN
        XCTAssertEqual(sut.itemPrevious(to: 0, section: sectionGroups), nil)

        XCTAssertEqual(sut.itemPrevious(to: 1, section: sectionGroups), IndexPath(item: 0, section: Int(sectionGroups)))

        XCTAssertEqual(sut.itemPrevious(to: 0, section: sectionContacts), IndexPath(item: 1, section: Int(sectionGroups)))
    }

    func testForSelectItem() {
        sut.folderEnabled = true

        let mockConversation = ZMConversation()

        fillDummyConversations(mockConversation: mockConversation)

        ///WHEN & THEN
        XCTAssert(sut.select(itemToSelect: mockConversation))

        ///THEN
        XCTAssertEqual(sut.selectedItem as? AnyHashable, mockConversation)
    }

    func testThatSelectItemAtIndexReturnCorrectConversation() {
        /// GIVEN
        sut.folderEnabled = true

        let mockConversation = ZMConversation()

        fillDummyConversations(mockConversation: mockConversation)

        ///WHEN
        let indexPath = sut.indexPath(for: mockConversation)!

        ///THEN
        XCTAssertEqual(sut.selectItem(at: indexPath) as? AnyHashable, mockConversation)
    }

    // MARK: - state
    func testThatSectionIsExpandedAfterSelected() {
        ///GIVEN
        sut.folderEnabled = true
        let mockConversation = ZMConversation()
        fillDummyConversations(mockConversation: mockConversation)
        sut.setCollapsed(sectionIndex: Int(sectionGroups), collapsed: true)///todo

        ///WHEN
        XCTAssert(sut.collapsed(at: Int(sectionGroups)))
        XCTAssert(sut.select(itemToSelect: mockConversation))

        ///THEN
        XCTAssertFalse(sut.collapsed(at: Int(sectionGroups)))
    }

    func testThatCollapseStateCanBeRestoredAfterFolderDisabled() {
        ///GIVEN
        sut.folderEnabled = true

        let mockConversation = ZMConversation()

        fillDummyConversations(mockConversation: mockConversation)

        XCTAssertFalse(sut.collapsed(at: 1))

        ///WHEN
        sut.setCollapsed(sectionIndex: 1, collapsed: true)

        XCTAssert(sut.collapsed(at: 1))

        /// all folder are not collapsed when folder disabled
        sut.folderEnabled = false

        XCTAssertFalse(sut.collapsed(at: 1))
        sut.folderEnabled = true

        ///THEN

        ///collapsed state is restored
        XCTAssert(sut.collapsed(at: 1))
    }

    func testThatStateJsonFormatIsCorrect() {
        /// GIVEN

        /// state is initial value when first run
        XCTAssertEqual(sut.jsonString, #"{"collapsed":[],"folderEnabled":false}"#)

        sut.folderEnabled = true

        let mockConversation = ZMConversation()

        fillDummyConversations(mockConversation: mockConversation)

        /// WHEN
        sut.setCollapsed(sectionIndex: 2, collapsed: true)

        /// THEN
        XCTAssertEqual(sut.jsonString, #"{"collapsed":["groups"],"folderEnabled":true}"#)
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
