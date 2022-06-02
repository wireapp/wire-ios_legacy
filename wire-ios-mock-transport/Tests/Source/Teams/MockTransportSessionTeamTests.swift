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
@testable import WireMockTransport

// MARK: - Teams
class MockTransportSessionTeamTests : MockTransportSessionTests {
    
    func checkThat(response: ZMTransportResponse?, contains teams: [MockTeam], hasMore: Bool = false, file: StaticString = #file, line: UInt = #line) {
        
        XCTAssertNotNil(response, "Response should not be empty", file: file, line: line)
        XCTAssertEqual(response?.httpStatus, 200, "Http status should be 200", file: file, line: line)
        XCTAssertNotNil(response?.payload, "Response should have payload", file: file, line: line)
        
        // Then
        let payload = response?.payload?.asDictionary() as? [String : Any]
        guard let payloadTeams = payload?["teams"] as? [[String : Any]] else {
            XCTFail("Response payload should have teams array", file: file, line: line)
            return
        }
        guard let receivedHasMore = payload?["has_more"] as? Bool else {
            XCTFail("Response payload should have 'has_more' flag")
            return
        }
        
        XCTAssertEqual(receivedHasMore, hasMore, "has_more should be \(hasMore)")

        XCTAssertEqual(payloadTeams.count, teams.count, "Response should have \(teams.count) teams", file: file, line: line)
        
        let receivedTeamIdentifiers = payloadTeams.compactMap { $0["id"] as? String }
        let expectedTeamIdentifiers = teams.map { $0.identifier }
        
        for expectedId in expectedTeamIdentifiers {
            XCTAssertTrue(receivedTeamIdentifiers.contains(expectedId), "Payload should contain team with identifier '\(expectedId)'", file: file, line: line)
        }
        
        let extraTeams = Set(receivedTeamIdentifiers).subtracting(expectedTeamIdentifiers)
        for extraTeam in extraTeams {
            XCTFail("Payload should not contain team with identifier '\(extraTeam)'", file: file, line: line)
        }
    }
    
    func testThatItInsertsTeam() {
        // Given
        let name1 = "foo"
        let name2 = "bar"

        var team1: MockTeam!
        var team2: MockTeam!

        // When
        sut.performRemoteChanges { session in
            team1 = session.insertTeam(withName: name1, isBound: true)
            team2 = session.insertTeam(withName: name2, isBound: false)
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // Then
        XCTAssertEqual(team1.name, name1)
        XCTAssertNotNil(team1.identifier)
        XCTAssertEqual(team2.name, name2)
        XCTAssertNotNil(team2.identifier)
        XCTAssertNotEqual(team1.identifier, team2.identifier)
    }
    
    func testThatItCreatesTeamPayload() {
        // Given
        var team: MockTeam!
        var creator: MockUser!
        
        sut.performRemoteChanges { session in
            let selfUser = session.insertSelfUser(withName: "Am I")
            team = session.insertTeam(withName: "name", isBound: false, users: [selfUser])
            team.pictureAssetKey = "1234-abc"
            team.pictureAssetId = "123-1234-abc"
            creator = session.insertUser(withName: "creator")
            team.creator = creator
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // When
        let payload = team.payload.asDictionary() as? [String : Any?]

        // Then
        XCTAssertEqual(payload?["id"] as? String, team.identifier)
        XCTAssertEqual(payload?["creator"] as? String, creator.identifier)
        XCTAssertEqual(payload?["name"] as? String, team.name)
        XCTAssertEqual(payload?["icon_key"] as? String, team.pictureAssetKey)
        XCTAssertEqual(payload?["icon"] as? String, team.pictureAssetId)
        XCTAssertEqual(payload?["binding"] as? Bool, false)
    }
    
    func testThatItFetchesTeam() {
        // Given
        var team: MockTeam!
        var creator: MockUser!
        
        sut.performRemoteChanges { session in
            let selfUser = session.insertSelfUser(withName: "Am I")
            team = session.insertTeam(withName: "name", isBound: true, users: [selfUser])
            team.pictureAssetKey = "1234-abc"
            team.pictureAssetId = "123-1234-abc"
            creator = session.insertUser(withName: "creator")
            team.creator = creator
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // When
        let path = "/teams/\(team.identifier)"
        let response = self.response(forPayload: nil, path: path, method: .methodGET, apiVersion: .v0)
        XCTAssertNotNil(response)
        XCTAssertEqual(response?.httpStatus, 200)
        XCTAssertNotNil(response?.payload)

        // Then
        let payload = response?.payload?.asDictionary() as? [String : Any?]
        XCTAssertEqual(payload?["id"] as? String, team.identifier)
        XCTAssertEqual(payload?["creator"] as? String, creator.identifier)
        XCTAssertEqual(payload?["name"] as? String, team.name)
        XCTAssertEqual(payload?["icon_key"] as? String, team.pictureAssetKey)
        XCTAssertEqual(payload?["icon"] as? String, team.pictureAssetId)
        XCTAssertEqual(payload?["binding"] as? Bool, true)

    }
    
    func testThatItFetchesAllTeams() {
        // Given
        var team1: MockTeam!
        var team2: MockTeam!

        sut.performRemoteChanges { session in
            let selfUser = session.insertSelfUser(withName: "Am I")
            team1 = session.insertTeam(withName: "some", isBound: true, users: [selfUser])
            team2 = session.insertTeam(withName: "other", isBound: false, users: [selfUser])
        }
        
        // When
        let path = "/teams"
        let response = self.response(forPayload: nil, path: path, method: .methodGET, apiVersion: .v0)
        
        // Then
        checkThat(response: response, contains: [team2, team1], hasMore: false)
    }
}

// MARK: - Team permissions
extension MockTransportSessionTeamTests {
    
    func testThatItReturnsErrorForNonExistingTeam() {
        // Given
        sut.performRemoteChanges { session in
            _ = session.insertSelfUser(withName: "Am I")
            _ = session.insertTeam(withName: "name", isBound: true)
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // When
        let path = "/teams/1234"
        let response = self.response(forPayload: nil, path: path, method: .methodGET, apiVersion: .v0)
        
        // Then
        XCTAssertNotNil(response)
        XCTAssertEqual(response?.httpStatus, 404)
        let payload = response?.payload?.asDictionary() as? [String : String]
        XCTAssertEqual(payload?["label"], "no-team")
    }

    
    func testThatItReturnsErrorForTeamsWhereUserIsNotAMember() {
        // Given
        var team: MockTeam!
        
        sut.performRemoteChanges { session in
            _ = session.insertSelfUser(withName: "Am I")
            team = session.insertTeam(withName: "name", isBound: true)
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // When
        let path = "/teams/\(team.identifier)"
        let response = self.response(forPayload: nil, path: path, method: .methodGET, apiVersion: .v0)
        
        // Then
        XCTAssertNotNil(response)
        XCTAssertEqual(response?.httpStatus, 404)
        let payload = response?.payload?.asDictionary() as? [String : String]
        XCTAssertEqual(payload?["label"], "no-team")
    }
    
    func testThatItReturnsErrorForTeamMembersWhereUserIsNotAMember() {
        // Given
        var team: MockTeam!
        
        sut.performRemoteChanges { session in
            _ = session.insertSelfUser(withName: "Am I")
            team = session.insertTeam(withName: "name", isBound: true)
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // When
        let path = "/teams/\(team.identifier)/members"
        let response = self.response(forPayload: nil, path: path, method: .methodGET, apiVersion: .v0)
        
        // Then
        XCTAssertNotNil(response)
        XCTAssertEqual(response?.httpStatus, 403)
        let payload = response?.payload?.asDictionary() as? [String : String]
        XCTAssertEqual(payload?["label"], "no-team-member")
    }

    func testThatItReturnsErrorForTeamMembersWhereUserDoesNotHavePermission() {
        // Given
        var team: MockTeam!
        
        sut.performRemoteChanges { session in
            let selfUser = session.insertSelfUser(withName: "Am I")
            team = session.insertTeam(withName: "name", isBound: true)
            let member = session.insertMember(with: selfUser, in: team)
            member.permissions = []
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // When
        let path = "/teams/\(team.identifier)/members"
        let response = self.response(forPayload: nil, path: path, method: .methodGET, apiVersion: .v0)
        
        // Then
        XCTAssertNotNil(response)
        XCTAssertEqual(response?.httpStatus, 403)
        let payload = response?.payload?.asDictionary() as? [String : String]
        XCTAssertEqual(payload?["label"], "operation-denied")
    }
}

// MARK: - Conversation

extension MockTransportSessionTeamTests {
    
    func testThatTeamConversationCantBeDeleted_ByNonTeamUser() {
        // Given
        var team: MockTeam!
        var creator: MockUser!
        var selfUser: MockUser!
        var conversation: MockConversation!
        
        sut.performRemoteChanges { session in
            team = session.insertTeam(withName: "name", isBound: true)
            selfUser = session.insertSelfUser(withName: "Self User")
            creator = session.insertUser(withName: "creator")
            team.creator = creator
            conversation = session.insertTeamConversation(to: team, with: [creator, selfUser], creator: creator)
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // When
        let response = self.response(forPayload: nil, path: "/teams/\(team.identifier)/conversations/\(conversation.identifier)", method: .methodDELETE, apiVersion: .v0)
        
        // Then
        XCTAssertEqual(response?.httpStatus, 403)
    }
    
    func testThatTeamConversationCanBeDeleted() {
        // Given
        var team: MockTeam!
        var creator: MockUser!
        var selfUser: MockUser!
        var conversation: MockConversation!
        
        sut.performRemoteChanges { session in
            team = session.insertTeam(withName: "name", isBound: true)
            selfUser = session.insertSelfUser(withName: "Self User")
            creator = session.insertUser(withName: "creator")
            team.creator = creator
            session.insertMember(with: selfUser, in: team)
            conversation = session.insertTeamConversation(to: team, with: [creator, selfUser], creator: creator)
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // When
        let response = self.response(forPayload: nil, path: "/teams/\(team.identifier)/conversations/\(conversation.identifier)", method: .methodDELETE, apiVersion: .v0)
        
        // Then
        XCTAssertEqual(response?.httpStatus, 200)
        XCTAssertTrue(conversation.isFault)
    }
    
    func testThatConversationReturnsTeamInPayload() {
        // Given
        var team: MockTeam!
        var creator: MockUser!
        var conversation: MockConversation!
        
        sut.performRemoteChanges { session in
            team = session.insertTeam(withName: "name", isBound: true)
            team.pictureAssetKey = "1234-abc"
            team.pictureAssetId = "123-1234-abc"
            
            creator = session.insertUser(withName: "creator")
            team.creator = creator
            conversation = session.insertTeamConversation(to: team, with: [creator, session.insertSelfUser(withName: "Am I")], creator: creator)
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // When
        let payload = conversation.transportData().asDictionary() as? [String : Any]
        
        // Then
        XCTAssertEqual(payload?["team"] as? String, team.identifier)
    }
}

// MARK: - Members

extension MockTransportSessionTeamTests {
    
    func testMembersPayload() {
        // Given
        var member: MockMember!
        var user: MockUser!
        let permission1 = MockPermissions.addTeamMember
        let permission2 = MockPermissions.getTeamConversations

        sut.performRemoteChanges { session in
            let team = session.insertTeam(withName: "name", isBound: true)
            user = session.insertUser(withName: "Am I")
            member = session.insertMember(with: user, in: team)
            member.permissions = [permission1, permission2]
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // When
        let payload = member.payload.asDictionary() as? [String : Any]
        
        // Then
        let userId = payload?["user"]
        XCTAssertNotNil(userId)
        XCTAssertEqual(userId as? String, user.identifier)
        
        guard let permissionsPayload = payload?["permissions"] as? [String: Any] else { return XCTFail("No permissions payload") }
        guard let permissionsValue = permissionsPayload["self"] as? NSNumber else { return XCTFail("No permissions value") }
        let permissions = MockPermissions(rawValue: permissionsValue.int64Value)
        XCTAssertEqual(permissions, [permission1, permission2])
    }
    
    func testThatItFetchesTeamMembers() {
        // Given
        var user1: MockUser!
        var user2: MockUser!
        var team: MockTeam!
        
        sut.performRemoteChanges { session in
            user1 = session.insertSelfUser(withName: "one")
            user2 = session.insertUser(withName: "two")

            team = session.insertTeam(withName: "name", isBound: true, users: [user1, user2])
            team.pictureAssetKey = "1234-abc"
            team.pictureAssetId = "123-1234-abc"
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // When
        let path = "/teams/\(team.identifier)/members"
        let response = self.response(forPayload: nil, path: path, method: .methodGET, apiVersion: .v0)
        XCTAssertNotNil(response)
        XCTAssertEqual(response?.httpStatus, 200)
        XCTAssertNotNil(response?.payload)
        
        // Then
        let payload = response?.payload?.asDictionary() as? [String : Any]
        guard let teams = payload?["members"] as? [[String : Any]] else {
            XCTFail("Should have teams array")
            return
        }
        XCTAssertEqual(teams.count, 2)
        
        let identifiers = Set(teams.compactMap { $0["user"] as? String })
        XCTAssertEqual(identifiers, [user1.identifier, user2.identifier])
    }
    
    func testThatItFetchesTeamMembersByID() {
        // Given
        var user1: MockUser!
        var user2: MockUser!
        var team: MockTeam!
        
        sut.performRemoteChanges { session in
            user1 = session.insertSelfUser(withName: "one")
            user2 = session.insertUser(withName: "two")
            
            team = session.insertTeam(withName: "name", isBound: true, users: [user1, user2])
            team.pictureAssetKey = "1234-abc"
            team.pictureAssetId = "123-1234-abc"
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // When
        let requestPayload = ["user_ids": [user1.identifier, user2.identifier]]
        let path = "/teams/\(team.identifier)/get-members-by-ids-using-post"
        let response = self.response(forPayload: requestPayload as ZMTransportData, path: path, method: .methodPOST, apiVersion: .v0)
        XCTAssertNotNil(response)
        XCTAssertEqual(response?.httpStatus, 200)
        XCTAssertNotNil(response?.payload)
        
        // Then
        let payload = response?.payload?.asDictionary() as? [String : Any]
        guard let teams = payload?["members"] as? [[String : Any]] else {
            XCTFail("Should have teams array")
            return
        }
        XCTAssertEqual(teams.count, 2)
        
        let identifiers = Set(teams.compactMap { $0["user"] as? String })
        XCTAssertEqual(identifiers, [user1.identifier, user2.identifier])
    }

    func testThatItFetchesSingleTeamMembers() {
        // Given
        var user1: MockUser!
        var user2: MockUser!
        var team: MockTeam!
        
        sut.performRemoteChanges { session in
            user1 = session.insertSelfUser(withName: "one")
            user2 = session.insertUser(withName: "two")
            
            team = session.insertTeam(withName: "name", isBound: true, users: [user1, user2])
            team.pictureAssetKey = "1234-abc"
            team.pictureAssetId = "123-1234-abc"
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // When
        let path = "/teams/\(team.identifier)/members/\(user1.identifier)"
        let response = self.response(forPayload: nil, path: path, method: .methodGET, apiVersion: .v0)
        XCTAssertNotNil(response)
        XCTAssertEqual(response?.httpStatus, 200)
        XCTAssertNotNil(response?.payload)
        
        // Then
        let payload = response?.payload?.asDictionary() as? [String : Any]
        XCTAssertEqual(payload?["user"] as? String, user1.identifier)
    }

    func testThatItDoesNotApproveLegalHoldRequestForNonPendingUser() {
        var user: MockUser!
        var team: MockTeam!

        sut.performRemoteChanges { session in
            user = session.insertSelfUser(withName: "one")
            user.password = "Ex@mple!"

            team = session.insertTeam(withName: "name", isBound: true, users: [user])
            team.pictureAssetKey = "1234-abc"
            team.pictureAssetId = "123-1234-abc"

            team.hasLegalHoldService = true
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // Then
        let path = "/teams/\(team.identifier)/legalhold/\(user.identifier)/approve"
        let response = self.response(forPayload: ["password": "Ex@mple!"] as NSDictionary, path: path, method: .methodPUT, apiVersion: .v0)
        XCTAssertNotNil(response)
        XCTAssertEqual(response?.httpStatus, 412)
        XCTAssertEqual(response?.payload as? NSDictionary, ["label": "legalhold-not-pending"])
    }

    func testThatItApprovesLegalHoldRequestForUser() {
        var user: MockUser!
        var team: MockTeam!

        sut.performRemoteChanges { session in
            user = session.insertSelfUser(withName: "one")
            user.password = "Ex@mple!"

            team = session.insertTeam(withName: "name", isBound: true, users: [user])
            team.pictureAssetKey = "1234-abc"
            team.pictureAssetId = "123-1234-abc"

            team.hasLegalHoldService = true
            XCTAssertTrue(user.requestLegalHold())
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // Then
        let path = "/teams/\(team.identifier)/legalhold/\(user.identifier)/approve"
        let response = self.response(forPayload: ["password": "Ex@mple!"] as NSDictionary, path: path, method: .methodPUT, apiVersion: .v0)
        XCTAssertNotNil(response)
        XCTAssertEqual(response?.httpStatus, 200)
        XCTAssertNil(response?.payload)
        XCTAssertEqual(user.legalHoldState, .enabled)
        XCTAssertNil(user.pendingLegalHoldClient)
    }
    
    func testThatTeamHasTwoConversationRoles() {
        // Given
        var team: MockTeam!
        var creator: MockUser!
        
        sut.performRemoteChanges { session in
            let selfUser = session.insertSelfUser(withName: "Am I")
            team = session.insertTeam(withName: "name", isBound: true, users: [selfUser])
            creator = session.insertUser(withName: "creator")
            team.creator = creator
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // When
        let path = "/teams/\(team.identifier)/conversations/roles"
        let response = self.response(forPayload: nil, path: path, method: .methodGET, apiVersion: .v0)
        XCTAssertNotNil(response)
        XCTAssertEqual(response?.httpStatus, 200)
        XCTAssertNotNil(response?.payload)
        
        // Then
        let payload = response?.payload?.asDictionary() as? [String : Any?]
        guard let conversationRoles = payload?["conversation_roles"] as? [[String : Any]] else {
            XCTFail("Should have conversation roles array")
            return
        }
        XCTAssertEqual(conversationRoles.count, team.roles.count)
        let admin = conversationRoles.first(where: {($0["conversation_role"] as? String) == MockConversation.admin})
        XCTAssertEqual((admin?["actions"] as? [String]).map({Set($0)}), Set([
            "add_conversation_member",
            "remove_conversation_member",
            "modify_conversation_name",
            "modify_conversation_message_timer",
            "modify_conversation_receipt_mode",
            "modify_conversation_access",
            "modify_other_conversation_member",
            "leave_conversation","delete_conversation"
            ]))
        
        let member = conversationRoles.first(where: {($0["conversation_role"] as? String) == MockConversation.member})
        XCTAssertEqual(member?["actions"] as? [String], ["leave_conversation"])
    }

}
