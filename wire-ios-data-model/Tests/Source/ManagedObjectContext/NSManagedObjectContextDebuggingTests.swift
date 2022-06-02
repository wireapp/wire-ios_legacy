//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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

class NSManagedObjectContextDebuggingTests: ZMBaseManagedObjectTest {

    func testThatItInvokesCallbackWhenFailedToSave() {

        // GIVEN
        self.makeChangeThatWillCauseRollback()
        let expectation = self.expectation(description: "callback invoked")
        self.uiMOC.errorOnSaveCallback = { (moc, error) in
            XCTAssertEqual(moc, self.uiMOC)
            XCTAssertNotNil(error)
            expectation.fulfill()
        }

        // WHEN
        self.performIgnoringZMLogError {
            self.uiMOC.saveOrRollback()
        }

        // THEN
        XCTAssertTrue(self.waitForCustomExpectations(withTimeout: 0.5))
    }
}

// MARK: - Helper

private let longString = (0..<50).reduce("") { (prev, _) -> String in
    return prev + "AaAaAaAaAa"
}

extension NSManagedObjectContextDebuggingTests {

    func makeChangeThatWillCauseRollback() {
        let user = ZMUser.selfUser(in: self.uiMOC)
        // this user name is too long and will fail validation
        user.name = longString
    }
}
