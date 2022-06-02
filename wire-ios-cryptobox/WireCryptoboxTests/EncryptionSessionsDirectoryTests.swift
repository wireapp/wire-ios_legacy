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
import XCTest
@testable import WireCryptobox
import WireSystem

class EncryptionSessionsDirectoryTests : XCTestCase {
    
    var contextAlice : EncryptionContext!
    var contextBob : EncryptionContext!
    var statusAlice : EncryptionSessionsDirectory!
    var statusBob : EncryptionSessionsDirectory!
    
    override func setUp() {
        self.contextAlice = createEncryptionContext()
        self.contextBob = createEncryptionContext()
        self.recreateStatuses()
    }
    
    override func tearDown() {
        statusAlice = nil
        statusBob = nil
        contextAlice = nil
        contextBob = nil
    }
    
}

// MARK: - Session creation and encoding/decoding
extension EncryptionSessionsDirectoryTests {
    func testThatItCanDecodeAfterInitializingWithAValidKey() {
        
        // GIVEN
        let plainText = "foo".data(using: String.Encoding.utf8)!
        
        // WHEN
        do {
            try statusAlice.createClientSession(Person.Bob.identifier, base64PreKeyString: statusBob.generatePrekey(2))
        } catch {
            XCTFail()
            return
        }
        
        // THEN
        let prekeyMessage = try! statusAlice.encrypt(plainText, for: Person.Bob.identifier)
        let decoded = try! statusBob.createClientSessionAndReturnPlaintext(for: Person.Alice.identifier, prekeyMessage: prekeyMessage)
        XCTAssertEqual(decoded, plainText)
    }
    
    func testThatItCanCallCreateSessionWithTheSameKeyMultipleTimes() {
        
        // GIVEN
        let plainText = "foo".data(using: String.Encoding.utf8)!
        let prekey = try! statusBob.generatePrekey(34)
        do {
            try statusAlice.createClientSession(Person.Bob.identifier, base64PreKeyString: prekey)
        } catch {
            XCTFail()
            return
        }
        
        // WHEN
        do {
            try statusAlice.createClientSession(Person.Bob.identifier, base64PreKeyString: prekey)
        } catch {
            XCTFail()
            return
        }
        
        // THEN
        let prekeyMessage = try! statusAlice.encrypt(plainText, for: Person.Bob.identifier)
        let decoded = try! statusBob.createClientSessionAndReturnPlaintext(for: Person.Alice.identifier, prekeyMessage: prekeyMessage)
        XCTAssertEqual(decoded, plainText)
        
    }
    
    func testThatItCanNotCreateANewSessionWithAnInvalidKey() {
     
        // GIVEN
        
        // WHEN
        do {
            _ = try statusAlice.createClientSession(Person.Bob.identifier, base64PreKeyString: "aabb")
            XCTFail("should have failed to use prekey")
        }
        catch let err as CBoxResult {
            XCTAssertEqual(err, CBOX_DECODE_ERROR)
        } catch {
            XCTFail("should have thrown a CBoxResult")
        }
    }
    
    func testThatItCanNotDecodePrekeyMessagesWithTheWrongKey() {
        
        // GIVEN
        
        // WHEN
        do {
            _ = try statusAlice.createClientSession(Person.Bob.identifier, base64PreKeyString: hardcodedPrekey)
        }
        catch {
            XCTFail()
            return
        }
        
        // THEN
        XCTAssertFalse(checkThatAMessageCanBeSent(.Alice))
        
    }
}

// MARK: - Prekeys
extension EncryptionSessionsDirectoryTests {
    
    func testThatFingerprintExtractedFromPrekeyMatchesLocalFingerprint() throws {
        let prekeyId : UInt16 = 12
        let prekeyData = try statusAlice.generatePrekey(prekeyId)
        let fingerprint = EncryptionSessionsDirectory.fingerprint(fromPrekey: Data(base64Encoded: prekeyData)!)
        
        XCTAssertEqual(fingerprint, statusAlice.localFingerprint)
    }

    func testThatItGeneratesAPrekey() {
        
        // GIVEN
        let prekeyId : UInt16 = 12
        
        // WHEN
        let prekey = try! statusAlice.generatePrekey(prekeyId)
        
        // THEN
        var prekeyRetrievedId : UInt16 = 0
        let prekeyData = Data(base64Encoded: prekey, options: [])!
        let result = prekeyData.withUnsafeBytes { (prekeyDataPointer: UnsafeRawBufferPointer) -> CBoxResult in  cbox_is_prekey(prekeyDataPointer.baseAddress!.assumingMemoryBound(to: UInt8.self), prekeyData.count, &prekeyRetrievedId) }
        XCTAssertEqual(result, CBOX_SUCCESS)
        XCTAssertEqual(prekeyRetrievedId, prekeyId)
        
    }
    
    func testThatItGeneratesLastPrekey() {
        
        // GIVEN
        let prekeyId : UInt16 = CBOX_LAST_PREKEY_ID
        
        // WHEN
        let prekey = try! statusAlice.generateLastPrekey()
        
        // THEN
        var prekeyRetrievedId : UInt16 = 0
        let prekeyData = Data(base64Encoded: prekey, options: [])!
        let result = prekeyData.withUnsafeBytes { (prekeyDataPointer: UnsafeRawBufferPointer) -> CBoxResult in  cbox_is_prekey(prekeyDataPointer.baseAddress!.assumingMemoryBound(to: UInt8.self), prekeyData.count, &prekeyRetrievedId) }
        XCTAssertEqual(result, CBOX_SUCCESS)
        XCTAssertEqual(prekeyRetrievedId, prekeyId)
        
    }
    
    func testThatItGeneratesARangeOfPrekeys() {
        
        // GIVEN
        let rangeStart = 3
        let rangeLength = 10
        let prekeyIds : CountableRange<UInt16> = UInt16(rangeStart)..<UInt16(rangeStart+rangeLength)
        
        // WHEN
        var prekeys : [(id: UInt16, prekey: String)] = []
        prekeys = try! statusAlice.generatePrekeys(prekeyIds)
        
        // THEN
        XCTAssertEqual(prekeyIds.count, rangeLength)
        for i in 0..<rangeLength {
            let (id, prekey) = prekeys[i]
            let prekeyData = Data(base64Encoded: prekey, options: [])!
            var prekeyRetrievedId : UInt16 = 0
            let result = prekeyData.withUnsafeBytes { (prekeyDataPointer: UnsafeRawBufferPointer) -> CBoxResult in  cbox_is_prekey(prekeyDataPointer.baseAddress!.assumingMemoryBound(to: UInt8.self), prekeyData.count, &prekeyRetrievedId) }
            XCTAssertEqual(result, CBOX_SUCCESS)
            XCTAssertEqual(Int(prekeyRetrievedId), i+rangeStart)
            XCTAssertEqual(prekeyRetrievedId, id)
        }
    }
}

// MARK: - Local fingerprint
extension EncryptionSessionsDirectoryTests {
    
    func testThatItReturnsTheLocalFingerprint() {
        
        // GIVEN

        // WHEN
        let fingerprint = statusAlice.localFingerprint
        
        // THEN
        // check it's consistent
        XCTAssertEqual(statusAlice.localFingerprint, fingerprint)
    }

    func testThatASessionHasAMatchingRemoteFingerprint() {
        
        // GIVEN
        
        // WHEN
        establishSessionBetweenAliceAndBob()
        
        // THEN
        let aliceLocalFingerprint = statusAlice.localFingerprint
        let bobLocalFingerprint = statusBob.localFingerprint
        let aliceRemoteFingerprint = statusBob.fingerprint(for: Person.Alice.identifier)
        let bobRemoteFingerprint = statusAlice.fingerprint(for: Person.Bob.identifier)
        XCTAssertEqual(aliceLocalFingerprint, aliceRemoteFingerprint)
        XCTAssertEqual(bobLocalFingerprint, bobRemoteFingerprint)
        XCTAssertNotNil(aliceLocalFingerprint)
        XCTAssertNotNil(bobLocalFingerprint)
    }
    
    func testThatAClientWithoutSessionHasNoRemoteFingerprint() {
        
        // GIVEN
        // WHEN
        // THEN
        XCTAssertNil(statusAlice.fingerprint(for: EncryptionSessionIdentifier(domain: "example.com", userId: "aa22", clientId: "8899")))
    }
}

// MARK: - Deletion
extension EncryptionSessionsDirectoryTests {
    
    func testThatItDeletesASession() {
        
        // GIVEN
        establishSessionBetweenAliceAndBob()
        
        // WHEN
        statusAlice.delete(Person.Bob.identifier)
        
        // THEN
        let cypherText = try? statusAlice.encrypt("foo".data(using: String.Encoding.utf8)!, for: Person.Bob.identifier)
        XCTAssertNil(cypherText)
    }
    
    func testThatItCanDeleteASessionThatDoesNotExist() {
        
        // GIVEN
        
        // WHEN
        statusAlice.delete(hardcodedClientId)
        
        // THEN
        // no crash
    }
}

// MARK: - Session cache management
extension EncryptionSessionsDirectoryTests {
    
    func testThatCreatedSessionsAreNotSavedImmediately() {
        
        // GIVEN
        
        // WHEN
        try! statusAlice.createClientSession(Person.Bob.identifier, base64PreKeyString: statusBob.generatePrekey(1))
        
        // THEN
        let statusAliceCopy = EncryptionSessionsDirectory(
            generatingContext: contextAlice,
            encryptionPayloadCache: Cache<GenericHash, Data>(maxCost: 1000, maxElementsCount: 100),
            extensiveLoggingSessions: Set())
        statusAliceCopy.debug_disableContextValidityCheck = true
        let cypher = try? statusAliceCopy.encrypt("foo".data(using: String.Encoding.utf8)!, for: Person.Bob.identifier)
        XCTAssertNil(cypher)
    }

    func testThatNewlyCreatedSessionsAreSavedWhenReleasingTheStatus() {
        
        // GIVEN
        let plainText = "foo".data(using: String.Encoding.utf8)!
        establishSessionFromAliceToBob()
        
        // WHEN
        statusAlice = nil
        
        // THEN
        let statusAliceCopy = EncryptionSessionsDirectory(
            generatingContext: contextAlice,
            encryptionPayloadCache: Cache<GenericHash, Data>(maxCost: 1000, maxElementsCount: 100),
            extensiveLoggingSessions: Set())
        statusAliceCopy.debug_disableContextValidityCheck = true
        let prekeyMessage = try! statusAliceCopy.encrypt(plainText, for: Person.Bob.identifier)
        let decoded = try! statusBob.createClientSessionAndReturnPlaintext(for: Person.Alice.identifier, prekeyMessage: prekeyMessage)
        XCTAssertEqual(plainText, decoded)
    }
    
    func testThatNewlyCreatedSessionsAreNotSavedWhenDiscarding() {
        
        // GIVEN
        establishSessionFromAliceToBob()
        
        // WHEN
        statusAlice.discardCache()
        statusAlice = nil
        
        // THEN
        let statusAliceCopy = EncryptionSessionsDirectory(
            generatingContext: contextAlice,
            encryptionPayloadCache: Cache<GenericHash, Data>(maxCost: 1000, maxElementsCount: 100),
            extensiveLoggingSessions: Set())
        statusAliceCopy.debug_disableContextValidityCheck = true
        let cypher = try? statusAliceCopy.encrypt("foo".data(using: String.Encoding.utf8)!, for: Person.Bob.identifier)
        XCTAssertNil(cypher)
    }
    
    func testThatModifiedSessionsAreNotSavedWhenDiscarding() {
        
        // GIVEN
        let plainText = "foo".data(using: String.Encoding.utf8)!
        establishSessionFromAliceToBob()
        let prekeyMessage = try! statusAlice.encrypt(plainText, for: Person.Bob.identifier)
        _ = try! statusBob.createClientSessionAndReturnPlaintext(for: Person.Alice.identifier, prekeyMessage: prekeyMessage)
        self.recreateStatuses() // force save
        
        // WHEN
        let cypherText = try! statusAlice.encrypt(plainText, for: Person.Bob.identifier)
        _ = try! statusBob.decrypt(cypherText, from: Person.Alice.identifier)
        statusBob.discardCache()
        statusBob = nil
        
        // THEN
        let statusBobCopy = EncryptionSessionsDirectory(
            generatingContext: contextBob,
            encryptionPayloadCache: Cache<GenericHash, Data>(maxCost: 1000, maxElementsCount: 100),
            extensiveLoggingSessions: Set())
        statusBobCopy.debug_disableContextValidityCheck = true
        let decoded = try! statusBobCopy.decrypt(cypherText, from: Person.Alice.identifier)
        XCTAssertEqual(decoded, plainText)
    }
    
    func testThatItCanNotDecodeAfterDiscardingCache() {
        
        // GIVEN
        establishSessionFromAliceToBob()
        
        // WHEN
        statusAlice.discardCache()
        
        // THEN
        XCTAssertFalse(checkThatAMessageCanBeSent(.Alice))
    }
    
    func testThatItDecodeFutureMessageAfterDiscardingCacheOnTheReceivingSide() {
        
        // GIVEN
        establishSessionBetweenAliceAndBob()
        checkThatAMessageCanBeSent(.Alice, saveReceiverCache: false)
        
        // WHEN
        statusBob.discardCache()
        
        // THEN
        XCTAssertNotNil(checkThatAMessageCanBeSent(.Alice))
    }
    
    func testThatItCanNotDecodeDuplicatedMessageIfTheCacheIsNotDiscarded() {
        
        // GIVEN
        establishSessionBetweenAliceAndBob()
        let plainText = "foo".data(using: String.Encoding.utf8)!
        let cypherText = try! statusAlice.encrypt(plainText, for: Person.Bob.identifier)
        _ = try! statusBob.decrypt(cypherText, from: Person.Alice.identifier)
        
        // WHEN
        do {
            _ = try statusBob.decrypt(cypherText, from: Person.Alice.identifier)
            XCTFail("Should have failed")
            return
        } catch let err as CBoxResult where err == CBOX_DUPLICATE_MESSAGE {
            // pass
        } catch {
            XCTFail("Wrong error")
        }
    }
    
    func testThatItCanNotDecodeDuplicatedMessageIfTheCacheIsNotDiscardedAndReportsTheCorrectErrorInObjC() {
        
        // GIVEN
        establishSessionBetweenAliceAndBob()
        let plainText = "foo".data(using: String.Encoding.utf8)!
        let cypherText = try! statusAlice.encrypt(plainText, for: Person.Bob.identifier)
        _ = try! statusBob.decrypt(cypherText, from: Person.Alice.identifier)
        
        // WHEN
        do {
            _ = try statusBob.decrypt(cypherText, from: Person.Alice.identifier)
            XCTFail("Should have failed")
            return
        } catch let error as CBoxResult {
            XCTAssertEqual(error, CBOX_DUPLICATE_MESSAGE)
        } catch {
            XCTFail()
        }
    }
    
    func testThatItCanDecodeDuplicatedMessageIfTheCacheIsDiscarded() {
        
        // GIVEN
        establishSessionBetweenAliceAndBob()
        let plainText = "foo".data(using: String.Encoding.utf8)!
        let cypherText = try! statusAlice.encrypt(plainText, for: Person.Bob.identifier)
        _ = try! statusBob.decrypt(cypherText, from: Person.Alice.identifier)
        
        // WHEN
        statusBob.discardCache()
        
        // THEN
        do {
            _ = try statusBob.decrypt(cypherText, from: Person.Alice.identifier)
        } catch {
            XCTFail("Should decrypt")
        }
    }
    
    func testThatItCanNotDecodeDuplicatedMessageIfTheCacheIsCommitted() {
        
        // GIVEN
        establishSessionBetweenAliceAndBob()
        let plainText = "foo".data(using: String.Encoding.utf8)!
        let cypherText = try! statusAlice.encrypt(plainText, for: Person.Bob.identifier)
        _ = try! statusBob.decrypt(cypherText, from: Person.Alice.identifier)
        
        // WHEN
        self.recreateStatuses() // force save
        
        // THEN
        do {
            _ = try statusBob.decrypt(cypherText, from: Person.Alice.identifier)
            XCTFail("Should have failed")
            return
        } catch let err as CBoxResult where err == CBOX_DUPLICATE_MESSAGE {
            // pass
        } catch {
            XCTFail("Wrong error")
        }
    }
    
    func testThatItCanDecodeAfterSavingCache() {
        
        // GIVEN
        let plainText = "foo".data(using: String.Encoding.utf8)!
        establishSessionFromAliceToBob()
        
        // WHEN
        self.recreateStatuses() // force save
        
        // THEN
        let prekeyMessage = try! statusAlice.encrypt(plainText, for: Person.Bob.identifier)
        let decoded = try! statusBob.createClientSessionAndReturnPlaintext(for: Person.Alice.identifier, prekeyMessage: prekeyMessage)
        XCTAssertEqual(decoded, plainText)
    }
    
    func testThatItCanDecodeMultipleMessagesWithoutSaving() {
        
        // GIVEN
        establishSessionBetweenAliceAndBob()
        
        // WHEN
        checkThatAMessageCanBeSent(.Alice, saveReceiverCache: false)
        
        // THEN
        XCTAssertTrue(checkThatAMessageCanBeSent(.Alice))
        XCTAssertTrue(checkThatAMessageCanBeSent(.Alice))
        XCTAssertTrue(checkThatAMessageCanBeSent(.Alice))
    }
}


// MARK: - Session migration tests
extension EncryptionSessionsDirectoryTests {
    
    func testThatItCanMigrateASessionAndReceive() {
        
        // GIVEN
        let oldIdentifier = "aabbccdd"
        bobIdentifierOverride = oldIdentifier
        
        establishSessionBetweenAliceAndBob()
        checkThatAMessageCanBeSent(.Alice)
        checkThatAMessageCanBeSent(.Bob)
        
        // WHEN
        bobIdentifierOverride = nil
        statusAlice.migrateSession(from: oldIdentifier, to: Person.Bob.identifier)
        
        
        // THEN
        XCTAssertTrue(checkThatAMessageCanBeSent(.Bob))
    }
    
    func testThatItCanMigrateASessionAndSend() {
        
        // GIVEN
        let oldIdentifier = "aabbccdd"
        bobIdentifierOverride = oldIdentifier
        
        establishSessionBetweenAliceAndBob()
        checkThatAMessageCanBeSent(.Alice)
        checkThatAMessageCanBeSent(.Bob)
        
        // WHEN
        bobIdentifierOverride = nil
        statusAlice.migrateSession(from: oldIdentifier, to: Person.Bob.identifier)
        
        
        // THEN
        XCTAssertTrue(checkThatAMessageCanBeSent(.Alice))
    }
    
    func testThatItWontMigrateIfNewSessionAlreadyExists() {
        
        // GIVEN
        let oldIdentifier = "aabbccdd"
        
        establishSessionBetweenAliceAndBob()
        checkThatAMessageCanBeSent(.Alice)
        checkThatAMessageCanBeSent(.Bob)
        
        bobIdentifierOverride = oldIdentifier
        establishSessionFromAliceToBob()
        
        // WHEN
        bobIdentifierOverride = nil
        statusAlice.migrateSession(from: oldIdentifier, to: Person.Bob.identifier)
        
        // THEN
        XCTAssertTrue(checkThatAMessageCanBeSent(.Bob))
    }
    
    func testThatItWontMigrateIfOldSessionDoesNotExists() {
        
        // GIVEN
        let oldIdentifier = "aabbccdd"
        
        establishSessionBetweenAliceAndBob()
        checkThatAMessageCanBeSent(.Alice)
        checkThatAMessageCanBeSent(.Bob)
        
        // WHEN
        statusAlice.migrateSession(from: oldIdentifier, to: Person.Bob.identifier)
        
        // THEN
        XCTAssertTrue(checkThatAMessageCanBeSent(.Bob))
    }
}

// MARK: - Extended logging
extension EncryptionSessionsDirectoryTests {
    
    func testThatItLogsEncryptionWhenExtendedLoggingIsSet() {
        
        // GIVEN
        self.recreateAliceStatus(extendedLoggingSession: Set([Person.Bob.identifier]))
        let plainText = "foo".data(using: String.Encoding.utf8)!
        establishSessionFromAliceToBob()
        let logExpectation = expectation(description: "Encrypting")
        
        // EXPECT
        let token = ZMSLog.addEntryHook { (level, tag, entry, isSafe) in
            if level == ZMLogLevel_t.public &&
                tag == "cryptobox" &&
                entry.text.contains("encrypted to cyphertext: cyphertext")
            {
                logExpectation.fulfill()
            }
        }
                
        // WHEN
        _ = try! statusAlice.encrypt(plainText, for: Person.Bob.identifier)
        
        // THEN
        waitForExpectations(timeout: 0.2)
        
        // AFTER
        ZMSLog.removeLogHook(token: token)
    }
    
    func testThatItDoesNotLogEncryptionWhenExtendedLoggingIsNotSet() {
        
        // GIVEN
        // set logging for a different identifier
        let wrongIdentifier = EncryptionSessionIdentifier(domain: "example.com", userId: "foo", clientId: "bar")
        self.recreateAliceStatus(extendedLoggingSession: Set([wrongIdentifier]))
        
        let plainText = "foo".data(using: String.Encoding.utf8)!
        establishSessionFromAliceToBob()
        
        // EXPECT
        let token = ZMSLog.addEntryHook { (_level, _tag, entry, isSafe) in
            XCTFail("Should not have logged")
        }
        
        // WHEN
        _ = try! statusAlice.encrypt(plainText, for: Person.Bob.identifier)
        
        // AFTER
        ZMSLog.removeLogHook(token: token)
    }
    
    func testThatItLogsDecryptionWhenExtendedLoggingIsSet_prekeyMessage() {
        
        // GIVEN
        self.recreateBobStatus(extendedLoggingSession: Set([Person.Alice.identifier]))
        let plainText = "foo".data(using: String.Encoding.utf8)!
        establishSessionFromAliceToBob()
        let logExpectation = expectation(description: "Encrypting")
        let prekeyMessage = try! statusAlice.encrypt(plainText, for: Person.Bob.identifier)
        
        // EXPECT
        let token = ZMSLog.addEntryHook { (level, tag, entry, isSafe) in
            if level == ZMLogLevel_t.public &&
                tag == "cryptobox" &&
                entry.text.contains("decrypting prekey cyphertext:")
            {
                logExpectation.fulfill()
            }
        }
                
        // WHEN
        _ = try! statusBob.createClientSessionAndReturnPlaintext(for: Person.Alice.identifier, prekeyMessage: prekeyMessage)
        
        // THEN
        waitForExpectations(timeout: 0.2)
        
        // AFTER
        ZMSLog.removeLogHook(token: token)
    }
    
    func testThatItLogsDecryptionWhenExtendedLoggingIsSet_nonPrekeyMessage() {
        
        // GIVEN
        
        let plainText = "foo".data(using: String.Encoding.utf8)!
        establishSessionBetweenAliceAndBob()
        self.recreateBobStatus(extendedLoggingSession: Set([Person.Alice.identifier]))
        let logExpectation = expectation(description: "Encrypting")
        let message = try! statusAlice.encrypt(plainText, for: Person.Bob.identifier)
        
        // EXPECT
        let token = ZMSLog.addEntryHook { (level, tag, entry, isSafe) in
            if level == ZMLogLevel_t.public &&
                tag == "cryptobox" &&
                entry.text.contains("decrypting cyphertext:")
            {
                logExpectation.fulfill()
            }
        }
                
        // WHEN
        _ = try! statusBob.decrypt(message, from: Person.Alice.identifier)
        
        // THEN
        waitForExpectations(timeout: 0.2)
        
        // AFTER
        ZMSLog.removeLogHook(token: token)
    }
    
    func testThatItDoesNotLogDecryptionWhenExtendedLoggingIsNotSet() {
        
        // GIVEN
        // set logging for a different identifier
        let wrongIdentifier = EncryptionSessionIdentifier(domain: "example.com", userId: "foo", clientId: "bar")
        self.recreateBobStatus(extendedLoggingSession: Set([wrongIdentifier]))

        let plainText = "foo".data(using: String.Encoding.utf8)!
        establishSessionFromAliceToBob()
        
        let prekeyMessage = try! statusAlice.encrypt(plainText, for: Person.Bob.identifier)
        
        // EXPECT
        let token = ZMSLog.addEntryHook { (_level, _tag, entry, isSafe) in
            XCTFail("Should not have logged")
        }
        
        // WHEN
        _ = try! statusBob.createClientSessionAndReturnPlaintext(for: Person.Alice.identifier, prekeyMessage: prekeyMessage)
        
        // AFTER
        ZMSLog.removeLogHook(token: token)
    }
}


// MARK: - Helpers

/// Custom session identifier for Bob
private var bobIdentifierOverride : String? = nil

extension EncryptionSessionsDirectoryTests {
    
    /// Recreate the statuses, reloading from disk. This also forces a save of the previous
    /// statuses, if any.
    func recreateStatuses(
        only: Person? = nil
    ) {
        if only == nil || only == .Alice {
            self.recreateAliceStatus()
        }
        if only == nil || only == .Bob {
            self.recreateBobStatus()
        }
    }
    
    
    func recreateAliceStatus(
        extendedLoggingSession: Set<EncryptionSessionIdentifier> = Set()
    ) {
        self.statusAlice = EncryptionSessionsDirectory(
            generatingContext: contextAlice,
            encryptionPayloadCache: Cache<GenericHash, Data>(maxCost: 1000, maxElementsCount: 100),
            extensiveLoggingSessions: extendedLoggingSession
        )
        self.statusAlice.debug_disableContextValidityCheck = true
    }
    
    func recreateBobStatus(
        extendedLoggingSession: Set<EncryptionSessionIdentifier> = Set()
    ) {
        self.statusBob = EncryptionSessionsDirectory(
            generatingContext: contextBob,
            encryptionPayloadCache: Cache<GenericHash, Data>(maxCost: 1000, maxElementsCount: 100),
            extensiveLoggingSessions: extendedLoggingSession
        )
        self.statusBob.debug_disableContextValidityCheck = true
    }
    
    /// Sends a prekey message from Alice to Bob, decrypts it on Bob's side, and save both
    func establishSessionBetweenAliceAndBob() {
        self.establishSessionFromAliceToBob()
        let prekeyMessage = try! statusAlice.encrypt("foo".data(using: String.Encoding.utf8)!, for: Person.Bob.identifier)
        _ = try! statusBob.createClientSessionAndReturnPlaintext(for: Person.Alice.identifier, prekeyMessage: prekeyMessage)
        
        /// This will force commit
        self.recreateStatuses()
    }
    
    /// Creates a client session from Alice to Bob
    func establishSessionFromAliceToBob() {
        let prekey = try! statusBob.generatePrekey(2)
        try! statusAlice.createClientSession(Person.Bob.identifier, base64PreKeyString: prekey)
    }
    
    
    enum Person {
        case Alice
        case Bob
        
        var identifier : EncryptionSessionIdentifier {
            switch(self) {
            case .Alice:
                return EncryptionSessionIdentifier(domain: "example.com", userId: "234ab2e4", clientId: "c45-a11c30")
            case .Bob:
                return EncryptionSessionIdentifier(fromLegacyV1Identifier: bobIdentifierOverride ?? "a34affe3366-b0b0b0b")
            }
        }
        
        var other : Person {
            switch(self) {
            case .Alice:
                return .Bob
            case .Bob:
                return .Alice
            }
        }
    }
    
    /// Checks if a person already decrypted a message
    /// Reverts the session after performing the check
    /// Will only work after after calling `establishSessionBetweenAliceAndBob`
    func checkIfPersonAlreadyDecryptedMessage(_ person: Person, message: Data) -> Bool {
        let clientId = person.identifier
        let status = person == .Alice ? statusAlice : statusBob
        guard let _ = try? status?.decrypt(message, from: clientId) else {
            return true
        }
        status?.discardCache()
        return false
    }
    
    /// Checks if a message can be encrypted and successfully decrypted
    /// by the other person
    /// - note: it does commit the session cache
    @discardableResult func checkThatAMessageCanBeSent(_ from: Person, saveReceiverCache : Bool = true) -> Bool {
        let senderId = from.identifier
        let receiverId = from.other.identifier

        let status1 = from == .Alice ? statusAlice : statusBob
        let status2 = from == .Alice ? statusBob : statusAlice
        
        defer {
            self.recreateStatuses(only: from)
            if saveReceiverCache {
                self.recreateStatuses(only: from.other)
            }
        }
        
        let plainText = "निर्वाण".data(using: String.Encoding.utf8)!
        do {
            let cypherText = try status1?.encrypt(plainText, for: receiverId)
            let decoded = try status2?.decrypt(cypherText!, from: senderId)
            return decoded == plainText
        } catch {
            return false
        }
    }
}
