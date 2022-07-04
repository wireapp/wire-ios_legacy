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

@available(iOS 13.0, *)
final class ContactsCellSnapshotTests: XCTestCase {

    var sut: ContactsCell!

    override func setUp() {
        super.setUp()
        XCTestCase.accentColor = .strongBlue
        sut = ContactsCell()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testForInviteButton() {
        sut.user = SwiftMockLoader.mockUsers()[0]
        sut.action = .invite

        verifyInAllColorSchemes(matching: sut)
    }

    func testForOpenButton() {
        sut.user = SwiftMockLoader.mockUsers()[0]
        sut.action = .open

        verifyInAllColorSchemes(matching: sut)
    }

    func testForOpenButtonWithALongUsername() {
        let user = SwiftMockLoader.mockUsers()[0]
        user.name = "A very long username which should be clipped at tail"
        sut.user = user
        sut.action = .open

        verifyInAllColorSchemes(matching: sut)
    }

    func testForNoSubtitle() {
        let user = SwiftMockLoader.mockUsers()[0]
        user.handle = nil
        sut.user = user
        sut.action = .open

        verifyInAllColorSchemes(matching: sut)
    }
}
