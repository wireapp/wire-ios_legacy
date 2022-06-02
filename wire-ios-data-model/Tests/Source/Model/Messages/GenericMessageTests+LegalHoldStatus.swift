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

@testable import WireDataModel

class GenericMessageTests_LegalHoldStatus: BaseZMClientMessageTests {

    func testThatItUpdatesLegalHoldStatusFlagForTextMessage() {

        // given
        var genericMessage = GenericMessage(content: Text(content: "foo"), nonce: UUID.create())

        // when
        XCTAssertEqual(genericMessage.text.legalHoldStatus, .unknown)
        genericMessage.setLegalHoldStatus(.disabled)

        // then
        XCTAssertEqual(genericMessage.text.legalHoldStatus, .disabled)
    }

    func testThatItUpdatesLegalHoldStatusFlagForReaction() {

        // given
        var genericMessage = GenericMessage(content: WireProtos.Reaction.createReaction(emoji: "🤠", messageID: UUID.create()))

        // when
        XCTAssertEqual(genericMessage.reaction.legalHoldStatus, .unknown)
        genericMessage.setLegalHoldStatus(.enabled)

        // then
        XCTAssertEqual(genericMessage.reaction.legalHoldStatus, .enabled)
    }

    func testThatItUpdatesLegalHoldStatusFlagForKnock() {

        // given
        var genericMessage = GenericMessage(content: WireProtos.Knock.with { $0.hotKnock = true }, nonce: UUID.create())

        // when
        XCTAssertEqual(genericMessage.knock.legalHoldStatus, .unknown)
        genericMessage.setLegalHoldStatus(.disabled)

        // then
        XCTAssertEqual(genericMessage.knock.legalHoldStatus, .disabled)
    }

    func testThatItUpdatesLegalHoldStatusFlagForLocation() {

        // given
        let location = WireProtos.Location.with {
            $0.latitude = 0.0
            $0.longitude = 0.0
        }
        var genericMessage = GenericMessage(content: location, nonce: UUID.create())

        // when
        XCTAssertEqual(genericMessage.location.legalHoldStatus, .unknown)
        genericMessage.setLegalHoldStatus(.enabled)

        // then
        XCTAssertEqual(genericMessage.location.legalHoldStatus, .enabled)
    }

    func testThatItUpdatesLegalHoldStatusFlagForAsset() {

        // given
        var genericMessage = GenericMessage(content: WireProtos.Asset(imageSize: CGSize(width: 42, height: 12), mimeType: "image/jpeg", size: 123), nonce: UUID.create())

        // when
        XCTAssertEqual(genericMessage.asset.legalHoldStatus, .unknown)
        genericMessage.setLegalHoldStatus(.disabled)

        // then
        XCTAssertEqual(genericMessage.asset.legalHoldStatus, .disabled)
    }

    func testThatItUpdatesLegalHoldStatusFlagForEphemeral() {

        // given
        let asset = WireProtos.Asset(imageSize: CGSize(width: 42, height: 12), mimeType: "image/jpeg", size: 123)
        var genericMessage = GenericMessage(content: asset, nonce: UUID.create(), expiresAfter: .tenSeconds)

        // when
        XCTAssertEqual(genericMessage.ephemeral.legalHoldStatus, .unknown)
        genericMessage.setLegalHoldStatus(.enabled)

        // then
        XCTAssertEqual(genericMessage.ephemeral.legalHoldStatus, .enabled)
    }
}
