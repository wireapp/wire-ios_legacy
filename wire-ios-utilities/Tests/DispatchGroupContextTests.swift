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

import WireTesting
@testable import WireUtilities

class DispatchGroupContextTests: ZMTBaseTest {
    
    var sut : DispatchGroupContext!
        
    override func tearDown() {
        sut = nil
        
        super.tearDown()
    }
    
    func testInjectGroupsAreAdded() {
        // given
        let group = ZMSDispatchGroup(label: "group1")!
        sut = DispatchGroupContext(groups: [group])
        
        // then
        XCTAssertEqual(sut.groups, [group])
    }
    
    func testGroupsCanBeAdded() {
        // given
        let group = ZMSDispatchGroup(label: "group1")!
        sut = DispatchGroupContext(groups: [])
        
        // when
        sut.add(group)
        
        // then
        XCTAssertEqual(sut.groups, [group])
    }
    
    func testGroupsCanBeEntered() {
        // given
        let group = ZMSDispatchGroup(label: "group1")!
        sut = DispatchGroupContext(groups: [group])
        
        // when
        let enteredGroups = sut.enterAll()
        
        // then
        XCTAssertEqual(enteredGroups, [group])
    }
    
    func testGroupsCanBeEnteredExcludingOne() {
        // given
        let group1 = ZMSDispatchGroup(label: "group1")!
        let group2 = ZMSDispatchGroup(label: "group2")!
        sut = DispatchGroupContext(groups: [group1, group2])
        
        // when
        let enteredGroups = sut.enterAll(except: group1)
        
        // then
        XCTAssertEqual(enteredGroups, [group2])
    }
    
    func testGroupsCanBeLeft() {
        // given
        let groupIsEmpty = expectation(description: "group did become empty")
        let group = ZMSDispatchGroup(label: "group1")!
        sut = DispatchGroupContext(groups: [group])
        let enteredGroups = sut.enterAll()
        
        // expect
        enteredGroups.first?.notify(on: DispatchQueue.main, block: {
            groupIsEmpty.fulfill()
        })
        
        // when
        sut.leaveAll()
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
    }
    
    func testSelectedGroupsCanBeLeft() {
        // given
        let group1IsEmpty = expectation(description: "group1 did become empty")
        let group2IsEmpty = expectation(description: "group2 did become empty")
        let group1 = ZMSDispatchGroup(label: "group1")!
        let group2 = ZMSDispatchGroup(label: "group2")!
        sut = DispatchGroupContext(groups: [group1, group2])
        let enteredGroups = sut.enterAll()

        // expect
        enteredGroups.first?.notify(on: DispatchQueue.main, block: {
            group1IsEmpty.fulfill()
        })
        
        enteredGroups.last?.notify(on: DispatchQueue.main, block: {
            group2IsEmpty.fulfill()
        })
        
        // when
        sut.leave([group1])
        sut.leave([group2])
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
    }
    
}
