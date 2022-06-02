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

import Foundation
import XCTest
@testable import WireDataModel

class PBMessageValidationTests: XCTestCase {
    // MARK: Generic Message

    func testThatItCreatesGenericMessageWithValidFields() {
        let text = Text.with {
            $0.content = "Hello hello hello"
        }

        let message = GenericMessage.with {
            text.setContent(on: &$0)
            $0.messageID = "8783C4BD-A5D3-4F6B-8C41-A6E75F12926F"
        }

        XCTAssertNotNil(message.validatingFields())
    }

    func testThatItDoesNotCreateGenericMessageWithInvalidFields() {
        let text = Text.with {
            $0.content = "Hello hello hello"
        }

        let message = GenericMessage.with {
            text.setContent(on: &$0)
            $0.messageID = "nonce"
        }

        XCTAssertNil(message.validatingFields())
    }

    // MARK: Last Read

    func testThatItCreatesLastReadWithValidFields() {
        let lastRead = LastRead.with {
            $0.conversationID = "8783C4BD-A5D3-4F6B-8C41-A6E75F12926F"
            $0.lastReadTimestamp = 25_000
        }

        XCTAssertNotNil(GenericMessage(content: lastRead).validatingFields())
    }

    func testThatItDoesNotCreateLastReadWithInvalidFields() {
        let lastRead = LastRead.with {
            $0.conversationID = "null"
            $0.lastReadTimestamp = 25_000
        }

        XCTAssertNil(GenericMessage(content: lastRead).validatingFields())
    }

    // MARK: Cleared

    func testThatItCreatesClearedWithValidFields() {
        let cleared = Cleared.with {
            $0.conversationID = "8783C4BD-A5D3-4F6B-8C41-A6E75F12926F"
            $0.clearedTimestamp = 25_000
        }

        XCTAssertNotNil(GenericMessage(content: cleared).validatingFields())
    }

    func testThatItDoesNotCreateClearedWithInvalidFields() {
        let cleared = Cleared.with {
            $0.conversationID = "wirewire"
            $0.clearedTimestamp = 25_000
        }

        XCTAssertNil(GenericMessage(content: cleared).validatingFields())
    }

    // MARK: Message Hide

    func testThatItCreatesHideWithValidFields() {
        let messageHide = MessageHide.with {
            $0.conversationID = "8783C4BD-A5D3-4F6B-8C41-A6E75F12926F"
            $0.messageID = "8B496992-E74D-41D2-A2C4-C92EEE777DCE"
        }

        XCTAssertNotNil(GenericMessage(content: messageHide).validatingFields())
    }

    func testThatItDoesNotCreateHideWithInvalidFields() {
        var invalidMessageHide: MessageHide

        invalidMessageHide = MessageHide.with {
            $0.conversationID = ""
            $0.messageID = "8B496992-E74D-41D2-A2C4-C92EEE777DCE"
        }

        XCTAssertNil(GenericMessage(content: invalidMessageHide).validatingFields())

        invalidMessageHide = MessageHide.with {
            $0.conversationID = "8B496992-E74D-41D2-A2C4-C92EEE777DCE"
            $0.messageID = ""
        }

        XCTAssertNil(GenericMessage(content: invalidMessageHide).validatingFields())

        invalidMessageHide = MessageHide.with {
            $0.conversationID = ""
            $0.messageID = ""
        }

        XCTAssertNil(GenericMessage(content: invalidMessageHide).validatingFields())
    }

    // MARK: Message Delete

    func testThatItCreatesMessageDeleteWithValidFields() {
        let messageDelete = MessageDelete.with {
            $0.messageID = "8B496992-E74D-41D2-A2C4-C92EEE777DCE"
        }

        XCTAssertNotNil(GenericMessage(content: messageDelete).validatingFields())
    }

    func testThatItDoesNotCreateMessageDeleteWithInvalidFields() {
        let messageDelete = MessageDelete.with {
            $0.messageID = "invalid"
        }

        XCTAssertNil(GenericMessage(content: messageDelete).validatingFields())
    }

    // MARK: Message Edit

    func testThatItCreatesMessageEditWithValidFields() {

        let messageEdit = MessageEdit.with {
            $0.text = Text.with({ $0.content = "Hello" })
            $0.replacingMessageID = "8B496992-E74D-41D2-A2C4-C92EEE777DCE"
        }

        XCTAssertNotNil(GenericMessage(content: messageEdit).validatingFields())
    }

    func testThatItDoesNotCreateMessageEditWithInvalidFields() {
        let messageEdit = MessageEdit.with {
            $0.text = Text.with({ $0.content = "Hello" })
            $0.replacingMessageID = "N0TAUNIV-ER5A-77YU-NIQU-EID3NTIF1ER!"
        }

        XCTAssertNil(GenericMessage(content: messageEdit).validatingFields())
    }

    // MARK: Confirmation

    func testThatItCreatesConfirmationWithValidFields() {
        let confirmation = Confirmation.with {
            $0.type = .delivered
            $0.firstMessageID = "8B496992-E74D-41D2-A2C4-C92EEE777DCE"
            $0.moreMessageIds = ["54A6E947-1321-42C6-BA99-F407FDF1A229"]
        }

        XCTAssertNotNil(GenericMessage(content: confirmation).validatingFields())
    }

    func testThatItDoesNotCreateConfirmationWithInvalidFields() {
        var confirmation: Confirmation

        confirmation = Confirmation.with {
            $0.type = .delivered
            $0.firstMessageID = "invalid"
            $0.moreMessageIds = ["54A6E947-1321-42C6-BA99-F407FDF1A229"]
        }

        XCTAssertNil(GenericMessage(content: confirmation).validatingFields())

        confirmation = Confirmation.with {
            $0.type = .delivered
            $0.firstMessageID = "8B496992-E74D-41D2-A2C4-C92EEE777DCE"
            $0.moreMessageIds = ["54A6E947-1321-42C6-BA99-F407FDF1A229", "invalid"]
        }

        XCTAssertNil(GenericMessage(content: confirmation).validatingFields())
    }

    // MARK: Reaction

    func testThatItCreatesReactionWithValidFields() {
        let reaction = WireProtos.Reaction.with {
            $0.messageID = "8B496992-E74D-41D2-A2C4-C92EEE777DCE"
            $0.emoji = "🤩"
        }

        XCTAssertNotNil(GenericMessage(content: reaction).validatingFields())
    }

    func testThatItDoesNotCreateReactionWithInvalidFields() {
        let reaction = WireProtos.Reaction.with {
            $0.messageID = "Not-A-UUID"
            $0.emoji = "🤩"
        }

        XCTAssertNil(GenericMessage(content: reaction).validatingFields())
    }

    // MARK: User ID

    func testThatItCreatesUserIDWithValidFields() {
        let userId = Proteus_UserId.with({$0.uuid = NSUUID().data()})

        XCTAssertNotNil(userId.validatingFields())
    }

    func testThatItDoesNotCreateUserIDWithInvalidFields() {
        let userId = Proteus_UserId.with({$0.uuid = Data() })

        XCTAssertNil(userId.validatingFields())
    }

    // MARK: Assets

    func testThatItCreatesMessageWithValidAsset() {
        XCTAssertNotNil(genericMessage(assetId: "asset-id", assetToken: "token", assetDomain: "domain", preview: true))
        XCTAssertNotNil(genericMessage(assetId: "asset-id", assetToken: "token=", assetDomain: "domain", preview: false))

        XCTAssertNotNil(genericMessage(assetId: "3-1-C89D16C3-8FB4-48D7-8EE5-F8D69A2068C8", assetToken: "aV0TGxF3ugpawm3wAYPmew==", assetDomain: "wire.com", preview: true))
        XCTAssertNotNil(genericMessage(assetId: "3-1-c89d16c3-8fb4-48d7-8ee5-f8d69a2068c8", assetToken: "aV0TGxF3ugpawm3wAYPmew==", assetDomain: "wire.com", preview: false))

        XCTAssertNotNil(genericMessage(assetId: "C89D16C3-8FB4-48D7-8EE5-F8D69A2068C8", assetToken: "", assetDomain: "", preview: true))
        XCTAssertNotNil(genericMessage(assetId: "c89d16c3-8fb4-48d7-8ee5-f8d69a2068c8", assetToken: "", assetDomain: "", preview: false))

        XCTAssertNotNil(genericMessage(assetId: "", assetToken: "", assetDomain: "", preview: true))
        XCTAssertNotNil(genericMessage(assetId: "", assetToken: "", assetDomain: "", preview: false))
    }

    func testThatItDoesNotCreateMessageWithInvalidAsset() {
        // Invalid asset ID
        XCTAssertNil(genericMessage(assetId: "asset:id", assetToken: "token", assetDomain: "domain", preview: true))
        XCTAssertNil(genericMessage(assetId: "asset/id", assetToken: "token", assetDomain: "domain", preview: false))
        XCTAssertNil(genericMessage(assetId: "asset.id", assetToken: "token", assetDomain: "domain", preview: true))
        XCTAssertNil(genericMessage(assetId: "asset@id", assetToken: "token", assetDomain: "domain", preview: false))
        XCTAssertNil(genericMessage(assetId: "asset[id", assetToken: "token", assetDomain: "domain", preview: true))
        XCTAssertNil(genericMessage(assetId: "asset`id", assetToken: "token", assetDomain: "domain", preview: false))
        XCTAssertNil(genericMessage(assetId: "asset{id", assetToken: "token", assetDomain: "domain", preview: true))

        // Invalid asset token
        XCTAssertNil(genericMessage(assetId: "asset-id", assetToken: "5@shay_a3wAY4%$@#$@%)!@-pOe==", assetDomain: "wire.com", preview: true))
        XCTAssertNil(genericMessage(assetId: "asset-id", assetToken: "aV0TGxF3ugpawm3wAYPmew===", assetDomain: "wire.com", preview: false))
        XCTAssertNil(genericMessage(assetId: "3-1-C89D16C3-8FB4-48D7-8EE5-F8D69A2068C8", assetToken: "aV0TGxF3ugpawm3wAYPmew=Hello", assetDomain: "wire.com", preview: true))
        XCTAssertNil(genericMessage(assetId: "3-1-c89d16c3-8fb4-48d7-8ee5-f8d69a2068c8", assetToken: "aV0TGxF3ugpawm3wAYPmew==Hello", assetDomain: "wire.com", preview: false))

        // Both
        XCTAssertNil(genericMessage(assetId: "../C89D16C3-8FB4-48D7-8EE5-F8D69A2068C8", assetToken: "token?name=foo", assetDomain: "wire.com", preview: true))
        XCTAssertNil(genericMessage(assetId: "../C89D16C3-8FB4-48D7-8EE5-F8D69A2068C8", assetToken: "token?name=foo", assetDomain: "wire.com", preview: false))
    }

    // MARK: - Utilities

    private func genericMessage(assetId: String, assetToken: String?, assetDomain: String?, preview: Bool) -> GenericMessage? {
        var assetPreview: WireProtos.Asset.Preview!

        if preview {
            let metadata = WireProtos.Asset.ImageMetaData.with {
                $0.width = 1000
                $0.height = 1000
                $0.tag = "tag"
            }

            assetPreview = WireProtos.Asset.Preview.with {
                $0.size = 1000
                $0.mimeType = "image/png"
                $0.remote = assetRemoteData(id: assetId, token: assetToken!, domain: assetDomain!)
                $0.image = metadata
            }
        }

        let asset = WireProtos.Asset.with {
            if preview {
                $0.preview = assetPreview
            }
            $0.uploaded = assetRemoteData(id: assetId, token: assetToken!, domain: assetDomain!)
        }

        return GenericMessage(content: asset).validatingFields()
    }

    private func assetRemoteData(id: String, token: String, domain: String) -> WireProtos.Asset.RemoteData {
        return WireProtos.Asset.RemoteData.with {
            $0.assetID = id
            $0.assetToken = token
            $0.assetDomain = domain
            $0.otrKey = Data("pFHd6iVTvOVP2wFAd2yVlA==".utf8)
            $0.sha256 = Data("8fab1b98a5b5ac2b07f0f77c739980bd4c895db23a09a3bed9ecec584d3ed3e0".utf8)
            $0.encryption = .aesCbc
        }
    }

}

class ModelValidationTests: XCTestCase {

    // MARK: Generic Message

    func testThatItCreatesGenericMessageWithValidFields() {

        let text = Text(content: "Hello hello hello")
        var genericMessage = GenericMessage(content: text)
        genericMessage.messageID = "8783C4BD-A5D3-4F6B-8C41-A6E75F12926F"
        let message = genericMessage.validatingFields()

        XCTAssertNotNil(message)
    }

    func testThatItDoesNotCreateGenericMessageWithInvalidFields() {

        let text = Text(content: "Hieeee!")
        var genericMessage = GenericMessage(content: text)
        genericMessage.messageID = "nonce"
        let message = genericMessage.validatingFields()

        XCTAssertNil(message)
    }

    // MARK: Last Read

    func testThatItCreatesLastReadWithValidFields() {

        let lastRead = LastRead(conversationID: UUID(uuidString: "8783C4BD-A5D3-4F6B-8C41-A6E75F12926F")!, lastReadTimestamp: Date(timeIntervalSince1970: 25_000))
        let message = GenericMessage(content: lastRead).validatingFields()

        XCTAssertNotNil(message)
    }

    func testThatItDoesNotCreateLastReadWithInvalidFields() {

        let lastRead = LastRead.with {
            $0.lastReadTimestamp = 25000
        }
        let message = GenericMessage(content: lastRead).validatingFields()
        XCTAssertNil(message)
    }

    // MARK: Cleared

    func testThatItCreatesClearedWithValidFields() {

        let cleared = Cleared(timestamp: Date(timeIntervalSince1970: 25000), conversationID: UUID(uuidString: "8783C4BD-A5D3-4F6B-8C41-A6E75F12926F")!)
        let message = GenericMessage(content: cleared).validatingFields()

        XCTAssertNotNil(message)
    }

    func testThatItDoesNotCreateClearedWithInvalidFields() {

        let cleared = Cleared.with {
            $0.clearedTimestamp = 25000
            $0.conversationID = "wirewire"
        }
        let message = GenericMessage(content: cleared).validatingFields()

        XCTAssertNil(message)
    }

    // MARK: Message Hide

    func testThatItCreatesHideWithValidFields() {

        let messageHide = MessageHide(conversationId: UUID(uuidString: "8783C4BD-A5D3-4F6B-8C41-A6E75F12926F")!, messageId: UUID(uuidString: "8B496992-E74D-41D2-A2C4-C92EEE777DCE")!)
        let message = GenericMessage(content: messageHide).validatingFields()

        XCTAssertNotNil(message)
    }

    func testThatItDoesNotCreateHideWithInvalidFields() {

        let invalidConversation = MessageHide.with {
            $0.conversationID = ""
            $0.messageID = "8B496992-E74D-41D2-A2C4-C92EEE777DCE"
        }
        let invalidConversationHide = GenericMessage(content: invalidConversation).validatingFields()
        XCTAssertNil(invalidConversationHide)

        let invalidMessage = MessageHide.with {
            $0.conversationID = "8B496992-E74D-41D2-A2C4-C92EEE777DCE"
            $0.messageID = ""
        }
        let invalidMessageHide = GenericMessage(content: invalidMessage).validatingFields()
        XCTAssertNil(invalidMessageHide)

        let invalidHide = MessageHide.with {
            $0.conversationID = ""
            $0.messageID = ""
        }
        let invalidHideMessage = GenericMessage(content: invalidHide).validatingFields()
        XCTAssertNil(invalidHideMessage)
    }

    // MARK: Message Delete

    func testThatItCreatesMessageDeleteWithValidFields() {

        let delete = MessageDelete(messageId: UUID(uuidString: "8B496992-E74D-41D2-A2C4-C92EEE777DCE")!)
        let message = GenericMessage(content: delete).validatingFields()
        XCTAssertNotNil(message)
    }

    func testThatItDoesNotCreateMessageDeleteWithInvalidFields() {

        let delete = MessageDelete.with {
            $0.messageID = "invalid"
        }
        let message = GenericMessage(content: delete).validatingFields()
        XCTAssertNil(message)
    }

    // MARK: Message Edit

    func testThatItCreatesMessageEditWithValidFields() {

        let text = Text(content: "Hello")
        let messageEdit = MessageEdit(replacingMessageID: UUID(uuidString: "8B496992-E74D-41D2-A2C4-C92EEE777DCE")!,
                                      text: text)
        let message = GenericMessage(content: messageEdit).validatingFields()
        XCTAssertNotNil(message)
    }

    func testThatItDoesNotCreateMessageEditWithInvalidFields() {

        let text = Text(content: "Hello")
        let messageEdit = MessageEdit.with {
            $0.replacingMessageID = "N0TAUNIV-ER5A-77YU-NIQU-EID3NTIF1ER!"
            $0.text = text
        }
        let message = GenericMessage(content: messageEdit).validatingFields()
        XCTAssertNil(message)
    }

    // MARK: Message Confirmation

    func testThatItCreatesConfirmationWithValidFields() {

        let confirmation = Confirmation.with {
            $0.type = .delivered
            $0.firstMessageID = "8B496992-E74D-41D2-A2C4-C92EEE777DCE"
            $0.moreMessageIds = ["54A6E947-1321-42C6-BA99-F407FDF1A229"]
        }
        let message = GenericMessage(content: confirmation).validatingFields()
        XCTAssertNotNil(message)
    }

    func testThatItDoesNotCreateConfirmationWithInvalidFields() {

        let invalidFirstID = Confirmation.with {
            $0.type = .delivered
            $0.firstMessageID = "invalid"
            $0.moreMessageIds = ["54A6E947-1321-42C6-BA99-F407FDF1A229"]
        }
        let invalidFirstIDMessage = GenericMessage(content: invalidFirstID).validatingFields()
        XCTAssertNil(invalidFirstIDMessage)

        let invalidArray = Confirmation.with {
            $0.type = .delivered
            $0.firstMessageID = "8B496992-E74D-41D2-A2C4-C92EEE777DCE"
            $0.moreMessageIds = ["54A6E947-1321-42C6-BA99-F407FDF1A229", "150"]
        }
        let invalidArrayMessage = GenericMessage(content: invalidArray).validatingFields()
        XCTAssertNil(invalidArrayMessage)
    }

    // MARK: Reaction

    func testThatItCreatesReactionWithValidFields() {

        let reaction = WireProtos.Reaction.createReaction(emoji: "🤩", messageID: UUID(uuidString: "8B496992-E74D-41D2-A2C4-C92EEE777DCE")!)
        let message = GenericMessage(content: reaction).validatingFields()
        XCTAssertNotNil(message)
    }

    func testThatItDoesNotCreateReactionWithInvalidFields() {

        let reaction = WireProtos.Reaction.with {
            $0.emoji = "🤩"
            $0.messageID = "Not-A-UUID"
        }
        let message = GenericMessage(content: reaction).validatingFields()
        XCTAssertNil(message)
    }

    // MARK: User ID

    func testThatItCreatesUserIDWithValidFields() {

        let userId = Proteus_UserId.with { $0.uuid = NSUUID().data() }

        XCTAssertNotNil(userId.validatingFields())
    }

    func testThatItDoesNotCreateUserIDWithInvalidFields() {

        let userId = Proteus_UserId.with { $0.uuid = Data() }

        XCTAssertNil(userId.validatingFields())
    }

    // MARK: - Assets

    func testThatItCreatesMessageWithValidAsset() {

        XCTAssertNotNil(genericMessage(assetId: "asset-id", assetToken: "token", assetDomain: "wire.com", preview: true))
        XCTAssertNotNil(genericMessage(assetId: "asset-id", assetToken: "token=", assetDomain: "wire.com", preview: false))

        XCTAssertNotNil(genericMessage(assetId: "3-1-C89D16C3-8FB4-48D7-8EE5-F8D69A2068C8", assetToken: "aV0TGxF3ugpawm3wAYPmew==", assetDomain: "wire.com", preview: true))
        XCTAssertNotNil(genericMessage(assetId: "3-1-c89d16c3-8fb4-48d7-8ee5-f8d69a2068c8", assetToken: "aV0TGxF3ugpawm3wAYPmew==", assetDomain: "wire.com", preview: false))

        XCTAssertNotNil(genericMessage(assetId: "C89D16C3-8FB4-48D7-8EE5-F8D69A2068C8", assetToken: "", assetDomain: "wire.com", preview: true))
        XCTAssertNotNil(genericMessage(assetId: "c89d16c3-8fb4-48d7-8ee5-f8d69a2068c8", assetToken: "", assetDomain: "wire.com", preview: false))

        XCTAssertNotNil(genericMessage(assetId: "", assetToken: "", assetDomain: "wire.com", preview: true))
        XCTAssertNotNil(genericMessage(assetId: "", assetToken: "", assetDomain: "wire.com", preview: false))

    }

    func testThatItDoesNotCreateMessageWithInvalidAsset() {

        // Invalid asset ID
        XCTAssertNil(genericMessage(assetId: "asset:id", assetToken: "token", assetDomain: "wire.com", preview: true))
        XCTAssertNil(genericMessage(assetId: "asset/id", assetToken: "token", assetDomain: "wire.com", preview: false))
        XCTAssertNil(genericMessage(assetId: "asset.id", assetToken: "token", assetDomain: "wire.com", preview: true))
        XCTAssertNil(genericMessage(assetId: "asset@id", assetToken: "token", assetDomain: "wire.com", preview: false))
        XCTAssertNil(genericMessage(assetId: "asset[id", assetToken: "token", assetDomain: "wire.com", preview: true))
        XCTAssertNil(genericMessage(assetId: "asset`id", assetToken: "token", assetDomain: "wire.com", preview: false))
        XCTAssertNil(genericMessage(assetId: "asset{id", assetToken: "token", assetDomain: "wire.com", preview: true))

        // Invalid asset token
        XCTAssertNil(genericMessage(assetId: "asset-id", assetToken: "5@shay_a3wAY4%$@#$@%)!@-pOe==", assetDomain: "wire.com", preview: true))
        XCTAssertNil(genericMessage(assetId: "asset-id", assetToken: "aV0TGxF3ugpawm3wAYPmew===", assetDomain: "wire.com", preview: false))
        XCTAssertNil(genericMessage(assetId: "3-1-C89D16C3-8FB4-48D7-8EE5-F8D69A2068C8", assetToken: "aV0TGxF3ugpawm3wAYPmew=Hello", assetDomain: "wire.com", preview: true))
        XCTAssertNil(genericMessage(assetId: "3-1-c89d16c3-8fb4-48d7-8ee5-f8d69a2068c8", assetToken: "aV0TGxF3ugpawm3wAYPmew==Hello", assetDomain: "wire.com", preview: false))

        // Both
        XCTAssertNil(genericMessage(assetId: "../C89D16C3-8FB4-48D7-8EE5-F8D69A2068C8", assetToken: "token?name=foo", assetDomain: "wire.com", preview: true))
        XCTAssertNil(genericMessage(assetId: "../C89D16C3-8FB4-48D7-8EE5-F8D69A2068C8", assetToken: "token?name=foo", assetDomain: "wire.com", preview: false))

    }

    // MARK: - Utilities

    private func genericMessage(assetId: String, assetToken: String?, assetDomain: String?, preview: Bool) -> GenericMessage? {

        var asset = WireProtos.Asset()

        if preview {
            let imageMetaData = WireProtos.Asset.ImageMetaData.with {
                $0.tag = "tag"
                $0.width = 1000
                $0.height = 1000
            }

            let remoteData = WireProtos.Asset.RemoteData.with {
                $0.assetID = assetId
                $0.assetToken = assetToken ?? ""
            }
            let preview = WireProtos.Asset.Preview(size: 1000,
                                                   mimeType: "image/png",
                                                   remoteData: remoteData,
                                                   imageMetadata: imageMetaData)
            asset.preview = preview
        }

        asset.uploaded = WireProtos.Asset.RemoteData.with {
            $0.assetID = assetId
            $0.assetToken = assetToken ?? ""
            $0.assetDomain = assetDomain ?? ""
        }

        return GenericMessage(content: asset).validatingFields()
    }
}
