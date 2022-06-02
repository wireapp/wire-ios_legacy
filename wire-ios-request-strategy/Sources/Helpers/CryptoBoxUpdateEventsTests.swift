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

import Foundation
import XCTest
import WireDataModel
import WireProtos
import WireCryptobox

class CryptoboxUpdateEventsTests: MessagingTestBase {

    func testThatItCanDecryptOTRMessageAddEvent() {
        self.syncMOC.performGroupedBlockAndWait {
            // GIVEN
            let text = "Trentatre trentini andarono a Trento tutti e trentatre trotterellando"
            let generic = GenericMessage(content: Text(content: text))

            // WHEN
            let decryptedEvent = self.decryptedUpdateEventFromOtherClient(message: generic)

            // THEN
            XCTAssertEqual(decryptedEvent.senderUUID, self.otherUser.remoteIdentifier!)
            XCTAssertEqual(decryptedEvent.recipientClientID, self.selfClient.remoteIdentifier!)

            guard let decryptedMessage = ZMClientMessage.createOrUpdate(from: decryptedEvent, in: self.syncMOC, prefetchResult: nil) else {
                return XCTFail("Failed to create client message")
            }
            XCTAssertEqual(decryptedMessage.nonce?.transportString(), generic.messageID)
            XCTAssertEqual(decryptedMessage.textMessageData?.messageText, text)
        }
    }

    func testThatItCanDecryptOTRAssetAddEvent() {
        self.syncMOC.performGroupedBlockAndWait {
            // GIVEN
            let image = self.verySmallJPEGData()
            let imageSize = ZMImagePreprocessor.sizeOfPrerotatedImage(with: image)
            let properties = ZMIImageProperties(size: imageSize, length: UInt(image.count), mimeType: "image/jpg")
            let keys = ZMImageAssetEncryptionKeys(otrKey: Data.randomEncryptionKey(), sha256: image.zmSHA256Digest())
            let generic = GenericMessage(content: ImageAsset(mediumProperties: properties, processedProperties: properties, encryptionKeys: keys, format: .medium))

            // WHEN
            let decryptedEvent = self.decryptedAssetUpdateEventFromOtherClient(message: generic)

            // THEN
            guard let decryptedMessage = ZMAssetClientMessage.createOrUpdate(from: decryptedEvent, in: self.syncMOC, prefetchResult: nil) else {
                return XCTFail("Failed to create client message")
            }

            XCTAssertEqual(decryptedMessage.nonce?.transportString(), generic.messageID)
        }
    }

    func testThatItInsertsAUnableToDecryptMessageIfItCanNotEstablishASession() {
        self.syncMOC.performGroupedBlockAndWait {
            // GIVEN
            let innerPayload = ["recipient": self.selfClient.remoteIdentifier!,
                                "sender": self.otherClient.remoteIdentifier!,
                                "id": UUID.create().transportString(),
                                "key": "bah".data(using: .utf8)!.base64String()
            ]

            let payload = [
                "type": "conversation.otr-message-add",
                "from": self.otherUser.remoteIdentifier!.transportString(),
                "data": innerPayload,
                "conversation": self.groupConversation.remoteIdentifier!.transportString(),
                "time": Date().transportString()
                ] as [String: Any]
            let wrapper = [
                "id": UUID.create().transportString(),
                "payload": [payload]
                ] as [String: Any]

            let event = ZMUpdateEvent.eventsArray(from: wrapper as NSDictionary, source: .download)!.first!

            // WHEN
            self.performIgnoringZMLogError {
                self.selfClient.keysStore.encryptionContext.perform { session in
                    _ = session.decryptAndAddClient(event, in: self.syncMOC)
                }
            }

            // THEN
            guard let lastMessage = self.groupConversation.lastMessage as? ZMSystemMessage else {
                return XCTFail("Last conversation message is not a system message")
            }
            XCTAssertEqual(lastMessage.systemMessageType, .decryptionFailed)
        }
    }

    func testThatItInsertsAnUnableToDecryptMessageIfTheEncryptedPayloadIsLongerThan_18_000() {
        syncMOC.performGroupedBlockAndWait {
            // Given
            let crlf = "\u{0000}\u{0001}\u{0000}\u{000D}\u{0000A}"
            let text = "https://wir\("".padding(toLength: crlf.count * 20_000, withPad: crlf, startingAt: 0))e.com/"
            XCTAssertGreaterThan(text.count, 18_000)
            let message = GenericMessage(content: Text(content: text))

            let wrapper = NSDictionary(dictionary: [
                "id": UUID.create().transportString(),
                "payload": [
                    [
                    "type": "conversation.otr-message-add",
                    "from": self.otherUser.remoteIdentifier!.transportString(),
                    "conversation": self.groupConversation.remoteIdentifier!.transportString(),
                    "time": Date().transportString(),
                    "data": [
                        "recipient": self.selfClient.remoteIdentifier!,
                        "sender": self.otherClient.remoteIdentifier!,
                        "text": self.encryptedMessageToSelf(message: message, from: self.otherClient).base64String()
                        ]
                    ]
                ]
            ])

            let event = ZMUpdateEvent.eventsArray(from: wrapper, source: .download)!.first!

            // When
            self.performIgnoringZMLogError {
                self.selfClient.keysStore.encryptionContext.perform { session in
                    _ = session.decryptAndAddClient(event, in: self.syncMOC)
                }
            }

            // Then
            guard let lastMessage = self.groupConversation.lastMessage as? ZMSystemMessage else {
                return XCTFail("Last conversation message is not a system message")
            }
            XCTAssertEqual(lastMessage.systemMessageType, .decryptionFailed)
        }
    }

    func testThatItInsertsAnUnableToDecryptMessageIfTheEncryptedPayloadIsLongerThan_18_000_External_Message() {
        syncMOC.performGroupedBlockAndWait {
            // Given
            let crlf = "\u{0000}\u{0001}\u{0000}\u{000D}\u{0000A}"
            let text = "https://wir\("".padding(toLength: crlf.count * 20_000, withPad: crlf, startingAt: 0))e.com/"
            XCTAssertGreaterThan(text.count, 18_000)

            let wrapper = NSDictionary(dictionary: [
                "id": UUID.create().transportString(),
                "payload": [
                    [
                        "type": "conversation.otr-message-add",
                        "from": self.otherUser.remoteIdentifier!.transportString(),
                        "conversation": self.groupConversation.remoteIdentifier!.transportString(),
                        "time": Date().transportString(),
                        "data": [
                            "data": text,
                            "recipient": self.selfClient.remoteIdentifier!,
                            "sender": self.otherClient.remoteIdentifier!,
                            "text": "something with less than 18000 characters count".data(using: .utf8)!.base64String()
                        ]
                    ]
                ]
            ])

            let event = ZMUpdateEvent.eventsArray(from: wrapper, source: .download)!.first!

            // When
            self.performIgnoringZMLogError {
                self.selfClient.keysStore.encryptionContext.perform { session in
                    _ = session.decryptAndAddClient(event, in: self.syncMOC)
                }
            }

            // Then
            guard let lastMessage = self.groupConversation.lastMessage as? ZMSystemMessage else {
                return XCTFail("Last conversation message is not a system message")
            }
            XCTAssertEqual(lastMessage.systemMessageType, .decryptionFailed)
        }
    }
}
