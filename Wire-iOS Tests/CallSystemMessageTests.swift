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
@testable import Wire
import SnapshotTesting

final class CallSystemMessageTests: XCTestCase, CoreDataFixtureTestHelper {
    var coreDataFixture: CoreDataFixture!

    override func setUp() {
        super.setUp()
        coreDataFixture = CoreDataFixture()
    }

    override func tearDown() {
        _ = waitForGroupsToBeEmpty([coreDataFixture.dispatchGroup])
        coreDataFixture = nil
        super.tearDown()
    }

    // MARK: - Missed Call

    func testThatItRendersMissedCallFromSelfUser() {
        let missedCell = cell(for: .missedCall, fromSelf: true)
        verify(matching: missedCell)
    }

    func testThatItRendersMissedCallFromOtherUser() {
        let missedCell = cell(for: .missedCall, fromSelf: false)
        verify(matching: missedCell)
    }

    func testThatItRendersMissedCallFromOtherUser_Expanded() {
        let missedCell = cell(for: .missedCall, fromSelf: false, expanded: true)
        verify(matching: missedCell)
    }

    func testThatItRendersMissedCallFromSelfUserInGroup() {
        let missedCell = cell(for: .missedCall, fromSelf: true, inGroup: true)
        verify(matching: missedCell)
    }

    func testThatItRendersMissedCallFromOtherUserInGroup() {
        let missedCell = cell(for: .missedCall, fromSelf: false, inGroup: true)
        verify(matching: missedCell)
    }

    func testThatItRendersMissedCallFromOtherUserInGroup_Expanded() {
        let missedCell = cell(for: .missedCall, fromSelf: false, expanded: true, inGroup: true)
        verify(matching: missedCell)
    }

    // MARK: - Performed Call

    func testThatItRendersPerformedCallFromSelfUser() {
        let missedCell = cell(for: .performedCall, fromSelf: true)
        verify(matching: missedCell)
    }

    func testThatItRendersPerformedCallFromOtherUser() {
        let missedCell = cell(for: .performedCall, fromSelf: false)
        verify(matching: missedCell)
    }

    func testThatItRendersPerformedCallFromOtherUser_Expanded() {
        let missedCell = cell(for: .performedCall, fromSelf: false, expanded: true)
        verify(matching: missedCell)
    }

    // MARK: - Helper

    private func cell(for type: ZMSystemMessageType, fromSelf: Bool, expanded: Bool = false, inGroup: Bool = false) -> UITableViewCell {
        let message = systemMessage(missed: type == .missedCall, in: .insertNewObject(in: uiMOC), from: fromSelf ? selfUser : otherUser, inGroup: inGroup)
        let cell = createCell(for: message, missed: type == .missedCall)

        // TODO: Check for expanded state
//        if expanded {
//            cell.setSelected(true, animated: false)
//        }

        return cell
    }

    private func systemMessage(missed: Bool, in conversation: ZMConversation, from user: ZMUser, inGroup: Bool) -> ZMSystemMessage {
        let date = Date(timeIntervalSince1970: 123456879)
        if missed {
            if inGroup {
                conversation.conversationType = .group
            }
            return conversation.appendMissedCallMessage(fromUser: user, at: date)
        } else {
            let message = conversation.appendPerformedCallMessage(with: 102, caller: user)
            message.serverTimestamp = date
            return message
        }
    }

    private func createCell(for systemMessage: ZMSystemMessage, missed: Bool) -> UITableViewCell {
        let description = ConversationCallSystemMessageCellDescription(message: systemMessage, data: systemMessage.systemMessageData!, missed: missed)

        let cell = ConversationMessageCellTableViewAdapter<ConversationCallSystemMessageCellDescription>(style: .default, reuseIdentifier: nil)
        cell.cellDescription = description
        cell.configure(with: description.configuration, fullWidth: description.isFullWidth, topMargin: description.topMargin)

        cell.frame = CGRect(origin: .zero, size: CGSize(width: CGSize.iPhoneSize.iPhone4.width, height: 32.5))

        cell.backgroundColor = .white

        return cell
    }

}
