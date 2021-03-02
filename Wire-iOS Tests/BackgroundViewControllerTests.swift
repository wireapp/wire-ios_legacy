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

import XCTest
@testable import Wire

final class BackgroundViewControllerTests: XCTestCase {

    var selfUser: MockUserType!

    override func setUp() {
        super.setUp()
        accentColor = .violet
        selfUser = MockUserType.createSelfUser(name: "")
        selfUser.accentColorValue = .violet
    }

    override func tearDown() {
        selfUser = nil

        super.tearDown()
    }

    func testThatItShowsUserWithoutImage() {
        // GIVEN
        let sut = BackgroundViewController(user: selfUser, userSession: .none)
        XCTAssertTrue(waitForGroupsToBeEmpty([sut.dispatchGroup]))

        // WHEN & THEN
        verify(matching: sut)
    }

    func testThatItShowsUserWithImage() {
        // GIVEN
        selfUser.completeImageData = image(inTestBundleNamed: "unsplash_matterhorn.jpg").pngData()
        let sut = BackgroundViewController(user: selfUser, userSession: .none)
        // make sure view is loaded
        _ = sut.view
        // WHEN
        /// TODO: hacks to make below line passes
        selfUser.accentColorValue = selfUser.accentColorValue

        XCTAssertTrue(waitForGroupsToBeEmpty([sut.dispatchGroup], timeout: 10))

        // WHEN & THEN
        verify(matching: sut)
    }

    func testThatItUpdatesForUserAccentColorUpdate_fromAccentColor() {
        // GIVEN
        let sut = BackgroundViewController(user: selfUser, userSession: .none)
        _ = sut.view
        // WHEN
        selfUser.accentColorValue = .brightOrange
        sut.updateFor(imageMediumDataChanged: false, accentColorValueChanged: true)

        // THEN
        verify(matching: sut)
    }

    func testThatItUpdatesForUserAccentColorUpdate_fromUserImageRemoved() {
        // GIVEN
        selfUser.completeImageData = image(inTestBundleNamed: "unsplash_matterhorn.jpg").pngData()
        let sut = BackgroundViewController(user: selfUser, userSession: .none)
        _ = sut.view
        // WHEN
        selfUser.completeImageData = nil
        selfUser.accentColorValue = .brightOrange
        sut.updateFor(imageMediumDataChanged: true, accentColorValueChanged: true)
        // THEN
        verify(matching: sut)
    }

    func testThatItUpdatesForUserAccentColorUpdate_fromUserImage() {
        // GIVEN
        selfUser.completeImageData = image(inTestBundleNamed: "unsplash_matterhorn.jpg").pngData()
        let sut = BackgroundViewController(user: selfUser, userSession: .none)
        _ = sut.view
        // WHEN
        selfUser.accentColorValue = .brightOrange
        sut.updateFor(imageMediumDataChanged: true, accentColorValueChanged: true)
        XCTAssertTrue(waitForGroupsToBeEmpty([sut.dispatchGroup]))

        // THEN
        verify(matching: sut)
    }

    func testThatItUpdatesForUserImageUpdate_fromAccentColor() {
        // GIVEN
        selfUser.completeImageData = nil
        let sut = BackgroundViewController(user: selfUser, userSession: .none)
        _ = sut.view
        // WHEN
        selfUser.completeImageData = image(inTestBundleNamed: "unsplash_matterhorn.jpg").pngData()
        sut.updateFor(imageMediumDataChanged: true, accentColorValueChanged: false)
        XCTAssertTrue(waitForGroupsToBeEmpty([sut.dispatchGroup]))
        // THEN
        verify(matching: sut)
    }

    func testThatItUpdatesForUserImageUpdate_fromUserImage() {
        // GIVEN
        selfUser.completeImageData = image(inTestBundleNamed: "unsplash_matterhorn.jpg").pngData()
        let sut = BackgroundViewController(user: selfUser, userSession: .none)
        _ = sut.view
        // WHEN
        selfUser.completeImageData = image(inTestBundleNamed: "unsplash_burger.jpg").pngData()
        sut.updateFor(imageMediumDataChanged: true, accentColorValueChanged: false)
        XCTAssertTrue(waitForGroupsToBeEmpty([sut.dispatchGroup]))
        // THEN
        verify(matching: sut)
    }
}
