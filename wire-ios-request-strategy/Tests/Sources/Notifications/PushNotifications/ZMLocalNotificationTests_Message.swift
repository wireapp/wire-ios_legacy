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

import WireTesting
import WireDataModel
@testable import WireRequestStrategy
import XCTest

class ZMLocalNotificationTests_Message: ZMLocalNotificationTests {

    // MARK: - Text Messages
    // MARK: Helpers

    /**
     *  Some (but not all) of these tests require the team identifier to be
     *  set. These tests should be called used this method.
     */
    func teamTest(_ block: () -> Void) {
        selfUser.teamIdentifier = UUID()
        block()
        selfUser.teamIdentifier = nil
    }

    func textNotification(_ conversation: ZMConversation, sender: ZMUser, text: String? = nil, mentionedUser: UserType? = nil, quotedUser: ZMUser? = nil, isEphemeral: Bool = false) -> ZMLocalNotification? {

        let expiresAfter: TimeInterval = isEphemeral ? 200 : 0

        let mention = mentionedUser.map(papply(Mention.init, NSRange(location: 0, length: 8)))
        let mentions = mention.map { [$0] } ?? []

        var quotedMessage: ZMClientMessage?

        if let quotedUser = quotedUser {
            quotedMessage = try! conversation.appendText(content: "Don't quote me on this...") as? ZMClientMessage
            quotedMessage?.sender = quotedUser
            quotedMessage?.serverTimestamp = conversation.lastReadServerTimeStamp!.addingTimeInterval(10)
        }

        let event = createUpdateEvent(UUID.create(),
                                      conversationID: conversation.remoteIdentifier!,
                                      genericMessage: GenericMessage(content: Text(content: text ?? "Hello Hello!",
                                                                                   mentions: mentions,
                                                                                   linkPreviews: [],
                                                                                   replyingTo: quotedMessage),
                                                                     nonce: UUID.create(),
                                                                     expiresAfterTimeInterval: expiresAfter),
                                      senderID: sender.remoteIdentifier)

        return ZMLocalNotification(event: event, conversation: conversation, managedObjectContext: syncMOC)
    }

    func bodyForNote(_ conversation: ZMConversation, sender: ZMUser, text: String? = nil, isEphemeral: Bool = false) -> String {
        let note = textNotification(conversation, sender: sender, text: text, isEphemeral: isEphemeral)
        XCTAssertNotNil(note)
        return note!.body
    }

    // MARK: Tests

    func testThatItShowsDefaultAlertBodyWhenHidePreviewSettingIsTrue() {

        // given
        syncMOC.performGroupedBlockAndWait {
            self.sender.name = "Super User"
            let note1 = self.textNotification(self.oneOnOneConversation, sender: self.sender)
            XCTAssertEqual(note1?.content.title, "Super User")
            XCTAssertEqual(note1?.content.body, "Hello Hello!")

            // when
            let moc = self.oneOnOneConversation.managedObjectContext!
            let key = ZMLocalNotification.ZMShouldHideNotificationContentKey
            moc.setPersistentStoreMetadata(true as NSNumber, key: key)
            let setting = moc.persistentStoreMetadata(forKey: key) as? NSNumber
            XCTAssertEqual(setting?.boolValue, true)
            let note2 = self.textNotification(self.oneOnOneConversation, sender: self.sender)

            // then
            XCTAssertEqual(note2?.content.title, "")
            XCTAssertEqual(note2?.content.body, "New message")
        }
    }

    func testThatItShowsShowsEphemeralStringEvenWhenHidePreviewSettingIsTrue() {
        // given
        syncMOC.performGroupedBlockAndWait {
            let note1 = self.textNotification(self.oneOnOneConversation, sender: self.sender, isEphemeral: true)
            XCTAssertEqual(note1?.content.title, "Someone")
            XCTAssertEqual(note1?.content.body, "Sent a message")

            // when
            let moc = self.oneOnOneConversation.managedObjectContext!
            let key = ZMLocalNotification.ZMShouldHideNotificationContentKey
            moc.setPersistentStoreMetadata(true as NSNumber, key: key)
            let setting = moc.persistentStoreMetadata(forKey: key) as? NSNumber
            XCTAssertEqual(setting?.boolValue, true)
            let note2 = self.textNotification(self.oneOnOneConversation, sender: self.sender, isEphemeral: true)

            // then
            XCTAssertEqual(note2?.content.title, "Someone")
            XCTAssertEqual(note2?.content.body, "Sent a message")
        }
    }

    func testThatItDoesNotSetThreadIdentifierForEphemeralMessages() {
        // given
        syncMOC.performGroupedBlockAndWait {
            let note = self.textNotification(self.oneOnOneConversation, sender: self.sender, isEphemeral: true)

            // then
            XCTAssertNotNil(note)
            XCTAssertEqual(note!.content.title, "Someone")
            XCTAssertEqual(note!.content.body, "Sent a message")
            XCTAssertEqual(note!.content.threadIdentifier, "")
        }
    }

    func testItCreatesMessageNotificationsCorrectly() {

        //    "push.notification.add.message.oneonone" = "%1$@";
        //    "push.notification.add.message.group" = "%1$@: %2$@";
        //    "push.notification.add.message.group.noconversationname" = "%1$@ in a conversation: %2$@";
        syncMOC.performGroupedBlockAndWait {
            XCTAssertEqual(self.bodyForNote(self.oneOnOneConversation, sender: self.sender), "Hello Hello!")
            XCTAssertEqual(self.bodyForNote(self.groupConversation, sender: self.sender), "Super User: Hello Hello!")
            XCTAssertEqual(self.bodyForNote(self.groupConversationWithoutUserDefinedName, sender: self.sender), "Super User: Hello Hello!")
            XCTAssertEqual(self.bodyForNote(self.groupConversationWithoutName, sender: self.sender), "Super User in a conversation: Hello Hello!")
            XCTAssertEqual(self.bodyForNote(self.invalidConversation, sender: self.sender), "Super User in a conversation: Hello Hello!")
        }
    }

    func testThatObfuscatesNotificationsForEphemeralMessages() {
        syncMOC.performGroupedBlockAndWait {
            [self.oneOnOneConversation,
             self.groupConversation,
             self.groupConversationWithoutUserDefinedName,
             self.groupConversationWithoutName,
             self.invalidConversation].forEach {
                let note = self.textNotification($0!, sender: self.sender, isEphemeral: true)
                XCTAssertEqual(note?.title, "Someone")
                XCTAssertEqual(note?.body, "Sent a message")
            }
        }
    }

    func testThatItDoesNotDuplicatePercentageSignsInTextAndConversationName() {
        syncMOC.performGroupedBlockAndWait {
            XCTAssertEqual(self.bodyForNote(self.groupConversation, sender: self.sender, text: "Today we grew by 100%"), "Super User: Today we grew by 100%")
        }
    }

    func testThatItSavesTheSenderOfANotification() {

        // given
        syncMOC.performGroupedBlockAndWait {
            let note = self.textNotification(self.oneOnOneConversation, sender: self.sender)!

            // then
            XCTAssertEqual(note.senderID, self.sender.remoteIdentifier)
        }
    }

    func testThatItSavesTheConversationOfANotification() {

        // given
        syncMOC.performGroupedBlockAndWait {
            let note = self.textNotification(self.oneOnOneConversation, sender: self.sender)!

            // then
            XCTAssertEqual(note.conversationID, self.oneOnOneConversation.remoteIdentifier)
        }
    }

    func testThatItSavesTheMessageNonce() {

        // given
        syncMOC.performGroupedBlockAndWait {
            let event = self.createUpdateEvent(UUID.create(),
                                               conversationID: self.oneOnOneConversation.remoteIdentifier!,
                                               genericMessage: GenericMessage(content: Text(content: "Hello Hello!"),
                                                                              nonce: UUID.create()),
                                               senderID: self.sender.remoteIdentifier)

            let note = ZMLocalNotification(event: event, conversation: self.oneOnOneConversation, managedObjectContext: self.syncMOC)

            // then
            XCTAssertEqual(note!.messageNonce, event.messageNonce)
            XCTAssertEqual(note!.selfUserID, self.selfUser.remoteIdentifier)
        }
    }

    func testThatItDoesNotCreateANotificationWhenTheConversationIsSilenced() {

        // given
        syncMOC.performGroupedBlockAndWait {
            self.groupConversation.mutedMessageTypes = .all

            // when
            let note = self.textNotification(self.groupConversation, sender: self.sender)

            // then
            XCTAssertNil(note)
        }
    }

    // MARK: Mentions

    func testThatItDoesNotCreateANotificationWhenTheConversationIsSilencedAndOtherUserIsMentioned() {
        syncMOC.performGroupedBlockAndWait {
            self.teamTest {
                // Given
                self.groupConversation.mutedMessageTypes = .all

                // When
                let note = self.textNotification(self.groupConversation, sender: self.sender, mentionedUser: self.sender)

                // Then
                XCTAssertNil(note)
            }
        }
    }

    func testThatItDoesNotCreateANotificationWhenTheConversationIsFullySilencedAndSelfUserIsMentioned() {
        syncMOC.performGroupedBlockAndWait {
            self.teamTest {
                // Given
                self.groupConversation.mutedMessageTypes = .all

                // When
                let note = self.textNotification(self.groupConversation, sender: self.sender, mentionedUser: self.selfUser)

                // Then
                XCTAssertNil(note)
            }
        }
    }

    func testThatItDoesCreateANotificationWhenTheConversationIsSilencedAndSelfUserIsMentioned() {
        syncMOC.performGroupedBlockAndWait {
            self.teamTest {
                // Given
                self.groupConversation.mutedMessageTypes = .regular

                // When
                let note = self.textNotification(self.groupConversation, sender: self.sender, mentionedUser: self.selfUser)

                // Then
                XCTAssertNotNil(note)
            }
        }
    }

    func testThatItUsesCorrectBodyWhenSelfUserIsMentioned() {
        // Given & When
        syncMOC.performGroupedBlockAndWait {
            let note = self.textNotification(self.groupConversation, sender: self.sender, mentionedUser: self.selfUser)

            // Then
            XCTAssertEqual(note?.body, "Mention from Super User: Hello Hello!")
        }
    }

    func testThatItUsesCorrectBodyWhenSelfUserIsMentioned_UserWithoutName() {
        // Given
        syncMOC.performGroupedBlockAndWait {
            self.sender.name = nil

            // When
            let note = self.textNotification(self.groupConversation, sender: self.sender, mentionedUser: self.selfUser)

            // Then
            XCTAssertEqual(note?.body, "New mention: Hello Hello!")
        }
    }

    func testThatItUsesCorrectBodyWhenSelfUserIsMentioned_NoConversationName() {
        // Given & When
        syncMOC.performGroupedBlockAndWait {
            let note = self.textNotification(self.groupConversationWithoutName, sender: self.sender, mentionedUser: self.selfUser)

            // Then
            XCTAssertEqual(note?.body, "Super User mentioned you in a conversation: Hello Hello!")
        }
    }

    func testThatItUsesCorrectBodyWhenSelfUserIsMentioned_UserWithoutNameNoConversationName() {
        // Given
        syncMOC.performGroupedBlockAndWait {
            self.sender.name = nil

            // When
            let note = self.textNotification(self.groupConversation, sender: self.sender, mentionedUser: self.selfUser)

            // Then
            XCTAssertEqual(note?.body, "New mention: Hello Hello!")
        }
    }

    func testThatItUsesCorrectBodyWhenSelfUserIsMentioned_OneOnOne() {
        // Given & When
        syncMOC.performGroupedBlockAndWait {
            let note = self.textNotification(self.oneOnOneConversation, sender: self.sender, mentionedUser: self.selfUser)

            // Then
            XCTAssertEqual(note?.body, "Mention: Hello Hello!")
        }
    }

    func testThatItUsesCorrectBodyWhenSelfUserIsMentioned_OneOnOne_NoUserName() {
        // Given
        syncMOC.performGroupedBlockAndWait {
            self.sender.name = nil

            // Given
            let note = self.textNotification(self.oneOnOneConversation, sender: self.sender, mentionedUser: self.selfUser)

            // Then
            XCTAssertEqual(note?.body, "New mention: Hello Hello!")
        }
    }

    func testThatItUsesCorrectBodyWhenSelfUserIsMentioned_Ephemeral() {
        // Given & When
        syncMOC.performGroupedBlockAndWait {
            let note = self.textNotification(self.groupConversation, sender: self.sender, mentionedUser: self.selfUser, isEphemeral: true)

            // Then
            XCTAssertEqual(note?.title, "Someone")
            XCTAssertEqual(note?.body, "Mentioned you")
        }
    }

    // MARK: Replies

    func testThatItDoesNotCreateANotificationWhenTheConversationIsFullySilencedAndSelfUserIsQuoted() {
        syncMOC.performGroupedBlockAndWait {
            self.teamTest {
                // Given
                self.groupConversation.mutedMessageTypes = .all

                // When
                let note = self.textNotification(self.groupConversation, sender: self.sender, quotedUser: self.selfUser)

                // Then
                XCTAssertNil(note)
            }
        }
    }

    func testThatItDoesNotCreateANotificationWhenTheConversationIsSilencedAndOtherUserIsQuoted() {
        syncMOC.performGroupedBlockAndWait {
            self.teamTest {
                // Given
                self.groupConversation.mutedMessageTypes = .regular

                // When
                let note = self.textNotification(self.groupConversation, sender: self.sender, quotedUser: self.otherUser1)

                // Then
                XCTAssertNil(note)
            }
        }
    }

    func testThatItCreatesANotificationWhenTheConversationIsSilencedAndSelfUserIsQuoted() {
        syncMOC.performGroupedBlockAndWait {
            self.teamTest {
                // Given
                self.groupConversation.mutedMessageTypes = .regular

                // When
                let note = self.textNotification(self.groupConversation, sender: self.sender, quotedUser: self.selfUser)

                // Then
                XCTAssertNotNil(note)
            }
        }
    }

    func testThatItCreatesCorrectBodyWhenSelfIsQuoted() {
        // Given & When
        syncMOC.performGroupedBlockAndWait {
            let note = self.textNotification(self.groupConversation, sender: self.sender, quotedUser: self.selfUser)

            // Then
            XCTAssertEqual(note?.body, "Reply from Super User: Hello Hello!")
        }
    }

    func testThatItCreatesCorrectBodyWhenSelfIsQuoted_NoUserName() {
        // Given
        syncMOC.performGroupedBlockAndWait {
            self.sender.name = nil

            // When
            let note = self.textNotification(self.groupConversation, sender: self.sender, quotedUser: self.selfUser)

            // Then
            XCTAssertEqual(note?.body, "New reply: Hello Hello!")
        }
    }

    func testThatItCreatesCorrectBodyWhenSelfIsQuoted_NoConversationName() {
        // Given & When
        syncMOC.performGroupedBlockAndWait {
            let note = self.textNotification(self.groupConversationWithoutName, sender: self.sender, quotedUser: self.selfUser)

            // Then
            XCTAssertEqual(note?.body, "Super User replied to you in a conversation: Hello Hello!")
        }
    }

    func testThatItCreatesCorrectBodyWhenSelfIsQuoted_NoUserName_NoConversationName() {
        // Given
        syncMOC.performGroupedBlockAndWait {
            self.sender.name = nil

            // When
            let note = self.textNotification(self.groupConversationWithoutName, sender: self.sender, quotedUser: self.selfUser)

            // Then
            XCTAssertEqual(note?.body, "New reply: Hello Hello!")
        }
    }

    func testThatItCreatesCorrectBodyWhenSelfIsQuoted_OneOnOne() {
        // Given & When
        syncMOC.performGroupedBlockAndWait {
            let note = self.textNotification(self.oneOnOneConversation, sender: self.sender, quotedUser: self.selfUser)

            // Then
            XCTAssertEqual(note?.body, "Reply: Hello Hello!")
        }
    }

    func testThatItCreatesCorrectBodyWhenSelfIsQuoted_OneOnOne_NoUserName() {
        // Given
        syncMOC.performGroupedBlockAndWait {
            self.sender.name = nil

            // When
            let note = self.textNotification(self.oneOnOneConversation, sender: self.sender, quotedUser: self.selfUser)

            // Then
            XCTAssertEqual(note?.body, "New reply: Hello Hello!")
        }
    }

    func testThatItCreatesCorrectBodyWhenSelfIsQuoted_Ephemeral() {
        // Given & When
        syncMOC.performGroupedBlockAndWait {
            let note = self.textNotification(self.groupConversation, sender: self.sender, quotedUser: self.selfUser, isEphemeral: true)

            // Then
            XCTAssertEqual(note?.title, "Someone")
            XCTAssertEqual(note?.body, "Replied to you")
        }
    }

    func testThatItCreatesCorrectBodyWhenOtherIsQuoted() {
        // Given & When
        syncMOC.performGroupedBlockAndWait {
            let note = self.textNotification(self.groupConversation, sender: self.sender, quotedUser: self.sender)

            // Then
            XCTAssertEqual(note?.body, "Super User: Hello Hello!")
        }
    }

    func testThatItPrioritizesMentionsOverReply() {
        // Given & When
        syncMOC.performGroupedBlockAndWait {
            let note = self.textNotification(self.groupConversation, sender: self.sender, mentionedUser: self.selfUser, quotedUser: self.selfUser)

            // Then
            XCTAssertEqual(note?.body, "Mention from Super User: Hello Hello!")
        }
    }

    // MARK: Misc

    func testThatItAddsATitleIfTheUserIsPartOfATeam() {

        // given
        syncMOC.performGroupedBlockAndWait {
            let team = Team.insertNewObject(in: self.syncMOC)
            team.name = "Wire Amazing Team"
            team.remoteIdentifier = UUID.create()
            let user = ZMUser.selfUser(in: self.syncMOC)
            _ = Member.getOrCreateMember(for: user, in: team, context: self.syncMOC)
            user.teamIdentifier = team.remoteIdentifier

            // when
            let note = self.textNotification(self.oneOnOneConversation, sender: self.sender)

            // then
            XCTAssertNotNil(note)
            XCTAssertEqual(note!.title, "Super User in \(team.name!)")
        }
    }

    func testThatItDoesNotAddATitleIfTheUserIsNotPartOfATeam() {
        // when
        syncMOC.performGroupedBlockAndWait {
            let note = self.textNotification(self.oneOnOneConversation, sender: self.sender)

            // then
            XCTAssertNotNil(note)
            XCTAssertEqual(note!.title, "Super User")
        }
    }
}

// MARK: - Image Asset Messages

extension ZMLocalNotificationTests_Message {

    // MARK: Helpers

    func imageNote(_ conversation: ZMConversation, sender: ZMUser, text: String? = nil, isEphemeral: Bool = false) -> ZMLocalNotification? {
        let expiresAfter: TimeInterval = isEphemeral ? 10 : 0
        let imageData = verySmallJPEGData()
        let assetMessage = GenericMessage(content: WireProtos.Asset(imageSize: .zero, mimeType: "image/jpeg", size: UInt64(imageData.count)), nonce: UUID.create(), expiresAfterTimeInterval: expiresAfter)

        let payload: [String: Any] = [
            "id": UUID.create().transportString(),
            "conversation": conversation.remoteIdentifier!.transportString(),
            "from": sender.remoteIdentifier.transportString(),
            "time": Date.distantFuture.transportString(),
            "data": ["text": try? assetMessage.serializedData().base64String()],
            "type": "conversation.otr-message-add"
        ]

        let event = ZMUpdateEvent(fromEventStreamPayload: payload as ZMTransportData, uuid: UUID())!
        return ZMLocalNotification(event: event, conversation: conversation, managedObjectContext: syncMOC)
    }

    func bodyForImageNote(_ conversation: ZMConversation, sender: ZMUser, text: String? = nil, isEphemeral: Bool = false) -> String {
        let note = imageNote(conversation, sender: sender, text: text, isEphemeral: isEphemeral)
        XCTAssertNotNil(note)
        return note!.body
    }

    // MARK: Tests

    func testItCreatesImageNotificationsCorrectly() {
        syncMOC.performGroupedBlockAndWait {
            XCTAssertEqual(self.bodyForImageNote(self.oneOnOneConversation, sender: self.sender), "Shared a picture")
            XCTAssertEqual(self.bodyForImageNote(self.groupConversation, sender: self.sender), "Super User shared a picture")
            XCTAssertEqual(self.bodyForImageNote(self.groupConversationWithoutUserDefinedName, sender: self.sender), "Super User shared a picture")
            XCTAssertEqual(self.bodyForImageNote(self.groupConversationWithoutName, sender: self.sender), "Super User shared a picture in a conversation")
            XCTAssertEqual(self.bodyForImageNote(self.invalidConversation, sender: self.sender), "Super User shared a picture in a conversation")
        }
    }

    func testThatObfuscatesNotificationsForEphemeralImageMessages() {
        syncMOC.performGroupedBlockAndWait {
            [self.oneOnOneConversation, self.groupConversation, self.groupConversationWithoutUserDefinedName, self.groupConversationWithoutName, self.invalidConversation].forEach {
                let note = self.imageNote($0!, sender: self.sender, isEphemeral: true)
                XCTAssertEqual(note?.title, "Someone")
                XCTAssertEqual(note?.body, "Sent a message")
            }
        }
    }
}

// MARK: - File Asset Messages

enum FileType {
    case txt, video, audio

    var testURL: URL {
        var name: String
        var fileExtension: String
        switch self {
        case .txt:
            name = "Lorem Ipsum"
            fileExtension = "txt"
        case .video:
            name = "video"
            fileExtension = "mp4"
        case  .audio:
            name = "audio"
            fileExtension = "m4a"
        }
        return Bundle(for: ZMLocalNotificationTests.self).url(forResource: name, withExtension: fileExtension)!
    }

    var testData: Data {
        return try! Data(contentsOf: testURL)
    }
}

extension ZMLocalNotificationTests_Message {

    // MARK: Helpers

    func assetNote(_ fileType: FileType, conversation: ZMConversation, sender: ZMUser, isEphemeral: Bool = false) -> ZMLocalNotification? {
        var asset: WireProtos.Asset
        switch fileType {
        case .video:
            asset = WireProtos.Asset(ZMVideoMetadata(fileURL: fileType.testURL))
        case .audio:
            asset = WireProtos.Asset(ZMAudioMetadata(fileURL: fileType.testURL))
        default:
            asset = WireProtos.Asset(ZMFileMetadata(fileURL: fileType.testURL))
        }
        let expiresAfter: TimeInterval = isEphemeral ? 10 : 0
        let assetMessage = GenericMessage(content: asset, nonce: UUID.create(), expiresAfterTimeInterval: expiresAfter)
        let payload: [String: Any] = [
            "id": UUID.create().transportString(),
            "conversation": conversation.remoteIdentifier!.transportString(),
            "from": sender.remoteIdentifier.transportString(),
            "time": Date.distantFuture.transportString(),
            "data": ["text": try? assetMessage.serializedData().base64String()],
            "type": "conversation.otr-message-add"
        ]

        let event = ZMUpdateEvent(fromEventStreamPayload: payload as ZMTransportData, uuid: UUID())!
        return ZMLocalNotification(event: event, conversation: conversation, managedObjectContext: syncMOC)

    }

    func bodyForAssetNote(_ fileType: FileType, conversation: ZMConversation, sender: ZMUser, isEphemeral: Bool = false) -> String {
        let note = assetNote(fileType, conversation: conversation, sender: sender, isEphemeral: isEphemeral)
        XCTAssertNotNil(note)
        return note!.body
    }

    // MARK: Tests

    func testThatItCreatesFileAddNotificationsCorrectly() {
        syncMOC.performGroupedBlockAndWait {
            XCTAssertEqual(self.bodyForAssetNote(.txt, conversation: self.oneOnOneConversation, sender: self.sender), "Shared a file")
            XCTAssertEqual(self.bodyForAssetNote(.txt, conversation: self.groupConversation, sender: self.sender), "Super User shared a file")
            XCTAssertEqual(self.bodyForAssetNote(.txt, conversation: self.groupConversationWithoutUserDefinedName, sender: self.sender), "Super User shared a file")
            XCTAssertEqual(self.bodyForAssetNote(.txt, conversation: self.groupConversationWithoutName, sender: self.sender), "Super User shared a file in a conversation")
            XCTAssertEqual(self.bodyForAssetNote(.txt, conversation: self.invalidConversation, sender: self.sender), "Super User shared a file in a conversation")
        }
    }

    func testThatItCreatesVideoAddNotificationsCorrectly() {
        syncMOC.performGroupedBlockAndWait {
            XCTAssertEqual(self.bodyForAssetNote(.video, conversation: self.oneOnOneConversation, sender: self.sender), "Shared a video")
            XCTAssertEqual(self.bodyForAssetNote(.video, conversation: self.groupConversation, sender: self.sender), "Super User shared a video")
            XCTAssertEqual(self.bodyForAssetNote(.video, conversation: self.groupConversationWithoutUserDefinedName, sender: self.sender), "Super User shared a video")
            XCTAssertEqual(self.bodyForAssetNote(.video, conversation: self.groupConversationWithoutName, sender: self.sender), "Super User shared a video in a conversation")
            XCTAssertEqual(self.bodyForAssetNote(.video, conversation: self.invalidConversation, sender: self.sender), "Super User shared a video in a conversation")
        }
    }

    func testThatItCreatesEphemeralFileAddNotificationsCorrectly() {
        syncMOC.performGroupedBlockAndWait {
            [self.oneOnOneConversation, self.groupConversation, self.groupConversationWithoutUserDefinedName, self.groupConversationWithoutName, self.invalidConversation].forEach {
                let note = self.assetNote(.txt, conversation: $0!, sender: self.sender, isEphemeral: true)
                XCTAssertEqual(note?.title, "Someone")
                XCTAssertEqual(note?.body, "Sent a message")
            }
        }
    }

    func testThatItCreatesEphemeralVideoAddNotificationsCorrectly() {
        syncMOC.performGroupedBlockAndWait {
            [self.oneOnOneConversation, self.groupConversation, self.groupConversationWithoutUserDefinedName, self.groupConversationWithoutName, self.invalidConversation].forEach {
                let note = self.assetNote(.video, conversation: $0!, sender: self.sender, isEphemeral: true)
                XCTAssertEqual(note?.title, "Someone")
                XCTAssertEqual(note?.body, "Sent a message")
            }
        }
    }

    func testThatItCreatesAudioNotificationsCorrectly() {
        syncMOC.performGroupedBlockAndWait {
            XCTAssertEqual(self.bodyForAssetNote(.audio, conversation: self.oneOnOneConversation, sender: self.sender), "Shared an audio message")
            XCTAssertEqual(self.bodyForAssetNote(.audio, conversation: self.groupConversation, sender: self.sender), "Super User shared an audio message")
            XCTAssertEqual(self.bodyForAssetNote(.audio, conversation: self.groupConversationWithoutUserDefinedName, sender: self.sender), "Super User shared an audio message")
            XCTAssertEqual(self.bodyForAssetNote(.audio, conversation: self.groupConversationWithoutName, sender: self.sender), "Super User shared an audio message in a conversation")
            XCTAssertEqual(self.bodyForAssetNote(.audio, conversation: self.invalidConversation, sender: self.sender), "Super User shared an audio message in a conversation")
        }
    }
}

// MARK: - Knock Messages

extension ZMLocalNotificationTests_Message {

    // MARK: Helpers

    func knockNote(_ conversation: ZMConversation, sender: ZMUser, isEphemeral: Bool = false) -> ZMLocalNotification? {
        let expiresAfter: TimeInterval = isEphemeral ? 10 : 0
        let knockMessage = GenericMessage(content: Knock.with { $0.hotKnock = false }, nonce: UUID.create(), expiresAfterTimeInterval: expiresAfter)

        let payload: [String: Any] = [
            "id": UUID.create().transportString(),
            "conversation": conversation.remoteIdentifier!.transportString(),
            "from": sender.remoteIdentifier.transportString(),
            "time": Date.distantFuture.transportString(),
            "data": ["text": try? knockMessage.serializedData().base64String()],
            "type": "conversation.otr-message-add"
        ]

        let event = ZMUpdateEvent(fromEventStreamPayload: payload as ZMTransportData, uuid: UUID())!
        return ZMLocalNotification(event: event, conversation: conversation, managedObjectContext: syncMOC)
    }

    func bodyForKnockNote(_ conversation: ZMConversation, sender: ZMUser, isEphemeral: Bool = false) -> String {
        let note = knockNote(conversation, sender: sender, isEphemeral: isEphemeral)
        XCTAssertNotNil(note)
        return note!.body
    }

    // MARK: Tests

    func testThatItCreatesKnockNotificationsCorrectly() {
        syncMOC.performGroupedBlockAndWait {
            XCTAssertEqual(self.bodyForKnockNote(self.oneOnOneConversation, sender: self.sender), "pinged")
            XCTAssertEqual(self.bodyForKnockNote(self.groupConversation, sender: self.sender), "Super User pinged")
            XCTAssertEqual(self.bodyForKnockNote(self.groupConversationWithoutUserDefinedName, sender: self.sender), "Super User pinged")
        }
    }

    func testThatItCreatesEphemeralKnockNotificationsCorrectly() {
        syncMOC.performGroupedBlockAndWait {
            [self.oneOnOneConversation, self.groupConversation, self.groupConversationWithoutUserDefinedName, self.groupConversationWithoutName, self.invalidConversation].forEach {
                let note = self.knockNote($0!, sender: self.sender, isEphemeral: true)
                XCTAssertEqual(note?.title, "Someone")
                XCTAssertEqual(note?.body, "Sent a message")
            }
        }
    }
}

// MARK: - Editing Message

extension ZMLocalNotificationTests_Message {

    func editNote(_ message: ZMOTRMessage, sender: ZMUser, text: String) -> ZMLocalNotification? {
        let editTextMessage = GenericMessage(content: MessageEdit(replacingMessageID: message.nonce!, text: Text(content: text)), nonce: UUID.create())

        let payload: [String: Any] = [
            "id": UUID.create().transportString(),
            "conversation": message.conversation!.remoteIdentifier!.transportString(),
            "from": sender.remoteIdentifier.transportString(),
            "time": Date.distantFuture.transportString(),
            "data": ["text": try? editTextMessage.serializedData().base64String()],
            "type": "conversation.otr-message-add"
        ]

        let event = ZMUpdateEvent(fromEventStreamPayload: payload as ZMTransportData, uuid: UUID())!
        return ZMLocalNotification(event: event, conversation: message.conversation!, managedObjectContext: uiMOC)
    }

    func testThatItDoesntCreateANotificationForAnEditMessage() {
        syncMOC.performGroupedBlockAndWait {
            let message = try! self.oneOnOneConversation.appendText(content: "Foo") as! ZMClientMessage
            message.markAsSent()
            let note = self.editNote(message, sender: self.sender, text: "Edited Text")
            XCTAssertNil(note)
        }
    }

}

// MARK: - Categories

extension ZMLocalNotificationTests_Message {

    func testThatItGeneratesTheNotificationWithoutMuteInTheTeam() {
        // GIVEN
        syncMOC.performGroupedBlockAndWait {
            let team = Team.insertNewObject(in: self.syncMOC)
            team.name = "Wire Amazing Team"
            let user = ZMUser.selfUser(in: self.syncMOC)
            _ = Member.getOrCreateMember(for: user, in: team, context: self.syncMOC)

            // WHEN
            let note = self.textNotification(self.oneOnOneConversation, sender: self.sender, text: "Hello", isEphemeral: false)!

            // THEN
            XCTAssertEqual(note.category, .conversationWithLike)
        }
    }

    func testThatItGeneratesTheNotificationWithMuteForNormalUser() {
        // WHEN
        syncMOC.performGroupedBlockAndWait {
            let note = self.textNotification(self.oneOnOneConversation, sender: self.sender, text: "Hello", isEphemeral: false)!

            // THEN
            XCTAssertEqual(note.category, .conversationWithLikeAndMute)
        }
    }

    func testThatItGeneratesCorrectCategoryIfEncryptionAtRestIsEnabledForTeamUser() throws {
        // GIVEN
        try syncMOC.performGroupedAndWait { _ in
       #if targetEnvironment(simulator) && swift(>=5.4)
            if #available(iOS 15, *) {
                XCTExpectFailure("Expect to fail on iOS 15 simulator. ref: https://wearezeta.atlassian.net/browse/SQCORE-1188")
            }
        #endif

            guard let encryptionKeys = try? EncryptionKeys.createKeys(for: Account(userName: "", userIdentifier: UUID())) else {
                XCTFail("couldn't create encryption keys")
                return
            }

            try self.syncMOC.enableEncryptionAtRest(encryptionKeys: encryptionKeys, skipMigration: true)

            // WHEN
            let note = self.textNotification(self.oneOnOneConversation, sender: self.sender, text: "Hello", isEphemeral: false)!

            // THEN
           #if targetEnvironment(simulator) && swift(>=5.4)
            if #available(iOS 15, *) {
                XCTExpectFailure("Expect to fail on iOS 15 simulator. ref: https://wearezeta.atlassian.net/browse/SQCORE-1188")
            }
            #endif
            XCTAssertEqual(note.category, .conversationUnderEncryptionAtRestWithMute)
        }
    }

    func testThatItGeneratesCorrectCategoryIfEncryptionAtRestIsEnabledForNormalUser() throws {
        // GIVEN
        try syncMOC.performGroupedAndWait { _ in
        #if targetEnvironment(simulator) && swift(>=5.4)
            if #available(iOS 15, *) {
                XCTExpectFailure("Expect to fail on iOS 15 simulator. ref: https://wearezeta.atlassian.net/browse/SQCORE-1188")
            }
         #endif
            guard let encryptionKeys = try? EncryptionKeys.createKeys(for: Account(userName: "", userIdentifier: UUID())) else {
                XCTFail("couldn't create encryption keys")
                return
            }

            try self.syncMOC.enableEncryptionAtRest(encryptionKeys: encryptionKeys, skipMigration: true)

            let team = Team.insertNewObject(in: self.syncMOC)
            team.name = "Wire Amazing Team"

            let user = ZMUser.selfUser(in: self.syncMOC)
            _ = Member.getOrCreateMember(for: user, in: team, context: self.syncMOC)

            // When
            let note = self.textNotification(self.oneOnOneConversation, sender: self.sender, text: "Hello", isEphemeral: false)!

            // THEN
            XCTAssertEqual(note.category, .conversationUnderEncryptionAtRest)
        }
    }
}
