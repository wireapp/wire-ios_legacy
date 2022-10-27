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

import UIKit
import XCTest
@testable import Wire

final class MockDestination: NSObject, ShareDestination {

    var isUnderLegalHold: Bool

    var showsGuestIcon: Bool

    var displayName: String

    var securityLevel: ZMConversationSecurityLevel

    var avatarView: UIView?

    init(displayName: String, avatarView: UIView? = nil, securityLevel: ZMConversationSecurityLevel = .notSecure, showsGuestIcon: Bool = false, isUnderLegalHold: Bool = false) {
        self.displayName = displayName
        self.securityLevel = securityLevel
        self.avatarView = avatarView
        self.showsGuestIcon = showsGuestIcon
        self.isUnderLegalHold = isUnderLegalHold
    }
}

final class ShareDestinationCellTests: ZMSnapshotTestCase {

    var sut: ShareDestinationCell<MockDestination>!
    var destination: MockDestination?
    var mockAvatarView: UIImageView {
        // just using a simple UIImageView, since ConversationAvatarView is covered in ConversationAvatarViewTests
        let imageView = UIImageView(image: image(inTestBundleNamed: "unsplash_burger.jpg"))
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }

    override func setUp() {
        super.setUp()

        accentColor = .vividRed
        sut = ShareDestinationCell(style: .default, reuseIdentifier: "reuseIdentifier")
        sut.overrideUserInterfaceStyle = .dark
        sut.backgroundColor = .black
    }

    override func tearDown() {
        sut = nil
        destination = nil
        super.tearDown()
    }

    func testThatItRendersCorrectly_CellWithPersonalNameAndPicture_NotSecure_Unchecked() {
        // given
        let destination = MockDestination(displayName: "John Burger",
                                          avatarView: mockAvatarView,
                                          securityLevel: .notSecure)
        // when
        sut.destination = destination
        let view = sut.prepareForSnapshots()
        // then
        verify(matching: view)
    }

    func testThatItRendersCorrectly_CellWithPersonalNameAndPicture_NotSecure_Unchecked_Guest() {
        // given
        let destination = MockDestination(displayName: "John Burger",
                                          avatarView: mockAvatarView,
                                          securityLevel: .notSecure,
                                          showsGuestIcon: true)
        // when
        sut.destination = destination
        // then
        verify(matching: sut.prepareForSnapshots())
    }

    func testThatItRendersCorrectly_CellWithPersonalNameAndPicture_NotSecure_Unchecked_LegalHold() {
        // given
        let destination = MockDestination(displayName: "John Burger",
                                          avatarView: mockAvatarView,
                                          securityLevel: .notSecure,
                                          isUnderLegalHold: true)
        // when
        sut.destination = destination
        // then
        verify(matching: sut.prepareForSnapshots())
    }

    func testThatItRendersCorrectly_CellWithLongPersonalNameAndPicture_NotSecure_Unchecked() {
        // given
        let destination = MockDestination(displayName: "His Majesty John Carl Steven Bob Burger II",
                                          avatarView: mockAvatarView,
                                          securityLevel: .notSecure)
        // when
        sut.destination = destination
        // then
        verify(matching: sut.prepareForSnapshots())
    }

    func testThatItRendersCorrectly_CellWithLongPersonalNameAndPicture_NotSecure_Unchecked_Guest() {
        // given
        let destination = MockDestination(displayName: "His Majesty John Carl Steven Bob Burger II",
                                          avatarView: mockAvatarView,
                                          securityLevel: .notSecure,
                                          showsGuestIcon: true)
        // when
        sut.destination = destination
        // then
        verify(matching: sut.prepareForSnapshots())
    }

    func testThatItRendersCorrectly_CellWithPersonalNameAndPicture_NotSecure_Checked() {
        // given
        let destination = MockDestination(displayName: "John Burger",
                                          avatarView: mockAvatarView,
                                          securityLevel: .notSecure)
        // when
        sut.destination = destination
        // then
        verify(matching: sut.prepareForSnapshotWithCellSelected())
    }

    func testThatItRendersCorrectly_CellWithPersonalNameAndPicture_NotSecure_Checked_Guest() {
        // given
        let destination = MockDestination(displayName: "John Burger",
                                          avatarView: mockAvatarView,
                                          securityLevel: .notSecure,
                                          showsGuestIcon: true)
        // when
        sut.destination = destination
        // then
        verify(matching: sut.prepareForSnapshotWithCellSelected())
    }

    func testThatItRendersCorrectly_CellWithLongPersonalNameAndPicture_NotSecure_Checked() {
        // given
        let destination = MockDestination(displayName: "His Majesty John Carl Steven Bob Burger II",
                                          avatarView: mockAvatarView,
                                          securityLevel: .notSecure)
        // when
        sut.destination = destination
        // then
        verify(matching: sut.prepareForSnapshotWithCellSelected())
    }

    func testThatItRendersCorrectly_CellWithLongPersonalNameAndPicture_NotSecure_Checked_Guest() {
        // given
        let destination = MockDestination(displayName: "His Majesty John Carl Steven Bob Burger II",
                                          avatarView: mockAvatarView,
                                          securityLevel: .notSecure,
                                          showsGuestIcon: true)
        // when
        sut.destination = destination
        // then
        verify(matching: sut.prepareForSnapshotWithCellSelected())
    }

    func testThatItRendersCorrectly_CellWithPersonalNameAndPicture_Secure_Unchecked() {
        // given
        let destination = MockDestination(displayName: "John Burger",
                                          avatarView: mockAvatarView,
                                          securityLevel: .secure)
        // when
        sut.destination = destination
        // then
        verify(matching: sut.prepareForSnapshots())
    }

    func testThatItRendersCorrectly_CellWithPersonalNameAndPicture_Secure_Unchecked_Guest() {
        // given
        let destination = MockDestination(displayName: "John Burger",
                                          avatarView: mockAvatarView,
                                          securityLevel: .secure,
                                          showsGuestIcon: true)
        // when
        sut.destination = destination
        // then
        verify(matching: sut.prepareForSnapshots())
    }

    func testThatItRendersCorrectly_CellWithPersonalNameAndPicture_Secure_Unchecked_Guest_LegalHold() {
        // given
        let destination = MockDestination(displayName: "John Burger",
                                          avatarView: mockAvatarView,
                                          securityLevel: .secure,
                                          showsGuestIcon: true,
                                          isUnderLegalHold: true)
        // when
        sut.destination = destination
        // then
        verify(matching: sut.prepareForSnapshots())
    }

    func testThatItRendersCorrectly_CellWithLongPersonalNameAndPicture_Secure_Unchecked() {
        // given
        let destination = MockDestination(displayName: "His Majesty John Carl Steven Bob Burger II",
                                          avatarView: mockAvatarView,
                                          securityLevel: .secure)
        // when
        sut.destination = destination
        // then
        verify(matching: sut.prepareForSnapshots())
    }

    func testThatItRendersCorrectly_CellWithLongPersonalNameAndPicture_Secure_Unchecked_Guest() {
        // given
        let destination = MockDestination(displayName: "His Majesty John Carl Steven Bob Burger II",
                                          avatarView: mockAvatarView,
                                          securityLevel: .secure,
                                          showsGuestIcon: true)
        // when
        sut.destination = destination
        // then
        verify(matching: sut.prepareForSnapshots())
    }

    func testThatItRendersCorrectly_CellWithPersonalNameAndPicture_Secure_Checked() {
        // given
        let destination = MockDestination(displayName: "John Burger",
                                          avatarView: mockAvatarView,
                                          securityLevel: .secure)
        // when
        sut.destination = destination
        // then
        verify(matching: sut.prepareForSnapshotWithCellSelected())
    }

    func testThatItRendersCorrectly_CellWithPersonalNameAndPicture_Secure_Checked_Guest() {
        // given
        let destination = MockDestination(displayName: "John Burger",
                                          avatarView: mockAvatarView,
                                          securityLevel: .secure,
                                          showsGuestIcon: true)
        // when
        sut.destination = destination
        // then
        verify(matching: sut.prepareForSnapshotWithCellSelected())
    }

    func testThatItRendersCorrectly_CellWithLongPersonalNameAndPicture_Secure_Checked() {
        // given
        let destination = MockDestination(displayName: "His Majesty John Carl Steven Bob Burger II",
                                          avatarView: mockAvatarView,
                                          securityLevel: .secure)
        // when
        sut.destination = destination
        // then
        verify(matching: sut.prepareForSnapshotWithCellSelected())
    }

    func testThatItRendersCorrectly_CellWithLongPersonalNameAndPicture_Secure_Checked_Guest() {
        // given
        let destination = MockDestination(displayName: "His Majesty John Carl Steven Bob Burger II",
                                          avatarView: mockAvatarView,
                                          securityLevel: .secure,
                                          showsGuestIcon: true)
        // when
        sut.destination = destination
        // then
        verify(matching: sut.prepareForSnapshotWithCellSelected())
    }
}

fileprivate extension UITableViewCell {

    func prepareForSnapshotWithCellSelected() -> UITableView {
        let view = prepareForSnapshots()
        view.selectRow(at: IndexPath(row: 0, section: 0), animated: false, scrollPosition: .none)
        return view
    }

}
