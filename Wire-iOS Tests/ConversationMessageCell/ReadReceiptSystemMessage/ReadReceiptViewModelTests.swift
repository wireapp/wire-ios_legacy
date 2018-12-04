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
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }



    /// Example checker method which can be reused in different tests
    ///
    /// - Parameters:
    ///   - file: optional, for XCTAssert logging error source
    ///   - line: optional, for XCTAssert logging error source
    fileprivate func checkerExample(file: StaticString = #file, line: UInt = #line) {
        XCTAssert(true, file: file, line: line)
    }

    func testThatSelfUserSwitchOffReceiptOption(){
        // GIVEN & WHEN

        let usersCount = 1
        let clientsCount = 1
        let type = ZMSystemMessageType.readReceiptSettingChanged

        let mockMessage = MockMessageFactory.systemMessage(with: type, users: usersCount, clients: clientsCount)!

        mockMessage.backingSystemMessageData?.users = Set<AnyHashable>([MockUser.mockSelf()]) as! Set<ZMUser>

        sut = ReadReceiptViewModel(icon: .eye,
                                   iconColor: UIColor.from(scheme: .textDimmed),
                                   message: mockMessage,
                                   systemMessage:mockMessage.systemMessageData!)

        // THEN
        XCTAssertEqual(sut.attributedTitle()?.string, "You turned read receipts off for everyone")
    }

    /*
    func testThatOneUserSwitchOffReceiptOption(){
        // GIVEN & WHEN

        let usersCount = 1
        let clientsCount = 1
        let type = ZMSystemMessageType.readReceiptSettingChanged

        let systemMessage = MockMessageFactory.systemMessage(with: type, users: usersCount, clients: clientsCount)!

        sut = ReadReceiptViewModel(icon: .eye,
                                   iconColor: UIColor.from(scheme: .textDimmed),
                                   message: systemMessage)

        // THEN
        XCTAssertEqual(sut.attributedTitle()?.string, "Someone turned read receipts off for everyone")
    }
 */
}
