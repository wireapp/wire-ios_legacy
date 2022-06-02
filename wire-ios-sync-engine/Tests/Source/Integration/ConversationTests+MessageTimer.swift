////
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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

class ConversationMessageTimerTests: IntegrationTest {

    override func setUp() {
        super.setUp()
        createSelfUserAndConversation()
        createExtraUsersAndConversations()
        createTeamAndConversations()
    }

    private func responsePayload(for conversation: ZMConversation, timeout: MessageDestructionTimeoutValue) -> ZMTransportData {
        var payload: [String: Any] = [
            "from": user1.identifier,
            "conversation": conversation.remoteIdentifier!.transportString(),
            "time": NSDate().transportString(),
            "type": "conversation.message-timer-update"
        ]

        switch timeout {
        case .none:
            payload["data"] = ["message_timer": NSNull()]
        default:
            let timeoutInMiliseconds = timeout.rawValue * 1000
            payload["data"] = ["message_timer": Int(timeoutInMiliseconds)]
        }

        return payload as ZMTransportData
    }

    func testThatItUpdatesTheDestructionTimerOneDay() {
        // given
        XCTAssert(login())
        let sut = conversation(for: groupConversation)!
        XCTAssertNil(sut.activeMessageDestructionTimeoutValue)

        // when
        setGlobalTimeout(for: sut, timeout: .oneDay)

        // then
        XCTAssertEqual(sut.activeMessageDestructionTimeoutValue, .oneDay)
        XCTAssertEqual(sut.activeMessageDestructionTimeoutType, .groupConversation)
    }

    func testThatItRemovesTheDestructionTimer() {
        // given
        XCTAssert(login())
        let sut = conversation(for: groupConversation)!

        // given
        userSession?.enqueue {
            sut.setMessageDestructionTimeoutValue(.oneDay, for: .groupConversation)
        }

        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.1))
        XCTAssertNotNil(sut.activeMessageDestructionTimeoutValue)

        setGlobalTimeout(for: sut, timeout: .none)

        // then
        guard let request = mockTransportSession.receivedRequests().first else {
            XCTFail()
            return
        }
        XCTAssertNotNil(request.payload?.asDictionary()?["message_timer"] as? NSNull)
        XCTAssertNil(sut.activeMessageDestructionTimeoutValue)
    }

    func testThatItCanSetASyncedTimerWithExistingLocalOneAndFallsBackToTheLocalAfterRemovingSyncedTimer() {
        // given
        XCTAssert(login())
        let sut = conversation(for: groupConversation)!

        userSession?.enqueue {
            sut.setMessageDestructionTimeoutValue(.oneDay, for: .selfUser)
        }

        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.1))
        XCTAssertEqual(sut.activeMessageDestructionTimeoutValue, .oneDay)
        XCTAssertEqual(sut.activeMessageDestructionTimeoutType, .selfUser)

        // when
        setGlobalTimeout(for: sut, timeout: .tenSeconds)

        // then
        XCTAssertEqual(sut.activeMessageDestructionTimeoutValue, .tenSeconds)
        XCTAssertEqual(sut.activeMessageDestructionTimeoutType, .groupConversation)

        // when
        setGlobalTimeout(for: sut, timeout: .none)

        // then
        XCTAssertEqual(sut.activeMessageDestructionTimeoutValue, .oneDay)
        XCTAssertEqual(sut.activeMessageDestructionTimeoutType, .selfUser)
    }

    // MARK: - Helper

    private func setGlobalTimeout(
        for conversation: ZMConversation,
        timeout: MessageDestructionTimeoutValue,
        file: StaticString = #file,
        line: UInt = #line
        ) {
        mockTransportSession.resetReceivedRequests()
        let identifier = conversation.remoteIdentifier!.transportString()
        mockTransportSession.responseGeneratorBlock = { request in
            guard request.path == "/conversations/\(identifier)/message-timer" else { return nil }
            return ZMTransportResponse(payload: self.responsePayload(for: conversation, timeout: timeout), httpStatus: 200, transportSessionError: nil, apiVersion: APIVersion.v0.rawValue)
        }

        // when
        conversation.setMessageDestructionTimeout(timeout, in: userSession!) { result in
            switch result {
            case .success: break
            case .failure(let error): XCTFail("failed to update timeout \(error)", file: file, line: line)
            }
        }

        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.1), file: file, line: line)

        // then
        XCTAssertEqual(mockTransportSession.receivedRequests().count, 1, "wrong request count", file: file, line: line)
        guard let request = mockTransportSession.receivedRequests().first else { return }
        XCTAssertEqual(request.path, "/conversations/\(identifier)/message-timer", "wrong path \(request.path)", file: file, line: line)
        XCTAssertEqual(request.method, .methodPUT, "wrong method", file: file, line: line)
    }
}
