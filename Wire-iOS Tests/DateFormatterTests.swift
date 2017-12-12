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

    func testThatDateStringDoesNotContainYearIfDateIsToday() {
        // GIVEN
        let date = Date()
        let dateFormatter = date.localizedDateFormatter()
        let dateString = dateFormatter.string(from: date)

        let calendar = Calendar.current
        let year = calendar.component(.year, from: Date())

        // WHEN & THEN
        XCTAssertFalse(dateString.contains(String(year)))
    }

    func testThatDateStringContainsYearIfDateIsOneYearAgo() {
        // GIVEN
        let oneYearBefore = Calendar.current.date(byAdding: .year, value: -1, to: Date())

        let dateFormatter = oneYearBefore!.localizedDateFormatter()
        let dateString = dateFormatter.string(from: oneYearBefore!)

        let calendar = Calendar.current
        let year = calendar.component(.year, from: Date()) - 1

        // WHEN & THEN
        XCTAssert(dateString.contains(String(year)), "dateString is \(dateString)")
    }

    func testThatDateStringIsLocalizedToEN_USFormatWithDaySuffix() {
        // GIVEN
        let date = Date()
        let locale = Locale(identifier: "en-US")

        let calendar = Calendar.current
        let day = calendar.component(.day, from: Date())

        // WHEN
        let dateFormatter = date.localizedDateFormatter(locale: locale)
        let dateString = dateFormatter.string(from: date)

        // THEN
        XCTAssert(dateString.hasSuffix(String(day)), "dateString is \(dateString)")
    }

    func testThatDateStringIsLocalizedToDEFormatWithMonthSuffix() {
        // GIVEN
        let date = Date()
        let locale = Locale(identifier: "de")

        let monthDateFormatter = DateFormatter()
        monthDateFormatter.dateFormat = "MMMM"
        let nameOfMonth = monthDateFormatter.string(from: date)

        // WHEN
        let dateFormatter = date.localizedDateFormatter(locale: locale)
        let dateString = dateFormatter.string(from: date)

        // THEN
        XCTAssert(dateString.hasSuffix(nameOfMonth), "dateString is \(dateString)")
    }

    func testThatDateStringIsLocalizedToZH_HKFormatWithMonthPrefixAndContainsChineseChar() {
        // GIVEN
        let date = Date()
        let locale = Locale(identifier: "zh-HK")

        let calendar = Calendar.current
        let day = calendar.component(.day, from: Date())

        // WHEN
        let dateFormatter = date.localizedDateFormatter(locale: locale)
        let dateString = dateFormatter.string(from: date)

        // THEN
        XCTAssert(dateString.hasPrefix(String(day)), "dateString is \(dateString)")

        ///Confirm "day" & "Month" exists in dateString
        XCTAssert(dateString.contains("日"))
        XCTAssert(dateString.contains("月"))
    }
}

