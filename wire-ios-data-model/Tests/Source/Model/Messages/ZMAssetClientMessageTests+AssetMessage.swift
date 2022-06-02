//
// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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

class ZMAssetClientMessageTests_AssetMessage: BaseZMClientMessageTests {

    // MARK: Helpers

    var videoMetadataWithThumbnail: ZMVideoMetadata {
        return ZMVideoMetadata(fileURL: self.fileURL(forResource: "video", extension: "mp4"), thumbnail: verySmallJPEGData())
    }

    var videoMetadata: ZMVideoMetadata {
        return ZMVideoMetadata(fileURL: self.fileURL(forResource: "video", extension: "mp4"))
    }

    var fileMetadata: ZMFileMetadata {
        return ZMFileMetadata(fileURL: self.fileURL(forResource: "Lorem Ipsum", extension: "txt"))
    }

    // MARK: Assets

    func testThatReturnsAssetsForImageMessage() {
        // given
        let message = try! conversation.appendImage(from: verySmallJPEGData()) as! ZMAssetClientMessage

        // then
        XCTAssertEqual(message.assets.count, 1)
    }

    func testThatReturnsAssetsForFileMessage() {
        // given
        let message = try! conversation.appendFile(with: fileMetadata) as! ZMAssetClientMessage

        // then
        XCTAssertEqual(message.assets.count, 1)
    }

    func testThatReturnsAssetsForVideoMessage() {
        // given
        let message = try! conversation.appendFile(with: videoMetadata) as! ZMAssetClientMessage

        // then
        XCTAssertEqual(message.assets.count, 1)
    }

    func testThatReturnsAssetsForVideoMessage_WithThumbnail() {
        // given
        let message = try! conversation.appendFile(with: videoMetadataWithThumbnail) as! ZMAssetClientMessage

        // then
        XCTAssertEqual(message.assets.count, 2)
    }

    // MARK: Processing State

    func testThatProcessingStateIsProcessing_WhenEncryptedDataIsMissing() {
        // given
        let message = try! conversation.appendFile(with: fileMetadata) as! ZMAssetClientMessage

        // then
        XCTAssertEqual(message.processingState, .preprocessing)
    }

    func testThatProcessingStateIsProcessing_WhenEncryptedDataIsPartiallyMissing() {
        // given
        let message = try! conversation.appendFile(with: videoMetadataWithThumbnail) as! ZMAssetClientMessage
        message.assets.last?.encrypt()

        // then
        XCTAssertEqual(message.processingState, .preprocessing)
    }

    func testThatProcessingStateIsUploading_WhenEncryptedDataIsPresent() {
        // given
        let message = try! conversation.appendFile(with: fileMetadata) as! ZMAssetClientMessage
        message.assets.first?.encrypt()

        // then
        XCTAssertEqual(message.processingState, .uploading)
    }

    func testThatProcessingStateIsUploading_WhenWhenAssetsIsPartiallyUploaded() {
        // given
        let message = try! conversation.appendFile(with: videoMetadataWithThumbnail) as! ZMAssetClientMessage
        message.assets.last?.updateWithPreprocessedData(verySmallJPEGData(), imageProperties: ZMIImageProperties(size: CGSize(width: 5, height: 5), length: 100, mimeType: "image/jpeg"))
        message.assets.forEach({ $0.encrypt() })
        message.assets.first?.updateWithAssetId("123", token: "abc", domain: UUID().uuidString)

        // then
        XCTAssertEqual(message.processingState, .uploading)
    }

    func testThatProcessingStateIsDone_WhenAssetsIsUploaded() {
        // given
        let message = try! conversation.appendFile(with: fileMetadata) as! ZMAssetClientMessage
        message.assets.first?.encrypt()
        message.assets.first?.updateWithAssetId("123", token: "abc", domain: UUID().uuidString)

        // then
        XCTAssertEqual(message.processingState, .done)
    }

}
