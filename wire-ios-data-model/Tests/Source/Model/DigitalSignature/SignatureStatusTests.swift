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
@testable import WireDataModel

final class SignatureStatusTests: ZMBaseManagedObjectTest {
    var status: SignatureStatus!
    var asset: WireProtos.Asset?

    override func setUp() {
        super.setUp()
        asset = createAsset()
        status = SignatureStatus(asset: asset,
                                 data: Data(),
                                 managedObjectContext: syncMOC)
    }

    override func tearDown() {
        asset = nil
        status = nil
        super.tearDown()
    }

    func testThatItChangesStatusAfterTriggerASignDocumentMethod() {
        // given
        XCTAssertEqual(status.state, .initial)

        // when
        status.signDocument()

        // then
        XCTAssertEqual(status.state, .waitingForConsentURL)
    }

    func testThatItChangesStatusAfterTriggerARetrieveSignatureMethod() {
        // given
        status.state = .waitingForCodeVerification

        // when
        status.retrieveSignature()

        // then
        XCTAssertEqual(status.state, .waitingForSignature)
    }

    func testThatItTakesRequiredAssetAttributesForTheRequest() {
        XCTAssertEqual(asset?.uploaded.assetID, "id")
        XCTAssertEqual(asset?.preview.remote.assetID, "")

        XCTAssertEqual(status.documentID, asset?.uploaded.assetID)
        XCTAssertEqual(status.fileName, asset?.original.name)
    }

    private func createAsset() -> WireProtos.Asset {
        let (otrKey, sha) = (Data.randomEncryptionKey(), Data.zmRandomSHA256Key())
        let (assetId, token) = ("id", "token")
        let original = WireProtos.Asset.Original(withSize: 200, mimeType: "application/pdf", name: "PDF test")

        let remoteData = WireProtos.Asset.RemoteData(withOTRKey: otrKey,
                                                     sha256: sha,
                                                     assetId: assetId,
                                                     assetToken: token)
        let asset = WireProtos.Asset.with {
            $0.original = original
            $0.uploaded = remoteData
        }
        let sut = GenericMessage(content: asset, nonce: UUID.create())

        return sut.asset
    }
}
