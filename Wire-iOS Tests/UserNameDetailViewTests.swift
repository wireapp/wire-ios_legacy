//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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

class UserNameDetailViewTests: ZMSnapshotTestCase {

    override func setUp() {
        super.setUp()
        snapshotBackgroundColor = .white
    }

    func createSutWithHeadStyle(user: UserType? = nil,
                                addressBookName: String? = nil,
                                fallbackName: String = "Jose Luis") -> UserNameDetailView {
        let model = UserNameDetailViewModel(user: user, fallbackName: fallbackName, addressBookName: addressBookName)
        let sut = UserNameDetailView()
        sut.configure(with: model)

        return sut
    }

    func testThatItRendersFallbackUserName() {
        let sut = createSutWithHeadStyle()
        verifyInAllPhoneWidths(view: sut)
    }

    func testThatItRendersAddressBookName() {
        let user = MockUser.mockUsers().first
        let sut = createSutWithHeadStyle(user: user, addressBookName: "JameyBoy")
        verifyInAllPhoneWidths(view: sut)
    }

    func testThatItRendersAddressBookName_EqualName() {
        let user = MockUser.mockUsers().first
        let sut = createSutWithHeadStyle(user: user, addressBookName: user?.name, fallbackName: "")
        verifyInAllPhoneWidths(view: sut)
    }

    func testThatItRendersUserName() {
        let user = MockUser.mockUsers().first
        let sut = createSutWithHeadStyle(user: user, fallbackName: "")
        verifyInAllPhoneWidths(view: sut)
    }
    
}

