//
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

enum ConversationCellType: Int {
    case text
    case textWithRichMedia
    case image
    case fileTransfer
    case ping
    case systemMessage
    case count
}

final class DeleteMessageTests: XCTestCase {
    
    var sut: DeleteMessageTests!

    override func setUp() {
        super.setUp()
        sut = DeleteMessageTests()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func message(for conversationType: ConversationCellType) -> ZMConversationMessage? {
        var message: MockMessage? = nil

        switch conversationType {
        case .text:
            message = MockMessageFactory.textMessage(includingRichMedia: false)
        case .textWithRichMedia:
            message = MockMessageFactory.textMessage(includingRichMedia: true)
        case .image:
            message = MockMessageFactory.imageMessage()
        case .ping:
            message = MockMessageFactory.pingMessage()
        case .fileTransfer:
            message = MockMessageFactory.fileTransferMessage()
            message?.backingFileMessageData?.transferState = .uploaded
            message?.backingFileMessageData?.downloadState = .downloaded
        case .systemMessage:
            message = MockMessageFactory.systemMessage(with: .missedCall, users: 1, clients: 1)
        case .count:
            XCTFail("You can't just give the ConversationCellTypeCOUNT and expect a message!")
        }

        return message as Any as? ZMConversationMessage
    }

    func actionController(for conversationType: ConversationCellType) -> ConversationMessageActionController {
        let message = self.message(for: conversationType)!
        return ConversationMessageActionController(responder: nil, message: message, context: .content, view: UIView())
    }

    func testThatTheExpectedCellsCanBeDeleted() {
        let deleteAction = #selector(ConversationMessageActionController.deleteMessage)

        // can perform action decides if the action will be present in menu, therefore be deletable
        let textMessageCell = actionController(for: .text)
        XCTAssertTrue(textMessageCell.canPerformAction(deleteAction))

        let richMediaMessageCell = actionController(for: .textWithRichMedia)
        XCTAssertTrue(richMediaMessageCell.canPerformAction(deleteAction))

        let fileMessageCell = actionController(for: .fileTransfer)
        XCTAssertTrue(fileMessageCell.canPerformAction(deleteAction))

        let pingMessageCell = actionController(for: .ping)
        XCTAssertTrue(pingMessageCell.canPerformAction(deleteAction))

        let imageMessageCell = actionController(for: .image)
        XCTAssertTrue(imageMessageCell.canPerformAction(deleteAction))

        let systemMessageCell = actionController(for: .systemMessage)
        XCTAssertFalse(systemMessageCell.canPerformAction(deleteAction))
    }

}
