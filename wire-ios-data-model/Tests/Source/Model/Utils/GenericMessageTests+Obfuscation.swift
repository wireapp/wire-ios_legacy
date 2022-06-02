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

import Foundation
@testable import WireDataModel

class GenericMessageTests_Obfuscation: ZMBaseManagedObjectTest {

    func assetWithImage() -> WireProtos.Asset {
        let original = WireProtos.Asset.Original.with({
            $0.size = 1000
            $0.mimeType = "image"
            $0.name = "foo"
        })
        let remoteData = WireProtos.Asset.RemoteData.with {
            $0.otrKey = Data()
            $0.sha256 = Data()
            $0.assetID = "id"
            $0.assetToken = "token"
        }
        let imageMetaData = WireProtos.Asset.ImageMetaData.with({
            $0.width = 30
            $0.height = 40
            $0.tag = "bar"
        })
        let preview = WireProtos.Asset.Preview(size: 2000, mimeType: "video", remoteData: remoteData, imageMetadata: imageMetaData)
        let asset  = WireProtos.Asset(original: original, preview: preview)
        return asset
    }

    func testThatItObfuscatesEmojis() {
        // given
        let text = "📲"
        let message = GenericMessage(content: Text(content: text), nonce: UUID.create(), expiresAfter: .tenSeconds)

        // when
        let obfuscatedMessage = message.obfuscatedMessage()

        // then
        XCTAssertNotEqual(obfuscatedMessage?.text.content, text)
        guard let content = obfuscatedMessage?.content else { return }
        switch content {
        case .text:
            XCTAssertNotNil(obfuscatedMessage)
        default:
            break
        }
    }

    func testThatItObfuscatesCyrillic() {
        // given
        let text = "привет мир!"
        let message = GenericMessage(content: Text(content: text), nonce: UUID.create(), expiresAfter: .tenSeconds)

        // when
        let obfuscatedMessage = message.obfuscatedMessage()

        // then
        XCTAssertNotEqual(obfuscatedMessage?.text.content, text)

        guard let content = obfuscatedMessage?.content else { return }
        switch content {
        case .text:
            XCTAssertNotNil(obfuscatedMessage)
        default:
            break
        }
    }

    func testThatItObfuscatesTextMessages() {
        // given
        let text = "foo"
        let message = GenericMessage(content: Text(content: text), nonce: UUID.create(), expiresAfter: .tenSeconds)

        // when
        let obfuscatedMessage = message.obfuscatedMessage()

        // then
        XCTAssertNotEqual(obfuscatedMessage?.text.content, text)

        guard let content = obfuscatedMessage?.content else { return }
        switch content {
        case .text:
            XCTAssertNotNil(obfuscatedMessage)
        default:
            break
        }
    }

    func testThatItObfuscatesTextMessageDifferentlyEachTime() {
        // given
        let text = "foo"
        let message = GenericMessage(content: Text(content: text), nonce: UUID.create(), expiresAfter: .tenSeconds)

        // when
        let obfuscatedMessage1 = message.obfuscatedMessage()
        let obfuscatedMessage2 = message.obfuscatedMessage()

        // then
        XCTAssertNotNil(obfuscatedMessage1?.text)
        XCTAssertNotNil(obfuscatedMessage2?.text)
        XCTAssertNotEqual(obfuscatedMessage1?.text.content, text)
        XCTAssertNotEqual(obfuscatedMessage2?.text.content, text)
        XCTAssertNotEqual(obfuscatedMessage1?.text.content, obfuscatedMessage2?.text.content)
    }

    func testThatItDoesNotObfuscateNonEphemeralTextMessages() {
        // given
        let text = "foo"
        let message = GenericMessage(content: Text(content: text), nonce: UUID.create())

        // when
        let obfuscatedMessage = message.obfuscatedMessage()

        // then
        XCTAssertNil(obfuscatedMessage)
    }

    func testThatItObfuscatesLinkPreviews() {
        // given
        let title = "title"
        let summary = "summary"
        let permURL = "www.example.com/permanent"
        let origURL = "www.example.com/original"
        let text = "foo www.example.com/original"
        let offset: Int32 = 4

        let linkPreview = LinkPreview.with {
            $0.url = origURL
            $0.permanentURL = permURL
            $0.urlOffset = offset
            $0.title = title
            $0.summary = summary
        }
        let messageText = Text.with {
            $0.content = text
            $0.linkPreview = [linkPreview]
        }
        let genericMessage = GenericMessage(content: messageText, nonce: UUID.create(), expiresAfter: .tenSeconds)

        // when
        let obfuscated =  genericMessage.obfuscatedMessage()

        // then
        guard let obfuscatedLinkPreview = obfuscated?.linkPreviews.first else { return XCTFail()}

        // then
        let obfText = obfuscated!.text.content
        let obfOrgURL = String(obfText[obfText.index(obfText.startIndex, offsetBy: 4)...])
        XCTAssertNotEqual(obfuscatedLinkPreview.url, origURL)
        XCTAssertEqual(obfuscatedLinkPreview.url, obfOrgURL)
        XCTAssertEqual(obfuscatedLinkPreview.urlOffset, offset)

        XCTAssertNotNil(obfuscatedLinkPreview.article)
        XCTAssertNotEqual(obfuscatedLinkPreview.article.permanentURL, permURL)
        XCTAssertNotEqual(obfuscatedLinkPreview.article.permanentURL.count, 0)
        XCTAssertNotEqual(obfuscatedLinkPreview.article.title, title)
        XCTAssertNotEqual(obfuscatedLinkPreview.article.title.count, 0)
        XCTAssertNotEqual(obfuscatedLinkPreview.article.summary, summary)
        XCTAssertNotEqual(obfuscatedLinkPreview.article.summary.count, 0)
    }

    func testThatItObfuscatesLinkPreviews_Images() {
        // given
        let title = "title"
        let summary = "summary"
        let permURL = "www.example.com/permanent"
        let origURL = "www.example.com/original"
        let text = "foo www.example.com/original"
        let image = assetWithImage()
        let offset: Int32 = 4

        let linkPreview = LinkPreview.with {
            $0.url = origURL
            $0.permanentURL = permURL
            $0.urlOffset = offset
            $0.title = title
            $0.summary = summary
            $0.image = image
        }

        let obfuscatedText = Text.with {
            $0.content = text
            $0.linkPreview = [linkPreview]
        }

        let genericMessage = GenericMessage(content: obfuscatedText, nonce: UUID.create(), expiresAfter: .tenSeconds)

        // when
        let obfuscated =  genericMessage.obfuscatedMessage()

        // then
        guard let obfuscatedLinkPreview = obfuscated?.linkPreviews.first else { return XCTFail()}
        let obfuscatedAsset = obfuscatedLinkPreview.image
        XCTAssertTrue(obfuscatedAsset.hasOriginal)
        XCTAssertEqual(obfuscatedAsset.original.size, 10)
        XCTAssertEqual(obfuscatedAsset.original.mimeType, "image")
        XCTAssertEqual(obfuscatedAsset.preview.size, 10)
        XCTAssertEqual(obfuscatedAsset.preview.mimeType, "video")
        XCTAssertEqual(obfuscatedAsset.preview.image.width, 30)
        XCTAssertEqual(obfuscatedAsset.preview.image.height, 40)
        XCTAssertEqual(obfuscatedAsset.preview.image.tag, "bar")
        XCTAssertFalse(obfuscatedAsset.preview.hasRemote)
    }

    func testThatItObfuscatesLinkPreviews_Tweets() {
        // given
        let title = "title"
        let summary = "summary"
        let permURL = "www.example.com/permanent"
        let origURL = "www.example.com/original"
        let text = "foo www.example.com/original"
        let tweet = WireProtos.Tweet.with({
            $0.author = "author"
            $0.username = "username"
        })
        let offset: Int32 = 4

        let linkPreview = LinkPreview.with {
            $0.url = origURL
            $0.permanentURL = permURL
            $0.urlOffset = offset
            $0.title = title
            $0.summary = summary
            $0.tweet = tweet
        }

        let obfuscatedText = Text.with {
            $0.content = text
            $0.linkPreview = [linkPreview]
        }
        let genericMessage = GenericMessage(content: obfuscatedText, nonce: UUID.create(), expiresAfter: .tenSeconds)

        // when
        let obfuscated =  genericMessage.obfuscatedMessage()

        // then
        guard let obfuscatedLinkPreview = obfuscated?.linkPreviews.first else { return XCTFail()}

        // then
        let obfuscatedTweet = obfuscatedLinkPreview.tweet
        XCTAssertNotEqual(obfuscatedTweet.author, "author")
        XCTAssertEqual(obfuscatedTweet.author.count, "author".count)

        XCTAssertNotEqual(obfuscatedTweet.username, "username")
        XCTAssertEqual(obfuscatedTweet.username.count, "username".count)
    }

    func testThatItObfuscatesAssetsImageContent() {
        // given
        let asset  = assetWithImage()
        let genericMessage = GenericMessage(content: asset, nonce: UUID.create(), expiresAfter: .tenSeconds)

        // when
        let obfuscated =  genericMessage.obfuscatedMessage()

        // then
        guard let obfuscatedAsset = obfuscated?.asset else { return XCTFail()}

        // then
        XCTAssertTrue(obfuscatedAsset.hasOriginal)
        XCTAssertEqual(obfuscatedAsset.original.size, 10)
        XCTAssertEqual(obfuscatedAsset.original.mimeType, "image")
        XCTAssertEqual(obfuscatedAsset.preview.size, 10)
        XCTAssertEqual(obfuscatedAsset.preview.mimeType, "video")
        XCTAssertEqual(obfuscatedAsset.preview.image.width, 30)
        XCTAssertEqual(obfuscatedAsset.preview.image.height, 40)
        XCTAssertEqual(obfuscatedAsset.preview.image.tag, "bar")
        XCTAssertFalse(obfuscatedAsset.preview.hasRemote)
    }

    func testThatItObfuscatesAssetsVideoContent() {
        // given

        let original = WireProtos.Asset.Original.with({
            $0.size = 200
            $0.mimeType = "video"
            $0.name = "foo"
            $0.video = WireProtos.Asset.VideoMetaData.with({
                $0.durationInMillis = 500
                $0.width = 305
                $0.height = 200
            })
        })

        let asset  = WireProtos.Asset(original: original, preview: nil)
        let genericMessage = GenericMessage(content: asset, nonce: UUID.create(), expiresAfter: .tenSeconds)

        // when
        let obfuscated =  genericMessage.obfuscatedMessage()

        // then
        guard let obfuscatedAsset = obfuscated?.asset else { return XCTFail()}

        // then
        XCTAssertTrue(obfuscatedAsset.hasOriginal)
        XCTAssertEqual(obfuscatedAsset.original.size, 10)
        XCTAssertEqual(obfuscatedAsset.original.mimeType, "video")
        XCTAssertNotEqual(obfuscatedAsset.original.name, "foo")

        XCTAssertTrue(obfuscatedAsset.original.hasSize)
        XCTAssertFalse(obfuscatedAsset.original.video.hasWidth)
        XCTAssertFalse(obfuscatedAsset.original.video.hasHeight)
        XCTAssertFalse(obfuscatedAsset.original.video.hasDurationInMillis)
    }

    func testCheckThatItObfuscatesAudioMessages() {
        // given
        let original = WireProtos.Asset.Original.with({
            $0.size = 200
            $0.mimeType = "audio"
            $0.name = "foo"
            $0.audio = WireProtos.Asset.AudioMetaData.with({
                $0.durationInMillis = 300
                $0.normalizedLoudness = NSData(bytes: [2.9], length: [2.9].count) as Data
            })
        })

        let asset  = WireProtos.Asset(original: original, preview: nil)
        let genericMessage = GenericMessage(content: asset, nonce: UUID.create(), expiresAfter: .tenSeconds)

        // when
        let obfuscated =  genericMessage.obfuscatedMessage()

        // then
        guard let obfuscatedAsset = obfuscated?.asset else { return XCTFail()}

        XCTAssertTrue(obfuscatedAsset.hasOriginal)
        XCTAssertEqual(obfuscatedAsset.original.size, 10)
        XCTAssertEqual(obfuscatedAsset.original.mimeType, "audio")
        XCTAssertNotEqual(obfuscatedAsset.original.name, "foo")

        guard case .audio? = obfuscatedAsset.original.metaData else { return XCTFail() }

        XCTAssertFalse(obfuscatedAsset.original.audio.hasDurationInMillis)
        XCTAssertFalse(obfuscatedAsset.original.audio.hasNormalizedLoudness)
    }

    func testThatItObfuscatesLocationMessages() {
        // given
        let location  = Location(latitude: 2.0, longitude: 3.0)
        let message = GenericMessage(content: location, nonce: UUID.create(), expiresAfter: .tenSeconds)

        // when
        let obfuscatedMessage = message.obfuscatedMessage()

        // then
        XCTAssertNotNil(obfuscatedMessage?.locationData)
        XCTAssertEqual(obfuscatedMessage?.location.longitude, 0.0)
        XCTAssertEqual(obfuscatedMessage?.location.latitude, 0.0)
    }

}
