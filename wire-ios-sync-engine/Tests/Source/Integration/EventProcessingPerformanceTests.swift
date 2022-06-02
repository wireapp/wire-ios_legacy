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

/// These tests are measuring the performance of processing events of
/// in different scenarios.
///
/// NOTE that we are not receiving encrypted events since we are not
/// interested in measuring decryption performance here.
class EventProcessingPerformanceTests: IntegrationTest {

    override func setUp() {
        super.setUp()

        createSelfUserAndConversation()
        createTeamAndConversations()
    }

    var users: [MockUser]!
    var conversations: [MockConversation]!

    func testTextEventProcessingPerformance_InLargeGroups() {
        // given
        createUsersAndConversations(userCount: 100, conversationCount: 10)
        XCTAssertTrue(login())

        simulateApplicationDidEnterBackground()
        mockTransportSession.performRemoteChanges { (_) in
            self.conversations.forEach { (conversation) in
                conversation.insertRandomTextMessages(count: 100, from: self.users)
            }
        }

        // then
        measure {
            simulateApplicationWillEnterForeground()
            XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        }
    }

    func testTextEventProcessingPerformance_inSmallGroups() {
        // given
        createUsersAndConversations(userCount: 5, conversationCount: 10)
        XCTAssertTrue(login())

        simulateApplicationDidEnterBackground()
        mockTransportSession.performRemoteChanges { (_) in
            self.conversations.forEach { (conversation) in
                conversation.insertRandomTextMessages(count: 100, from: self.users)
            }
        }

        // then
        measure {
            simulateApplicationWillEnterForeground()
            XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        }
    }

    func testKnockEventProcessingPerformance() {
        // given
        createUsersAndConversations(userCount: 5, conversationCount: 10)
        XCTAssertTrue(login())

        simulateApplicationDidEnterBackground()
        mockTransportSession.performRemoteChanges { (_) in
            self.conversations.forEach { (conversation) in
                conversation.insertRandomKnocks(count: 100, from: self.users)
            }
        }

        // then
        measure {
            simulateApplicationWillEnterForeground()
            XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        }
    }

    // MARK: Helpers

    func createUsersAndConversations(userCount: Int, conversationCount: Int) {
        mockTransportSession.performRemoteChanges { (session) in
            self.users = (1...userCount).map({
                session.insertUser(withName: "User \($0)")
            })

            let usersIncludingSelfUser = self.users + [self.selfUser!]

            self.conversations = (1...conversationCount).map({
                let conversation = session.insertTeamConversation(to: self.team, with: usersIncludingSelfUser, creator: self.selfUser)
                conversation.changeName(by: self.selfUser, name: "Team conversation \($0)")
                return conversation
            })
        }
    }

}

extension MockConversation {

    func insertRandomKnocks(count: Int, from users: [MockUser]) {
        (1...count).forEach { (_) in
            let knock = try! GenericMessage(content: Knock.with { $0.hotKnock = false }).serializedData()
            insertClientMessage(from: users.randomElement()!, data: knock)
        }
    }

    func insertRandomTextMessages(count: Int, from users: [MockUser]) {
        (1...count).forEach { (counter) in
            let text = try! GenericMessage(content: Text(content: "Random message \(counter)")).serializedData()
            insertClientMessage(from: users.randomElement()!, data: text)
        }
    }

}
