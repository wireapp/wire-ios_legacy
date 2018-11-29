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
import UIKit
@testable import Wire

class DismissalTests: ZMSnapshotTestCase {

    var viewController: UIViewController!

    // MARK: - Detection

    func testThatItAllowsDismissalForViewController() {
        // GIVEN
        let viewController = UIViewController()

        // WHEN
        presentViewController(viewController)

        // THEN
        XCTAssertTrue(viewController.canBeDismissed)
    }

    func testThatItDoesNotAllowDismissalForUnpresentedViewController() {
        // GIVEN
        let viewController = UIViewController()

        // THEN
        XCTAssertFalse(viewController.canBeDismissed)
    }

    func testThatItDoesNotAllowDismissalForDismissedViewController() {
        // GIVEN
        let viewController = UIViewController()
        presentViewController(viewController)

        // WHEN
        dismissViewController(viewController)

        // THEN
        XCTAssertFalse(viewController.canBeDismissed)
    }

    func testThatItAllowsDismissalForControllerInNavigationController() {
        // GIVEN
        let viewController = UIViewController()
        let navigationController = UINavigationController(rootViewController: viewController)

        // WHEN
        presentViewController(navigationController)

        // THEN
        XCTAssertTrue(viewController.canBeDismissed)
        XCTAssertTrue(navigationController.canBeDismissed)
    }

    func testThatItDoesAllowDismissalForNavigationControllerAfterChildDismissed() {
        // GIVEN
        let viewController = UIViewController()
        let navigationController = UINavigationController(rootViewController: viewController)

        // WHEN
        presentViewController(navigationController)
        dismissViewController(viewController)

        // THEN
        XCTAssertFalse(viewController.canBeDismissed)
        XCTAssertFalse(navigationController.canBeDismissed)
    }

    // MARK: - Dismissal

    func testThatItCallsHandlerAfterDismissing() {
        // GIVEN
        let viewController = UIViewController()
        presentViewController(viewController)

        // WHEN
        let dismissalExpectation = expectation(description: "The handler is called.")

        viewController.dismissIfNeeded(animated: false) {
            dismissalExpectation.fulfill()
        }

        // THEN
        waitForExpectations(timeout: 2, handler: nil)
    }

    func testThatItCallsHandlerForAlreadyDismissedViewController() {
        // GIVEN
        let viewController = UIViewController()
        presentViewController(viewController)
        dismissViewController(viewController)

        // WHEN
        let dismissalExpectation = expectation(description: "The handler is called.")

        viewController.dismissIfNeeded(animated: false) {
            dismissalExpectation.fulfill()
        }

        // THEN
        waitForExpectations(timeout: 2, handler: nil)
    }

}
