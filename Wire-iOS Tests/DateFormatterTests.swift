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

final class DateFormatterTests: XCTestCase {

    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }

    func testThatDateStringDoesNotContainYearIfDateIsToday(){
        // GIVEN
        let date = Date()
        let dateFormatter = Date.localizedDateFormatter(date: date)
        let dateString = dateFormatter.string(from: date)

        let calendar = Calendar.current
        let year = calendar.component(.year, from: Date())

        // WHEN & THEN
        XCTAssertFalse(dateString.contains(String(year)))
    }

    func testThatDateStringContainsYearIfDateIsOneYearBeforeToday(){
        // GIVEN
        let oneYearBefore = Calendar.current.date(byAdding: .year, value: -1, to: Date())

        let dateFormatter = Date.localizedDateFormatter(date: oneYearBefore!)
        let dateString = dateFormatter.string(from: oneYearBefore!)

        let calendar = Calendar.current
        let year = calendar.component(.year, from: Date()) - 1

        // WHEN & THEN
        XCTAssert(dateString.contains(String(year)), "dateString is \(dateString)")
    }
}
