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


class CallSystemMessageTests: CoreDataSnapshotTestCase {

    // MARK: - Missed Call

    func testThatItRendersMissedCallFromSelfUser() {
        let missedCell = cell(for: .missedCall, fromSelf: true)
        verify(view: missedCell.prepareForSnapshots())
    }

    func testThatItRendersMissedCallFromOtherUser() {
        let missedCell = cell(for: .missedCall, fromSelf: false)
        verify(view: missedCell.prepareForSnapshots())
    }

    func testThatItRendersMissedCallFromOtherUser_Expanded() {
        let missedCell = cell(for: .missedCall, fromSelf: false, expanded: true)
        verify(view: missedCell.prepareForSnapshots())
    }

    // MARK: - Performed Call

    func testThatItRendersPerformedCallFromSelfUser() {
        let missedCell = cell(for: .performedCall, fromSelf: true)
        verify(view: missedCell.prepareForSnapshots())
    }

    func testThatItRendersPerformedCallFromOtherUser() {
        let missedCell = cell(for: .performedCall, fromSelf: false)
        verify(view: missedCell.prepareForSnapshots())
    }

    func testThatItRendersPerformedCallFromOtherUser_Expanded() {
        let missedCell = cell(for: .performedCall, fromSelf: false, expanded: true)
        verify(view: missedCell.prepareForSnapshots())
    }

    // MARK: - Helper

    private func cell(for type: ZMSystemMessageType, fromSelf: Bool, expanded: Bool = false) -> IconSystemCell {
        let message = systemMessage(missed: type == .missedCall, in: .insertNewObject(in: moc), from: fromSelf ? selfUser : otherUser)
        let cell = createCell(missed: type == .missedCall)
        cell.layer.speed = 0
        if expanded {
            cell.setSelected(true, animated: false)
        }
        let props = ConversationCellLayoutProperties()

        cell.configure(for: message, layoutProperties: props)
        return cell
    }

    private func systemMessage(missed: Bool, in conversation: ZMConversation, from user: ZMUser) -> ZMSystemMessage {
        let date = Date(timeIntervalSince1970: 123456879)
        if missed {
            return conversation.appendMissedCallMessage(fromUser: user, at: date)
        } else {
            let message = conversation.appendPerformedCallMessage(with: 102, caller: user)
            message.serverTimestamp = date
            return message
        }
    }

    private func createCell(missed: Bool) -> IconSystemCell {
        if missed {
            return MissedCallCell(style: .default, reuseIdentifier: name)
        } else {
            return PerformedCallCell(style: .default, reuseIdentifier: name)
        }
    }

}



private extension UITableViewCell {

    func prepareForSnapshots() -> UIView {
        setNeedsLayout()
        layoutIfNeeded()

        bounds.size = systemLayoutSizeFitting(
            CGSize(width: 320, height: 0),
            withHorizontalFittingPriority: UILayoutPriorityRequired,
            verticalFittingPriority: UILayoutPriorityFittingSizeLevel
        )

        return wrapInTableView()
    }

}
