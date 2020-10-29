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
    
    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }
    
    func testThatDeepLinkIsNotOpened_WhenDeepLinkIsNotValid() {
        // GIVEN
        let invalidDeppLinkUrl = URL(string:"wire://invalidDeppLinkUrl")!
        let router =  TestableURLActionRouter(viewController: RootViewController(), url: invalidDeppLinkUrl)
        
        // WHEN
        router.openDeepLink(needsAuthentication: false)
        
        // THEN
        XCTAssertFalse(router.hasBeenDeepLinkOpened)
    }
    
    func testThatDeepLinkIsOpened_WhenDeepLinkIsValid() {
        // GIVEN
        let validDeepLink = URL(string:"wire://start-sso/wire-5977c2d2-aa60-4657-bad8-4e4ed08e483a")!
        let router =  TestableURLActionRouter(viewController: RootViewController(), url: validDeepLink)
        
        // WHEN
        router.openDeepLink()
        
        // THEN
        XCTAssertTrue(router.hasBeenDeepLinkOpened)
    }
    
    func testThatDeepLinkIsNotOpened_WhenDeepLinkIsValidAndNeedsAuthentication() {
        // GIVEN
        let validDeepLink = URL(string:"wire://user/user_id")!
        let router =  TestableURLActionRouter(viewController: RootViewController(), url: validDeepLink)
        
        // WHEN
        router.openDeepLink(needsAuthentication: true)
        
        // THEN
        XCTAssertFalse(router.hasBeenDeepLinkOpened)
    }
}

class TestableURLActionRouter: URLActionRouter {
    var hasBeenDeepLinkOpened = false
    override func open(url: URL) -> Bool {
        hasBeenDeepLinkOpened = true
        return hasBeenDeepLinkOpened
    }
}
