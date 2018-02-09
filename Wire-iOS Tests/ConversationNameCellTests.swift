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
@testable import Wire

class ConversationNameCellTests: CoreDataSnapshotTestCase {

    func testThatItRendersConversationNameCellFromSelfUser() {
        let sut = cell(fromSelf: true, title: "Conversation")
        verify(view: sut.prepareForSnapshots())
    }

    func testThatItRendersConversationNameCellFromOtherUser() {
        let sut = cell(fromSelf: false, title: "Conversation")
        verify(view: sut.prepareForSnapshots())
    }

    private func cell(fromSelf: Bool, title: String) -> IconSystemCell {
        let message = ZMSystemMessage.insertNewObject(in: uiMOC)
        message.sender = fromSelf ? selfUser : otherUser
        message.systemMessageType = .newConversationWithName
        message.text = title

        let cell = ConversationNameCell(style: .default, reuseIdentifier: nil)
        let props = ConversationCellLayoutProperties()
        cell.configure(for: message, layoutProperties: props)
        cell.layer.speed = 0
        return cell
    }

}

private extension UITableViewCell {

    func prepareForSnapshots() -> UIView {
        setNeedsLayout()
        layoutIfNeeded()

        bounds.size = systemLayoutSizeFitting(
            CGSize(width: 375, height: 0),
            withHorizontalFittingPriority: UILayoutPriorityRequired,
            verticalFittingPriority: UILayoutPriorityFittingSizeLevel
        )

        return wrapInTableView()
    }

}

