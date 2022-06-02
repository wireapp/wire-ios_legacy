//
// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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
@testable import WireDataModel

class ConversationTests_Team: ZMConversationTestsBase {

    var sut: ZMConversation!

    override func setUp() {
        super.setUp()
        sut = createConversation(in: uiMOC)
        selfUser = ZMUser.selfUser(in: uiMOC)
    }

    override func tearDown() {
        sut = nil
        selfUser = nil
        super.tearDown()
    }

    func test_ConversationIsNotATeamConversation_WhenTeamIdIsNil() {
        // Given
        sut.teamRemoteIdentifier = nil

        // When / Then
        XCTAssertFalse(sut.isTeamConversation)
    }

    func test_ConversationIsNotATeamConversation_WhenTeamIdIsDifferentFromSelfUser() {
        // Given
        let team = createTeam(in: uiMOC)
        createMembership(in: uiMOC, user: selfUser, team: team, with: nil)
        sut.teamRemoteIdentifier = UUID()

        // When / Then
        XCTAssertFalse(sut.isTeamConversation)
    }

    // @SF.Federation @SF.Separation @TSFI.UserInterface @S0.2
    func test_ConversationIsNotATeamConversation_WhenItIsFederated() {
        // Given
        let teamId = UUID()
        let team = createTeam(in: uiMOC)
        team.remoteIdentifier = teamId
        createMembership(in: uiMOC, user: selfUser, team: team, with: nil)
        sut.teamRemoteIdentifier = teamId

        sut.domain = UUID().transportString()
        selfUser.domain = UUID().transportString()

        // When / Then
        XCTAssertFalse(sut.isTeamConversation)
    }

    // @SF.Federation @SF.Separation @TSFI.UserInterface @S0.2
    func test_ConversationIsATeamConversation_WhenTeamIdIsTheSameAsSelfUser_AndItIsNotFederated() {
        // Given
        let teamId = UUID()
        let team = createTeam(in: uiMOC)
        team.remoteIdentifier = teamId
        createMembership(in: uiMOC, user: selfUser, team: team, with: nil)
        sut.teamRemoteIdentifier = teamId

        // When / Then
        XCTAssertTrue(sut.isTeamConversation)
    }

}
