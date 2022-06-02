//
// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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
@testable import WireRequestStrategy

class LocalNotificationContentTypeTest: ZMLocalNotificationTests {

    private typealias Sut = LocalNotificationContentType

    func testThatItCreatesACorrectLocalNotificationContentTypeForTheLocationMessage() {
        // given
        syncMOC.performGroupedBlockAndWait {
            let location = WireProtos.Location.with {
                $0.latitude = 0.0
                $0.longitude = 0.0
            }
            let message = GenericMessage(content: location)
            let event = self.createUpdateEvent(UUID.create(), conversationID: UUID.create(), genericMessage: message)

            // when
            let contentType = Sut(event: event, conversation: self.groupConversation, in: self.syncMOC)

            // then
            XCTAssertEqual(contentType, .location)
        }
    }

    func testThatItCreatesACorrectLocalNotificationContentTypeForTheKnockMessage() {
        // given
        syncMOC.performGroupedBlockAndWait {
            let message = GenericMessage(content: WireProtos.Knock.with { $0.hotKnock = true })
            let event = self.createUpdateEvent(UUID.create(), conversationID: UUID.create(), genericMessage: message)

            // when
            let contentType = Sut(event: event, conversation: self.groupConversation, in: self.syncMOC)

            // then
            XCTAssertEqual(contentType, .knock)
        }
    }

    func testThatItCreatesACorrectLocalNotificationContentTypeForTheEphemeralMessage() {
        // given
        syncMOC.performGroupedBlockAndWait {
            let message = GenericMessage(content: Text(content: "Ephemeral Message"), nonce: UUID(), expiresAfterTimeInterval: 100)
            let event = self.createUpdateEvent(UUID.create(), conversationID: UUID.create(), genericMessage: message)

            // when
            let contentType = Sut(event: event, conversation: self.groupConversation, in: self.syncMOC)

            // then
            XCTAssertEqual(contentType, .ephemeral(isMention: false, isReply: false))
        }
    }

    func testThatItCreatesACorrectLocalNotificationContentTypeForTheTextMessage() {
        // given
        syncMOC.performGroupedBlockAndWait {
            let message = GenericMessage(content: Text(content: "Text Message"))
            let event = self.createUpdateEvent(UUID.create(), conversationID: UUID.create(), genericMessage: message)

            // when
            let contentType = Sut(event: event, conversation: self.groupConversation, in: self.syncMOC)

            // then
            XCTAssertEqual(contentType, .text("Text Message", isMention: false, isReply: false))
        }
    }

    func testThatItCreatesACorrectLocalNotificationContentTypeForTheAudioMessage() {
        // given
        syncMOC.performGroupedBlockAndWait {
            let audioMetadata = ZMAudioMetadata(fileURL: self.fileURL(forResource: "video", extension: "mp4"), duration: 100)
            let message = GenericMessage(content: WireProtos.Asset(audioMetadata))
            let event = self.createUpdateEvent(UUID.create(), conversationID: UUID.create(), genericMessage: message)

            // when
            let contentType = Sut(event: event, conversation: self.groupConversation, in: self.syncMOC)

            // then
            XCTAssertEqual(contentType, .audio)
        }
    }

    func testThatItCreatesACorrectLocalNotificationContentTypeForTheVideoMessage() {
        // given
        syncMOC.performGroupedBlockAndWait {
            let videoMetadata = ZMVideoMetadata(fileURL: self.fileURL(forResource: "video", extension: "mp4"), thumbnail: self.verySmallJPEGData())
            let message = GenericMessage(content: WireProtos.Asset(videoMetadata))
            let event = self.createUpdateEvent(UUID.create(), conversationID: UUID.create(), genericMessage: message)

            // when
            let contentType = Sut(event: event, conversation: self.groupConversation, in: self.syncMOC)

            // then
            XCTAssertEqual(contentType, .video)
        }
    }

    func testThatItCreatesACorrectLocalNotificationContentTypeForTheFileMessage() {
        // given
        syncMOC.performGroupedBlockAndWait {
            let fileMetaData = self.createFileMetadata()
            let message = GenericMessage(content: WireProtos.Asset(fileMetaData))
            let event = self.createUpdateEvent(UUID.create(), conversationID: UUID.create(), genericMessage: message)

            // when
            let contentType = Sut(event: event, conversation: self.groupConversation, in: self.syncMOC)

            // then
            XCTAssertEqual(contentType!, .fileUpload)
        }
    }

    func testThatItCreatesASystemMessageNotificationContentTypeForTheMemberJoinEvent() {
        // given
        syncMOC.performGroupedBlockAndWait {
            let event = self.createMemberJoinUpdateEvent(UUID.create(), conversationID: UUID.create(), users: [self.selfUser])

            // when
            let contentType = Sut(event: event, conversation: self.groupConversation, in: self.syncMOC)

            // then
            XCTAssertEqual(contentType, .participantsAdded)
        }
    }

    func testThatItCreatesASystemMessageNotificationContentTypeForTheMemberLeaveEvent() {
        // given
        syncMOC.performGroupedBlockAndWait {
            let event = self.createMemberLeaveUpdateEvent(UUID.create(), conversationID: UUID.create(), users: [self.selfUser])

            // when
            let contentType = Sut(event: event, conversation: self.groupConversation, in: self.syncMOC)

            // then
            XCTAssertEqual(contentType, .participantsRemoved(reason: .none))
        }
    }

    func testThatItCreatesASystemMessageNotificationContentTypeForTheMessageTimerUpdateEvent() {
        // given
        syncMOC.performGroupedBlockAndWait {
            let event = self.createMessageTimerUpdateEvent(UUID.create(), conversationID: UUID.create())

            // when
            let contentType = Sut(event: event, conversation: self.groupConversation, in: self.syncMOC)

            // then
            XCTAssertEqual(contentType, .messageTimerUpdate("1 year"))
        }
    }

    private func createFileMetadata(filename: String? = nil) -> ZMFileMetadata {
        let fileURL: URL

        if let fileName = filename {
            fileURL = testURLWithFilename(fileName)
        } else {
            fileURL = testURLWithFilename("file.dat")
        }

        _ = createTestFile(at: fileURL)

        return ZMFileMetadata(fileURL: fileURL)
    }

    private func testURLWithFilename(_ filename: String) -> URL {
        let documents = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        let documentsURL = URL(fileURLWithPath: documents)
        return documentsURL.appendingPathComponent(filename)
    }

    private func createTestFile(at url: URL) -> Data {
        let data: Data! = "Some other data".data(using: String.Encoding.utf8)
        try! data.write(to: url, options: [])
        return data
    }

}
