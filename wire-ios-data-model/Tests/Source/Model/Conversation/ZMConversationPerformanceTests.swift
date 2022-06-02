//
//  ZMConversationPerformanceTests.swift
//  WireDataModelTests
//
//  Created by John Nguyen on 28.09.20.
//  Copyright © 2020 Wire Swiss GmbH. All rights reserved.
//

import XCTest
@testable import WireDataModel

class ZMConversationPerformanceTests: ZMConversationTestsBase {

    /// There are no true 1:1 conversations in teams, so we check to see if it
    /// should be considered a 1:1 depending on certain properties. This was
    /// previously expensive because the conversation participants were iterated
    /// over several times. The implementation has been optimized to avoid iterating
    /// over the conversation participants entirely.

    func testPerformanceWhenCalculatingConversationType() {
        // Given
        let conversation = createLargeTeamGroupConversation()

        // The typical worst case scenario is where we need to check the local participants
        // since this is where the bottleneck is most likely to occur. To ensure that
        // we check the local participants, we assert that all other criteria is satisfied,
        // otherwise some boolean expressions may return early (due to short circuiting).

        XCTAssertEqual(conversation.conversationType, .group)
        XCTAssertNotNil(conversation.teamRemoteIdentifier)
        XCTAssertTrue(conversation.userDefinedName?.isEmpty ?? true)

        measure {
            // When
            _ = conversation.conversationType
        }
    }

    private func createLargeTeamGroupConversation() -> ZMConversation {
        let (team, _) = createTeamAndMember(for: .selfUser(in: uiMOC), with: .member)

        let users: [ZMUser] = (0..<299).map { _ in
            let otherUser = ZMUser.insertNewObject(in: uiMOC)
            let otherMember = Member.insertNewObject(in: uiMOC)
            otherMember.team = team
            otherMember.user = otherUser
            return otherUser
        }

        let conversation = ZMConversation.insertGroupConversation(moc: uiMOC, participants: users, team: team)!
        conversation.teamRemoteIdentifier = team.remoteIdentifier

        return conversation
    }

}
