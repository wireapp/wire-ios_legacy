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
import Cartography
@testable import Wire

class ProfileHeaderViewTests: ZMSnapshotTestCase {

    override func setUp() {
        super.setUp()
        snapshotBackgroundColor = .white
    }

    func createSutWithHeadStyle(style: ProfileHeaderStyle,
                                user: ZMBareUser? = nil,
                                addressBookName: String? = nil,
                                fallbackName: String = "Jose Luis") -> ProfileHeaderView {
        let model = ProfileHeaderViewModel(user: user, fallbackName: fallbackName, addressBookName: addressBookName, navigationControllerViewControllerCount: 0)
        let sut = ProfileHeaderView(with: model)
        sut.headerStyle = style
        sut.updateDismissButton()

        return sut
    }

    func testThatItRendersFallbackUserName() {
        let sut = createSutWithHeadStyle(style: .noButton)
        verifyInAllPhoneWidths(view: sut)
    }

    func testThatItRendersFallbackUserName_CancelButton() {
        let sut = createSutWithHeadStyle(style: .cancelButton)
        verifyInAllPhoneWidths(view: sut)
    }

    func testThatItRendersFallbackUserName_CancelButton_Verified() {
        let sut = createSutWithHeadStyle(style: .cancelButton)
        sut.showVerifiedShield = true
        verifyInAllPhoneWidths(view: sut)
    }

    func testThatItRendersFallbackUserName_BackButton() {
        let sut = createSutWithHeadStyle(style: .backButton)
        verifyInAllPhoneWidths(view: sut)
    }

    func testThatItRendersAddressBookName() {
        let user = MockUser.mockUsers().first
        let sut = createSutWithHeadStyle(style: .backButton, user: user, addressBookName: "JameyBoy")
        verifyInAllPhoneWidths(view: sut)
    }

    func testThatItRendersAddressBookName_EqualName() {
        let user = MockUser.mockUsers().first
        let sut = createSutWithHeadStyle(style: .backButton, user: user, addressBookName: user?.name, fallbackName: "")
        verifyInAllPhoneWidths(view: sut)
    }

    func testThatItRendersUserName() {
        let user = MockUser.mockUsers().first
        let sut = createSutWithHeadStyle(style: .noButton, user: user, fallbackName: "")
        verifyInAllPhoneWidths(view: sut)
    }

    func testThatItRendersUserName_Verified() {
        let user = MockUser.mockUsers().first
        let sut = createSutWithHeadStyle(style: .noButton, user: user, fallbackName: "")
        sut.showVerifiedShield = true
        verifyInAllPhoneWidths(view: sut)
    }

    func testThatItRendersUserNoUsernameButEmail() {
        let user = MockUser.mockUsers().last
        let sut = createSutWithHeadStyle(style: .noButton, user: user, fallbackName: "")
        verifyInAllPhoneWidths(view: sut)
    }

    func testThatItRendersUserWithEmptyUserName() {
        let user = MockUser.mockUsers().first
        (user as Any as! MockUser).handle = ""
        let sut = createSutWithHeadStyle(style: .noButton, user: user, fallbackName: "")
        verifyInAllPhoneWidths(view: sut)
    }

}

