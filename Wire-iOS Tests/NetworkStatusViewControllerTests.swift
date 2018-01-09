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

final class NetworkStatusViewControllerTests: XCTestCase {

    weak var sut: NetworkStatusViewController!

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testNetworkStatusViewControllerIsNotRetainedAfterTimerIsScheduled(){
        autoreleasepool{
            // GIVEN
            var networkStatusViewController: NetworkStatusViewController! = NetworkStatusViewController()
            sut = networkStatusViewController


            // WHEN
            networkStatusViewController.viewDidLoad()
            networkStatusViewController.didChangeAvailability(newState: .offline)
            networkStatusViewController.applyPendingState()
            
            let _ = networkStatusViewController.notifyWhenOffline()
            networkStatusViewController = nil
        }

        // THEN
        XCTAssertNil(sut)
    }
}

