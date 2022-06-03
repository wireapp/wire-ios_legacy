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


import XCTest

class ZMTExpectationTests: ZMTBaseTest {

    let notificationName = "ZMTFooBar"
    
    func testNotificationExpectationNotSent() {
        
        var handlerIsCalled = false;
        self.expectation(forNotification: NSNotification.Name(rawValue: notificationName), object: nil, handler: {
            _ in handlerIsCalled = true;
            return true;
        })
        
        let receivedBeforeSending = self.waitForCustomExpectations(withTimeout: 0.01)
        XCTAssertFalse(receivedBeforeSending);
        XCTAssertFalse(handlerIsCalled);
    }
    
    func testNotificationExpectationSent() {
        
        var handlerIsCalled = false;
        self.expectation(forNotification: NSNotification.Name(rawValue: notificationName), object: nil, handler: {
            _ in handlerIsCalled = true;
            return true;
        })
        
        NotificationCenter.default.post(name: Notification.Name(rawValue: notificationName), object: nil)
        XCTAssertTrue(handlerIsCalled);
        
        let receivedAfterSending = self.waitForCustomExpectations(withTimeout: 0.2)
        XCTAssertTrue(receivedAfterSending)
        
    }
    
}
