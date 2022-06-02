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

import XCTest

class AvailabilityTests: IntegrationTest {

    override func setUp() {
        super.setUp()

        createSelfUserAndConversation()
        createExtraUsersAndConversations()
    }

    func remotelyInsertTeam(members: [MockUser], isBound: Bool = true) -> MockTeam {
        var mockTeam: MockTeam!
        mockTransportSession.performRemoteChanges { (session) in
            mockTeam = session.insertTeam(withName: "Super-Team", isBound: isBound, users: Set(members))
            mockTeam.creator = members.first
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        return mockTeam
    }

    override func tearDown() {
        super.tearDown()
    }

    func testThatAvailabilityIsBroadcastedWhenChanged() {
        // given
        XCTAssertTrue(login())
        mockTransportSession.resetReceivedRequests()
        let selfUser = ZMUser.selfUser(inUserSession: self.userSession!)
        let client1 = user1.clients.anyObject() as! MockUserClient
        let client2 = user2.clients.anyObject() as! MockUserClient

        // when
        userSession?.perform {
            selfUser.availability = .busy
        }
        XCTAssertTrue(selfUser.modifiedKeys!.contains(AvailabilityKey))
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        let expectedRequests = ["/broadcast/otr/messages",                                      // attempt broadcast status (server responds with missing clients)
                                "/users/prekeys",                                               // establish sessions with missing clients
                                "/users/\(user1.identifier)/clients/\(client1.identifier!)",    // fetch client details
                                "/users/\(user2.identifier)/clients/\(client2.identifier!)",    // fetch client details
                                "/broadcast/otr/messages"]                                      // broadcast status

        XCTAssertNil(selfUser.modifiedKeys)
        XCTAssertEqual(expectedRequests.count, mockTransportSession.receivedRequests().count)
        XCTAssertEqual(Set(expectedRequests), Set(mockTransportSession.receivedRequests().map({ $0.path })))
    }

    func testThatAvailabilityIsBroadcastedToAllConnectedUsersAndTeamMembers() {
        // given
        _ = remotelyInsertTeam(members: [self.selfUser, self.user3, self.user4])

        XCTAssertTrue(login())
        mockTransportSession.resetReceivedRequests()
        let selfUser = ZMUser.selfUser(inUserSession: self.userSession!)

        // when
        userSession?.perform {
            selfUser.availability = .away
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        let request = mockTransportSession.receivedRequests().last!
        guard let data = request.binaryData, let message = try? Proteus_NewOtrMessage(serializedData: data) else { return XCTFail() }
        let connectedAndTeamMemberUUIDs = [user1, user2, user3, user4].compactMap { user(for: $0)?.remoteIdentifier }
        let recipientsUUIDs = message.recipients.compactMap({ UUID(data: $0.user.uuid) })

        XCTAssertEqual(Set(connectedAndTeamMemberUUIDs), Set(recipientsUUIDs))
    }

}
