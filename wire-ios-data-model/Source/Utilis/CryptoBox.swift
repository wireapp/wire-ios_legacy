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
import WireCryptobox

extension NSManagedObjectContext {

    fileprivate static let ZMUserClientKeysStoreKey = "ZMUserClientKeysStore"

    @objc(setupUserKeyStoreInAccountDirectory:applicationContainer:)
    public func setupUserKeyStore(accountDirectory: URL, applicationContainer: URL) {
        if !self.zm_isSyncContext {
            fatal("Can't initiliazie crypto box on non-sync context")
        }

        let newKeyStore = UserClientKeysStore(accountDirectory: accountDirectory, applicationContainer: applicationContainer)
        self.userInfo[NSManagedObjectContext.ZMUserClientKeysStoreKey] = newKeyStore
    }

    /// Returns the cryptobox instance associated with this managed object context
    @objc public var zm_cryptKeyStore: UserClientKeysStore! {
        if !self.zm_isSyncContext {
            fatal("Can't access key store: Currently not on sync context")
        }
        let keyStore = self.userInfo.object(forKey: NSManagedObjectContext.ZMUserClientKeysStoreKey)
        if let keyStore = keyStore as? UserClientKeysStore {
            return keyStore
        } else {
            fatal("Can't access key store: not keystore found.")
        }
    }

    @objc public func zm_tearDownCryptKeyStore() {
        self.userInfo.removeObject(forKey: NSManagedObjectContext.ZMUserClientKeysStoreKey)
    }
}

public extension FileManager {

    @objc static let keyStoreFolderPrefix = "otr"

    /// Returns the URL for the keyStore
    @objc(keyStoreURLForAccountInDirectory:createParentIfNeeded:)
    static func keyStoreURL(accountDirectory: URL, createParentIfNeeded: Bool) -> URL {
        if createParentIfNeeded {
            FileManager.default.createAndProtectDirectory(at: accountDirectory)
        }
        let keyStoreDirectory = accountDirectory.appendingPathComponent(FileManager.keyStoreFolderPrefix)
        return keyStoreDirectory
    }

}

public enum UserClientKeyStoreError: Error {
    case canNotGeneratePreKeys
    case preKeysCountNeedsToBePositive
}

/// A storage for cryptographic keys material
@objc(UserClientKeysStore) @objcMembers
open class UserClientKeysStore: NSObject {

    /// Maximum possible ID for prekey
    public static let MaxPreKeyID: UInt16 = UInt16.max-1

    public var encryptionContext: EncryptionContext

    /// Fallback prekeys (when no other prekey is available, this will always work)
    fileprivate var internalLastPreKey: String?

    /// Folder where the material is stored (managed by Cryptobox)
    public private(set) var cryptoboxDirectory: URL

    public private(set) var applicationContainer: URL

    /// Loads new key store (if not present) or load an existing one
    public init(accountDirectory: URL, applicationContainer: URL) {
        self.cryptoboxDirectory = FileManager.keyStoreURL(accountDirectory: accountDirectory, createParentIfNeeded: true)
        self.applicationContainer = applicationContainer
        self.encryptionContext = UserClientKeysStore.setupContext(in: self.cryptoboxDirectory)!
    }

    private static func setupContext(in directory: URL) -> EncryptionContext? {
        FileManager.default.createAndProtectDirectory(at: directory)
        return EncryptionContext(path: directory)
    }

    open func deleteAndCreateNewBox() {
        _ = try? FileManager.default.removeItem(at: cryptoboxDirectory)
        self.encryptionContext = UserClientKeysStore.setupContext(in: cryptoboxDirectory)!
        self.internalLastPreKey = nil
    }

    open func lastPreKey() throws -> String {
        var error: NSError?
        if internalLastPreKey == nil {
            encryptionContext.perform({ [weak self] (sessionsDirectory) in
                guard let strongSelf = self  else { return }
                do {
                    strongSelf.internalLastPreKey = try sessionsDirectory.generateLastPrekey()
                } catch let anError as NSError {
                    error = anError
                }
                })
        }
        if let error = error {
            throw error
        }
        return internalLastPreKey!
    }

    open func generateMoreKeys(_ count: UInt16 = 1, start: UInt16 = 0) throws -> [(id: UInt16, prekey: String)] {
        if count > 0 {
            var error: Error?
            var newPreKeys : [(id: UInt16, prekey: String)] = []

            let range = preKeysRange(count, start: start)
            encryptionContext.perform({(sessionsDirectory) in
                do {
                    newPreKeys = try sessionsDirectory.generatePrekeys(range)
                    if newPreKeys.count == 0 {
                        error = UserClientKeyStoreError.canNotGeneratePreKeys
                    }
                }
                catch let anError as NSError {
                    error = anError
                }
            })
            if let error = error {
                throw error
            }
            return newPreKeys
        }
        throw UserClientKeyStoreError.preKeysCountNeedsToBePositive
    }

    fileprivate func preKeysRange(_ count: UInt16, start: UInt16) -> CountableRange<UInt16> {
        if start >= UserClientKeysStore.MaxPreKeyID-count {
            return 0 ..< count
        }
        return start ..< (start + count)
    }

}
