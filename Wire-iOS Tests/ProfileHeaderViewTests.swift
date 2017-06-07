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

    func testThatItRendersFallbackUserName() {
        let model = ProfileHeaderViewModel(user: nil, fallbackName: "Jose Luis", addressBookName: nil, style: .noButton)
        let sut = ProfileHeaderView(with: model)
        verifyInAllPhoneWidths(view: sut)
    }

    func testThatItRendersFallbackUserName_CancelButton() {
        let model = ProfileHeaderViewModel(user: nil, fallbackName: "Jose Luis", addressBookName: nil, style: .cancelButton)
        let sut = ProfileHeaderView(with: model)
        verifyInAllPhoneWidths(view: sut)
    }

    func testThatItRendersFallbackUserName_CancelButton_Verified() {
        let model = ProfileHeaderViewModel(user: nil, fallbackName: "Jose Luis", addressBookName: nil, style: .cancelButton)
        let sut = ProfileHeaderView(with: model)
        sut.showVerifiedShield = true
        verifyInAllPhoneWidths(view: sut)
    }

    func testThatItRendersFallbackUserName_BackButton() {
        let model = ProfileHeaderViewModel(user: nil, fallbackName: "Jose Luis", addressBookName: nil, style: .backButton)
        let sut = ProfileHeaderView(with: model)
        verifyInAllPhoneWidths(view: sut)
    }

    func testThatItRendersAddressBookName() {
        let user = MockUser.mockUsers().first
        let model = ProfileHeaderViewModel(user: user, fallbackName: "Jose Luis", addressBookName: "JameyBoy", style: .backButton)
        let sut = ProfileHeaderView(with: model)
        verifyInAllPhoneWidths(view: sut)
    }

    func testThatItRendersAddressBookName_EqualName() {
        let user = MockUser.mockUsers().first
        let model = ProfileHeaderViewModel(user: user, fallbackName: "", addressBookName: user?.name, style: .backButton)
        let sut = ProfileHeaderView(with: model)
        verifyInAllPhoneWidths(view: sut)
    }

    func testThatItRendersUserName() {
        let user = MockUser.mockUsers().first
        let model = ProfileHeaderViewModel(user: user, fallbackName: "", addressBookName: nil, style: .noButton)
        let sut = ProfileHeaderView(with: model)
        verifyInAllPhoneWidths(view: sut)
    }

    func testThatItRendersUserName_Verified() {
        let user = MockUser.mockUsers().first
        let model = ProfileHeaderViewModel(user: user, fallbackName: "", addressBookName: nil, style: .noButton)
        let sut = ProfileHeaderView(with: model)
        sut.showVerifiedShield = true
        verifyInAllPhoneWidths(view: sut)
    }

    func testThatItRendersUserNoUsernameButEmail() {
        let user = MockUser.mockUsers().last
        let model = ProfileHeaderViewModel(user: user, fallbackName: "", addressBookName: nil, style: .noButton)
        let sut = ProfileHeaderView(with: model)
        verifyInAllPhoneWidths(view: sut)
    }


    func testThatItRendersUserWithEmptyUserName() {
        let user = MockUser.mockUsers().first
        (user as Any as! MockUser).handle = ""
        let model = ProfileHeaderViewModel(user: user, fallbackName: "", addressBookName: nil, style: .noButton)
        let sut = ProfileHeaderView(with: model)
        verifyInAllPhoneWidths(view: sut)
    }

}
