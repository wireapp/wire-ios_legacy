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
@testable import WireRequestStrategy

class AssetsPreprocessorTests: MessagingTestBase {

    var sut: AssetsPreprocessor!
    var conversation: ZMConversation!

    override func setUp() {
        super.setUp()

        sut = AssetsPreprocessor(managedObjectContext: uiMOC)
        conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.remoteIdentifier = UUID()
    }

    override func tearDown() {
        sut = nil
        conversation = nil

        super.tearDown()
    }

    func testThatItPreprocessAssetMessage() {
        // given
        let message = try! conversation.appendImage(from: verySmallJPEGData()) as! ZMAssetClientMessage
        let asset = message.assets.first!
        let messageSet: Set<NSManagedObject> = [message]

        // when
        sut.objectsDidChange(messageSet)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertTrue(asset.hasEncrypted)
        XCTAssertTrue(asset.hasPreprocessed)
    }

    func testThatItPreprocessAssetMessageWithMultipleAssets() {
        // given
        let message = try! conversation.appendFile(with: ZMVideoMetadata(fileURL: self.fileURL(forResource: "video", extension: "mp4"), thumbnail: self.verySmallJPEGData())) as! ZMAssetClientMessage
        let messageSet: Set<NSManagedObject> = [message]
        let assets = message.assets
        XCTAssertEqual(assets.count, 2)

        // when
        sut.objectsDidChange(messageSet)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        for asset in assets {
            XCTAssertTrue(asset.hasEncrypted)

            if asset.needsPreprocessing {
                XCTAssertTrue(asset.hasPreprocessed)
            }
        }
    }

    func testThatItMarksTheTransferStateAsModifiedAfterItsDoneProcessing() {
        // given
        let message = try! conversation.appendImage(from: verySmallJPEGData()) as! ZMAssetClientMessage
        let messageSet: Set<NSManagedObject> = [message]

        // when
        sut.objectsDidChange(messageSet)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertTrue(message.modifiedKeys!.contains(#keyPath(ZMAssetClientMessage.transferState)))
    }

}
