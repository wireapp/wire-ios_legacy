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

enum ConversationCellType : Int {
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
            message?.fileMessageData?.transferState = .downloaded
        case .systemMessage:
            message = MockMessageFactory.systemMessage(with: .missedCall, users: 1, clients: 1)
        case .count:
            XCTFail("You can't just give the ConversationCellTypeCOUNT and expect a message!")
        }

        return message as Any as? ZMConversationMessage
    }

    func conversationCell(for conversationType: ConversationCellType) -> ConversationCell? {
        var cell: ConversationCell! = nil

        switch conversationType {
        case .text, .textWithRichMedia:
            cell = TextMessageCell(style: .default, reuseIdentifier: "test")
        case .image:
            cell = ImageMessageCell(style: .default, reuseIdentifier: "test")
        case .ping:
            cell = PingCell(style: .default, reuseIdentifier: "test")
        case .fileTransfer:
            cell = FileTransferCell(style: .default, reuseIdentifier: "test")
        case .systemMessage:
            cell = CannotDecryptCell(style: .default, reuseIdentifier: "test")
        case .count:
            XCTFail("You can't just give the .COUNT and expect a cell!")
        }

        cell.configure(for: message(for: conversationType), layoutProperties: nil)
        cell.autoSetDimension(.height, toSize: 60)

        return cell
    }

    func testThatTheExpectedCellsCanBeDeleted() {
        
        // can perform action decides if the action will be present in menu, therefor be deletable
        let textMessageCell: ConversationCell? = conversationCell(for: .text)
        XCTAssertTrue((textMessageCell?.canPerformAction(#selector(ConversationCell.deleteMessage(_:)), withSender: nil))!)
        XCTAssertFalse((textMessageCell?.canPerformAction(#selector(ConversationCell.delete(_:)), withSender: nil))!)

        let richMediaMessageCell: ConversationCell? = conversationCell(for: .textWithRichMedia)
        XCTAssertTrue((richMediaMessageCell?.canPerformAction(#selector(ConversationCell.deleteMessage(_:)), withSender: nil))!)
        XCTAssertFalse((richMediaMessageCell?.canPerformAction(#selector(ConversationCell.delete(_:)), withSender: nil))!)

        let fileMessageCell: ConversationCell? = conversationCell(for: .fileTransfer)
        XCTAssertTrue((fileMessageCell?.canPerformAction(#selector(ConversationCell.deleteMessage(_:)), withSender: nil))!)
        XCTAssertFalse((fileMessageCell?.canPerformAction(#selector(ConversationCell.delete(_:)), withSender: nil))!)

        let pingMessageCell: ConversationCell? = conversationCell(for: .ping)
        XCTAssertTrue((pingMessageCell?.canPerformAction(#selector(ConversationCell.deleteMessage(_:)), withSender: nil))!)
        XCTAssertFalse((pingMessageCell?.canPerformAction(#selector(ConversationCell.delete(_:)), withSender: nil))!)

        let imageMessageCell: ConversationCell? = conversationCell(for: .image)
        XCTAssertTrue((imageMessageCell?.canPerformAction(#selector(ConversationCell.deleteMessage(_:)), withSender: nil))!)
        XCTAssertFalse((imageMessageCell?.canPerformAction(#selector(ConversationCell.delete(_:)), withSender: nil))!)
    }

}
