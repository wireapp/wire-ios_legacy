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

    func testThatDeepLinkIsNotOpened_WhenDeepLinkIsNotValid() {
        // GIVEN
        let invalidDeepLinkUrl = URL(string: "wire://invalidDeepLinkUrl")!
        let router =  TestableURLActionRouter(viewController: RootViewController())
        router.testHelper_setUrl(invalidDeepLinkUrl)

        // WHEN
        router.openDeepLink(for: .authenticated(completedRegistration: true))

        // THEN
        XCTAssertFalse(router.wasDeepLinkOpened)
    }

    func testThatDeepLinkIsOpened_WhenDeepLinkIsValidAndAppStateValid() {
        // GIVEN
        let validDeepLink = URL(string: "wire://start-sso/wire-5977c2d2-aa60-4657-bad8-4e4ed08e483a")!
        let router =  TestableURLActionRouter(viewController: RootViewController())
        router.testHelper_setUrl(validDeepLink)

        // WHEN
        router.openDeepLink(for: .authenticated(completedRegistration: true))

        // THEN
        XCTAssertTrue(router.wasDeepLinkOpened)
    }

    func testThatDeepLinkIsNotOpened_WhenDeepLinkIsValidAndAppStateInvalid() {
        // GIVEN
        let validDeepLink = URL(string: "wire://start-sso/wire-5977c2d2-aa60-4657-bad8-4e4ed08e483a")!
        let router =  TestableURLActionRouter(viewController: RootViewController())
        router.testHelper_setUrl(validDeepLink)

        // WHEN
        router.openDeepLink(for: .migrating)

        // THEN
        XCTAssertFalse(router.wasDeepLinkOpened)
    }
}

class TestableURLActionRouter: URLActionRouter {
    var wasDeepLinkOpened = false
    override func open(url: URL) -> Bool {
        wasDeepLinkOpened = true
        return wasDeepLinkOpened
    }
}
