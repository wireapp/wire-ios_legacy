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

@testable import WireSyncEngine

class SearchResultTests: DatabaseTest {

    func testThatItFiltersConnectedUsers() {
        // given
        let connectedUser = ZMUser.insertNewObject(in: uiMOC)
        connectedUser.remoteIdentifier = UUID.create()

        let connection = ZMConnection.insertNewObject(in: uiMOC)
        connection.to = connectedUser
        connection.status = .accepted

        uiMOC.saveOrRollback()

        let handle = "fabio"
        let payload = ["documents": [
            ["id": connectedUser.remoteIdentifier!,
             "name": "Maria",
             "accent_id": 4],
            ["id": UUID.create().uuidString,
             "name": "Fabio",
             "accent_id": 4,
             "handle": handle]
            ]]

        // when
        let result = SearchResult(payload: payload, query: .fullTextSearch(""), searchOptions: [.directory], contextProvider: coreDataStack!)

        // then
        XCTAssertEqual(result?.directory.count, 1)
        XCTAssertEqual(result?.directory.first!.handle, handle)
    }

    func testThatItFiltersTeamMembersFromDirectoryResults() {
        // given
        let team = Team.insertNewObject(in: uiMOC)
        let user = ZMUser.insertNewObject(in: uiMOC)
        let member = Member.insertNewObject(in: uiMOC)

        user.name = "Member A"
        user.remoteIdentifier = UUID.create()

        member.team = team
        member.user = user

        uiMOC.saveOrRollback()

        let handle = "fabio"
        let payload = ["documents": [
            ["id": user.remoteIdentifier!,
             "name": "Member A",
             "accent_id": 4],
            ["id": UUID.create().uuidString,
             "name": "Fabio",
             "accent_id": 4,
             "handle": handle]
            ]]

        // when
        let result = SearchResult(payload: payload, query: .fullTextSearch(""), searchOptions: [.directory], contextProvider: coreDataStack!)

        // then
        XCTAssertEqual(result?.directory.count, 1)
        XCTAssertEqual(result?.directory.first!.handle, handle)
    }

    func testThatItReturnsAllResultsWhenTheQueryIsNotAHandle() {
        // given
        let name = "User"
        let payload = ["documents": [
            ["id": UUID.create().uuidString,
             "name": name,
             "accent_id": 4],
            ["id": UUID.create().uuidString,
             "name": "Fabio",
             "accent_id": 4,
             "handle": "aa\(name.lowercased())"]
            ]]

        // when
        let result = SearchResult(payload: payload, query: .fullTextSearch(name), searchOptions: [.directory], contextProvider: coreDataStack!)

        // then
        XCTAssertEqual(result?.directory.count, 2)
    }

    func testThatItReturnsOnlyMatchingHandleResultsWhenTheQueryIsAHandle() {
        // given
        let name = "User"
        let expectedHandle = "aa\(name.lowercased())"

        let payload = ["documents": [
            ["id": UUID.create().uuidString,
             "name": name,
             "accent_id": 4],
            ["id": UUID.create().uuidString,
             "name": "Fabio",
             "accent_id": 4,
             "handle": "aa\(name.lowercased())"]
            ]]

        // when
        let result = SearchResult(payload: payload, query: .exactHandle(name), searchOptions: [.directory], contextProvider: coreDataStack!)!

        // then
        XCTAssertEqual(result.directory.count, 1)
        XCTAssertEqual(result.directory.first!.handle, expectedHandle)
    }

    func testThatItReturnsRemoteTeamMembers_WhenSearchOptionsIncludeTeamMembers() {
        // given
        let team = Team.insertNewObject(in: uiMOC)
        team.remoteIdentifier = UUID()
        let selfUser = ZMUser.selfUser(in: uiMOC)
        selfUser.teamIdentifier = team.remoteIdentifier
        let member = Member.insertNewObject(in: uiMOC)
        member.team = team
        member.user = selfUser
        let remoteTeamMemberID = UUID()
        uiMOC.saveOrRollback()

        let payload = ["documents": [
            ["id": remoteTeamMemberID.transportString(),
             "team": team.remoteIdentifier!.transportString(),
             "name": "Member A",
             "accent_id": 4]]]

        // when
        let result = SearchResult(payload: payload,
                                  query: .fullTextSearch(""),
                                  searchOptions: [.directory, .teamMembers],
                                  contextProvider: coreDataStack!)

        // then
        XCTAssertEqual(result?.teamMembers.count, 1)
        XCTAssertEqual(result?.teamMembers.first!.remoteIdentifier, remoteTeamMemberID)
    }

    func testThatItDoesNotReturnRemoteTeamMembers_WhenSearchOptionsIncludeExcludeNonActiveTeamMembers () {
        // given
        let team = Team.insertNewObject(in: uiMOC)
        team.remoteIdentifier = UUID()
        let selfUser = ZMUser.selfUser(in: uiMOC)
        selfUser.teamIdentifier = team.remoteIdentifier
        let member = Member.insertNewObject(in: uiMOC)
        member.team = team
        member.user = selfUser
        let remoteTeamMemberID = UUID()
        uiMOC.saveOrRollback()

        let payload = ["documents": [
            ["id": remoteTeamMemberID.transportString(),
             "team": team.remoteIdentifier!.transportString(),
             "name": "Member A",
             "accent_id": 4]]]

        // when
        let result = SearchResult(payload: payload,
                                  query: .fullTextSearch(""),
                                  searchOptions: [.directory, .teamMembers, .excludeNonActiveTeamMembers],
                                  contextProvider: coreDataStack!)

        // then
        XCTAssertEqual(result?.teamMembers.count, 0)
    }

    func testThatThatTeamMemberSearchResultsCanBeExtendedWithMembershipPayload() {
        // given
        let team = Team.insertNewObject(in: uiMOC)
        team.remoteIdentifier = UUID()
        let selfUser = ZMUser.selfUser(in: uiMOC)
        selfUser.teamIdentifier = team.remoteIdentifier
        let member = Member.insertNewObject(in: uiMOC)
        member.team = team
        member.user = selfUser
        let remoteTeamMemberID = UUID()
        uiMOC.saveOrRollback()

        let payload = ["documents": [
            ["id": remoteTeamMemberID.transportString(),
             "team": team.remoteIdentifier!.transportString(),
             "name": "Member A",
             "accent_id": 4]]]

        var result = SearchResult(payload: payload,
                                  query: .fullTextSearch(""),
                                  searchOptions: [.directory, .teamMembers],
                                  contextProvider: coreDataStack!)

        let membership = createMembershipPayload(userID: remoteTeamMemberID, createdBy: selfUser.remoteIdentifier, permissions: .partner)
        let membershipListPayload = WireSyncEngine.MembershipListPayload.init(hasMore: false, members: [membership])

        // when
        result?.extendWithMembershipPayload(payload: membershipListPayload)

        // then
        XCTAssertEqual(result?.teamMembers.count, 1)
        XCTAssertEqual(result?.teamMembers.first!.teamRole, .partner)
        XCTAssertEqual(result?.teamMembers.first!.teamCreatedBy, selfUser.remoteIdentifier)
    }

    // MARK: - Team member results filtering

    func testThatWhenFilteringTeamMemberSearchResults_PartnerCanNotBeFound() {
        // given
        let team = Team.insertNewObject(in: uiMOC)
        team.remoteIdentifier = UUID()
        let selfUser = ZMUser.selfUser(in: uiMOC)
        selfUser.remoteIdentifier = UUID()
        selfUser.teamIdentifier = team.remoteIdentifier
        let member = Member.insertNewObject(in: uiMOC)
        member.team = team
        member.user = selfUser
        let remoteTeamMemberID = UUID()
        uiMOC.saveOrRollback()

        let payload = ["documents": [
            ["id": remoteTeamMemberID.transportString(),
             "team": team.remoteIdentifier!.transportString(),
             "name": "Member A",
             "accent_id": 4]]]

        var result = SearchResult(payload: payload,
                                  query: .fullTextSearch(""),
                                  searchOptions: [.directory, .teamMembers],
                                  contextProvider: coreDataStack!)

        let membership = createMembershipPayload(userID: remoteTeamMemberID, createdBy: nil, permissions: .partner)
        let membershipListPayload = WireSyncEngine.MembershipListPayload.init(hasMore: false, members: [membership])

        result?.extendWithMembershipPayload(payload: membershipListPayload)

        // when
        result?.filterBy(searchOptions: .excludeNonActivePartners, query: "", contextProvider: coreDataStack!)

        // then
        XCTAssertEqual(result?.teamMembers.count, 0)
    }

    func testThatWhenFilteringTeamMemberSearchResults_PartnerCanBeFoundByItsCreator() {
        // given
        let team = Team.insertNewObject(in: uiMOC)
        team.remoteIdentifier = UUID()
        let selfUser = ZMUser.selfUser(in: uiMOC)
        selfUser.teamIdentifier = team.remoteIdentifier
        let member = Member.insertNewObject(in: uiMOC)
        member.team = team
        member.user = selfUser
        let remoteTeamMemberID = UUID()
        uiMOC.saveOrRollback()

        let payload = ["documents": [
            ["id": remoteTeamMemberID.transportString(),
             "team": team.remoteIdentifier!.transportString(),
             "name": "Member A",
             "accent_id": 4]]]

        var result = SearchResult(payload: payload,
                                  query: .fullTextSearch(""),
                                  searchOptions: [.directory, .teamMembers],
                                  contextProvider: coreDataStack!)

        let membership = createMembershipPayload(userID: remoteTeamMemberID, createdBy: selfUser.remoteIdentifier, permissions: .partner)
        let membershipListPayload = WireSyncEngine.MembershipListPayload.init(hasMore: false, members: [membership])

        result?.extendWithMembershipPayload(payload: membershipListPayload)

        // when
        result?.filterBy(searchOptions: .excludeNonActivePartners, query: "", contextProvider: coreDataStack!)

        // then
        XCTAssertEqual(result?.teamMembers.count, 1)
    }

    func testThatWhenFilteringTeamMemberSearchResults_PartnerCanBeFoundByExactHandleSearch() {
        // given
        let team = Team.insertNewObject(in: uiMOC)
        team.remoteIdentifier = UUID()
        let selfUser = ZMUser.selfUser(in: uiMOC)
        selfUser.teamIdentifier = team.remoteIdentifier
        let member = Member.insertNewObject(in: uiMOC)
        member.team = team
        member.user = selfUser
        let remoteTeamMemberID = UUID()
        uiMOC.saveOrRollback()

        let payload = ["documents": [
            ["id": remoteTeamMemberID.transportString(),
             "team": team.remoteIdentifier!.transportString(),
             "handle": "aaa",
             "name": "Member A",
             "accent_id": 4]]]

        var result = SearchResult(payload: payload,
                                  query: .fullTextSearch(""),
                                  searchOptions: [.directory, .teamMembers],
                                  contextProvider: coreDataStack!)

        let membership = createMembershipPayload(userID: remoteTeamMemberID, createdBy: nil, permissions: .partner)
        let membershipListPayload = WireSyncEngine.MembershipListPayload.init(hasMore: false, members: [membership])

        result?.extendWithMembershipPayload(payload: membershipListPayload)

        // when
        result?.filterBy(searchOptions: .excludeNonActivePartners, query: "@aaa", contextProvider: coreDataStack!)

        // then
        XCTAssertEqual(result?.teamMembers.count, 1)
    }

    // MARK: - Helpers

    func createMembershipPayload(userID: UUID,
                                 createdBy: UUID?,
                                 permissions: Permissions) -> WireSyncEngine.MembershipPayload {
        let membershipPermissons = WireSyncEngine.MembershipPayload.PermissionsPayload(copyPermissions: permissions.rawValue,
                                                                                       selfPermissions: permissions.rawValue)
        let membershipPayload = WireSyncEngine.MembershipPayload.init(userID: userID,
                                                                      createdBy: createdBy,
                                                                      createdAt: nil,
                                                                      permissions: membershipPermissons)

        return membershipPayload
    }

}
