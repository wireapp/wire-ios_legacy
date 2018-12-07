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

final class ReadReceiptViewModelTests: XCTestCase {
    
    var sut: ReadReceiptViewModel!
    var mockMessage: MockMessage!
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        sut = nil
        mockMessage = nil

        super.tearDown()
    }

    func createMockMessage(type: ZMSystemMessageType) {
        mockMessage = MockMessageFactory.systemMessage(with: type)!
    }

    func testThatSelfUserSwitchOffReceiptOption(){
        // GIVEN & WHEN
        let type = ZMSystemMessageType.readReceiptsDisabled
        createMockMessage(type: type)

        sut = ReadReceiptViewModel(icon: .eye,
                                   iconColor: UIColor.from(scheme: .textDimmed),
                                   systemMessageType: type,
                                   sender: mockMessage.sender!)

        // THEN
        XCTAssertEqual(sut.attributedTitle()?.string, "You turned read receipts off for everyone")
    }

    func testThatOneUserSwitchOffReceiptOption(){
        // GIVEN
        let type = ZMSystemMessageType.readReceiptsDisabled
        createMockMessage(type: type)
        mockMessage.sender = MockUser.mockUsers()?.first

        // WHEN
        sut = ReadReceiptViewModel(icon: .eye,
                                   iconColor: UIColor.from(scheme: .textDimmed),
                                   systemMessageType: type,
                                   sender: mockMessage.sender!)

        // THEN
        XCTAssertEqual(sut.attributedTitle()?.string, "James Hetfield turned read receipts off for everyone")
    }

    func testThatOneUserSwitchOnReceiptOption(){
        // GIVEN & WHEN
        let type = ZMSystemMessageType.readReceiptsEnabled
        createMockMessage(type: type)
        mockMessage.sender = MockUser.mockUsers()?.first

        sut = ReadReceiptViewModel(icon: .eye,
                                   iconColor: UIColor.from(scheme: .textDimmed),
                                   systemMessageType: type,
                                   sender: mockMessage.sender!)

        // THEN
        XCTAssertEqual(sut.attributedTitle()?.string, "James Hetfield turned read receipts on for everyone")
    }

    func testThatReceiptOptionOnMessageIsShown(){
        // GIVEN & WHEN
        let type = ZMSystemMessageType.readReceiptsOn
        createMockMessage(type: type)

        sut = ReadReceiptViewModel(icon: .eye,
                                   iconColor: UIColor.from(scheme: .textDimmed),
                                   systemMessageType: type,
                                   sender: mockMessage.sender!)

        // THEN
        XCTAssertEqual(sut.attributedTitle()?.string, "Read receipts are on")
    }
}
