//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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

final class ConversationCellTests: XCTestCase {

    weak var sut: ConversationCell?

    override func setUp() {
        super.setUp()
        sut = nil
    }

    override func tearDown() {
        sut = nil
        ColorScheme.default.variant = .light
        NSAttributedString.invalidateMarkdownStyle()
        NSAttributedString.invalidateParagraphStyle()
        super.tearDown()
    }

    func testThatBurstTimestampViewColorIsCorrectInLightTheme() {
        // GIVEN & WHEN
        let sut = ConversationCell(style: .default, reuseIdentifier: nil)

        // THEN
        XCTAssertEqual(sut.burstTimestampView.label.textColor, UIColor.from(scheme: .textForeground, variant:.light))
    }

    func testThatBurstTimestampViewColorIsCorrectInDarkTheme() {
        // GIVEN & WHEN
        ColorScheme.default.variant = .dark
        let sut = ConversationCell(style: .default, reuseIdentifier: nil)

        // THEN
        XCTAssertEqual(sut.burstTimestampView.label.textColor, UIColor.from(scheme: .textForeground, variant:.dark))
    }

    func testConversationCellIsNotRetainedAfterTimerIsScheduled() {
        autoreleasepool {
            // GIVEN
            let cellInTable = ConversationCell()
            sut = cellInTable

            let layoutProperties = ConversationCellLayoutProperties()
            layoutProperties.showBurstTimestamp = true
            let mockMessage = MockMessageFactory.locationMessage()
            cellInTable.configure(for: mockMessage, layoutProperties: layoutProperties)
            var tableView: UITableView! = cellInTable.wrapInTableView()
            tableView.reloadData()

            // WHEN
            cellInTable.willDisplayInTableView()
            tableView = nil
        }

        // THEN
        XCTAssertNil(sut)
    }
}

