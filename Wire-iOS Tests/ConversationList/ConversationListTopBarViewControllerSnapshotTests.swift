//
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
import SnapshotTesting
@testable import Wire

final class ConversationListTopBarViewControllerSnapshotTests: XCTestCase {

    var sut: ConversationListTopBarViewController!
    var mockAccount: Account!
    var mockSelfUser: MockUserType!

    override func setUp() {
        super.setUp()
        mockAccount = Account.mockAccount(imageData: mockImageData)
        mockSelfUser = MockUserType.createSelfUser(name: "James Hetfield")
    }

    override func tearDown() {
        sut = nil
        mockAccount = nil
        mockSelfUser = nil

        super.tearDown()
    }

    func setupSut() {
        sut = ConversationListTopBarViewController(account: mockAccount, selfUser: mockSelfUser)
        sut.view.frame = CGRect(x: 0, y: 0, width: 375, height: 48)
        sut.view.backgroundColor = .black
    }


    // MARK: - legal hold

    func testForLegalHoldEnabled() {
        mockSelfUser.isUnderLegalHold = true
        setupSut()

        verify(matching: sut)
    }

    func testForLegalHoldPending() {
        mockSelfUser.requestLegalHold()
        setupSut()

        verify(matching: sut)
    }

    func testForLegalHoldDisabled() {
        mockSelfUser.isUnderLegalHold = false
        setupSut()

        verify(matching: sut)
    }

    // MARK: - use cases

    func testForLongName() {
        mockSelfUser.name = "Johannes Chrysostomus Wolfgangus Theophilus Mozart"

        setupSut()

        verify(matching: sut)
    }

    func testForOverflowSeperatorIsShownWhenScrollViewScrollsDown() {
        setupSut()

        let mockScrollView = UIScrollView()
        mockScrollView.contentOffset.y = 100

        sut.scrollViewDidScroll(scrollView: mockScrollView)

        verify(matching: sut)
    }
}
