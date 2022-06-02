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
@testable import WireSyncEngine
import WireTesting
import WireTransport

class APSSignalingKeyStoreTests: MessagingTest {

    func testThatItCreatesKeyStoreFromUserClientWithKeys() {
        // given
        let keySize = Int(APSSignalingKeysStore.defaultKeyLengthBytes)
        let client = self.createSelfClient()
        let keys = APSSignalingKeysStore.createKeys()
        client.apsVerificationKey = keys.verificationKey
        client.apsDecryptionKey = keys.decryptionKey

        // when
        let keyStore = APSSignalingKeysStore(userClient: client)

        // then
        XCTAssertNotNil(keyStore)
        XCTAssertEqual(keyStore?.verificationKey.count, keySize)
        XCTAssertEqual(keyStore?.decryptionKey.count, keySize)
    }

    func testThatItReturnsNilKeyStoreFromUserClientWithoutKeys() {
        // given
        let client = self.createSelfClient()

        // when
        let keyStore = APSSignalingKeysStore(userClient: client)

        // then
        XCTAssertNil(keyStore)
    }

    func testThatItRandomizesTheKeys() {
        // when
        let keys1 = APSSignalingKeysStore.createKeys()
        let keys2 = APSSignalingKeysStore.createKeys()

        // then
        AssertOptionalNotNil(keys1) { keys1 in
            AssertOptionalNotNil(keys2) { keys2 in
                XCTAssertNotEqual(keys1.verificationKey, keys2.verificationKey)
                XCTAssertNotEqual(keys1.decryptionKey, keys2.decryptionKey)
                XCTAssertNotEqual(keys1.verificationKey, keys1.decryptionKey)
                XCTAssertNotEqual(keys2.verificationKey, keys2.decryptionKey)
            }
        }
    }

    func testThatItReturnsKeysStoredInKeyChain() {
        // given
        let data1 = Data.randomEncryptionKey()
        let data2 = Data.randomEncryptionKey()

        ZMKeychain.setData(data1, forAccount: APSSignalingKeysStore.verificationKeyAccountName)
        ZMKeychain.setData(data2, forAccount: APSSignalingKeysStore.decryptionKeyAccountName)

        // when
        let keys = APSSignalingKeysStore.keysStoredInKeyChain()

        // then
        XCTAssertNotNil(keys)

        ZMKeychain.deleteAllKeychainItems(withAccountName: APSSignalingKeysStore.verificationKeyAccountName)
        ZMKeychain.deleteAllKeychainItems(withAccountName: APSSignalingKeysStore.decryptionKeyAccountName)
    }

}
