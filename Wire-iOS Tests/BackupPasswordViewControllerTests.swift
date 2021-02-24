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

import Foundation
import XCTest
@testable import Wire

class BackupPasswordViewControllerTests: ZMSnapshotTestCase {
    
    func testDefaultState() {
        // GIVEN
        let sut = BackupPasswordViewController { (_, _) in }
        // WHEN & THEN
        self.verifyInIPhoneSize(view: sut.view)
    }
    
    func testThatItCallsTheCallback() {
        // GIVEN
        
        let validPassword = "Password123!"
        let expectation = self.expectation(description: "Callback called")
        let sut = BackupPasswordViewController { (_, password) in
            XCTAssertEqual(password!.value, validPassword)
            expectation.fulfill()
        }
        // WHEN
        XCTAssertTrue(sut.textField(UITextField(), shouldChangeCharactersIn: NSMakeRange(0, 0), replacementString: validPassword))
        XCTAssertFalse(sut.textField(UITextField(), shouldChangeCharactersIn: NSMakeRange(0, 0), replacementString: "\n"))
        // THEN
        self.waitForExpectations(timeout: 0.5) { error in
            XCTAssertNil(error)
        }
    }
    
    func testThatWhitespacesPasswordIsNotGood() {
        // GIVEN
        let sut = BackupPasswordViewController { (_, password) in
            XCTFail()
        }
        // WHEN
        XCTAssertFalse(sut.textField(UITextField(), shouldChangeCharactersIn: NSMakeRange(0, 0), replacementString: "              "))
        XCTAssertFalse(sut.textField(UITextField(), shouldChangeCharactersIn: NSMakeRange(0, 0), replacementString: "\n"))
    }
}

