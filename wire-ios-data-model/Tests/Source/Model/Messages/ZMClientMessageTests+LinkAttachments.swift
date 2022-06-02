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

import WireTesting

class ZMClientMessageTests_LinkAttachments: BaseZMClientMessageTests {

    func testThatItMatchesMessageNeedingUpdate() throws {
        // GIVEN
        let sender = ZMUser.insertNewObject(in: uiMOC)
        sender.remoteIdentifier = .create()

        let message1 = try! conversation.appendText(content: "Hello world") as! ZMMessage
        message1.sender = sender

        let message2 = try! conversation.appendText(content: "Hello world", fetchLinkPreview: false) as! ZMMessage
        message2.sender = sender
        uiMOC.saveOrRollback()

        // WHEN
        let fetchRequest = NSFetchRequest<ZMMessage>(entityName: ZMMessage.entityName())
        fetchRequest.predicate = ZMMessage.predicateForMessagesThatNeedToUpdateLinkAttachments()
        let fetchedMessages = try uiMOC.fetch(fetchRequest)

        // THEN
        XCTAssertEqual(fetchedMessages, [message1])
    }

    func testThatItSavesLinkAttachmentsAfterAssigning() throws {
        // GIVEN
        let sender = ZMUser.insertNewObject(in: uiMOC)
        sender.remoteIdentifier = .create()

        let nonce = UUID()

        let thumbnail = URL(string: "https://i.ytimg.com/vi/hyTNGkBSjyo/hqdefault.jpg")!

        var attachment: LinkAttachment! = LinkAttachment(type: .youTubeVideo, title: "Pingu Season 1 Episode 1",
                                                         permalink: URL(string: "https://www.youtube.com/watch?v=hyTNGkBSjyo")!,
                                                         thumbnails: [thumbnail],
                                                         originalRange: NSRange(location: 20, length: 43))

        var message: ZMClientMessage? = try? conversation.appendText(content: "Hello world", nonce: nonce) as? ZMClientMessage
        message?.sender = sender
        message?.linkAttachments = [attachment]
        uiMOC.saveOrRollback()
        uiMOC.refresh(message!, mergeChanges: false)

        message = nil
        attachment = nil

        // WHEN
        let fetchedMessage = ZMMessage.fetch(withNonce: nonce, for: conversation, in: uiMOC)
        let fetchedAttachment = fetchedMessage?.linkAttachments?.first

        // THEN
        XCTAssertEqual(fetchedAttachment?.type, .youTubeVideo)
        XCTAssertEqual(fetchedAttachment?.title, "Pingu Season 1 Episode 1")
        XCTAssertEqual(fetchedAttachment?.permalink, URL(string: "https://www.youtube.com/watch?v=hyTNGkBSjyo")!)
        XCTAssertEqual(fetchedAttachment?.thumbnails, [thumbnail])
        XCTAssertEqual(fetchedAttachment?.originalRange, NSRange(location: 20, length: 43))
    }

}
