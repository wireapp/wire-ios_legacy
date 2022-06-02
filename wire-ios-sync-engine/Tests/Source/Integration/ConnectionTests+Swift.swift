//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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

class ConnectionTests_Swift: IntegrationTest {
    var tokens = [Any]()
    var listObserver: ChangeObserver!

    override func setUp() {
        super.setUp()
        APIVersion.current = .v0
    }

    override func tearDown() {
        APIVersion.current = nil
        listObserver = nil
        tokens = .init()
        super.tearDown()
    }

    func testThatConnectionRequestsToTwoUsersAreAddedToPending() {
        // given two remote users
        let userName1 = "Hans Von Üser"
        let userName2 = "Hannelore Isstgern"

        var mockUser1: MockUser!
        var mockUser2: MockUser!

        mockTransportSession.performRemoteChanges { session in
            mockUser1 = session.insertUser(withName: userName1)
            mockUser1.handle = "hans"
            XCTAssertNotNil(mockUser1.identifier)
            mockUser1.email = ""
            mockUser1.phone = ""

            mockUser2 = session.insertUser(withName: userName2)
            mockUser2.handle = "hannelore"
            XCTAssertNotNil(mockUser2.identifier)
            mockUser2.email = ""
            mockUser2.phone = ""
        }

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        XCTAssertTrue(login())

        let active = ZMConversationList.conversations(inUserSession: userSession!)
        let count = active.count

        listObserver = ConversationListChangeObserver(conversationList: active)

        var conv1: ZMConversation!
        var conv2: ZMConversation!

        // when we search and send connection requests to users
        userSession?.perform {
            self.searchAndConnectToUser(withName: userName1, searchQuery: "Hans")
            self.searchAndConnectToUser(withName: userName2, searchQuery: "Hannelore")
        }

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // we should see two new active conversations
        let realUser1 = user(for: mockUser1)
        XCTAssertNotNil(realUser1)
        XCTAssertEqual(realUser1?.connection?.status, .sent)

        let realUser2 = user(for: mockUser2)
        XCTAssertNotNil(realUser2)
        XCTAssertEqual(realUser2?.connection?.status, .sent)

        conv1 = realUser1?.oneToOneConversation
        XCTAssertNotNil(conv1)

        conv2 = realUser2?.oneToOneConversation
        XCTAssertNotNil(conv2)

        XCTAssertEqual(active.count, count + 2)

        let observer = ConversationChangeObserver()
        tokens.append(ConversationChangeInfo.add(observer: observer, for: conv1))
        tokens.append(ConversationChangeInfo.add(observer: observer, for: conv2))

        // when the remote user accepts the connection requests
        mockTransportSession.performRemoteChanges { session in
            session.remotelyAcceptConnection(to: mockUser1)
            session.remotelyAcceptConnection(to: mockUser2)
        }

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // we should receive notifications about the changed status and participants
        let notifications = observer.notifications
        XCTAssertNotNil(notifications)

        var conv1StateChanged = false
        var conv2StateChanged = false
        var conv1ParticipantsChanged = false
        var conv2ParticipantsChanged = false

        (notifications as? [ConversationChangeInfo])?.forEach { note in
            let conv = note.conversation
            if note.participantsChanged {
                conv1ParticipantsChanged = conv1ParticipantsChanged ? true : (conv == conv1)
                conv2ParticipantsChanged = conv2ParticipantsChanged ? true : (conv == conv2)
            }
            if note.connectionStateChanged {
                conv1StateChanged = conv1StateChanged ? true : (conv == conv1)
                conv2StateChanged = conv2StateChanged ? true : (conv == conv2)
            }
        }

        XCTAssertTrue(conv1StateChanged)
        XCTAssertTrue(conv2StateChanged)
        XCTAssertTrue(conv1ParticipantsChanged)
        XCTAssertTrue(conv2ParticipantsChanged)
    }
}
