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

class MockTransportSessionObjectCreationTests : MockTransportSessionTests {
    
    func testThatItDoesNotReturnNonExistingUserWithIdentifier() {
        
        // GIVEN
        self.sut.performRemoteChanges { (session) in
            session.insertUser(withName: "Foo")
        }
        
        // WHEN
        self.sut.performRemoteChanges { (session) in
            let user = session.user(withRemoteIdentifier: "nonvalididentifier")
            
            // THEN
            XCTAssertNil(user)
        }
    }
    
    func testThatItReturnsTheExistingUserWithIdentifier() {
        
        // GIVEN
        var identifier: String!
        self.sut.performRemoteChanges { (session) in
            let user = session.insertUser(withName: "Foo")
            identifier = user.identifier
        }
        
        // WHEN
        self.sut.performRemoteChanges { (session) in
            let user = session.user(withRemoteIdentifier: identifier)
            
            // THEN
            XCTAssertNotNil(user)
            XCTAssertEqual(user?.identifier, identifier)
        }
    }
    
    func testThatItDoesNotReturnNonExistingClientWithIdentifier() {
        
        // GIVEN
        var user: MockUser!
        self.sut.performRemoteChanges { (session) in
            user = session.insertUser(withName: "Foo")
            session.registerClient(for: user, label: "iPhone 89", type: "permanent", deviceClass: "phone")
        }
        
        // WHEN
        self.sut.performRemoteChanges { (session) in
            let client = session.client(for: user, remoteIdentifier: "invalid")
            
            // THEN
            XCTAssertNil(client)
        }
    }
    
    func testThatItReturnsTheExistingClientWithIdentifier() {
        
        // GIVEN
        var user: MockUser!
        var identifier: String!
        self.sut.performRemoteChanges { (session) in
            user = session.insertUser(withName: "Foo")
            let client = session.registerClient(for: user, label: "iPhone 89", type: "permanent", deviceClass: "phone")
            identifier = client.identifier
        }
        
        // WHEN
        self.sut.performRemoteChanges { (session) in
            let client = session.client(for: user, remoteIdentifier: identifier)
            
            // THEN
            XCTAssertNotNil(client)
            XCTAssertEqual(client?.identifier, identifier)
            XCTAssertEqual(client?.user, user)
        }
    }
    
}
