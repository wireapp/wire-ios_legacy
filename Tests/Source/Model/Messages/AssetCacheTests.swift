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
@testable import ZMCDataModel

private func testData() -> NSData {
    return NSData.secureRandomDataOfLength(2000);
}

class ImageAssetCacheTests: XCTestCase {
}

class FileAssetCacheTests: XCTestCase {
    override func setUp() {
        FileAssetCache.wipeCaches()
    }
}

// MARK: - Storing and retrieving image assets
extension ImageAssetCacheTests {
    
    func testThatStoringAndRetrievingAssetsWithDifferentOptionsRetrievesTheRightData() {
        
        // given
        let sut = ImageAssetCache(MBLimit: 5)
        let msg1 = NSUUID.createUUID()
        let msg2 = NSUUID.createUUID()
        let msg1_full_enc = "msg1_full_enc".dataUsingEncoding(NSUTF8StringEncoding)!
        let msg2_full_enc = "msg2_full_enc".dataUsingEncoding(NSUTF8StringEncoding)!
        let msg1_prev_enc = "msg1_prev_enc".dataUsingEncoding(NSUTF8StringEncoding)!
        let msg2_prev_enc = "msg2_prev_enc".dataUsingEncoding(NSUTF8StringEncoding)!
        let msg1_full = "msg1_full".dataUsingEncoding(NSUTF8StringEncoding)!
        let msg2_full = "msg2_full".dataUsingEncoding(NSUTF8StringEncoding)!
        let msg1_prev = "msg1_prev".dataUsingEncoding(NSUTF8StringEncoding)!
        let msg2_prev = "msg2_prev".dataUsingEncoding(NSUTF8StringEncoding)!
        
        sut.storeAssetData(msg1, format: .Medium, encrypted: true, data: msg1_full_enc)
        sut.storeAssetData(msg2, format: .Medium, encrypted: true, data: msg2_full_enc)
        sut.storeAssetData(msg1, format: .Preview, encrypted: true, data: msg1_prev_enc)
        sut.storeAssetData(msg2, format: .Preview, encrypted: true, data: msg2_prev_enc)
        sut.storeAssetData(msg1, format: .Medium, encrypted: false, data: msg1_full)
        sut.storeAssetData(msg2, format: .Medium, encrypted: false, data: msg2_full)
        sut.storeAssetData(msg1, format: .Preview, encrypted: false, data: msg1_prev)
        sut.storeAssetData(msg2, format: .Preview, encrypted: false, data: msg2_prev)
        
        
        // then
        XCTAssertEqual(sut.assetData(msg1, format: .Medium, encrypted: true), msg1_full_enc, "msg1_full_enc does not match")
        XCTAssertEqual(sut.assetData(msg2, format: .Medium, encrypted: true), msg2_full_enc, "msg2_full_enc does not match")
        XCTAssertEqual(sut.assetData(msg1, format: .Preview, encrypted: true), msg1_prev_enc, "msg1_prev_enc does not match")
        XCTAssertEqual(sut.assetData(msg2, format: .Preview, encrypted: true), msg2_prev_enc, "msg2_prev_enc does not match")
        XCTAssertEqual(sut.assetData(msg1, format: .Medium, encrypted: false), msg1_full, "msg1_full does not match")
        XCTAssertEqual(sut.assetData(msg2, format: .Medium, encrypted: false), msg2_full, "msg2_full does not match")
        XCTAssertEqual(sut.assetData(msg1, format: .Preview, encrypted: false), msg1_prev, "msg1_prev does not match")
        XCTAssertEqual(sut.assetData(msg2, format: .Preview, encrypted: false), msg2_prev, "msg2_prev does not match")
        
    }
    
    func testThatRetrievingMissingAssetsReturnsNil() {
        
        // given
        let sut = ImageAssetCache(MBLimit: 5)
        sut.storeAssetData(NSUUID.createUUID(), format: .Medium, encrypted: false, data: testData())
        
        // when
        let data = sut.assetData(NSUUID.createUUID(), format: .Medium, encrypted: false)
        
        // then
        XCTAssertNil(data)
    }
    
    func testThatAssetsAreLoadedAcrossInstances() {
        // given
        let msgID = NSUUID.createUUID()
        let data = testData()
        let sut = ImageAssetCache(MBLimit: 5)
        sut.storeAssetData(msgID, format: .Medium, encrypted: false, data: data)
        
        // when
        let extractedData = ImageAssetCache(MBLimit: 5).assetData(msgID, format: .Medium, encrypted: false)
        
        // then
        XCTAssertEqual(extractedData, data)
    }
    
    func testThatItDeletesAnExistingAssetData() {
        
        // given
        let msgID = NSUUID.createUUID()
        let data = testData()
        let sut = ImageAssetCache(MBLimit: 5)
        sut.storeAssetData(msgID, format: .Medium, encrypted: false, data: data)
        
        // when
        sut.deleteAssetData(msgID, format: .Medium, encrypted: false)
        let extractedData = sut.assetData(msgID, format: .Medium, encrypted: false)
        
        // then
        XCTAssertNil(extractedData)
    }
    
    func testThatItDeletesTheRightAssetData() {
        
        // given
        let msgID = NSUUID.createUUID()
        let data = testData()
        let sut = ImageAssetCache(MBLimit: 5)
        sut.storeAssetData(msgID, format: .Medium, encrypted: true, data: data)
        sut.storeAssetData(msgID, format: .Medium, encrypted: false, data: data)
        
        // when
        sut.deleteAssetData(msgID, format: .Medium, encrypted: false) // this one exists
        sut.deleteAssetData(NSUUID.createUUID(), format: .Medium, encrypted: false) // this one doesn't exist
        let expectedNilData = sut.assetData(msgID, format: .Medium, encrypted: false)
        let expectedNotNilData = sut.assetData(msgID, format: .Medium, encrypted: true)
        
        // then
        XCTAssertNil(expectedNilData)
        XCTAssertEqual(expectedNotNilData, data)
    }
    
}

// MARK: - Storing and retrieving image assets
extension FileAssetCacheTests {
    
    func testThatStoringAndRetrievingAssetsWithDifferentOptionsRetrievesTheRightData() {
        
        // given
        let sut = FileAssetCache()
        let id1 = NSUUID.createUUID()
        let id2 = NSUUID.createUUID()
        let name1 = "file.txt"
        let name2 = "file.pdf"
        let data1_plain = "data1_plain".dataUsingEncoding(NSUTF8StringEncoding)!
        let data2_plain = "data2_plain".dataUsingEncoding(NSUTF8StringEncoding)!
        let data1_enc = "data1_enc".dataUsingEncoding(NSUTF8StringEncoding)!
        let data2_enc = "data2_enc".dataUsingEncoding(NSUTF8StringEncoding)!
        
        sut.storeAssetData(id1, fileName: name1, encrypted: true, data: data1_enc)
        sut.storeAssetData(id2, fileName: name2, encrypted: true, data: data2_enc)
        sut.storeAssetData(id1, fileName: name1, encrypted: false, data: data1_plain)
        sut.storeAssetData(id2, fileName: name2, encrypted: false, data: data2_plain)
        
        // then
        XCTAssertEqual(sut.assetData(id1, fileName: name1, encrypted: false), data1_plain)
        XCTAssertEqual(sut.assetData(id2, fileName: name2, encrypted: false), data2_plain)
        XCTAssertEqual(sut.assetData(id1, fileName: name1, encrypted: true), data1_enc)
        XCTAssertEqual(sut.assetData(id2, fileName: name2, encrypted: true), data2_enc)
        
        XCTAssertTrue(sut.hasDataOnDisk(id1, fileName: name1, encrypted: false))
        XCTAssertTrue(sut.hasDataOnDisk(id2, fileName: name2, encrypted: false))
        XCTAssertTrue(sut.hasDataOnDisk(id1, fileName: name1, encrypted: true))
        XCTAssertTrue(sut.hasDataOnDisk(id2, fileName: name2, encrypted: true))
    }
    
    func testThatRetrievingMissingAssetsFilenameReturnsNil() {
        
        // given
        let sut = FileAssetCache()
        let uuid = NSUUID.createUUID()
        sut.storeAssetData(uuid, fileName: "Mario.txt", encrypted: false, data: testData())
        
        // when
        let data = sut.assetData(uuid, fileName: "York.pdf", encrypted: false)
        
        // then
        XCTAssertNil(data)
    }
    
    func testThatHasDataOnDisk() {
        
        // given
        let sut = FileAssetCache()
        let uuid = NSUUID.createUUID()
        sut.storeAssetData(uuid, fileName: "Mario.txt", encrypted: false, data: testData())
        
        // when
        let data = sut.hasDataOnDisk(uuid, fileName: "Mario.txt", encrypted: false)
        
        // then
        XCTAssertTrue(data)
    }
    
    func testThatHasNoDataOnDiskWithWrongEncryptionFlag() {
        
        // given
        let sut = FileAssetCache()
        let uuid = NSUUID.createUUID()
        sut.storeAssetData(uuid, fileName: "Mario.txt", encrypted: false, data: testData())
        
        // when
        let data = sut.hasDataOnDisk(uuid, fileName: "Mario.txt", encrypted: true)
        
        // then
        XCTAssertFalse(data)
    }
    
    func testThatHasNoDataOnDiskWithWrongFileName() {
        
        // given
        let sut = FileAssetCache()
        let uuid = NSUUID.createUUID()
        sut.storeAssetData(uuid, fileName: "Mario.txt", encrypted: false, data: testData())
        
        // when
        let data = sut.hasDataOnDisk(uuid, fileName: "York.pdf", encrypted: false)
        
        // then
        XCTAssertFalse(data)
    }
    
    func testThatRetrievingMissingAssetsUUIDReturnsNil() {
        
        // given
        let sut = FileAssetCache()
        let name = "Report.txt"
        sut.storeAssetData(NSUUID.createUUID(), fileName: name, encrypted: false, data: testData())
        
        // when
        let data = sut.assetData(NSUUID.createUUID(), fileName: name, encrypted: false)
        
        // then
        XCTAssertNil(data)
    }
    
    func testThatHasNoDataOnDiskWithWrongUUID() {
        
        // given
        let sut = FileAssetCache()
        let name = "Report.txt"
        sut.storeAssetData(NSUUID.createUUID(), fileName: name, encrypted: false, data: testData())
        
        // when
        let data = sut.hasDataOnDisk(NSUUID.createUUID(), fileName: name, encrypted: false)
        
        // then
        XCTAssertFalse(data)
    }
    
    func testThatAssetsAreLoadedAcrossInstances() {
        // given
        let msgID = NSUUID.createUUID()
        let data = testData()
        let name = "Report.txt"
        let sut = FileAssetCache()
        sut.storeAssetData(msgID, fileName: name, encrypted: false, data: data)
        
        // when
        let extractedData = FileAssetCache().assetData(msgID, fileName: name, encrypted: false)
        
        // then
        XCTAssertEqual(extractedData, data)
    }
    
    func testThatItDeletesAnExistingAssetData() {
        
        // given
        let msgID = NSUUID.createUUID()
        let data = testData()
        let sut = FileAssetCache()
        let name = "full.pdf"
        sut.storeAssetData(msgID, fileName: name, encrypted: false, data: data)
        
        // when
        sut.deleteAssetData(msgID, fileName: name, encrypted: false)
        let extractedData = sut.assetData(msgID, fileName: name, encrypted: false)
        
        // then
        XCTAssertNil(extractedData)
    }
    
    func testThatItDeletesTheRightAssetData() {
        
        // given
        let msgID = NSUUID.createUUID()
        let data = testData()
        let name = "data.xls"
        let sut = FileAssetCache()
        sut.storeAssetData(msgID, fileName: name, encrypted: true, data: data)
        sut.storeAssetData(msgID, fileName: name, encrypted: false, data: data)
        
        // when
        sut.deleteAssetData(msgID, fileName: name, encrypted: false) // this one exists
        sut.deleteAssetData(NSUUID.createUUID(), fileName: name, encrypted: false) // this one doesn't exist
        let expectedNilData = sut.assetData(msgID, fileName: name, encrypted: false)
        let expectedNotNilData = sut.assetData(msgID, fileName: name, encrypted: true)
        
        // then
        XCTAssertNil(expectedNilData)
        AssertOptionalEqual(expectedNotNilData, expression2: data)
    }
}

// MARK: - Decryption and hash
extension ImageAssetCacheTests {
    
    func testThatItDoesNotDecryptAFileThatDoesNotExistSHA256() {
        
        // when
        let sut = ImageAssetCache(MBLimit: 5)
        let result = sut.decryptFileIfItMatchesDigest(NSUUID.createUUID(), format: .Medium, encryptionKey: NSData.randomEncryptionKey(), sha256Digest: NSData.secureRandomDataOfLength(128))
        
        // then
        XCTAssertFalse(result)
    }
    
    func testThatItDoesNotDecryptAndDeletesAFileWithWrongSHA256() {
        
        // given
        let messageID = NSUUID.createUUID()
        let sut = ImageAssetCache(MBLimit: 5)
        sut.storeAssetData(messageID, format: .Medium, encrypted: true, data: testData())
        
        // when
        let result = sut.decryptFileIfItMatchesDigest(messageID, format: .Medium, encryptionKey: NSData.randomEncryptionKey(), sha256Digest: NSData.secureRandomDataOfLength(128))
        XCTAssertFalse(result)
        
        // then
        let extractedData = sut.assetData(messageID, format: .Medium, encrypted: true)
        XCTAssertNil(extractedData)
    }
    
    func testThatItDoesDecryptAndDeletesAFileWithTheRightSHA256() {
        
        // given
        let sut = ImageAssetCache(MBLimit: 5)
        let messageID = NSUUID.createUUID()
        let plainTextData = NSData.secureRandomDataOfLength(500)
        let key = NSData.randomEncryptionKey()
        let encryptedData = plainTextData.zmEncryptPrefixingPlainTextIVWithKey(key)
        sut.storeAssetData(messageID, format: .Medium, encrypted: true, data: encryptedData)
        let sha = encryptedData.zmSHA256Digest()
        
        // when
        let result = sut.decryptFileIfItMatchesDigest(messageID, format: .Medium, encryptionKey: key, sha256Digest: sha)
        
        // then
        XCTAssertTrue(result)
        let decryptedData = sut.assetData(messageID, format: .Medium, encrypted: false)
        XCTAssertEqual(decryptedData, plainTextData)
    }
}

extension FileAssetCacheTests {
    
    func testThatItDoesNotDecryptAFileThatDoesNotExistSHA256() {
        
        // when
        let sut = FileAssetCache()
        let result = sut.decryptFileIfItMatchesDigest(NSUUID.createUUID(), fileName: "sales.xls", encryptionKey: NSData.randomEncryptionKey(), sha256Digest: NSData.secureRandomDataOfLength(128))
        
        // then
        XCTAssertFalse(result)
    }
    
    func testThatItDoesNotDecryptAndDeletesAFileWithWrongSHA256() {
        
        // given
        let messageID = NSUUID.createUUID()
        let sut = FileAssetCache()
        let name = "2014.txt"
        sut.storeAssetData(messageID, fileName: name, encrypted: true, data: testData())
        
        // when
        let result = sut.decryptFileIfItMatchesDigest(messageID, fileName: name, encryptionKey: NSData.randomEncryptionKey(), sha256Digest: NSData.secureRandomDataOfLength(128))
        XCTAssertFalse(result)
        
        // then
        let extractedData = sut.assetData(messageID, fileName: name, encrypted: true)
        XCTAssertNil(extractedData)
    }
    
    func testThatItDoesDecryptAndDeletesAFileWithTheRightSHA256() {
        
        // given
        let sut = FileAssetCache()
        let messageID = NSUUID.createUUID()
        let plainTextData = NSData.secureRandomDataOfLength(500)
        let key = NSData.randomEncryptionKey()
        let encryptedData = plainTextData.zmEncryptPrefixingPlainTextIVWithKey(key)
        let name = "q1.xls"
        sut.storeAssetData(messageID, fileName: name, encrypted: true, data: encryptedData)
        let sha = encryptedData.zmSHA256Digest()
        
        // when
        let result = sut.decryptFileIfItMatchesDigest(messageID, fileName: name, encryptionKey: key, sha256Digest: sha)
        
        // then
        XCTAssertTrue(result)
        let decryptedData = sut.assetData(messageID, fileName: name, encrypted: false)
        XCTAssertEqual(decryptedData, plainTextData)
    }
}

// MARK: - Encryption
extension ImageAssetCacheTests {
    
    func testThatReturnsNilWhenEncryptingAMissingFileWithSHA256() {
        
        // given
        let sut = ImageAssetCache(MBLimit: 5)
        let messageID = NSUUID.createUUID()
        
        // when
        let result = sut.encryptFileAndComputeSHA256Digest(messageID, format: .Preview)
        
        // then
        AssertOptionalNil(result)
        XCTAssertNil(sut.assetData(messageID, format: .Preview, encrypted: true))
    }
    
    func testThatItCreatesTheEncryptedFileAndDoesNotDeletedThePlainTextWithSHA256() {
        
        // given
        let sut = ImageAssetCache(MBLimit: 5)
        let messageID = NSUUID.createUUID()
        let plainData = NSData.secureRandomDataOfLength(500)
        sut.storeAssetData(messageID, format: .Preview, encrypted: false, data: plainData)
        
        // when
        _ = sut.encryptFileAndComputeSHA256Digest(messageID, format: .Preview)
        
        // then
        XCTAssertNotNil(sut.assetData(messageID, format: .Preview, encrypted: true))
        XCTAssertNotNil(sut.assetData(messageID, format: .Preview, encrypted: false))
    }
    
    func testThatItReturnsCorrectEncryptionResultWithSHA256() {
        // given
        let sut = ImageAssetCache(MBLimit: 5)
        let messageID = NSUUID.createUUID()
        let plainData = NSData.secureRandomDataOfLength(500)
        sut.storeAssetData(messageID, format: .Preview, encrypted: false, data: plainData)
        
        // when
        let result = sut.encryptFileAndComputeSHA256Digest(messageID, format: .Preview)
        
        // then
        let encryptedData = sut.assetData(messageID, format: .Preview, encrypted: true)
        AssertOptionalNotNil(result, "Result") { result in
            AssertOptionalNotNil(encryptedData, "Encrypted data") { encryptedData in
                let decodedData = encryptedData.zmDecryptPrefixedPlainTextIVWithKey(result.otrKey)
                XCTAssertEqual(decodedData, plainData)
                let sha = encryptedData.zmSHA256Digest()
                XCTAssertEqual(sha, result.sha256)
            }
        }
    }
}

extension FileAssetCacheTests {
    
    func testThatReturnsNilWhenEncryptingAMissingFileWithSHA256() {
        
        // given
        let sut = FileAssetCache()
        let messageID = NSUUID.createUUID()
        let name = "lines.txt"
        
        // when
        let result = sut.encryptFileAndComputeSHA256Digest(messageID, fileName: name)
        
        // then
        AssertOptionalNil(result)
        XCTAssertNil(sut.assetData(messageID, fileName: name, encrypted: true))
    }
    
    func testThatItCreatesTheEncryptedFileAndDoesNotDeletedThePlainTextWithSHA256() {
        
        // given
        let sut = FileAssetCache()
        let messageID = NSUUID.createUUID()
        let plainData = NSData.secureRandomDataOfLength(500)
        let name = "novel.doc"

        sut.storeAssetData(messageID, fileName: name, encrypted: false, data: plainData)
        
        // when
        _ = sut.encryptFileAndComputeSHA256Digest(messageID, fileName: name)
        
        // then
        XCTAssertNotNil(sut.assetData(messageID, fileName: name, encrypted: true))
        XCTAssertNotNil(sut.assetData(messageID, fileName: name, encrypted: false))
    }
    
    func testThatItReturnsCorrectEncryptionResultWithSHA256() {
        // given
        let sut = FileAssetCache()
        let messageID = NSUUID.createUUID()
        let plainData = NSData.secureRandomDataOfLength(500)
        let name = "office.cad"

        sut.storeAssetData(messageID, fileName: name, encrypted: false, data: plainData)
        
        // when
        let result = sut.encryptFileAndComputeSHA256Digest(messageID, fileName: name)
        
        // then
        let encryptedData = sut.assetData(messageID, fileName: name, encrypted: true)
        AssertOptionalNotNil(result, "Result") { result in
            AssertOptionalNotNil(encryptedData, "Encrypted data") { encryptedData in
                let decodedData = encryptedData.zmDecryptPrefixedPlainTextIVWithKey(result.otrKey)
                XCTAssertEqual(decodedData, plainData)
                let sha = encryptedData.zmSHA256Digest()
                XCTAssertEqual(sha, result.sha256)
            }
        }
    }
}

// MARK: - File urls
extension FileAssetCacheTests {

    func testThatTheURLOfAFileHasTheSameFilenameAndExtension() {
        // given
        let sut = FileAssetCache()
        let messageID = NSUUID.createUUID()
        let plainData = NSData.secureRandomDataOfLength(500)
        let name = "office.cad"
        sut.storeAssetData(messageID, fileName: name, encrypted: false, data: plainData)
        
        // when
        let url = sut.accessAssetURL(messageID, fileName: name)

        // then
        XCTAssertNotNil(url)
        if let url = url {
            XCTAssertTrue(url.absoluteString.hasSuffix(name))
            XCTAssertNotEqual(url.lastPathComponent, name)
        }
        
    }
    
    func testThatItCreatesASafeURLWhenFileNameHasInvalidCharacters() {
        // given
        let sut = FileAssetCache()
        let messageID = NSUUID.createUUID()
        let plainData = NSData.secureRandomDataOfLength(500)
        let name = "c:/bin/sudo\\"
        sut.storeAssetData(messageID, fileName: name, encrypted: false, data: plainData)
        
        // when
        let url = sut.accessAssetURL(messageID, fileName: name)
        
        // then
        XCTAssertNotNil(url)
        if let url = url {
            XCTAssertFalse(url.absoluteString.hasSuffix(name))
            XCTAssertNotEqual(url.lastPathComponent, name)
            XCTAssertTrue(url.absoluteString.hasSuffix("c__bin_sudo_"), "URL does not match: \(url.absoluteString)")
        }
        
    }
    
    func testThatItStoresTheRequestDataAndReturnsTheFileURL() {
        let sut = FileAssetCache()
        let messageID = NSUUID.createUUID()
        let requestData = NSData.secureRandomDataOfLength(500)
        
        // when
        let assetURL = sut.storeRequestData(messageID, data: requestData)
        
        // then
        guard let url = assetURL else { return XCTFail() }
        XCTAssertTrue(url.absoluteString.hasSuffix("_request"))
        XCTAssertNotEqual(url.lastPathComponent, name)
        guard let data = NSData(contentsOfURL: url) else { return XCTFail() }
        XCTAssertTrue(requestData.isEqualToData(data))
    }
    
    func testThatItDeletesTheRequestData() {
        let sut = FileAssetCache()
        let messageID = NSUUID.createUUID()
        let requestData = NSData.secureRandomDataOfLength(500)
        
        // when
        let assetURL = sut.storeRequestData(messageID, data: requestData)
        sut.deleteRequestData(messageID)
        
        // then
        XCTAssertNotNil(assetURL)
        if let assetURL = assetURL {
            let data = NSData(contentsOfURL: assetURL)
            XCTAssertNil(data)
        }
    }
}
