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
@testable import WireDataModel

class TransferStateMigrationTests: DiskDatabaseTest {

    override func setUp() {
        super.setUp()

        // Batch update doesn't inform the MOC of any changes so we disable caching in order to fetch directly from the store
        moc.stalenessInterval = 0.0
    }

    func verifyThatLegacyTransferStateIsMigrated(_ rawLegacyTranferState: Int, expectedTranferState: AssetTransferState, line: UInt = #line) throws {
        // Given
        let conversation = createConversation()
        let assetMessage = try! conversation.appendImage(from: verySmallJPEGData()) as! ZMAssetClientMessage
        moc.stalenessInterval = 0.0
        moc.willChangeValue(forKey: #keyPath(ZMAssetClientMessage.transferState))
        assetMessage.setPrimitiveValue(rawLegacyTranferState, forKey: #keyPath(ZMAssetClientMessage.transferState))
        moc.didChangeValue(forKey: #keyPath(ZMAssetClientMessage.transferState))
        try self.moc.save()

        // When
        WireDataModel.TransferStateMigration.migrateLegacyTransferState(in: moc)

        // Then
        moc.refresh(assetMessage, mergeChanges: false)
        XCTAssertEqual(assetMessage.transferState, expectedTranferState, "\(assetMessage.transferState.rawValue) is not equal to \(expectedTranferState.rawValue)", line: line)
        moc.delete(assetMessage)
        try moc.save()
    }

    func testThatItMigratesTheLegacyTransferState() throws {
        let expectedMapping: [(WireDataModel.TransferStateMigration.LegacyTransferState, AssetTransferState)] =
            [(.uploading, .uploading),
             (.uploaded, .uploaded),
             (.cancelledUpload, .uploadingCancelled),
             (.downloaded, .uploaded),
             (.downloading, .uploaded),
             (.failedDownloaded, .uploaded),
             (.failedUpload, .uploadingFailed)]

        for (legacy, migrated) in expectedMapping {
            try verifyThatLegacyTransferStateIsMigrated(legacy.rawValue, expectedTranferState: migrated)
        }
    }

}
