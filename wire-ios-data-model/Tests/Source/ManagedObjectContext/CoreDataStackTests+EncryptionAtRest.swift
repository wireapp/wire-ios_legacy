////
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

final class CoreDataStackTests_EncryptionAtRest: DatabaseBaseTest {

    // @SF.Storage @TSFI.FS-IOS @TSFI.Enclave-IOS @S0.1 @S0.2
    // This test makes sure that the database encryption keys are actually deleted on all core data contexts (in this case view, sync and search)
    func testThatItStoresAndClearsDatabaseKeyOnAllContexts() throws {
        // Given
        let sut = createStorageStackAndWaitForCompletion()
        let account = Account(userName: "", userIdentifier: UUID())
#if targetEnvironment(simulator) && swift(>=5.4)
        if #available(iOS 15, *) {
            XCTExpectFailure("Expect to fail on iOS 15 simulator. ref: https://wearezeta.atlassian.net/browse/SQCORE-1188")
        }
#endif
        let encryptionKeys = try XCTUnwrap( EncryptionKeys.createKeys(for: account))

        // When
        sut.storeEncryptionKeysInAllContexts(encryptionKeys: encryptionKeys)

        // Then
        sut.viewContext.performGroupedBlockAndWait {
            XCTAssertEqual(sut.viewContext.encryptionKeys, encryptionKeys)
        }

        sut.syncContext.performGroupedBlockAndWait {
            XCTAssertEqual(sut.syncContext.encryptionKeys, encryptionKeys)
        }

        sut.searchContext.performGroupedBlockAndWait {
            XCTAssertEqual(sut.searchContext.encryptionKeys, encryptionKeys)
        }

        // When
        sut.clearEncryptionKeysInAllContexts()

        // Then
        sut.viewContext.performGroupedBlockAndWait {
            XCTAssertNil(sut.viewContext.encryptionKeys)
        }

        sut.syncContext.performGroupedBlockAndWait {
            XCTAssertNil(sut.syncContext.encryptionKeys)
        }

        sut.searchContext.performGroupedBlockAndWait {
            XCTAssertNil(sut.searchContext.encryptionKeys)
        }

        // Clean up
        try! EncryptionKeys.deleteKeys(for: account)
    }

}
