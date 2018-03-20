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

import Foundation
import XCTest
@testable import Wire

class NetworkStatusViewTests: XCTestCase {
    var sut: NetworkStatusView!
    var mockApplication: MockApplication!

    override func setUp() {
        super.setUp()
        mockApplication = MockApplication()
        sut = NetworkStatusView(application: mockApplication)
    }

    override func tearDown() {
        sut = nil
        mockApplication = nil
        super.tearDown()
    }

    func testThatSyncBarChangesToHiddenWhenTheAppGoesToBackground() {
        // GIVEN
        mockApplication.applicationState = .active
        sut.state = .onlineSynchronizing
        XCTAssertEqual(sut.connectingViewHeight?.constant, CGFloat.OfflineBar.collapsedHeight)

        // WHEN
        mockApplication.applicationState = .background
        sut.state = .onlineSynchronizing

        // THEN
        XCTAssertEqual(sut.connectingViewHeight?.constant, 0)
    }
}

class NetworkStatusViewSnapShotTests: ZMSnapshotTestCase {

    var sut: NetworkStatusView!

    override func setUp() {
        super.setUp()
        accentColor = .violet
        sut = NetworkStatusView()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testOfflineExpandedState() {
        // GIVEN
        sut.state = .offlineExpanded
        // WHEN && THEN
        verifyInAllPhoneWidths(view: sut)
    }

    func testOnlineSynchronizing() {
        // GIVEN
        sut.state = .onlineSynchronizing
        sut.layer.speed = 0 // freeze animations for deterministic tests
        // WHEN && THEN
        verifyInAllPhoneWidths(view: sut)
    }

}
