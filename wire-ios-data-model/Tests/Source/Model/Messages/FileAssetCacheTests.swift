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

class FileAssetCacheTests: BaseZMMessageTests {
    override func setUp() {
        super.setUp()
        createSelfClient()
        FileAssetCache().wipeCaches()
    }

    override func tearDown() {
        FileAssetCache().wipeCaches()
        super.tearDown()
    }

    fileprivate func createMessageForCaching() -> ZMConversationMessage {
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.remoteIdentifier = UUID()

        let message = try! conversation.appendText(content: "123")

        return message
    }

    fileprivate func testData() -> Data {
        return Data.secureRandomData(ofLength: 2000)
    }

}

// MARK: - Storing and retrieving image assets
extension FileAssetCacheTests {

    func testThatStoringAndRetrievingAssetsWithDifferentOptionsRetrievesTheRightData() {

        // given
        let sut = FileAssetCache()
        let message1 = createMessageForCaching()
        let message2 = createMessageForCaching()
        let data1_plain = "data1_plain".data(using: String.Encoding.utf8)!
        let data2_plain = "data2_plain".data(using: String.Encoding.utf8)!
        let data1_enc = "data1_enc".data(using: String.Encoding.utf8)!
        let data2_enc = "data2_enc".data(using: String.Encoding.utf8)!

        sut.storeAssetData(message1, encrypted: true, data: data1_enc)
        sut.storeAssetData(message2, encrypted: true, data: data2_enc)
        sut.storeAssetData(message1, encrypted: false, data: data1_plain)
        sut.storeAssetData(message2, encrypted: false, data: data2_plain)

        // then
        XCTAssertEqual(sut.assetData(message1, encrypted: false), data1_plain)
        XCTAssertEqual(sut.assetData(message2, encrypted: false), data2_plain)
        XCTAssertEqual(sut.assetData(message1, encrypted: true), data1_enc)
        XCTAssertEqual(sut.assetData(message2, encrypted: true), data2_enc)

        XCTAssertTrue(sut.hasDataOnDisk(message1, encrypted: false))
        XCTAssertTrue(sut.hasDataOnDisk(message2, encrypted: false))
        XCTAssertTrue(sut.hasDataOnDisk(message1, encrypted: true))
        XCTAssertTrue(sut.hasDataOnDisk(message2, encrypted: true))
    }

    func testThatCreationDateIsLinkedToMessageServerTimestamp() throws {
        // given
        let sut = FileAssetCache()
        let message = createMessageForCaching() as! ZMClientMessage
        message.serverTimestamp = Date(timeIntervalSinceReferenceDate: 1000)

        // when
        sut.storeAssetData(message, encrypted: false, data: "data1_plain".data(using: String.Encoding.utf8)!)

        // then
        let attributes = try FileManager.default.attributesOfItem(atPath: sut.accessAssetURL(message)!.path)
        let creationDate = attributes[.creationDate] as? Date
        XCTAssertEqual(creationDate, message.serverTimestamp)
    }

    func testThatHasDataOnDisk() {

        // given
        let sut = FileAssetCache()
        let message = createMessageForCaching()
        sut.storeAssetData(message, encrypted: false, data: testData())

        // when
        let data = sut.hasDataOnDisk(message, encrypted: false)

        // then
        XCTAssertTrue(data)
    }

    func testThatHasNoDataOnDiskWithWrongEncryptionFlag() {

        // given
        let sut = FileAssetCache()
        let message = createMessageForCaching()
        sut.storeAssetData(message, encrypted: false, data: testData())

        // when
        let data = sut.hasDataOnDisk(message, encrypted: true)

        // then
        XCTAssertFalse(data)
    }

    func testThatRetrievingMissingAssetsUUIDReturnsNil() {

        // given
        let sut = FileAssetCache()
        let message1 = createMessageForCaching()
        let message2 = createMessageForCaching()
        sut.storeAssetData(message1, encrypted: false, data: testData())

        // when
        let data = sut.assetData(message2, encrypted: false)

        // then
        XCTAssertNil(data)
    }

    func testThatHasNoDataOnDiskWithWrongUUID() {

        // given
        let sut = FileAssetCache()
        let message1 = createMessageForCaching()
        let message2 = createMessageForCaching()
        sut.storeAssetData(message1, encrypted: false, data: testData())

        // when
        let data = sut.hasDataOnDisk(message2, encrypted: false)

        // then
        XCTAssertFalse(data)
    }

    func testThatAssetsAreLoadedAcrossInstances() {
        // given
        let message = createMessageForCaching()
        let data = testData()
        let sut = FileAssetCache()
        sut.storeAssetData(message, encrypted: false, data: data)

        // when
        let extractedData = FileAssetCache().assetData(message, encrypted: false)

        // then
        XCTAssertEqual(extractedData, data)
    }

    func testThatItDeletesAnExistingAssetData() {

        // given
        let message = createMessageForCaching()
        let data = testData()
        let sut = FileAssetCache()
        sut.storeAssetData(message, encrypted: false, data: data)

        // when
        sut.deleteAssetData(message, encrypted: false)
        let extractedData = sut.assetData(message, encrypted: false)

        // then
        XCTAssertNil(extractedData)
    }

    func testThatItDeletesTheRightAssetData() {

        // given
        let message1 = createMessageForCaching()
        let message2 = createMessageForCaching()
        let data = testData()
        let sut = FileAssetCache()
        sut.storeAssetData(message1, encrypted: true, data: data)
        sut.storeAssetData(message1, encrypted: false, data: data)

        // when
        sut.deleteAssetData(message1, encrypted: false) // this one exists
        sut.deleteAssetData(message2, encrypted: false) // this one doesn't exist
        let expectedNilData = sut.assetData(message1, encrypted: false)
        let expectedNotNilData = sut.assetData(message1, encrypted: true)

        // then
        XCTAssertNil(expectedNilData)
        AssertOptionalEqual(expectedNotNilData, expression2: data)
    }

    func testThatItDeletesAssets_WhenAssetIsOlderThanGivenDate() {
        let message = createMessageForCaching()
        let data = testData()
        let sut = FileAssetCache()
        sut.storeAssetData(message, encrypted: false, data: data)

        // when
        sut.deleteAssetsOlderThan(Date())

        // then
        XCTAssertNil(sut.assetData(message, encrypted: false))
    }

    func testThatItKeepsAssets_WhenAssetIsNewerThanGivenDate() {
        let message = createMessageForCaching()
        let data = testData()
        let sut = FileAssetCache()
        sut.storeAssetData(message, encrypted: false, data: data)

        // when
        sut.deleteAssetsOlderThan(Date.distantPast)

        // then
        XCTAssertNotNil(sut.assetData(message, encrypted: false))
    }
}

extension FileAssetCacheTests {

    func testThatItDoesNotDecryptAFileThatDoesNotExistSHA256() {

        // given
        let sut = FileAssetCache()
        let message = createMessageForCaching()

        // when
        let result = sut.decryptFileIfItMatchesDigest(message, encryptionKey: Data.randomEncryptionKey(), sha256Digest: Data.secureRandomData(ofLength: 128))

        // then
        XCTAssertFalse(result)
    }

    // @SF.Messages @TSFI.RESTfulAPI @S0.1 @S0.2 @S0.3
    func testThatItDoesNotDecryptAndDeletesAFileWithWrongSHA256() {

        // given
        let message = createMessageForCaching()
        let sut = FileAssetCache()
        sut.storeAssetData(message, encrypted: true, data: testData())

        // when
        let result = sut.decryptFileIfItMatchesDigest(message, encryptionKey: Data.randomEncryptionKey(), sha256Digest: Data.secureRandomData(ofLength: 128))
        XCTAssertFalse(result)

        // then
        let extractedData = sut.assetData(message, encrypted: true)
        XCTAssertNil(extractedData)
    }

    // @SF.Messages @TSFI.RESTfulAPI @S0.1 @S0.2 @S0.3
    func testThatItDoesDecryptAndDeletesAFileWithTheRightSHA256() {

        // given
        let sut = FileAssetCache()
        let message = createMessageForCaching()
        let plainTextData = Data.secureRandomData(ofLength: 500)
        let key = Data.randomEncryptionKey()
        let encryptedData = plainTextData.zmEncryptPrefixingPlainTextIV(key: key)
        sut.storeAssetData(message, encrypted: true, data: encryptedData)
        let sha = encryptedData.zmSHA256Digest()

        // when
        let result = sut.decryptFileIfItMatchesDigest(message, encryptionKey: key, sha256Digest: sha)

        // then
        XCTAssertTrue(result)
        let decryptedData = sut.assetData(message, encrypted: false)
        XCTAssertEqual(decryptedData, plainTextData)
    }
}

// MARK: - File encryption
extension FileAssetCacheTests {

    func testThatReturnsNilWhenEncryptingAMissingFileWithSHA256() {

        // given
        let sut = FileAssetCache()
        let message = createMessageForCaching()

        // when
        let result = sut.encryptFileAndComputeSHA256Digest(message)

        // then
        AssertOptionalNil(result)
        XCTAssertNil(sut.assetData(message, encrypted: true))
    }

    func testThatItCreatesTheEncryptedFileAndDoesNotDeletedThePlainTextWithSHA256() {

        // given
        let sut = FileAssetCache()
        let message = createMessageForCaching()
        let plainData = Data.secureRandomData(ofLength: 500)

        sut.storeAssetData(message, encrypted: false, data: plainData)

        // when
        _ = sut.encryptFileAndComputeSHA256Digest(message)

        // then
        XCTAssertNotNil(sut.assetData(message, encrypted: true))
        XCTAssertNotNil(sut.assetData(message, encrypted: false))
    }

    func testThatItReturnsCorrectEncryptionResultWithSHA256() {
        // given
        let sut = FileAssetCache()
        let message = createMessageForCaching()
        let plainData = Data.secureRandomData(ofLength: 500)

        sut.storeAssetData(message, encrypted: false, data: plainData)

        // when
        let result = sut.encryptFileAndComputeSHA256Digest(message)

        // then
        let encryptedData = sut.assetData(message, encrypted: true)
        AssertOptionalNotNil(result, "Result") { result in
            AssertOptionalNotNil(encryptedData, "Encrypted data") { encryptedData in
                let decodedData = encryptedData.zmDecryptPrefixedPlainTextIV(key: result.otrKey)
                XCTAssertEqual(decodedData, plainData)
                let sha = encryptedData.zmSHA256Digest()
                XCTAssertEqual(sha, result.sha256)
            }
        }
    }
}

// MARK: - Image encryption
extension FileAssetCacheTests {

    func testThatReturnsNilWhenEncryptingAMissingImageWithSHA256() {

        // given
        let sut = FileAssetCache()
        let message = createMessageForCaching()

        // when
        let result = sut.encryptImageAndComputeSHA256Digest(message, format: .medium)

        // then
        AssertOptionalNil(result)
        XCTAssertNil(sut.assetData(message, encrypted: true))
    }

    func testThatItCreatesTheEncryptedImageAndDoesNotDeletedThePlainTextWithSHA256() {

        // given
        let sut = FileAssetCache()
        let message = createMessageForCaching()
        let plainData = Data.secureRandomData(ofLength: 500)

        sut.storeAssetData(message, format: .medium, encrypted: false, data: plainData)

        // when
        _ = sut.encryptImageAndComputeSHA256Digest(message, format: .medium)

        // then
        XCTAssertNotNil(sut.assetData(message, format: .medium, encrypted: true))
        XCTAssertNotNil(sut.assetData(message, format: .medium, encrypted: false))
    }

    func testThatItReturnsCorrectEncryptionImageResultWithSHA256() {
        // given
        let sut = FileAssetCache()
        let message = createMessageForCaching()
        let plainData = Data.secureRandomData(ofLength: 500)

        sut.storeAssetData(message, format: .medium, encrypted: false, data: plainData)

        // when
        let result = sut.encryptImageAndComputeSHA256Digest(message, format: .medium)

        // then
        let encryptedData = sut.assetData(message, format: .medium, encrypted: true)
        AssertOptionalNotNil(result, "Result") { result in
            AssertOptionalNotNil(encryptedData, "Encrypted data") { encryptedData in
                let decodedData = encryptedData.zmDecryptPrefixedPlainTextIV(key: result.otrKey)
                XCTAssertEqual(decodedData, plainData)
                let sha = encryptedData.zmSHA256Digest()
                XCTAssertEqual(sha, result.sha256)
            }
        }
    }
}

// MARK: - File urls
extension FileAssetCacheTests {

    func testThatItStoresTheRequestDataAndReturnsTheFileURL() {
        let sut = FileAssetCache()
        let message = createMessageForCaching()
        let requestData = Data.secureRandomData(ofLength: 500)

        // when
        let assetURL = sut.storeRequestData(message, data: requestData)

        // then
        guard let url = assetURL else { return XCTFail() }
        guard let data = try? Data(contentsOf: url) else { return XCTFail() }
        XCTAssertTrue(requestData == data)
    }

    func testThatItDeletesTheRequestData() {
        let sut = FileAssetCache()
        let message = createMessageForCaching()
        let requestData = Data.secureRandomData(ofLength: 500)

        // when
        let assetURL = sut.storeRequestData(message, data: requestData)
        sut.deleteRequestData(message)

        // then
        XCTAssertNotNil(assetURL)
        if let assetURL = assetURL {
            let data = try? Data(contentsOf: assetURL)
            XCTAssertNil(data)
        }
    }

    // MARK: - FileAssetCache

    func testThatItReturnsCorrectEncryptionTeamLogoResultWithSHA256() {

        syncMOC.performGroupedBlockAndWait {
            // given
            let sut = FileAssetCache()
            let team = Team.mockTeam(context: self.syncMOC)
            let assetId = UUID.create().transportString(), assetKey = UUID.create().transportString()
            team.pictureAssetId = assetId
            team.pictureAssetKey = assetKey

            let plainData = self.testData()

            sut.storeAssetData(for: team, format: .medium, encrypted: false, data: plainData)

            // when
            let encryptionKeys = sut.encryptImageAndComputeSHA256Digest(for: team, format: .medium)

            // then
            let encryptedData = sut.assetData(for: team, format: .medium, encrypted: true)
            AssertOptionalNotNil(encryptionKeys, "Result") { result in
                AssertOptionalNotNil(encryptedData, "Encrypted data") { encryptedData in
                    let decodedData = encryptedData.zmDecryptPrefixedPlainTextIV(key: result.otrKey)
                    XCTAssertEqual(decodedData, plainData)
                    let sha = encryptedData.zmSHA256Digest()
                    XCTAssertEqual(sha, result.sha256)
                }
            }

            // when
            let decryptResult = sut.decryptImageIfItMatchesDigest(for: team, format: .medium, encryptionKey: encryptionKeys!.otrKey)

            // then
            XCTAssert(decryptResult)
        }
    }

    func testThatHasDataOnDiskForTeam() {

        // given
        let sut = FileAssetCache()
        syncMOC.performGroupedBlockAndWait {

            let team = Team.mockTeam(context: self.syncMOC)
            team.pictureAssetId = "abc123"

            sut.storeAssetData(for: team,
                               format: .medium,
                               encrypted: false,
                               data: self.testData())

            // when
            let data = sut.hasDataOnDisk(for: team,
                                         format: .medium,
                                         encrypted: false)

            // then
            XCTAssert(data)
        }
    }

    func testThatItDeletesAnExistingAssetDataForTeam() {

        syncMOC.performGroupedBlockAndWait {
            // given
            let team = Team.mockTeam(context: self.syncMOC)
            team.pictureAssetId = "abc123"
            let sut = FileAssetCache()
            sut.storeAssetData(for: team,
                               format: .medium,
                               encrypted: false,
                               data: self.testData())

            // when
            sut.deleteAssetData(for: team,
                                format: .medium,
                                encrypted: false)
            let extractedData = sut.assetData(for: team,
                                              format: .medium,
                                              encrypted: false)

            // then
            XCTAssertNil(extractedData)
        }
    }

}
