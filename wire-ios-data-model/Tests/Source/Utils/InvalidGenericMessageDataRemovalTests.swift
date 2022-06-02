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
import WireTesting
@testable import WireDataModel

class InvalidGenericMessageDataRemovalTests: DiskDatabaseTest {

    func testThatItDoesNotRemoveValidGenericMessageData() throws {
        // Given
        let conversation = createConversation()
        let textMessage = try! conversation.appendText(content: "Hello world") as! ZMClientMessage
        let genericMessageData = textMessage.dataSet.firstObject! as! ZMGenericMessageData
        try self.moc.save()

        // When
        WireDataModel.InvalidGenericMessageDataRemoval.removeInvalid(in: self.moc)

        // Then
        XCTAssertFalse(genericMessageData.isDeleted)
        XCTAssertFalse(genericMessageData.isZombieObject)
    }

    func testThatItDoesRemoveInvalidGenericMessageData() throws {
        // Given
        let conversation = createConversation()
        let textMessage = try! conversation.appendText(content: "Hello world") as! ZMClientMessage
        let genericMessageData = textMessage.dataSet.firstObject! as! ZMGenericMessageData
        try self.moc.save()

        // Then
        XCTAssertFalse(genericMessageData.isDeleted)
        XCTAssertFalse(genericMessageData.isZombieObject)

        // And when
        genericMessageData.message = nil
        try self.moc.save()

        // When
        WireDataModel.InvalidGenericMessageDataRemoval.removeInvalid(in: self.moc)

        // Then
        XCTAssertTrue(genericMessageData.isDeleted)
        XCTAssertTrue(genericMessageData.isZombieObject)
    }

    func testThatItDoesNotRemoveValidGenericMessageData_Asset() throws {
        // Given
        let conversation = createConversation()
        let assetMessage = try! conversation.appendImage(from: self.verySmallJPEGData()) as! ZMAssetClientMessage
        let genericMessageData = assetMessage.dataSet.firstObject! as! ZMGenericMessageData
        try self.moc.save()

        // When
        WireDataModel.InvalidGenericMessageDataRemoval.removeInvalid(in: self.moc)

        // Then
        XCTAssertFalse(genericMessageData.isDeleted)
        XCTAssertFalse(genericMessageData.isZombieObject)
    }

    func testThatItDoesRemoveInvalidGenericMessageData_Asset() throws {
        // Given
        let conversation = createConversation()
        let assetMessage = try! conversation.appendImage(from: self.verySmallJPEGData()) as! ZMAssetClientMessage
        let genericMessageData = assetMessage.dataSet.firstObject! as! ZMGenericMessageData
        try self.moc.save()

        // Then
        XCTAssertFalse(genericMessageData.isDeleted)
        XCTAssertFalse(genericMessageData.isZombieObject)

        // And when

        genericMessageData.asset = nil
        try self.moc.save()

        // When
        WireDataModel.InvalidGenericMessageDataRemoval.removeInvalid(in: self.moc)

        // Then
        XCTAssertTrue(genericMessageData.isDeleted)
        XCTAssertTrue(genericMessageData.isZombieObject)
    }

}
