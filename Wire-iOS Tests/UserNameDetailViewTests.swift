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

class UserNameDetailViewTests: XCTestCase {
    var sut: UserNameDetailView!

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func createSutWithHeadStyle(user: UserType? = nil,
                                addressBookName: String? = nil,
                                fallbackName: String = "Jose Luis") -> UserNameDetailView {
        let model = UserNameDetailViewModel(user: user, fallbackName: fallbackName, addressBookName: addressBookName)
        let view = UserNameDetailView()
        view.translatesAutoresizingMaskIntoConstraints = true
        view.configure(with: model)
        view.backgroundColor = .white
        view.frame = CGRect(x: 0, y: 0, width: 320, height: 32)
        return view
    }

    func testThatItRendersAddressBookName() {
        let user = SwiftMockLoader.mockUsers().first
        sut = createSutWithHeadStyle(user: user, addressBookName: "JameyBoy")
        verify(matching: sut)
    }

    func testThatItRendersAddressBookName_EqualName() {
        let user = SwiftMockLoader.mockUsers().first
        sut = createSutWithHeadStyle(user: user, addressBookName: user?.name, fallbackName: "")
        verify(matching: sut)
    }

    func testThatItRendersUserName() {
        let user = SwiftMockLoader.mockUsers().first
        sut = createSutWithHeadStyle(user: user, fallbackName: "")
        verify(matching: sut)
    }

    func testThatItRendersUserName_Federated() {
        let user = SwiftMockLoader.mockUsers().first
        user?.domain = "wire.com"
        user?.isFederated = true
        sut = createSutWithHeadStyle(user: user, fallbackName: "")
        verify(matching: sut)
    }
}
