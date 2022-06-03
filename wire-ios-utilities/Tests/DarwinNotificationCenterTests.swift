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
import WireUtilities

class DarwinNotificationCenterTests: XCTestCase {
    
    func testThatItInvokesHandlers() {
        // given
        let sut = DarwinNotificationCenter.shared
        let firstHandler = expectation(description: "first handler called")
        let secondHandler = expectation(description: "second handler called")
        
        sut.observe(notification: .shareExtDidSaveNote) { firstHandler.fulfill() }
        sut.observe(notification: .shareExtDidSaveNote) { secondHandler.fulfill() }
        
        // when
        DarwinNotification.shareExtDidSaveNote.post()
        
        // then
        wait(for: [firstHandler, secondHandler], timeout: 0.5)
    }
}
