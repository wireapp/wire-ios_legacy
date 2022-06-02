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
import WireLinkPreview

@testable import WireDataModel

enum ContentType {
    case textMessage, editMessage
}

class ClientMessageTests_ZMImageOwner: BaseZMClientMessageTests {

    func insertMessageWithLinkPreview(contentType: ContentType) -> ZMClientMessage {
        let nonce = UUID()
        let clientMessage = ZMClientMessage(nonce: nonce, managedObjectContext: uiMOC)
        let article = ArticleMetadata(
            originalURLString: "example.com/article/original",
            permanentURLString: "http://www.example.com/article/1",
            resolvedURLString: "http://www.example.com/article/1",
            offset: 5
        )
        article.title = "title"
        article.summary = "tile"
        let mention = Mention(range: NSRange(location: 0, length: 4), user: user1)

        let text = Text(content: "@joe example.com/article/original", mentions: [mention], linkPreviews: [article], replyingTo: nil)
        var genericMessage: GenericMessage!
        switch contentType {
        case .textMessage:
            genericMessage = GenericMessage(content: text, nonce: nonce)
        case .editMessage:
            genericMessage = GenericMessage(content: MessageEdit(replacingMessageID: UUID.create(), text: text), nonce: nonce)
        }
        do {
            try clientMessage.setUnderlyingMessage(genericMessage)
        } catch {
            XCTFail()
        }
        clientMessage.visibleInConversation = conversation
        clientMessage.sender = selfUser
        return clientMessage
    }

    func testThatItKeepsMentionsWhenSettingImageData() {
        // given
        let clientMessage = insertMessageWithLinkPreview(contentType: .textMessage)
        let imageData = mediumJPEGData()

        // when
        let properties = ZMIImageProperties(size: CGSize(width: 42, height: 12), length: UInt(imageData.count), mimeType: "image/jpeg")
        clientMessage.setImageData(imageData, for: .medium, properties: properties)

        // then
        XCTAssertEqual(clientMessage.mentions.count, 1)
    }

    func testThatItCachesAndEncryptsTheMediumImage_TextMessage() {
        // given
        let clientMessage = insertMessageWithLinkPreview(contentType: .textMessage)
        let imageData = mediumJPEGData()

        // when
        let properties = ZMIImageProperties(size: CGSize(width: 42, height: 12), length: UInt(imageData.count), mimeType: "image/jpeg")
        clientMessage.setImageData(imageData, for: .medium, properties: properties)

        // then
        XCTAssertNotNil(self.uiMOC.zm_fileAssetCache.assetData(clientMessage, format: .medium, encrypted: false))
        XCTAssertNotNil(self.uiMOC.zm_fileAssetCache.assetData(clientMessage, format: .medium, encrypted: true))

        guard let linkPreview = clientMessage.underlyingMessage?.linkPreviews.first else { return XCTFail("did not contain linkpreview") }
        XCTAssertNotNil(linkPreview.image.uploaded.otrKey)
        XCTAssertNotNil(linkPreview.image.uploaded.sha256)

        let original = linkPreview.image.original
        XCTAssertEqual(Int(original.size), imageData.count)
        XCTAssertEqual(original.mimeType, "image/jpeg")
        XCTAssertEqual(original.image.width, 42)
        XCTAssertEqual(original.image.height, 12)
        XCTAssertFalse(original.hasName)
    }

    func testThatItCachesAndEncryptsTheMediumImage_EditMessage() {
        // given
        let clientMessage = insertMessageWithLinkPreview(contentType: .editMessage)
        let imageData = mediumJPEGData()

        // when
        let properties = ZMIImageProperties(size: CGSize(width: 42, height: 12), length: UInt(imageData.count), mimeType: "image/jpeg")
        clientMessage.setImageData(imageData, for: .medium, properties: properties)

        // then
        XCTAssertNotNil(self.uiMOC.zm_fileAssetCache.assetData(clientMessage, format: .medium, encrypted: false))
        XCTAssertNotNil(self.uiMOC.zm_fileAssetCache.assetData(clientMessage, format: .medium, encrypted: true))

        guard let linkPreview = clientMessage.underlyingMessage?.linkPreviews.first else { return XCTFail("did not contain linkpreview") }
        XCTAssertNotNil(linkPreview.image.uploaded.otrKey)
        XCTAssertNotNil(linkPreview.image.uploaded.sha256)

        let original = linkPreview.image.original
        XCTAssertEqual(Int(original.size), imageData.count)
        XCTAssertEqual(original.mimeType, "image/jpeg")
        XCTAssertEqual(original.image.width, 42)
        XCTAssertEqual(original.image.height, 12)
        XCTAssertFalse(original.hasName)
    }

    func testThatUpdatesLinkPreviewStateAndDeleteOriginalDataAfterProcessingFinishes() {
        // given
        let nonce = UUID()
        let clientMessage = ZMClientMessage(nonce: nonce, managedObjectContext: uiMOC)
        clientMessage.sender = selfUser
        clientMessage.visibleInConversation = conversation
        self.uiMOC.zm_fileAssetCache.storeAssetData(clientMessage, format: .original, encrypted: false, data: mediumJPEGData())

        // when
        clientMessage.processingDidFinish()

        // then
        XCTAssertEqual(clientMessage.linkPreviewState, ZMLinkPreviewState.processed)
        XCTAssertNil(self.uiMOC.zm_fileAssetCache.assetData(clientMessage, format: .original, encrypted: false))
    }

    func testThatItReturnsCorrectOriginalImageSize() {
        // given
        let nonce = UUID()
        let clientMessage = ZMClientMessage(nonce: nonce, managedObjectContext: uiMOC)
        clientMessage.sender = selfUser
        clientMessage.visibleInConversation = conversation
        self.uiMOC.zm_fileAssetCache.storeAssetData(clientMessage, format: .original, encrypted: false, data: mediumJPEGData())

        // when
        let imageSize = clientMessage.originalImageSize()

        // then
        XCTAssertEqual(imageSize, CGSize(width: 1352, height: 1803))
    }

}
