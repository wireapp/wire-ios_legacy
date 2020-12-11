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
    var sut: BackgroundViewController!
    var snapshotExpectation: XCTestExpectation!
    var firstTrigger = true

    override func setUp() {
        super.setUp()
        accentColor = .violet
        selfUser = MockUserType.createSelfUser(name: "")
        selfUser.accentColorValue = .violet
        
        firstTrigger = true
   }

    override func tearDown() {
        selfUser = nil
        sut = nil
        snapshotExpectation = nil

        super.tearDown()
    }

    func testThatItShowsUserWithoutImage() {
        // GIVEN
        snapshotExpectation = expectation(description: "snapshot verified")

        let userImageLoaded: Completion = {
            // WHEN & THEN
            self.verify(matching: self.sut)
            self.snapshotExpectation.fulfill()
        }

        sut = BackgroundViewController(user: selfUser, userSession: .none, userImageLoaded: userImageLoaded)

        waitForExpectations(timeout: 5)
    }

    func testThatItShowsUserWithImage() {
        // GIVEN
        snapshotExpectation = expectation(description: "snapshot verified")

        let userImageLoaded: Completion = {
            // WHEN
            ///TODO: hacks to make below line passes
            self.selfUser.accentColorValue = self.selfUser.accentColorValue

            // THEN
            self.verify(matching: self.sut)
            self.snapshotExpectation.fulfill()
        }

        selfUser.completeImageData = image(inTestBundleNamed: "unsplash_matterhorn.jpg").pngData()
        sut = BackgroundViewController(user: selfUser, userSession: .none, userImageLoaded: userImageLoaded)

        waitForExpectations(timeout: 5)
    }

    func testThatItUpdatesForUserAccentColorUpdate_fromAccentColor() {
        // GIVEN
        sut = BackgroundViewController(user: selfUser, userSession: .none)

        // WHEN
        selfUser.accentColorValue = .brightOrange
        sut.updateFor(user: selfUser, imageMediumDataChanged: false, accentColorValueChanged: true)

        // THEN
        verify(matching: sut)
    }

    func testThatItUpdatesForUserAccentColorUpdate_fromUserImageRemoved() {
        // GIVEN
        selfUser.completeImageData = image(inTestBundleNamed: "unsplash_matterhorn.jpg").pngData()
        sut = BackgroundViewController(user: selfUser, userSession: .none)
        // WHEN
        selfUser.completeImageData = nil
        selfUser.accentColorValue = .brightOrange
        sut.updateFor(user: selfUser, imageMediumDataChanged: true, accentColorValueChanged: true)
        // THEN
        verify(matching: sut)
    }

    func testThatItUpdatesForUserAccentColorUpdate_fromUserImage() {
        // GIVEN
        snapshotExpectation = expectation(description: "snapshot verified")

        selfUser.completeImageData = image(inTestBundleNamed: "unsplash_matterhorn.jpg").pngData()
        sut = BackgroundViewController(user: selfUser, userSession: .none, userImageLoaded: createIgnoreFirstTriggerVerifyClosure())

        // WHEN
        selfUser.accentColorValue = .brightOrange

        ///This triggers user image updating again, we skip the first snapshot triggered by sut init
        sut.updateFor(user: selfUser, imageMediumDataChanged: true, accentColorValueChanged: true)

        waitForExpectations(timeout: 10)
    }

    func testThatItUpdatesForUserImageUpdate_fromAccentColor() {
        // GIVEN
        snapshotExpectation = expectation(description: "snapshot verified")


        selfUser.completeImageData = nil
        sut = BackgroundViewController(user: selfUser, userSession: .none, userImageLoaded: createIgnoreFirstTriggerVerifyClosure())
        // WHEN
        selfUser.completeImageData = image(inTestBundleNamed: "unsplash_matterhorn.jpg").pngData()

        ///This triggers user image updating again, we skip the first snapshot triggered by sut init
        sut.updateFor(user: selfUser, imageMediumDataChanged: true, accentColorValueChanged: false)

        waitForExpectations(timeout: 10)
    }

    func testThatItUpdatesForUserImageUpdate_fromUserImage() {
        // GIVEN
        snapshotExpectation = expectation(description: "snapshot verified")

        selfUser.completeImageData = image(inTestBundleNamed: "unsplash_matterhorn.jpg").pngData()
        sut = BackgroundViewController(user: selfUser, userSession: .none, userImageLoaded: createIgnoreFirstTriggerVerifyClosure())
        // WHEN
        selfUser.completeImageData = image(inTestBundleNamed: "unsplash_burger.jpg").pngData()
        sut.updateFor(user: selfUser, imageMediumDataChanged: true, accentColorValueChanged: false)

        waitForExpectations(timeout: 10)
    }
    
    private func createIgnoreFirstTriggerVerifyClosure(file: StaticString = #file,
                                                       testName: String = #function,
                                                       line: UInt = #line) -> Completion {
        let userImageLoaded: Completion = {
            if self.firstTrigger {
                self.firstTrigger = false
                return
            }
            
            // THEN
            self.verify(matching: self.sut, file: file, testName: testName, line: line)
            self.snapshotExpectation.fulfill()
        }
        
        return userImageLoaded
    }
}
