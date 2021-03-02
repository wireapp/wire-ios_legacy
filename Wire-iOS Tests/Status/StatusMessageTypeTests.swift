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

func localizeString (stringToLocalize: String, language: String) -> String? {
    guard let path = Bundle.main.path(forResource: language, ofType: "lproj") else { return nil }

    let languageBundle = Bundle(path: path)
    return languageBundle! .localizedString(forKey: stringToLocalize, value: "", table: nil)
}

final class StatusMessageTypeTests: XCTestCase {

    func testForAllLanguageIsLocalized() {
        /// GIVEN
        let availableLanguages = Bundle.main.localizations

        for statusMessageType in StatusMessageType.allCases {
            if let key = statusMessageType.localizationKey {
                availableLanguages.forEach() { language in
                    if let localizationKey = localizeString(stringToLocalize: key, language: language) {

                        /// WHEN
                        var sut = String(format: localizationKey.localized, 1)

                        /// THEN
                        XCTAssertGreaterThan(sut.count, 0, "localized string is \(sut)")

                        /// WHEN
                        sut = String(format: localizationKey.localized, 2)

                        /// THEN
                        XCTAssertGreaterThan(sut.count, 0, "localized string is \(sut)")

                        /// WHEN
                        sut = String(format: localizationKey.localized, 100)

                        /// THEN
                        XCTAssertGreaterThan(sut.count, 0, "localized string is \(sut)")
                    }
                }
            }
        }
    }

    func testForBaseLanguageIsLocalized() {

        /// GIVEN
        for statusMessageType in StatusMessageType.allCases {
            /// WHEN
            var count: UInt = 1

            /// THEN
            switch statusMessageType {
            case .mention:
                XCTAssertEqual(statusMessageType.localizedString(with: count), "1 mention")
            case .reply:
                XCTAssertEqual(statusMessageType.localizedString(with: count), "1 reply")
            case .missedCall:
                XCTAssertEqual(statusMessageType.localizedString(with: count), "1 missed call")
            case .knock:
                XCTAssertEqual(statusMessageType.localizedString(with: count), "1 ping")
            case .text:
                XCTAssertEqual(statusMessageType.localizedString(with: count), "1 message")
            default:
                XCTAssertNil(statusMessageType.localizedString(with: count))
            }

            /// WHEN
            count = 2

            /// THEN
            switch statusMessageType {
            case .mention:
                XCTAssertEqual(statusMessageType.localizedString(with: count), "2 mentions")
            case .reply:
                XCTAssertEqual(statusMessageType.localizedString(with: count), "2 replies")
            case .missedCall:
                XCTAssertEqual(statusMessageType.localizedString(with: count), "2 missed calls")
            case .knock:
                XCTAssertEqual(statusMessageType.localizedString(with: count), "2 pings")
            case .text:
                XCTAssertEqual(statusMessageType.localizedString(with: count), "2 messages")
            default:
                XCTAssertNil(statusMessageType.localizedString(with: count))
            }

        }
    }
}
