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

final class EphemeralTimeoutFormatterTests: XCTestCase {
    
    var sut: EphemeralTimeoutFormatter!
    static let ephemeralTimeFormatter = EphemeralTimeoutFormatter()

    override func setUp() {
        super.setUp()
        sut = EphemeralTimeoutFormatter()
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testFor1Year11Months30DaysLeft(){
        // GIVEN & WHEN
        // minus one day to make sure it is less than 1 year 6 months
        let formattedString = sut.string(from: 31536000 * 2 - 86400)

        // THEN
        XCTAssertEqual(formattedString, "1 year, 11 months, 30 days left")
    }


    func testForOneAndAHalfYearLeft(){
        // GIVEN & WHEN
        // minus one day to make sure it is less than 1 year 6 months
        let formattedString = sut.string(from: 31536000 * 1.5 - 86400)

        // THEN
        XCTAssertEqual(formattedString, "1 year, 6 months left")
    }

    func testFor1YearLeft(){
        // GIVEN & WHEN
        let formattedString = sut.string(from: 31536000)

        // THEN
        XCTAssertEqual(formattedString, "1 year left")
    }

    func testFor1SecondLessThanAYearLeft(){
        // GIVEN & WHEN
        let formattedString = sut.string(from: 31535999)

        // THEN
        XCTAssertEqual(formattedString, "364 days, 23 hours left")
    }

    func testFor4WeeksLeft(){
        // GIVEN & WHEN
        let formattedString = sut.string(from: 2419200)

        // THEN
        XCTAssertEqual(formattedString, "28 days left")
    }

    func testFor27days23HoursLeft(){
        // GIVEN & WHEN
        let formattedString = sut.string(from: 2419199)

        // THEN
        XCTAssertEqual(formattedString, "27 days, 23 hours left")
    }

    func testFor1dayLeft(){
        // GIVEN & WHEN
        let formattedString = sut.string(from: 86400)

        // THEN
        XCTAssertEqual(formattedString, "1 day left")
    }

    func testFor23hours59minutesLeft(){
        // GIVEN & WHEN
        let formattedString = sut.string(from: 86399)

        // THEN
        XCTAssertEqual(formattedString, "23:59:59 left")
    }

    func testFor1hourLeft(){
        // GIVEN & WHEN
        let formattedString = sut.string(from: 3600)

        // THEN
        XCTAssertEqual(formattedString, "1:00:00 left")
    }

    func testFor59minutes59secondsLeft(){
        // GIVEN & WHEN
        let formattedString = sut.string(from: 3599)

        // THEN
        XCTAssertEqual(formattedString, "59:59 left")
    }

    func testFor59secondsLeft(){
        // GIVEN & WHEN
        let formattedString = sut.string(from: 59)

        // THEN
        XCTAssertEqual(formattedString, "59 seconds left")
    }
}
