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

final class ConversationListTabBarTests: ZMSnapshotTestCase {

    var sut: ConversationListTabBar!

    override func setUp() {
        super.setUp()

        snapshotBackgroundColor = UIColor(white: 0.2, alpha: 1) // In order to make the separator more visible
        accentColor = .brightYellow
        UIView.performWithoutAnimation({
            self.sut = ConversationListTabBar()

            // SUT has a priority 750 height constraint. fix its height first
            NSLayoutConstraint.activate([
                sut.heightAnchor.constraint(equalToConstant: 56)
                ])
        })
    }

    override func tearDown() {
        sut = nil

        super.tearDown()
    }

    func testThatItRendersTheBottomBarCorrectlyInInitialState() {
        // then
        verifyInAllPhoneWidths(view: sut)
    }

    func testThatItHidesTheContactsTitleAndShowsArchivedButtonWhen_ShowArchived_IsSetToYes() {
        // when
        sut.showArchived = true

        // then
        verifyInAllPhoneWidths(view: sut)
    }

    func testThatItShowsTheContactsTitleAndHidesTheArchivedButtonWhen_ShowArchived_WasSetToYesAndIsSetToNo() {
        // given
        accentColor = .strongBlue // To make the snapshot distinguishable from the inital state
        sut.showArchived = true

        // when
        sut.showArchived = false

        // then
        verifyInAllPhoneWidths(view: sut)
    }

}
