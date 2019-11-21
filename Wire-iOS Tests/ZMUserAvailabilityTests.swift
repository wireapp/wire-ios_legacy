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

class ZMUserAvailabilityTests: XCTestCase {
    var sut: ZMUser!
    var selfUser: ZMUser!
    var team1: Team!
    var team2: Team!
    var fixture: CoreDataFixture!

    override func setUp() {
        super.setUp()
        fixture = CoreDataFixture()
        selfUser = ZMUser.selfUser(in: fixture.uiMOC)
        sut = ZMUser.insertNewObject(in: fixture.uiMOC)
        team1 = Team.insertNewObject(in: fixture.uiMOC)
        team1.remoteIdentifier = UUID()
        team2 = Team.insertNewObject(in: fixture.uiMOC)
        team2.remoteIdentifier = UUID()
    }
    
    override func tearDown() {
        selfUser = nil
        sut = nil
        team1 = nil
        team2 = nil
        fixture = nil
        super.tearDown()
    }
    
    func testThatItShouldHideAvailabilityIfLimitIsReachedAndOtherUserIsTeammate() {
        // given
        for _ in 1...(Team.membersOptimalLimit - 2) { // Saving two users for later
            team1.members.insert(Member.insertNewObject(in: fixture.uiMOC))
        }
        let member = Member.insertNewObject(in: fixture.uiMOC)
        member.user = sut
        member.team = team1
        
        let selfMember = Member.insertNewObject(in: fixture.uiMOC)
        selfMember.user = selfUser
        selfMember.team = team1
        
        // then
        XCTAssertTrue(sut.shouldHideAvailability)
    }
    
    func testThatItShouldntHideAvailabilityIfLimitIsReachedAndOtherUserIsntTeammate() {
        // given
        for _ in 1...(Team.membersOptimalLimit - 1) { // Saving one user for later
            team1.members.insert(Member.insertNewObject(in: fixture.uiMOC))
        }
        let member = Member.insertNewObject(in: fixture.uiMOC)
        member.user = sut
        member.team = team2
        
        let selfMember = Member.insertNewObject(in: fixture.uiMOC)
        selfMember.user = selfUser
        selfMember.team = team1

        // then
        XCTAssertFalse(sut.shouldHideAvailability)
    }
    
    func testThatItShouldntHideAvailabilityIfLimitIsntReached() {
        // given
        for _ in 1...(Team.membersOptimalLimit - 3) { // Saving two users for later + going under limit
            team1.members.insert(Member.insertNewObject(in: fixture.uiMOC))
        }
        let member = Member.insertNewObject(in: fixture.uiMOC)
        member.user = sut
        member.team = team1
        
        let selfMember = Member.insertNewObject(in: fixture.uiMOC)
        selfMember.user = selfUser
        selfMember.team = team1
        
        // then
        XCTAssertFalse(sut.shouldHideAvailability)
    }
    
    func testThatItShouldntHideAvailabilityIfSelfUser() {
        // given
        for _ in 1...(Team.membersOptimalLimit - 1) { // Saving two users for later
            team1.members.insert(Member.insertNewObject(in: fixture.uiMOC))
        }
        
        let selfMember = Member.insertNewObject(in: fixture.uiMOC)
        selfMember.user = selfUser
        selfMember.team = team1
        
        // then
        XCTAssertFalse(selfUser.shouldHideAvailability)
    }
}
