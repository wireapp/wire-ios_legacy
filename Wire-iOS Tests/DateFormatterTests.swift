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

    /// MDY date format
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

    /// MD date format
    func testThatDateStringIsLocalizedToEN_USFormatWithDaySuffix() {
        // GIVEN
        let localeIdentifier = "en-US"
        let dateString = dateStringFromLocaleIdentifier(localeIdentifier: localeIdentifier)

        // WHEN & THEN
        let calendar = Calendar.current
        let day = calendar.component(.day, from: Date())

        XCTAssert(dateString.hasSuffix(String(day)), "dateString is \(dateString)")
    }

    /// YMD date format
    func testThatDateStringIsLocalizedToCAFormatWithYearPrefix() {
        // GIVEN
        let oneYearBefore = Calendar.current.date(byAdding: .year, value: -1, to: Date())!
        let localeIdentifier = "zh-TW"
        let dateString = dateStringFromLocaleIdentifier(localeIdentifier: localeIdentifier, date: oneYearBefore)

        // WHEN & THEN
        let year = Calendar.current.component(.year, from: Date()) - 1

        XCTAssert(dateString.hasPrefix(String(year)), "dateString is \(dateString)")
    }

    /// DM date format
    func testThatDateStringIsLocalizedToDEFormatWithMonthSuffix() {
        // GIVEN
        let localeIdentifier = "de_DE"
        let dateString = dateStringFromLocaleIdentifier(localeIdentifier: localeIdentifier)

        // WHEN & THEN
        let monthDateFormatter = DateFormatter()
        monthDateFormatter.dateFormat = "MMMM"
        let nameOfMonth = monthDateFormatter.string(from: Date())

        XCTAssert(dateString.hasSuffix(nameOfMonth), "dateString is \(dateString)")
    }

    /// MD date format, month is in digit format
    func testThatDateStringIsLocalizedToZH_HKFormatWithMonthPrefixAndContainsChineseChar() {
        // GIVEN
        let localeIdentifier = "zh-HK"
        let dateString = dateStringFromLocaleIdentifier(localeIdentifier: localeIdentifier)

        // WHEN & THEN
        let month = Calendar.current.component(.month, from: Date())

        XCTAssert(dateString.hasPrefix(String(month)), "dateString is \(dateString)")

        ///Confirm "day" & "Month" exists in dateString
        XCTAssert(dateString.contains("日"))
        XCTAssert(dateString.contains("月"))
    }

    func dateStringFromLocaleIdentifier(localeIdentifier: String, date: Date = Date()) -> String {
        let locale = Locale(identifier: localeIdentifier)

        let dateFormatter = date.localizedDateFormatter()
        let formatString = date.localizedDateFormatString(locale: locale)
        dateFormatter.dateFormat = formatString

        let dateString = dateFormatter.string(from: date)

        return dateString
    }
}

