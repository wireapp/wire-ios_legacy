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

import XCTest
@testable import Wire

class ConversationMessageSectionControllerTests: XCTestCase {

    // MARK: - Dequeuing
    
    var context: ConversationMessageContext!
    var layoutProperties: ConversationCellLayoutProperties!
    
    override func setUp() {
        super.setUp()
        
        context = ConversationMessageContext(isSameSenderAsPrevious: false, isTimeIntervalSinceLastMessageSignificant: false, isFirstMessageOfTheDay: false, isFirstUnreadMessage: false, isLastMessage: false, searchQueries: [], previousMessageIsKnock: false)
        layoutProperties = ConversationCellLayoutProperties()
    }
    
    override func tearDown() {
        context = nil
        layoutProperties = nil
        
        super.tearDown()
    }

    func testThatItReturnsCellsInCorrectOrder_Normal() {
        
        // GIVEN
        let section = ConversationMessageSectionController(message: MockMessage(), context: context, layoutProperties: layoutProperties)
        section.cellDescriptions.removeAll()
        section.useInvertedIndices = false

        // WHEN
        section.add(description: MockCellDescription<Bool>())
        section.add(description: MockCellDescription<String>())

        // THEN
        let cell1 = section.tableViewCellDescriptions[0]
        let cell2 = section.tableViewCellDescriptions[1]

        XCTAssertEqual(String(describing: cell1.baseType), "MockCellDescription<Bool>")
        XCTAssertEqual(String(describing: cell2.baseType), "MockCellDescription<String>")
    }

    func testThatItReturnsCellsInCorrectOrder_UpsideDown() {
        // GIVEN
        let section = ConversationMessageSectionController(message: MockMessage(), context: context, layoutProperties: layoutProperties)
        section.cellDescriptions.removeAll()
        section.useInvertedIndices = true

        // WHEN
        section.add(description: MockCellDescription<Bool>())
        section.add(description: MockCellDescription<String>())

        // THEN
        let cell1 = section.tableViewCellDescriptions[0]
        let cell2 = section.tableViewCellDescriptions[1]

        XCTAssertEqual(String(describing: cell1.baseType), "MockCellDescription<String>")
        XCTAssertEqual(String(describing: cell2.baseType), "MockCellDescription<Bool>")
    }

    // MARK: - Configuration

    func testThatItConfiguresCellAfterDequeuing() {
        // GIVEN
        let section = ConversationMessageSectionController(message: MockMessage(), context: context, layoutProperties: layoutProperties)
        section.cellDescriptions.removeAll()
        let tableView = UITableView()

        section.add(description: MockCellDescription<Any>())
        section.cellDescriptions[0].register(in: tableView)

        // WHEN
        let indexPath = IndexPath(row: 0, section: 0)
        let cell = section.makeCell(for: tableView, at: indexPath) as? ConversationMessageCellTableViewAdapter<MockCellDescription<Any>>

        // THEN
        XCTAssertTrue(cell?.cellView.isConfigured == true)
    }

}
