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
@testable import WireTransport

@objc class NotificationObserver : NSObject, RequestAvailableObserver {
    
    var requestsAvailable = false
    
    func newRequestsAvailable() {
        requestsAvailable = true
    }
    
}

class RequestAvailableNotificationTests: XCTestCase {
    
    var sut = NotificationObserver()
    
    override func setUp() {
        super.setUp()
        
        sut = NotificationObserver()
    }
    
    override func tearDown() {
        RequestAvailableNotification.removeObserver(sut)
        
        super.tearDown()
    }
    
    func testObserverIsReceivingNotificationsAfterSubscribing() {
        
        // given
        RequestAvailableNotification.addObserver(sut)
        
        // when
        RequestAvailableNotification.notifyNewRequestsAvailable(self)
        
        // then 
        XCTAssertTrue(sut.requestsAvailable)
    }
    
    func testObserverIsNotReceivingNotificationsAfterUnsubscribing() {
        
        // given
        RequestAvailableNotification.addObserver(sut)
        RequestAvailableNotification.removeObserver(sut)
        
        // when
        RequestAvailableNotification.notifyNewRequestsAvailable(self)
        
        // then
        XCTAssertFalse(sut.requestsAvailable)
    }
    
}
