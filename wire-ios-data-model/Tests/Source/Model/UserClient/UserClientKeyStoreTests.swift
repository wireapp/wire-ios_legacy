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
@testable import WireDataModel
import WireCryptobox

class UserClientKeysStoreTests: OtrBaseTest {

    var sut: UserClientKeysStore!
    var accountID: UUID!
    var accountFolder: URL!

    override func setUp() {
        super.setUp()
        self.accountID = UUID()
        self.accountFolder = CoreDataStack.accountDataFolder(accountIdentifier: accountID, applicationContainer: OtrBaseTest.sharedContainerURL)
        self.cleanOTRFolder()
        self.sut = UserClientKeysStore(accountDirectory: accountFolder, applicationContainer: OtrBaseTest.sharedContainerURL)
    }

    override func tearDown() {
        self.sut = nil
        self.cleanOTRFolder()
        self.accountID = nil
        self.accountFolder = nil
        super.tearDown()
    }

    func cleanOTRFolder() {
        let fm = FileManager.default
        var paths: [String] = []
        if let accountID = accountID {
            paths.append(OtrBaseTest.otrDirectoryURL(accountIdentifier: accountID).path)
        }
        paths.forEach { try? fm.removeItem(atPath: $0) }
    }

    func testThatTheOTRFolderHasBackupDisabled() {
        // when
        guard let values = try? self.sut.cryptoboxDirectory.resourceValues(forKeys: Set(arrayLiteral: URLResourceKey.isExcludedFromBackupKey)) else {return XCTFail()}

        // then
        XCTAssertTrue(values.isExcludedFromBackup!)
    }

    func testThatItCanGenerateMoreKeys() {
        // when
        do {
            let newKeys = try sut.generateMoreKeys(1, start: 0)
            XCTAssertNotEqual(newKeys.count, 0, "Should generate more keys")

        } catch let error as NSError {
            XCTAssertNil(error, "Should not return error while generating key")

        }
    }

    func testThatItWrapsKeysTo0WhenReachingTheMaximum() {
        // given
        let maxPreKey: UInt16 = UserClientKeysStore.MaxPreKeyID
        let prekeyBatchSize: UInt16 = 50
        let startingPrekey = maxPreKey - prekeyBatchSize - 1 // -1 is to generate at least 2 batches
        let maxIterations = 2

        var previousMaxKeyId: UInt16 = startingPrekey
        var iterations = 0

        // when
        while true {
            var newKeys : [(id: UInt16, prekey: String)]!
            var maxKey: UInt16!
            var minKey: UInt16!
            do {
                newKeys = try sut.generateMoreKeys(50, start: previousMaxKeyId)
                maxKey = newKeys.last?.id ?? 0
                minKey = newKeys.first?.id ?? 0
            } catch let error as NSError {
                XCTAssertNil(error, "Should not return error while generating key: \(error)")
                return
            }

            // then
            iterations += 1
            if iterations > maxIterations {
                XCTFail("Too many keys are generated without wrapping: \(iterations) iterations, max key is \(String(describing: maxKey))")
                return
            }

            XCTAssertGreaterThan(newKeys.count, 0, "Should generate more keys")
            if minKey == 0 { // it wrapped!!
                XCTAssertGreaterThan(iterations, 1)
                // success!
                return
            }

            XCTAssertEqual(minKey, previousMaxKeyId) // is it the right starting point?

            previousMaxKeyId = maxKey
            if maxKey > UserClientKeysStore.MaxPreKeyID {
                XCTFail("Prekey \(String(describing: maxKey)) is too big")
                return
            }

        }

    }

    fileprivate func createLegacyOTRFolderWithDummyFile(fileName: String, data: Data, folder: URL = OtrBaseTest.legacyOtrDirectory) -> URL {
        try! FileManager.default.createDirectory(atPath: folder.path, withIntermediateDirectories: true, attributes: [:])
        try! data.write(to: folder.appendingPathComponent(fileName))
        return folder
    }

}
