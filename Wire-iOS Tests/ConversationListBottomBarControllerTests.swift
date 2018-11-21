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

class MockConversationListBottomBarDelegate: NSObject, ConversationListBottomBarControllerDelegate {
    func conversationListBottomBar(_ bar: ConversationListBottomBarController, didTapButtonWithType buttonType: ConversationListButtonType) {
        switch (buttonType) {
        case .archive:
            self.archiveButtonTapCount += 1
        case .compose:
            self.composeButtonCallCount += 1
        case .camera:
            self.cameraButtonTapCount += 1
        case .startUI:
            self.startUIButtonCallCount += 1
        }
    }

    var startUIButtonCallCount: Int = 0
    var archiveButtonTapCount: Int = 0
    var cameraButtonTapCount: Int = 0
    var composeButtonCallCount: Int = 0
}

final class ConversationListBottomBarControllerTests: ZMSnapshotTestCase {
    
    var sut: ConversationListBottomBarController!
    var mockDelegate: MockConversationListBottomBarDelegate!

    override func setUp() {
        super.setUp()

        snapshotBackgroundColor = UIColor(white: 0.2, alpha: 1) // In order to make the separator more visible
        accentColor = .brightYellow
        mockDelegate = MockConversationListBottomBarDelegate()
        UIView.performWithoutAnimation({
            self.sut = ConversationListBottomBarController(delegate: self.mockDelegate)

            ///SUT has a priority 750 height constraint. fix its height first
            NSLayoutConstraint.activate([
                sut.view.heightAnchor.constraint(equalToConstant: 56)
                ])
        })
    }
    
    override func tearDown() {
        sut = nil
        mockDelegate = nil
        
        super.tearDown()
    }

    func testThatItRendersTheBottomBarCorrectlyInInitialState() {
        // when
        XCTAssertFalse(sut.showSeparator)

        // then
        verifyInAllPhoneWidths(view: sut.view)
    }

    func testThatTheSeparatorIsNotHiddenWhen_ShowSeparator_IsSetToYes() {
        // when
        sut.showSeparator = true

        // then
        XCTAssertFalse(sut.separator.isHidden)
        verifyInAllPhoneWidths(view: sut.view)
    }

    func testThatItHidesTheContactsTitleAndShowsArchivedButtonWhen_ShowArchived_IsSetToYes() {
        // when
        sut.showArchived = true

        // then
        verifyInAllPhoneWidths(view: sut.view)
    }

    func testThatItShowsTheContactsTitleAndHidesTheArchivedButtonWhen_ShowArchived_WasSetToYesAndIsSetToNo() {
        // given
        accentColor = .strongBlue // To make the snapshot distinguishable from the inital state
        sut.showArchived = true

        // when
        sut.showArchived = false

        // then
        verifyInAllPhoneWidths(view: sut.view)
    }

    func testThatItCallsTheDelegateWhenTheContactsButtonIsTapped() {
        // when
        sut.startUIButton.sendActions(for: .touchUpInside)

        // then
        XCTAssertEqual(mockDelegate.startUIButtonCallCount, 1)
        XCTAssertEqual(mockDelegate.archiveButtonTapCount, 0)
        XCTAssertEqual(mockDelegate.cameraButtonTapCount, 0)
        XCTAssertEqual(mockDelegate.composeButtonCallCount, 0)
    }

    func testThatItCallsTheDelegateWhenTheArchivedButtonIsTapped() {
        // when
        sut.archivedButton.sendActions(for: .touchUpInside)

        // then
        XCTAssertEqual(mockDelegate.startUIButtonCallCount, 0)
        XCTAssertEqual(mockDelegate.archiveButtonTapCount, 1)
        XCTAssertEqual(mockDelegate.cameraButtonTapCount, 0)
        XCTAssertEqual(mockDelegate.composeButtonCallCount, 0)
    }

    func testThatItCallsTheDelegateWhenTheCameraButtonIsTapped() {
        // when
        sut.cameraButton.sendActions(for: .touchUpInside)

        // then
        XCTAssertEqual(mockDelegate.startUIButtonCallCount, 0)
        XCTAssertEqual(mockDelegate.archiveButtonTapCount, 0)
        XCTAssertEqual(mockDelegate.cameraButtonTapCount, 1)
        XCTAssertEqual(mockDelegate.composeButtonCallCount, 0)
    }

    func testThatItCallsTheDelegateWhenTheComposeButtonIsTapped() {
        // when
        sut.composeButton.sendActions(for: .touchUpInside)

        // then
        XCTAssertEqual(mockDelegate.startUIButtonCallCount, 0)
        XCTAssertEqual(mockDelegate.archiveButtonTapCount, 0)
        XCTAssertEqual(mockDelegate.cameraButtonTapCount, 0)
        XCTAssertEqual(mockDelegate.composeButtonCallCount, 1)
    }

}
