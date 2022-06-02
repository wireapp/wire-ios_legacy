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

import XCTest
import WireTesting

@testable import WireDataModel

class ProtobufUtilitiesTests: BaseZMClientMessageTests {

    func testThatItSetsAndReadsTheLoudness() {

        // given
        let loudness: [Float] = [0.8, 0.3, 1.0, 0.0, 0.001]
        let sut = WireProtos.Asset.Original(withSize: 200, mimeType: "audio/m4a", name: "foo.m4a", audioDurationInMillis: 1000, normalizedLoudness: loudness)

        // when
        let extractedLoudness = sut.audio.normalizedLoudness

        // then
        XCTAssertTrue(sut.audio.hasNormalizedLoudness)
        XCTAssertEqual(extractedLoudness.count, loudness.count)
        XCTAssertEqual(loudness.map { Float(UInt8(roundf($0*255)))/255.0 }, sut.normalizedLoudnessLevels)
    }

    func testThatItDoesNotReturnTheLoudnessIfEmpty() {

        // given
        let sut = WireProtos.Asset.Original(withSize: 234, mimeType: "foo/bar", name: "boo.bar")

        // then
        XCTAssertEqual(sut.normalizedLoudnessLevels, [])
    }

    func testThatItUpdatesTheLinkPreviewWithOTRKeyAndSha() {
        // given
        var preview = createLinkPreview()
        XCTAssertFalse(preview.article.image.hasUploaded)
        XCTAssertFalse(preview.image.hasUploaded)

        // when
        let (otrKey, sha256) = (Data.randomEncryptionKey(), Data.zmRandomSHA256Key())
        let metadata = WireProtos.Asset.ImageMetaData(width: 42, height: 12)
        let original = WireProtos.Asset.Original(withSize: 256, mimeType: "image/jpeg", name: nil, imageMetaData: metadata)
        preview.update(withOtrKey: otrKey, sha256: sha256, original: original)

        // then
        XCTAssertTrue(preview.image.hasUploaded)
        XCTAssertEqual(preview.image.uploaded.otrKey, otrKey)
        XCTAssertEqual(preview.image.uploaded.sha256, sha256)
        XCTAssertEqual(preview.image.original.size, 256)
        XCTAssertEqual(preview.image.original.mimeType, "image/jpeg")
        XCTAssertEqual(preview.image.original.image.height, 12)
        XCTAssertEqual(preview.image.original.image.width, 42)
        XCTAssertFalse(preview.image.original.hasName)
    }

    func testThatItUpdatesTheLinkPreviewWithAssetIDAndTokenAndDomain() {
        // given
        var preview = createLinkPreview()
        preview.update(withOtrKey: .randomEncryptionKey(), sha256: .zmRandomSHA256Key(), original: nil)
        XCTAssertTrue(preview.image.hasUploaded)
        XCTAssertFalse(preview.image.uploaded.hasAssetID)

        // when
        let (assetKey, token, domain) = ("key", "token", "domain")
        preview.update(withAssetKey: assetKey, assetToken: token, assetDomain: domain)

        // then
        XCTAssertTrue(preview.image.uploaded.hasAssetID)
        XCTAssertEqual(preview.image.uploaded.assetID, assetKey)
        XCTAssertEqual(preview.image.uploaded.assetToken, token)
        XCTAssertEqual(preview.image.uploaded.assetDomain, domain)
    }

    func testThatItUpdatesRemoteAssetDataWIthAssetIdAndAssetTokenAndDomain() {
        // given
        let (otrKey, sha) = (Data.randomEncryptionKey(), Data.zmRandomSHA256Key())
        let (assetId, token, domain) = ("id", "token", "domain")
        var sut = WireProtos.Asset.RemoteData(withOTRKey: otrKey, sha256: sha)

        // when
        sut.update(assetId: assetId, token: token, domain: domain)

        // then
        XCTAssertEqual(sut.assetID, assetId)
        XCTAssertEqual(sut.assetToken, token)
        XCTAssertEqual(sut.assetDomain, domain)
        XCTAssertEqual(sut.otrKey, otrKey)
        XCTAssertEqual(sut.sha256, sha)
    }

    func testThatItUpdatesAGenericMessageWithAssetUploadedWithAssetIdAndTokenAndDomain() {
        // given
        let (otrKey, sha) = (Data.randomEncryptionKey(), Data.zmRandomSHA256Key())
        let (assetId, token, domain) = ("id", "token", "domain")
        let asset = WireProtos.Asset(withUploadedOTRKey: otrKey, sha256: sha)
        var sut = GenericMessage(content: asset, nonce: UUID.create())

        // when
        sut.updateUploaded(assetId: assetId, token: token, domain: domain)

        // then
        if case .ephemeral? = sut.content {
            return XCTFail()
        }
        XCTAssert(sut.hasAsset)
        XCTAssertEqual(sut.asset.uploaded.assetID, assetId)
        XCTAssertEqual(sut.asset.uploaded.assetToken, token)
        XCTAssertEqual(sut.asset.uploaded.assetDomain, domain)
        XCTAssertEqual(sut.asset.uploaded.otrKey, otrKey)
        XCTAssertEqual(sut.asset.uploaded.sha256, sha)
    }

    func testThatItUpdatesAGenericMessageWithAssetUploadedWithAssetIdAndTokenAndDomain_Ephemeral() {
        // given
        let (otrKey, sha) = (Data.randomEncryptionKey(), Data.zmRandomSHA256Key())
        let (assetId, token, domain) = ("id", "token", "domain")
        let asset = WireProtos.Asset(withUploadedOTRKey: otrKey, sha256: sha)
        var sut = GenericMessage(content: asset, nonce: UUID.create(), expiresAfter: .tenSeconds)

        // when
        sut.updateUploaded(assetId: assetId, token: token, domain: domain)

        // then
        guard case .ephemeral? = sut.content else {
            return XCTFail()
        }
        XCTAssertTrue(sut.ephemeral.hasAsset)
        XCTAssertEqual(sut.ephemeral.asset.uploaded.assetID, assetId)
        XCTAssertEqual(sut.ephemeral.asset.uploaded.assetToken, token)
        XCTAssertEqual(sut.ephemeral.asset.uploaded.assetDomain, domain)
        XCTAssertEqual(sut.ephemeral.asset.uploaded.otrKey, otrKey)
        XCTAssertEqual(sut.ephemeral.asset.uploaded.sha256, sha)
    }

    func testThatItUpdatesAGenericMessageWithAssetPreviewWithAssetIdAndTokenAndDomain() {
        // given
        let (otr, sha) = (Data.randomEncryptionKey(), Data.zmRandomSHA256Key())
        let (assetId, token, domain) = ("id", "token", "domain")
        let previewAsset = WireProtos.Asset.Preview(
            size: 128,
            mimeType: "image/jpg",
            remoteData: WireProtos.Asset.RemoteData(withOTRKey: otr, sha256: sha, assetId: nil, assetToken: nil),
            imageMetadata: WireProtos.Asset.ImageMetaData(width: 123, height: 420))

        var sut = GenericMessage(
            content: WireProtos.Asset(original: nil, preview: previewAsset),
            nonce: UUID.create()
        )

        // when
        sut.updatePreview(assetId: assetId, token: token, domain: domain)

        // then
        if case .ephemeral? = sut.content {
            return XCTFail()
        }
        XCTAssert(sut.hasAsset)
        XCTAssertEqual(sut.asset.preview.remote.assetID, assetId)
        XCTAssertEqual(sut.asset.preview.remote.assetToken, token)
        XCTAssertEqual(sut.asset.preview.remote.assetDomain, domain)
        XCTAssertEqual(sut.asset.preview.remote.otrKey, otr)
        XCTAssertEqual(sut.asset.preview.remote.sha256, sha)
    }

    func testThatItUpdatesAGenericMessageWithAssetPreviewWithAssetIdAndTokenAndDomain_Ephemeral() {
        // given
        let (otr, sha) = (Data.randomEncryptionKey(), Data.zmRandomSHA256Key())
        let (assetId, token, domain) = ("id", "token", "domain")
        let previewAsset = WireProtos.Asset.Preview(
        size: 128,
        mimeType: "image/jpg",
        remoteData: WireProtos.Asset.RemoteData(withOTRKey: otr, sha256: sha, assetId: nil, assetToken: nil),
        imageMetadata: WireProtos.Asset.ImageMetaData(width: 123, height: 420))

        var sut = GenericMessage(
            content: WireProtos.Asset(original: nil, preview: previewAsset),
            nonce: UUID.create(),
            expiresAfter: .tenSeconds
        )

        // when
        sut.updatePreview(assetId: assetId, token: token, domain: domain)

        // then
        guard case .ephemeral? = sut.content else {
            return XCTFail()
        }
        XCTAssert(sut.ephemeral.hasAsset)
        XCTAssertEqual(sut.ephemeral.asset.preview.remote.assetID, assetId)
        XCTAssertEqual(sut.ephemeral.asset.preview.remote.assetToken, token)
        XCTAssertEqual(sut.ephemeral.asset.preview.remote.assetDomain, domain)
        XCTAssertEqual(sut.ephemeral.asset.preview.remote.otrKey, otr)
        XCTAssertEqual(sut.ephemeral.asset.preview.remote.sha256, sha)
    }

    // MARK: - Helper

    func createLinkPreview() -> LinkPreview {
        return LinkPreview.with {
            $0.url = "www.example.com/original"
            $0.permanentURL = "www.example.com/permanent"
            $0.urlOffset = 42
            $0.title = "Title"
            $0.summary = name
        }
    }
}

// MARK: - Using Swift protobuf API, Update assets

extension ProtobufUtilitiesTests {

    func testThatItUpdatesAGenericMessageWithAssetUploadedWithAssetIdAndTokenAndDomain_SwiftProtobufAPI() {
        // given
        let (assetId, token, domain) = ("id", "token", "domain")
        let asset = WireProtos.Asset(imageSize: CGSize(width: 42, height: 12), mimeType: "image/jpeg", size: 123)
        var sut = GenericMessage(content: asset, nonce: UUID.create())

        // when
        XCTAssertNotEqual(sut.asset.uploaded.assetID, assetId)
        XCTAssertNotEqual(sut.asset.uploaded.assetToken, token)
        sut.updateUploaded(assetId: assetId, token: token, domain: domain)

        // then
        XCTAssertEqual(sut.asset.uploaded.assetID, assetId)
        XCTAssertEqual(sut.asset.uploaded.assetToken, token)
        XCTAssertEqual(sut.asset.uploaded.assetDomain, domain)
    }

    func testThatItUpdatesAGenericMessageWithAssetUploadedWithAssetIdAndTokenAndDomain_Ephemeral_SwiftProtobufAP() {
        // given
        let (assetId, token, domain) = ("id", "token", "domain")
        let asset = WireProtos.Asset(imageSize: CGSize(width: 42, height: 12), mimeType: "image/jpeg", size: 123)
        var sut = GenericMessage(content: asset, nonce: UUID.create(), expiresAfter: .tenSeconds)

        // when
        XCTAssertNotEqual(sut.ephemeral.asset.uploaded.assetID, assetId)
        XCTAssertNotEqual(sut.ephemeral.asset.uploaded.assetToken, token)
        sut.updateUploaded(assetId: assetId, token: token, domain: domain)

        // then
        XCTAssertEqual(sut.ephemeral.asset.uploaded.assetID, assetId)
        XCTAssertEqual(sut.ephemeral.asset.uploaded.assetToken, token)
        XCTAssertEqual(sut.ephemeral.asset.uploaded.assetDomain, domain)
    }

    func testThatItUpdatesAGenericMessageWithAssetPreviewWithAssetIdAndTokenAndDomain_SwiftProtobufAP() {
        // given
        let (otr, sha) = (Data.randomEncryptionKey(), Data.zmRandomSHA256Key())
        let remoteData = WireProtos.Asset.RemoteData.with {
            $0.otrKey = otr
            $0.sha256 = sha
        }
        let imageMetadata = WireProtos.Asset.ImageMetaData.with {
            $0.width = 123
            $0.height = 420
        }
        let previewAsset = WireProtos.Asset.Preview(size: 128, mimeType: "image/jpg", remoteData: remoteData, imageMetadata: imageMetadata)
        let asset = WireProtos.Asset.with {
            $0.preview = previewAsset
        }

        let (assetId, token, domain) = ("id", "token", "domain")
        var sut = GenericMessage(content: asset, nonce: UUID.create())

        // when
        XCTAssertNotEqual(sut.asset.preview.remote.assetID, assetId)
        XCTAssertNotEqual(sut.asset.preview.remote.assetToken, token)
        sut.updatePreview(assetId: assetId, token: token, domain: domain)

        // then
        XCTAssertEqual(sut.asset.preview.remote.assetID, assetId)
        XCTAssertEqual(sut.asset.preview.remote.assetToken, token)
        XCTAssertEqual(sut.asset.preview.remote.assetDomain, domain)

        XCTAssertEqual(sut.asset.preview.remote.otrKey, otr)
        XCTAssertEqual(sut.asset.preview.remote.sha256, sha)
    }

    func testThatItUpdatesAGenericMessageWithAssetPreviewWithAssetIdAndToken_Ephemeral_SwiftProtobufAP() {
        // given
        let (otr, sha) = (Data.randomEncryptionKey(), Data.zmRandomSHA256Key())
        let remoteData = WireProtos.Asset.RemoteData.with {
            $0.otrKey = otr
            $0.sha256 = sha
        }
        let imageMetadata = WireProtos.Asset.ImageMetaData.with {
            $0.width = 123
            $0.height = 420
        }
        let previewAsset = WireProtos.Asset.Preview(size: 128, mimeType: "image/jpg", remoteData: remoteData, imageMetadata: imageMetadata)
        let asset = WireProtos.Asset.with {
            $0.preview = previewAsset
        }

        let (assetId, token, domain) = ("id", "token", "domain")
        var sut = GenericMessage(content: asset, nonce: UUID.create(), expiresAfter: .tenSeconds)

        // when
        XCTAssertNotEqual(sut.ephemeral.asset.preview.remote.assetID, assetId)
        XCTAssertNotEqual(sut.ephemeral.asset.preview.remote.assetToken, token)
        XCTAssertNotEqual(sut.ephemeral.asset.preview.remote.assetDomain, domain)
        sut.updatePreview(assetId: assetId, token: token, domain: domain)

        // then
        XCTAssertEqual(sut.ephemeral.asset.preview.remote.assetID, assetId)
        XCTAssertEqual(sut.ephemeral.asset.preview.remote.assetToken, token)
        XCTAssertEqual(sut.ephemeral.asset.preview.remote.assetDomain, domain)
        XCTAssertEqual(sut.ephemeral.asset.preview.remote.otrKey, otr)
        XCTAssertEqual(sut.ephemeral.asset.preview.remote.sha256, sha)
     }
}
