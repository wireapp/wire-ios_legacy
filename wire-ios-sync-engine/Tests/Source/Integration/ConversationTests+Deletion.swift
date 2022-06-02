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

class ConversationTests_Deletion: ConversationTestsBase {

    func testThatDeletingAConversationAlsoDeletesItLocally_OnSuccessfulResponse() {
        // GIVEN
        createTeamAndConversations()
        XCTAssertTrue(login())
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // WHEN
        let conversationIsDeleted = expectation(description: "Team conversation is deleted")
        let teamConversation = conversation(for: groupConversationWithWholeTeam)!
        teamConversation.delete(in: userSession!, completion: { (result) in
            if case .success = result {
                conversationIsDeleted.fulfill()
            } else {
                XCTFail()
            }
        })
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // THEN
        XCTAssertTrue(teamConversation.isZombieObject)
    }

    func testThatDeletingAConversationIsNotDeletingItLocally_OnFailureResponse() {
        // GIVEN
        createTeamAndConversations()
        XCTAssertTrue(login())
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        mockTransportSession.responseGeneratorBlock = {[weak self] request in
            guard request.path == "/teams/\(self!.team.identifier)/conversations/\(self!.groupConversationWithWholeTeam.identifier)" else { return nil }

            self?.mockTransportSession.responseGeneratorBlock = nil

            return ZMTransportResponse(payload: nil, httpStatus: 403, transportSessionError: nil, apiVersion: APIVersion.v0.rawValue)
        }

        // WHEN
        let conversationDeletionFailed = expectation(description: "Team conversation deletion failed")
        let teamConversation = conversation(for: groupConversationWithWholeTeam)!
        teamConversation.delete(in: userSession!, completion: { (result) in
            if case .failure = result {
                conversationDeletionFailed.fulfill()
            } else {
                XCTFail()
            }
        })
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // THEN
        XCTAssertFalse(teamConversation.isZombieObject)
    }

}
