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

import Foundation
@testable import WireDataModel
import XCTest

class GenericMessageTests: XCTestCase {

    func testThatConsidersTextMessageTypeAsKnownMessage() {
        let textMessageType = GenericMessage(content: Text(content: "hello"))
        XCTAssertTrue(textMessageType.knownMessage)
    }

    func testThatItConsidersKnockMessageTypeAsKnownMessage() {
        let knockMessageType = GenericMessage(content: Knock())
        XCTAssertTrue(knockMessageType.knownMessage)
    }

    func testThatItConsidersLastReadMessageTypeAsKnownMessage() {
        let lastReadMessageType = GenericMessage(content: LastRead(conversationID: UUID.create(), lastReadTimestamp: Date()))
        XCTAssertTrue(lastReadMessageType.knownMessage)
    }

    func testThatItConsidersClearedMessageTypeAsKnownMessage() {
        let clearedMessageType = GenericMessage(content: Cleared(timestamp: Date(), conversationID: UUID.create()))
        XCTAssertTrue(clearedMessageType.knownMessage)
    }

    func testThatItConsidersExternalMessageTypeAsKnownMessage() {
        let sha256 = Data(base64Encoded: "47DEQpj8HBSa+/TImW+5JCeuQeRkm5NMpJWZG3hSuFU=")!
        let otrKey = Data(base64Encoded: "4H1nD6bG2sCxC/tZBnIG7avLYhkCsSfv0ATNqnfug7w=")!
        let externalMessageType = GenericMessage(content: External(withOTRKey: otrKey, sha256: sha256))

        XCTAssertTrue(externalMessageType.knownMessage)
    }

    func testThatItConsidersResetSessionMessageTypeAsKnownMessage() {
        let resetSessionMessageType = GenericMessage(clientAction: .resetSession)
        XCTAssertTrue(resetSessionMessageType.knownMessage)
    }

    func testThatItConsidersCallingMessageTypeAsKnownMessage() {
        let callingMessageType = GenericMessage(content: Calling(content: "Calling"))
        XCTAssertTrue(callingMessageType.knownMessage)
    }

    func testThatItConsidersAssetMessageTypeAsKnownMessage() {
        let assetMessageType = GenericMessage(content: WireProtos.Asset(imageSize: .zero, mimeType: "image/jpeg", size: 0))
        XCTAssertTrue(assetMessageType.knownMessage)
    }

    func testThatItConsidersHidingMessageTypeAsKnownMessage() {
        let hideMessageType = GenericMessage(content: MessageHide(conversationId: UUID.create(), messageId: UUID.create()))
        XCTAssertTrue(hideMessageType.knownMessage)
    }

    func testThatItConsidersLocationMessageTypeAsKnownMessage() {
        let locationMessageType = GenericMessage(content: Location(latitude: 1, longitude: 2))
        XCTAssertTrue(locationMessageType.knownMessage)
    }

    func testThatItConsidersDeletionMessageTypeAsKnownMessage() {
        let deletionMessageType = GenericMessage(content: MessageDelete(messageId: UUID.create()))
        XCTAssertTrue(deletionMessageType.knownMessage)
    }

    func testThatItConsidersCreatingReactionMessageTypeAsKnownMessage() {
        let creatingReactionMessageType = GenericMessage(content: WireProtos.Reaction.createReaction(emoji: "test", messageID: UUID.create()))
        XCTAssertTrue(creatingReactionMessageType.knownMessage)
    }

    func testThatItConsidersAvailabilityMessageTypeAsKnownMessage() {
        let awayAvailabilityMessageType = GenericMessage(content: WireProtos.Availability(.away))
        XCTAssertTrue(awayAvailabilityMessageType.knownMessage)
    }
}
