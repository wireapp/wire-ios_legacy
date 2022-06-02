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

import XCTest

class ConversationTests_ReceiptMode: IntegrationTest {

    override func setUp() {
        super.setUp()
        createSelfUserAndConversation()
        createExtraUsersAndConversations()
        createTeamAndConversations()
    }

    func testThatItUpdatesTheReadReceiptsSetting() {
        // given
        XCTAssert(login())
        let sut = conversation(for: groupConversation)!
        XCTAssertFalse(sut.hasReadReceiptsEnabled)

        // when
        sut.setEnableReadReceipts(true, in: userSession!) { (result) in
            switch result {
            case .failure:
                XCTFail()
            case .success:
                break
            }
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.1))

        // then
        XCTAssertTrue(sut.hasReadReceiptsEnabled)
    }

    func testThatItUpdatesTheReadReceiptsSettingWhenOutOfSyncWithBackend() {
        // given
        XCTAssert(login())
        let sut = conversation(for: groupConversation)!
        XCTAssertFalse(sut.hasReadReceiptsEnabled)

        mockTransportSession.performRemoteChanges { _ in
            self.groupConversation.receiptMode = 1
        }

        // when
        sut.setEnableReadReceipts(true, in: userSession!) { (result) in
            switch result {
            case .failure:
                XCTFail()
            case .success:
                break
            }
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.1))

        // then
        XCTAssertTrue(sut.hasReadReceiptsEnabled)
    }

    func testThatItUpdatesTheReadReceiptsSettingWhenChangedRemotely() {
        // given
        XCTAssert(login())
        let sut = conversation(for: groupConversation)!
        XCTAssertFalse(sut.hasReadReceiptsEnabled)

        // when
        mockTransportSession.performRemoteChanges { (_) in
            self.groupConversation.changeReceiptMode(by: self.user1, receiptMode: 1)
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.1))

        // then
        XCTAssertTrue(sut.hasReadReceiptsEnabled)
    }

    func testThatItWeCantChangeTheReadReceiptsSettingInAOneToOneConversation() {
        // given
        XCTAssert(login())
        let sut = conversation(for: selfToUser1Conversation)!
        XCTAssertFalse(sut.hasReadReceiptsEnabled)
        let expectation = self.expectation(description: "Invalid Operation")

        // when
        sut.setEnableReadReceipts(true, in: userSession!) { (result) in
            switch result {
            case .failure(ReadReceiptModeError.invalidOperation):
                expectation.fulfill()
            default:
                XCTFail()
            }
        }
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.1))
    }

}
