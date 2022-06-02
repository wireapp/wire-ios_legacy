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

import WireTesting
import WireDataModel
@testable import WireSyncEngine

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

        let event = createUpdateEvent(UUID.create(), conversationID: conversation.remoteIdentifier!, genericMessage: GenericMessage(content: Text(content: text ?? "Hello Hello!", mentions: mentions, linkPreviews: [], replyingTo: quotedMessage), nonce: UUID.create(), expiresAfterTimeInterval: expiresAfter), senderID: sender.remoteIdentifier)

        return ZMLocalNotification(event: event, conversation: conversation, managedObjectContext: uiMOC)
    }

    func bodyForNote(_ conversation: ZMConversation, sender: ZMUser, text: String? = nil, isEphemeral: Bool = false) -> String {
        let note = textNotification(conversation, sender: sender, text: text, isEphemeral: isEphemeral)
        XCTAssertNotNil(note)
        return note!.body
    }

    // MARK: Tests

    func testThatItShowsDefaultAlertBodyWhenHidePreviewSettingIsTrue() {

        // given
        sender.name = "Super User"
        let note1 = textNotification(oneOnOneConversation, sender: sender)
        XCTAssertEqual(note1?.content.title, "Super User")
        XCTAssertEqual(note1?.content.body, "Hello Hello!")

        // when
        let moc = oneOnOneConversation.managedObjectContext!
        let key = LocalNotificationDispatcher.ZMShouldHideNotificationContentKey
        moc.setPersistentStoreMetadata(true as NSNumber, key: key)
        let setting = moc.persistentStoreMetadata(forKey: key) as? NSNumber
        XCTAssertEqual(setting?.boolValue, true)
        let note2 = textNotification(oneOnOneConversation, sender: sender)

        // then
        XCTAssertEqual(note2?.content.title, "")
        XCTAssertEqual(note2?.content.body, "New message")
    }

    func testThatItShowsShowsEphemeralStringEvenWhenHidePreviewSettingIsTrue() {
        // given
        let note1 = textNotification(oneOnOneConversation, sender: sender, isEphemeral: true)
        XCTAssertEqual(note1?.content.title, "Someone")
        XCTAssertEqual(note1?.content.body, "Sent a message")

        // when
        let moc = oneOnOneConversation.managedObjectContext!
        let key = LocalNotificationDispatcher.ZMShouldHideNotificationContentKey
        moc.setPersistentStoreMetadata(true as NSNumber, key: key)
        let setting = moc.persistentStoreMetadata(forKey: key) as? NSNumber
        XCTAssertEqual(setting?.boolValue, true)
        let note2 = textNotification(oneOnOneConversation, sender: sender, isEphemeral: true)

        // then
        XCTAssertEqual(note2?.content.title, "Someone")
        XCTAssertEqual(note2?.content.body, "Sent a message")
    }

    func testThatItDoesNotSetThreadIdentifierForEphemeralMessages() {
        // given
        let note = textNotification(oneOnOneConversation, sender: sender, isEphemeral: true)

        // then
        XCTAssertNotNil(note)
        XCTAssertEqual(note!.content.title, "Someone")
        XCTAssertEqual(note!.content.body, "Sent a message")
        XCTAssertEqual(note!.content.threadIdentifier, "")
    }

    func testItCreatesMessageNotificationsCorrectly() {

        //    "push.notification.add.message.oneonone" = "%1$@";
        //    "push.notification.add.message.group" = "%1$@: %2$@";
        //    "push.notification.add.message.group.noconversationname" = "%1$@ in a conversation: %2$@";

        XCTAssertEqual(bodyForNote(oneOnOneConversation, sender: sender), "Hello Hello!")
        XCTAssertEqual(bodyForNote(groupConversation, sender: sender), "Super User: Hello Hello!")
        XCTAssertEqual(bodyForNote(groupConversationWithoutUserDefinedName, sender: sender), "Super User: Hello Hello!")
        XCTAssertEqual(bodyForNote(groupConversationWithoutName, sender: sender), "Super User in a conversation: Hello Hello!")
        XCTAssertEqual(bodyForNote(invalidConversation, sender: sender), "Super User in a conversation: Hello Hello!")
    }

    func testThatObfuscatesNotificationsForEphemeralMessages() {
        [oneOnOneConversation, groupConversation, groupConversationWithoutUserDefinedName, groupConversationWithoutName, invalidConversation].forEach {
            let note = textNotification($0!, sender: sender, isEphemeral: true)
            XCTAssertEqual(note?.title, "Someone")
            XCTAssertEqual(note?.body, "Sent a message")
        }
    }

    func testThatItDoesNotDuplicatePercentageSignsInTextAndConversationName() {
        XCTAssertEqual(bodyForNote(groupConversation, sender: sender, text: "Today we grew by 100%"), "Super User: Today we grew by 100%")
    }

    func testThatItSavesTheSenderOfANotification() {

        // given
        let note = textNotification(oneOnOneConversation, sender: sender)!

        // then
        XCTAssertEqual(note.senderID, sender.remoteIdentifier)
    }

    func testThatItSavesTheConversationOfANotification() {

        // given
        let note = textNotification(oneOnOneConversation, sender: sender)!

        // then
        XCTAssertEqual(note.conversationID, oneOnOneConversation.remoteIdentifier)
    }

    func testThatItSavesTheMessageNonce() {

        // given
        let event = createUpdateEvent(UUID.create(), conversationID: oneOnOneConversation.remoteIdentifier!, genericMessage: GenericMessage(content: Text(content: "Hello Hello!"), nonce: UUID.create()), senderID: sender.remoteIdentifier)

        let note = ZMLocalNotification(event: event, conversation: oneOnOneConversation, managedObjectContext: syncMOC)

        // then
        XCTAssertEqual(note!.messageNonce, event.messageNonce)
        XCTAssertEqual(note!.selfUserID, self.selfUser.remoteIdentifier)
    }

    func testThatItDoesNotCreateANotificationWhenTheConversationIsSilenced() {

        // given
        groupConversation.mutedMessageTypes = .all

        // when
        let note = textNotification(groupConversation, sender: sender)

        // then
        XCTAssertNil(note)
    }

    // MARK: Mentions

    func testThatItDoesNotCreateANotificationWhenTheConversationIsSilencedAndOtherUserIsMentioned() {
        teamTest {
            // Given
            groupConversation.mutedMessageTypes = .all

            // When
            let note = textNotification(groupConversation, sender: sender, mentionedUser: sender)

            // Then
            XCTAssertNil(note)
        }
    }

    func testThatItDoesNotCreateANotificationWhenTheConversationIsFullySilencedAndSelfUserIsMentioned() {
        teamTest {
            // Given
            groupConversation.mutedMessageTypes = .all

            // When
            let note = textNotification(groupConversation, sender: sender, mentionedUser: selfUser)

            // Then
            XCTAssertNil(note)
        }
    }

    func testThatItDoesCreateANotificationWhenTheConversationIsSilencedAndSelfUserIsMentioned() {
        teamTest {
            // Given
            groupConversation.mutedMessageTypes = .regular

            // When
            let note = textNotification(groupConversation, sender: sender, mentionedUser: selfUser)

            // Then
            XCTAssertNotNil(note)
        }
    }

    func testThatItUsesCorrectBodyWhenSelfUserIsMentioned() {
        // Given & When
        let note = textNotification(groupConversation, sender: sender, mentionedUser: selfUser)

        // Then
        XCTAssertEqual(note?.body, "Mention from Super User: Hello Hello!")
    }

    func testThatItUsesCorrectBodyWhenSelfUserIsMentioned_UserWithoutName() {
        // Given
        sender.name = nil

        // When
        let note = textNotification(groupConversation, sender: sender, mentionedUser: selfUser)

        // Then
        XCTAssertEqual(note?.body, "New mention: Hello Hello!")
    }

    func testThatItUsesCorrectBodyWhenSelfUserIsMentioned_NoConversationName() {
        // Given & When
        let note = textNotification(groupConversationWithoutName, sender: sender, mentionedUser: selfUser)

        // Then
        XCTAssertEqual(note?.body, "Super User mentioned you in a conversation: Hello Hello!")
    }

    func testThatItUsesCorrectBodyWhenSelfUserIsMentioned_UserWithoutNameNoConversationName() {
        // Given
        sender.name = nil

        // When
        let note = textNotification(groupConversation, sender: sender, mentionedUser: selfUser)

        // Then
        XCTAssertEqual(note?.body, "New mention: Hello Hello!")
    }

    func testThatItUsesCorrectBodyWhenSelfUserIsMentioned_OneOnOne() {
        // Given & When
        let note = textNotification(oneOnOneConversation, sender: sender, mentionedUser: selfUser)

        // Then
        XCTAssertEqual(note?.body, "Mention: Hello Hello!")
    }

    func testThatItUsesCorrectBodyWhenSelfUserIsMentioned_OneOnOne_NoUserName() {
        // Given
        sender.name = nil

        // Given
        let note = textNotification(oneOnOneConversation, sender: sender, mentionedUser: selfUser)

        // Then
        XCTAssertEqual(note?.body, "New mention: Hello Hello!")
    }

    func testThatItUsesCorrectBodyWhenSelfUserIsMentioned_Ephemeral() {
        // Given & When
        let note = textNotification(groupConversation, sender: sender, mentionedUser: selfUser, isEphemeral: true)

        // Then
        XCTAssertEqual(note?.title, "Someone")
        XCTAssertEqual(note?.body, "Mentioned you")
    }

    // MARK: Replies

    func testThatItDoesNotCreateANotificationWhenTheConversationIsFullySilencedAndSelfUserIsQuoted() {
        teamTest {
            // Given
            groupConversation.mutedMessageTypes = .all

            // When
            let note = textNotification(groupConversation, sender: sender, quotedUser: selfUser)

            // Then
            XCTAssertNil(note)
        }
    }

    func testThatItDoesNotCreateANotificationWhenTheConversationIsSilencedAndOtherUserIsQuoted() {
        teamTest {
            // Given
            groupConversation.mutedMessageTypes = .regular

            // When
            let note = textNotification(groupConversation, sender: sender, quotedUser: otherUser1)

            // Then
            XCTAssertNil(note)
        }
    }

    func testThatItCreatesANotificationWhenTheConversationIsSilencedAndSelfUserIsQuoted() {
        teamTest {
            // Given
            groupConversation.mutedMessageTypes = .regular

            // When
            let note = textNotification(groupConversation, sender: sender, quotedUser: selfUser)

            // Then
            XCTAssertNotNil(note)
        }
    }

    func testThatItCreatesCorrectBodyWhenSelfIsQuoted() {
        // Given & When
        let note = textNotification(groupConversation, sender: sender, quotedUser: selfUser)

        // Then
        XCTAssertEqual(note?.body, "Reply from Super User: Hello Hello!")
    }

    func testThatItCreatesCorrectBodyWhenSelfIsQuoted_NoUserName() {
        // Given
        sender.name = nil

        // When
        let note = textNotification(groupConversation, sender: sender, quotedUser: selfUser)

        // Then
        XCTAssertEqual(note?.body, "New reply: Hello Hello!")
    }

    func testThatItCreatesCorrectBodyWhenSelfIsQuoted_NoConversationName() {
        // Given & When
        let note = textNotification(groupConversationWithoutName, sender: sender, quotedUser: selfUser)

        // Then
        XCTAssertEqual(note?.body, "Super User replied to you in a conversation: Hello Hello!")
    }

    func testThatItCreatesCorrectBodyWhenSelfIsQuoted_NoUserName_NoConversationName() {
        // Given
        sender.name = nil

        // When
        let note = textNotification(groupConversationWithoutName, sender: sender, quotedUser: selfUser)

        // Then
        XCTAssertEqual(note?.body, "New reply: Hello Hello!")
    }

    func testThatItCreatesCorrectBodyWhenSelfIsQuoted_OneOnOne() {
        // Given & When
        let note = textNotification(oneOnOneConversation, sender: sender, quotedUser: selfUser)

        // Then
        XCTAssertEqual(note?.body, "Reply: Hello Hello!")
    }

    func testThatItCreatesCorrectBodyWhenSelfIsQuoted_OneOnOne_NoUserName() {
        // Given
        sender.name = nil

        // When
        let note = textNotification(oneOnOneConversation, sender: sender, quotedUser: selfUser)

        // Then
        XCTAssertEqual(note?.body, "New reply: Hello Hello!")
    }

    func testThatItCreatesCorrectBodyWhenSelfIsQuoted_Ephemeral() {
        // Given & When
        let note = textNotification(groupConversation, sender: sender, quotedUser: selfUser, isEphemeral: true)

        // Then
        XCTAssertEqual(note?.title, "Someone")
        XCTAssertEqual(note?.body, "Replied to you")
    }

    func testThatItCreatesCorrectBodyWhenOtherIsQuoted() {
        // Given & When
        let note = textNotification(groupConversation, sender: sender, quotedUser: sender)

        // Then
        XCTAssertEqual(note?.body, "Super User: Hello Hello!")
    }

    func testThatItPrioritizesMentionsOverReply() {
        // Given & When
        let note = textNotification(groupConversation, sender: sender, mentionedUser: selfUser, quotedUser: selfUser)

        // Then
        XCTAssertEqual(note?.body, "Mention from Super User: Hello Hello!")
    }

    // MARK: Misc

    func testThatItAddsATitleIfTheUserIsPartOfATeam() {

        // given
        let team = Team.insertNewObject(in: self.uiMOC)
        team.name = "Wire Amazing Team"
        team.remoteIdentifier = UUID.create()
        let user = ZMUser.selfUser(in: self.uiMOC)
        self.performPretendingUiMocIsSyncMoc {
            _ = Member.getOrCreateMember(for: user, in: team, context: self.uiMOC)
        }
        user.teamIdentifier = team.remoteIdentifier
        self.uiMOC.saveOrRollback()
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // when
        let note = self.textNotification(self.oneOnOneConversation, sender: self.sender)

        // then
        XCTAssertNotNil(note)
        XCTAssertEqual(note!.title, "Super User in \(team.name!)")
    }

    func testThatItDoesNotAddATitleIfTheUserIsNotPartOfATeam() {
        // when
        let note = self.textNotification(self.oneOnOneConversation, sender: self.sender)

        // then
        XCTAssertNotNil(note)
        XCTAssertEqual(note!.title, "Super User")
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
        return ZMLocalNotification(event: event, conversation: conversation, managedObjectContext: uiMOC)
    }

    func bodyForImageNote(_ conversation: ZMConversation, sender: ZMUser, text: String? = nil, isEphemeral: Bool = false) -> String {
        let note = imageNote(conversation, sender: sender, text: text, isEphemeral: isEphemeral)
        XCTAssertNotNil(note)
        return note!.body
    }

    // MARK: Tests

    func testItCreatesImageNotificationsCorrectly() {
        XCTAssertEqual(bodyForImageNote(oneOnOneConversation, sender: sender), "Shared a picture")
        XCTAssertEqual(bodyForImageNote(groupConversation, sender: sender), "Super User shared a picture")
        XCTAssertEqual(bodyForImageNote(groupConversationWithoutUserDefinedName, sender: sender), "Super User shared a picture")
        XCTAssertEqual(bodyForImageNote(groupConversationWithoutName, sender: sender), "Super User shared a picture in a conversation")
        XCTAssertEqual(bodyForImageNote(invalidConversation, sender: sender), "Super User shared a picture in a conversation")
    }

    func testThatObfuscatesNotificationsForEphemeralImageMessages() {
        [oneOnOneConversation, groupConversation, groupConversationWithoutUserDefinedName, groupConversationWithoutName, invalidConversation].forEach {
            let note = imageNote($0!, sender: sender, isEphemeral: true)
            XCTAssertEqual(note?.title, "Someone")
            XCTAssertEqual(note?.body, "Sent a message")
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
        return ZMLocalNotification(event: event, conversation: conversation, managedObjectContext: uiMOC)

    }

    func bodyForAssetNote(_ fileType: FileType, conversation: ZMConversation, sender: ZMUser, isEphemeral: Bool = false) -> String {
        let note = assetNote(fileType, conversation: conversation, sender: sender, isEphemeral: isEphemeral)
        XCTAssertNotNil(note)
        return note!.body
    }

    // MARK: Tests

    func testThatItCreatesFileAddNotificationsCorrectly() {
        XCTAssertEqual(bodyForAssetNote(.txt, conversation: oneOnOneConversation, sender: sender), "Shared a file")
        XCTAssertEqual(bodyForAssetNote(.txt, conversation: groupConversation, sender: sender), "Super User shared a file")
        XCTAssertEqual(bodyForAssetNote(.txt, conversation: groupConversationWithoutUserDefinedName, sender: sender), "Super User shared a file")
        XCTAssertEqual(bodyForAssetNote(.txt, conversation: groupConversationWithoutName, sender: sender), "Super User shared a file in a conversation")
        XCTAssertEqual(bodyForAssetNote(.txt, conversation: invalidConversation, sender: sender), "Super User shared a file in a conversation")
    }

    func testThatItCreatesVideoAddNotificationsCorrectly() {
        XCTAssertEqual(bodyForAssetNote(.video, conversation: oneOnOneConversation, sender: sender), "Shared a video")
        XCTAssertEqual(bodyForAssetNote(.video, conversation: groupConversation, sender: sender), "Super User shared a video")
        XCTAssertEqual(bodyForAssetNote(.video, conversation: groupConversationWithoutUserDefinedName, sender: sender), "Super User shared a video")
        XCTAssertEqual(bodyForAssetNote(.video, conversation: groupConversationWithoutName, sender: sender), "Super User shared a video in a conversation")
        XCTAssertEqual(bodyForAssetNote(.video, conversation: invalidConversation, sender: sender), "Super User shared a video in a conversation")
    }

    func testThatItCreatesEphemeralFileAddNotificationsCorrectly() {
        [oneOnOneConversation, groupConversation, groupConversationWithoutUserDefinedName, groupConversationWithoutName, invalidConversation].forEach {
            let note = assetNote(.txt, conversation: $0!, sender: sender, isEphemeral: true)
            XCTAssertEqual(note?.title, "Someone")
            XCTAssertEqual(note?.body, "Sent a message")
        }
    }

    func testThatItCreatesEphemeralVideoAddNotificationsCorrectly() {
        [oneOnOneConversation, groupConversation, groupConversationWithoutUserDefinedName, groupConversationWithoutName, invalidConversation].forEach {
            let note = assetNote(.video, conversation: $0!, sender: sender, isEphemeral: true)
            XCTAssertEqual(note?.title, "Someone")
            XCTAssertEqual(note?.body, "Sent a message")
        }
    }

    func testThatItCreatesAudioNotificationsCorrectly() {
        XCTAssertEqual(bodyForAssetNote(.audio, conversation: oneOnOneConversation, sender: sender), "Shared an audio message")
        XCTAssertEqual(bodyForAssetNote(.audio, conversation: groupConversation, sender: sender), "Super User shared an audio message")
        XCTAssertEqual(bodyForAssetNote(.audio, conversation: groupConversationWithoutUserDefinedName, sender: sender), "Super User shared an audio message")
        XCTAssertEqual(bodyForAssetNote(.audio, conversation: groupConversationWithoutName, sender: sender), "Super User shared an audio message in a conversation")
        XCTAssertEqual(bodyForAssetNote(.audio, conversation: invalidConversation, sender: sender), "Super User shared an audio message in a conversation")
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
        return ZMLocalNotification(event: event, conversation: conversation, managedObjectContext: uiMOC)
    }

    func bodyForKnockNote(_ conversation: ZMConversation, sender: ZMUser, isEphemeral: Bool = false) -> String {
        let note = knockNote(conversation, sender: sender, isEphemeral: isEphemeral)
        XCTAssertNotNil(note)
        return note!.body
    }

    // MARK: Tests

    func testThatItCreatesKnockNotificationsCorrectly() {
        XCTAssertEqual(bodyForKnockNote(oneOnOneConversation, sender: sender), "pinged")
        XCTAssertEqual(bodyForKnockNote(groupConversation, sender: sender), "Super User pinged")
        XCTAssertEqual(bodyForKnockNote(groupConversationWithoutUserDefinedName, sender: sender), "Super User pinged")
    }

    func testThatItCreatesEphemeralKnockNotificationsCorrectly() {
        [oneOnOneConversation, groupConversation, groupConversationWithoutUserDefinedName, groupConversationWithoutName, invalidConversation].forEach {
            let note = knockNote($0!, sender: sender, isEphemeral: true)
            XCTAssertEqual(note?.title, "Someone")
            XCTAssertEqual(note?.body, "Sent a message")
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
        let message = try! oneOnOneConversation.appendText(content: "Foo") as! ZMClientMessage
        message.markAsSent()
        let note = editNote(message, sender: sender, text: "Edited Text")
        XCTAssertNil(note)
    }

}

// MARK: - Categories

extension ZMLocalNotificationTests_Message {

    func testThatItGeneratesTheNotificationWithoutMuteInTheTeam() {
        // GIVEN
        let team = Team.insertNewObject(in: self.uiMOC)
        team.name = "Wire Amazing Team"
        let user = ZMUser.selfUser(in: self.uiMOC)
        self.performPretendingUiMocIsSyncMoc {
            _ = Member.getOrCreateMember(for: user, in: team, context: self.uiMOC)
        }
        self.uiMOC.saveOrRollback()

        // WHEN
        let note = textNotification(self.oneOnOneConversation, sender: sender, text: "Hello", isEphemeral: false)!

        // THEN
        XCTAssertEqual(note.category, .conversationWithLike)

    }

    func testThatItGeneratesTheNotificationWithMuteForNormalUser() {
        // WHEN
        let note = textNotification(oneOnOneConversation, sender: sender, text: "Hello", isEphemeral: false)!

        // THEN
        XCTAssertEqual(note.category, .conversationWithLikeAndMute)
    }

    func testThatItGeneratesCorrectCategoryIfEncryptionAtRestIsEnabledForTeamUser() throws {
        // GIVEN
#if targetEnvironment(simulator) && swift(>=5.4)
        if #available(iOS 15, *) {
            XCTExpectFailure("Expect to fail on iOS 15 simulator. ref: https://wearezeta.atlassian.net/browse/SQCORE-1188")
        }
#endif

        let encryptionKeys = try EncryptionKeys.createKeys(for: Account(userName: "", userIdentifier: UUID()))
        try uiMOC.enableEncryptionAtRest(encryptionKeys: encryptionKeys, skipMigration: true)

        // WHEN
        let note = textNotification(oneOnOneConversation, sender: sender, text: "Hello", isEphemeral: false)!

        // THEN
#if targetEnvironment(simulator) && swift(>=5.4)
        if #available(iOS 15, *) {
            XCTExpectFailure("Expect to fail on iOS 15 simulator. ref: https://wearezeta.atlassian.net/browse/SQCORE-1188")
        }
#endif
        XCTAssertEqual(note.category, .conversationUnderEncryptionAtRestWithMute)
    }

    func testThatItGeneratesCorrectCategoryIfEncryptionAtRestIsEnabledForNormalUser() throws {
        // GIVEN
#if targetEnvironment(simulator) && swift(>=5.4)
        if #available(iOS 15, *) {
            XCTExpectFailure("Expect to fail on iOS 15 simulator. ref: https://wearezeta.atlassian.net/browse/SQCORE-1188")
        }
#endif
        let encryptionKeys = try EncryptionKeys.createKeys(for: Account(userName: "", userIdentifier: UUID()))
        try uiMOC.enableEncryptionAtRest(encryptionKeys: encryptionKeys, skipMigration: true)

        let team = Team.insertNewObject(in: uiMOC)
        team.name = "Wire Amazing Team"

        let user = ZMUser.selfUser(in: uiMOC)
        self.performPretendingUiMocIsSyncMoc {
            _ = Member.getOrCreateMember(for: user, in: team, context: self.uiMOC)
        }

        uiMOC.saveOrRollback()

        // When
        let note = textNotification(oneOnOneConversation, sender: sender, text: "Hello", isEphemeral: false)!

        // THEN
        XCTAssertEqual(note.category, .conversationUnderEncryptionAtRest)
    }

}
