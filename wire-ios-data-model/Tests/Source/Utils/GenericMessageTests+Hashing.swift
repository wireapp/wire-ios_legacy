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

@testable import WireDataModel

class GenericMessageTests_Hashing: XCTestCase {

    // MARK: - Text

    func testCorrectHashValueForText1() {
        // given
        let textMessage = GenericMessage(content: Text(content: "Hello 👩‍💻👨‍👩‍👧!"))
        let timestamp = Date(timeIntervalSince1970: 1540213769)

        // when
        let hash = textMessage.hashOfContent(with: timestamp)

        // then
        XCTAssertEqual(hash?.zmHexEncodedString(), "4f8ee55a8b71a7eb7447301d1bd0c8429971583b15a91594b45dee16f208afd5")
    }

    func testCorrectHashValueForText2() {
        // given
        let textMessage = GenericMessage(content: Text(content: "https://www.youtube.com/watch?v=DLzxrzFCyOs"))
        let timestamp = Date(timeIntervalSince1970: 1540213769)

        // when
        let hash = textMessage.hashOfContent(with: timestamp)

        // then
        XCTAssertEqual(hash?.zmHexEncodedString(), "ef39934807203191c404ebb3acba0d33ec9dce669f9acec49710d520c365b657")
    }

    func testCorrectHashValueForText3() {
        // given
        let textMessage = GenericMessage(content: Text(content: "بغداد"))
        let timestamp = Date(timeIntervalSince1970: 1540213965)

        // when
        let hash = textMessage.hashOfContent(with: timestamp)

        // then
        XCTAssertEqual(hash?.zmHexEncodedString(), "5830012f6f14c031bf21aded5b07af6e2d02d01074f137d106d4645e4dc539ca")
    }

    // MARK: - Location

    func testCorrectHashValueForLocation1() {
        // given
        let location = WireProtos.Location.with {
            $0.latitude = 52.5166667
            $0.longitude = 13.4
        }
        let locationMessage = GenericMessage(content: location)
        let timestamp = Date(timeIntervalSince1970: 1540213769)

        // when
        let hash = locationMessage.hashOfContent(with: timestamp)

        // then
        XCTAssertEqual(hash?.zmHexEncodedString(), "56a5fa30081bc16688574fdfbbe96c2eee004d1fb37dc714eec6efb340192816")
    }

    func testCorrectHashValueForLocation2() {
        // given
        let location = WireProtos.Location.with {
            $0.latitude = 51.509143
            $0.longitude = -0.117277
        }
        let locationMessage = GenericMessage(content: location)
        let timestamp = Date(timeIntervalSince1970: 1540213769)

        // when
        let hash = locationMessage.hashOfContent(with: timestamp)

        // then
        XCTAssertEqual(hash?.zmHexEncodedString(), "803b2698104f58772dbd715ec6ee5853d835df98a4736742b2a676b2217c9499")
    }

    // MARK: - Asset

    func testCorrectHashValueForAsset1() {
        // given
        let asset = WireProtos.Asset.with {
            $0.uploaded.otrKey = Data()
            $0.uploaded.sha256 = Data()
        }
        var assetMessage = GenericMessage(content: asset)
        assetMessage.updateUploaded(assetId: "3-2-1-38d4f5b9", token: nil, domain: nil)
        let timestamp = Date(timeIntervalSince1970: 1540213769)

        // when
        let hash = assetMessage.hashOfContent(with: timestamp)

        // then
        XCTAssertEqual(hash?.zmHexEncodedString(), "bf20de149847ae999775b3cc88e5ff0c0382e9fa67b9d382b1702920b8afa1de")
    }

    func testCorrectHashValueForAsset2() {
        // given
        let asset = WireProtos.Asset.with {
            $0.uploaded.otrKey = Data()
            $0.uploaded.sha256 = Data()
        }
        var assetMessage = GenericMessage(content: asset)
        assetMessage.updateUploaded(assetId: "3-3-3-82a62735", token: nil, domain: nil)
        let timestamp = Date(timeIntervalSince1970: 1540213965)

        // when
        let hash = assetMessage.hashOfContent(with: timestamp)

        // then
        XCTAssertEqual(hash?.zmHexEncodedString(), "2235f5b6c00d9b0917675399d0314c8401f0525457b00aa54a38998ab93b90d6")
    }

    // MARK: - Ephemeral

    func testCorrectHashValueForEphemeral() {
        // given
        let ephemeralTextMessage = GenericMessage(content: Text(content: "Hello 👩‍💻👨‍👩‍👧!"), expiresAfter: .tenSeconds)
        let timestamp = Date(timeIntervalSince1970: 1540213769)

        // when
        let hash = ephemeralTextMessage.hashOfContent(with: timestamp)

        // then
        XCTAssertEqual(hash?.zmHexEncodedString(), "4f8ee55a8b71a7eb7447301d1bd0c8429971583b15a91594b45dee16f208afd5")
    }

    // MARK: - Edited

    func testCorrectHashValueForEdited() {
        // given

        let editedTextMessage = GenericMessage(content: MessageEdit(replacingMessageID: UUID(), text: Text(content: "Hello 👩‍💻👨‍👩‍👧!")))
        let timestamp = Date(timeIntervalSince1970: 1540213769)

        // when
        let hash = editedTextMessage.hashOfContent(with: timestamp)

        // then
        XCTAssertEqual(hash?.zmHexEncodedString(), "4f8ee55a8b71a7eb7447301d1bd0c8429971583b15a91594b45dee16f208afd5")
    }

}
