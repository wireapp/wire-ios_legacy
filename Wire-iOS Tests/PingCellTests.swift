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

final class PingCellTests: XCTestCase {

    var sut: PingCell!
    var originalAppleLanguages: [String]?

    override func setUp() {
        // change AppleLanguages to German, then restore to original language in tearDown()
        if originalAppleLanguages == nil {
            originalAppleLanguages = UserDefaults.standard.stringArray(forKey: "AppleLanguages")
        }
        UserDefaults.standard.set(["de"], forKey: "AppleLanguages")
        UserDefaults.standard.synchronize()

        super.setUp()

        sut = PingCell()
    }

    override func tearDown() {
        sut = nil
        UserDefaults.standard.set(originalAppleLanguages, forKey: "AppleLanguages")
        UserDefaults.standard.synchronize()

        super.tearDown()
    }

    func testYouPingedInGerman() {
        // GIVEN
        let senderText = "Du"
        MockUser.currentPointOfView = .secondPerson
        sut.configure(for: MockMessageFactory.pingMessage(), layoutProperties: nil)

        // WHEN
        let pingMessage = sut.pingMessage(senderText: senderText)

        // THEN
        XCTAssertEqual(pingMessage, "Du hast gepingt", "pointOfViewString is \(String(describing: pingMessage))")
    }

    func testSomeonePingedInGerman() {
        // GIVEN
        let senderText = "Bill"
        MockUser.currentPointOfView = .thirdPerson
        sut.configure(for: MockMessageFactory.pingMessage(), layoutProperties: nil)

        // WHEN
        let pingMessage = sut.pingMessage(senderText: senderText)

        // THEN
        XCTAssertEqual(pingMessage, "Bill hat gepingt", "pointOfViewString is \(String(describing: pingMessage))")
    }
}

