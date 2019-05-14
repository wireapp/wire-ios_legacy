//
// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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

final class RequestPasswordViewControllerSnapshotTests: ZMSnapshotTestCase {
    
    var sut: RequestPasswordViewController!
    let callback = { (result: Result<String>) -> () in}
    
    override func setUp() {
        super.setUp()


        /// TODO: remove this after snapshot is created
        recordMode = true
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testForRemoveDeviceContext(){
        sut = RequestPasswordViewController.requestPasswordController(context: .removeDevice, callback: callback)

        verifyAlertController(sut)
    }

    func testForLegalHoldContext() {
        let fingerprint = mockUserClient(fingerprintString: "102030405060708090a0b0c0d0e0f0708090102030405060708090").fingerprint!

        sut = RequestPasswordViewController.requestPasswordController(context: .legalHold(fingerprint: fingerprint), callback: callback)

        verifyAlertController(sut)
    }
}
