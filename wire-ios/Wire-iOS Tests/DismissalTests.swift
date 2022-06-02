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

final class DismissalTests: XCTestCase {

    var sut: UIViewController!

    override func setUp() {
        super.setUp()
        sut = UIViewController()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Detection

    func testThatItAllowsDismissalForViewController() {
        // GIVEN

        // WHEN
        presentViewController(sut)

        // THEN
        XCTAssertTrue(sut.canBeDismissed)
    }

    func testThatItDoesNotAllowDismissalForUnpresentedViewController() {
        // GIVEN

        // THEN
        XCTAssertFalse(sut.canBeDismissed)
    }

    func testThatItDoesNotAllowDismissalForDismissedViewController() {
        // GIVEN
        let dismissalExpectation = expectation(description: "SUT is dismissed")

        presentViewController(sut) {
            // WHEN
            self.dismissViewController(self.sut) {

                // THEN
                XCTAssertFalse(self.sut.canBeDismissed)
                dismissalExpectation.fulfill()
            }
        }

        waitForExpectations(timeout: 2, handler: nil)
    }

    func testThatItAllowsDismissalForControllerInNavigationController() {
        // GIVEN
        let navigationController = UINavigationController(rootViewController: sut)

        // WHEN
        presentViewController(navigationController)

        // THEN
        XCTAssertTrue(sut.canBeDismissed)
        XCTAssertTrue(navigationController.canBeDismissed)
    }

    func testThatItDoesAllowDismissalForNavigationControllerAfterChildDismissed() {
        // GIVEN
        let navigationController = UINavigationController(rootViewController: sut)

        // WHEN
        let dismissalExpectation = expectation(description: "SUT is dismissed")
        presentViewController(navigationController) {
            self.dismissViewController(self.sut) {
                // THEN
                XCTAssertFalse(self.sut.canBeDismissed)
                XCTAssertFalse(navigationController.canBeDismissed)
                dismissalExpectation.fulfill()
            }
        }

        waitForExpectations(timeout: 2, handler: nil)
    }

    // MARK: - Dismissal

    func testThatItCallsHandlerAfterDismissing() {
        // GIVEN
        presentViewController(sut)

        // WHEN
        let dismissalExpectation = expectation(description: "The handler is called.")

        sut.dismissIfNeeded(animated: false) {
            dismissalExpectation.fulfill()
        }

        // THEN
        waitForExpectations(timeout: 2, handler: nil)
    }

    func testThatItCallsHandlerForAlreadyDismissedViewController() {
        // GIVEN
        presentViewController(sut)
        dismissViewController(sut)

        // WHEN
        let dismissalExpectation = expectation(description: "The handler is called.")

        sut.dismissIfNeeded(animated: false) {
            dismissalExpectation.fulfill()
        }

        // THEN
        waitForExpectations(timeout: 2, handler: nil)
    }

}
