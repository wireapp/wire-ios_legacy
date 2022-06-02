//
// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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

final class URLActionRouterTests: XCTestCase {

    // MARK: Presenting Alerts

    func testThatAlertIsPresented_WhenCanDisplayAlertsReturnsTrue() {
        // GIVEN
        let alert = UIAlertController.alertWithOKButton(message: "Hello World")
        let viewController = RootViewController()
        let delegate = MockURLActionRouterDelegate()
        let router = TestableURLActionRouter(viewController: viewController)
        router.delegate = delegate

        // WHEN
        router.presentAlert(alert)

        // THEN
        XCTAssertEqual(router.presentedAlert, alert)
    }

    func testThatAlertIsNotPresented_WhenCanDisplayAlertsReturnsFalse() {
        // GIVEN
        let alert = UIAlertController.alertWithOKButton(message: "Hello World")
        let viewController = RootViewController()
        let delegate = MockURLActionRouterDelegate()
        delegate.canDisplayAlerts = false
        let router = TestableURLActionRouter(viewController: viewController)
        router.delegate = delegate

        // WHEN
        router.presentAlert(alert)

        // THEN
        XCTAssertEqual(router.presentedAlert, nil)
    }

    func testThatPendingAlertIsPresented_WhenPerformPendingActionsIsCalled() {
        // GIVEN
        let alert = UIAlertController.alertWithOKButton(message: "Hello World")
        let viewController = RootViewController()
        let delegate = MockURLActionRouterDelegate()
        delegate.canDisplayAlerts = false
        let router = TestableURLActionRouter(viewController: viewController)
        router.delegate = delegate
        router.presentAlert(alert)

        // WHEN
        delegate.canDisplayAlerts = true
        router.performPendingActions()

        // THEN
        XCTAssertEqual(router.presentedAlert, alert)
    }

    // MARK: Navigation

    func testThatNavigationPerformed_WhenAuthenticatedRouterIsAvailable() {
        // GIVEN
        let authenticatedRouter = MockAuthenticatedRouter()
        let router = TestableURLActionRouter(viewController: RootViewController())
        router.authenticatedRouter = authenticatedRouter

        // WHEN
        router.navigate(to: .conversationList)

        // THEN
        guard case .conversationList = authenticatedRouter.didNavigateToDestination else {
            return XCTFail("Failed to perform navigation")
        }
    }

    func testThatNavigationPerformed_WhenAuthenticatedRouterBecomesAvailable() {
        // GIVEN
        let authenticatedRouter = MockAuthenticatedRouter()
        let router = TestableURLActionRouter(viewController: RootViewController())
        router.navigate(to: .conversationList)

        // WHEN
        router.authenticatedRouter = authenticatedRouter
        router.performPendingActions()

        // THEN
        guard case .conversationList = authenticatedRouter.didNavigateToDestination else {
            return XCTFail("Failed to perform navigation")
        }
    }
}

class MockAuthenticatedRouter: AuthenticatedRouterProtocol {

    func updateActiveCallPresentationState() { }

    func minimizeCallOverlay(animated: Bool, withCompletion completion: Completion?) { }

    var didNavigateToDestination: NavigationDestination?
    func navigate(to destination: NavigationDestination) {
        didNavigateToDestination = destination
    }

}

class MockURLActionRouterDelegate: URLActionRouterDelegate {

    var didCallWillShowCompanyLoginError: Bool = false
    func urlActionRouterWillShowCompanyLoginError() {
        didCallWillShowCompanyLoginError = true
    }

    var canDisplayAlerts: Bool = true
    func urlActionRouterCanDisplayAlerts() -> Bool {
        return canDisplayAlerts
    }

}

class TestableURLActionRouter: URLActionRouter {

    var presentedAlert: UIAlertController?
    override func internalPresentAlert(_ alert: UIAlertController) {
        presentedAlert = alert
    }
}
