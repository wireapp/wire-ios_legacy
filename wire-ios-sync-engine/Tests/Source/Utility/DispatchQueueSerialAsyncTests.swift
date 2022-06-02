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
import XCTest

class DispatchQueueSerialAsyncTests: XCTestCase {
    let sut = DispatchQueue(label: "test")

    func testThatItWaitsForOneTaskBeforeAnother() {
        let doneExpectation = self.expectation(description: "Done with jobs")

        var done1: Bool = false
        var done2: Bool = false

        sut.serialAsync { finally in
            let time = DispatchTime.now() + DispatchTimeInterval.milliseconds(200)

            DispatchQueue.global(qos: .background).asyncAfter(deadline: time) {
                XCTAssertFalse(done1)
                XCTAssertFalse(done2)
                done1 = true
                finally()
            }
        }

        sut.serialAsync { finally in
            XCTAssertTrue(done1)
            XCTAssertFalse(done2)
            done2 = true
            finally()
            doneExpectation.fulfill()
        }

        self.waitForExpectations(timeout: 0.5) { error in
            XCTAssertNil(error)
        }

        XCTAssertTrue(done1)
        XCTAssertTrue(done2)
    }
}
