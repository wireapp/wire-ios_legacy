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


@testable import Wire


class ConversationRenamedCellTests: CoreDataSnapshotTestCase {

    func testThatItRendersRenamedCellCorrectlySelf() {
        verify(view: createSut(
            fromSelf: true,
            name: "Amazing Conversation"
        ))
    }

    func testThatItRendersRenamedCellCorrectlyOther() {
        verify(view: createSut(
            fromSelf: false,
            name: "Best Conversation Ever"
        ))
    }

    func testThatItRendersRenamedCellCorrectlyLongName() {
        verify(view: createSut(
            fromSelf: false,
            name: "This is the best conversation name I could come up with for now!"
        ))
    }

    // MARK: – Helper

    private func createSut(fromSelf: Bool, name: String) -> UIView {
        let sut = ConversationRenamedCell(style: .default, reuseIdentifier: nil)
        let message = renamedMessage(fromSelf: fromSelf, name: name)
        sut.configure(for: message, layoutProperties: ConversationCellLayoutProperties())
        return sut.prepareForSnapshots()
    }

    private func renamedMessage(fromSelf: Bool, name: String) -> ZMSystemMessage {
        let message = ZMSystemMessage.insertNewObject(in: moc)
        message.systemMessageType = .conversationNameChanged
        message.sender = fromSelf ? selfUser : otherUser
        message.text = name
        return message
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
