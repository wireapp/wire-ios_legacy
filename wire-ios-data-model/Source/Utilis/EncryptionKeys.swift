//
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

import Foundation
import Security
import LocalAuthentication

/// EncryptionKeys is responsible for creating / deleting the encryptions keys
/// which are used for supporting encryption at rest
///
public struct EncryptionKeys {

    enum KeychainItem {
        case privateKey(_ account: Account, _ context: LAContext?, _ prompt: String?)
        case publicKey(Account)
        case databaseKey(Account)

        var tag: Data {
            uniqueIdentifier.data(using: .utf8)!
        }

        var uniqueIdentifier: String {
            "com.wire.ear.\(label).\(accountIdentifier)"
        }

        var accountIdentifier: String {
            switch self {
            case .privateKey(let account, _, _):
                return account.userIdentifier.transportString()
            case .publicKey(let account):
                return account.userIdentifier.transportString()
            case .databaseKey(let account):
                return account.userIdentifier.transportString()
            }
        }

        var label: String {
            switch self {
            case .privateKey:
                return "private"
            case .publicKey:
                return "public"
            case .databaseKey:
                return "database"
            }
        }

        var getQuery: [CFString: Any] {
            var query: [CFString: Any]

            switch self {
            case .publicKey:
                query = [kSecClass: kSecClassKey,
                         kSecAttrApplicationTag: tag,
                         kSecReturnRef: true]
            case .databaseKey:
                query = [kSecClass: kSecClassGenericPassword,
                         kSecAttrAccount: uniqueIdentifier,
                         kSecReturnData: true]
            case .privateKey(_, var context, let prompt):
                query = [kSecClass: kSecClassKey,
                         kSecAttrKeyClass: kSecAttrKeyClassPrivate,
                         kSecAttrLabel: tag,
                         kSecReturnRef: true
                ]

                #if targetEnvironment(simulator)
                context = nil // kSecUseAuthenticationContext doesn't work on simulator
                #endif

                if let context = context {
                    query[kSecUseAuthenticationContext] = context
                    query[kSecUseAuthenticationUI] = kSecUseAuthenticationUISkip
                } else if let prompt = prompt {
                    query[kSecUseOperationPrompt] = prompt
                }
            }

            return query
        }

        func setQuery<T>(value: T) -> [CFString: Any] {
            var query: [CFString: Any]

            switch self {
            case .publicKey:
                query = [kSecClass: kSecClassKey,
                         kSecAttrApplicationTag: tag,
                         kSecValueRef: value]
            case .databaseKey:
                query = [kSecClass: kSecClassGenericPassword,
                         kSecAttrAccount: uniqueIdentifier,
                         kSecValueData: value]
            case .privateKey:
                query = [:]
            }

            return query
        }
    }

    public enum EncryptionKeysError: Error {
        case failedToStoreItemInKeychain(OSStatus)
        case failedToFetchItemFromKeychain(OSStatus)
        case failedToDeleteItemFromKeychain(OSStatus)
        case failedToGenerateDatabaseKey(OSStatus)
        case failedToCopyPublicAccountKey
        case failedToGenerateAccountKey(underlyingError: Error?)
        case failedToEncryptDatabaseKey(underlyingError: Error)
        case failedToDecryptDatabaseKey(underlyingError: Error)
    }

    /// Public key associated with an account.
    ///
    /// This key is used when sensitive information
    /// needs to be stored while the application operates in the background.
    public let publicKey: SecKey

    /// Private key associated with an account.
    ///
    /// This key is used by when the app runs in
    /// the foreground to decrypt data which was previously stored while the app running
    /// in the background.
    public let privateKey: SecKey

    /// Database key associated with an account.
    ///
    /// This key is used to encrypt/decrypt
    /// messages in the database.
    public let databaseKey: VolatileData

    private static let databaseKeyAlgorithm: SecKeyAlgorithm = .eciesEncryptionCofactorX963SHA256AESGCM

    /// Initialise EncryptionKeys for an account.
    ///
    /// The encryption keys can only be retrieved if the user is authenticated, this can be done
    /// by either supplying an LAContext where the user is already authenticated or by letting
    /// the system display an authentication prompt. Note that the authentication prompt is blocks
    /// the current thread until the authentication is completed.
    ///
    /// - Parameters:
    ///   - account: Account for which the encryption keys should fetched
    ///   - context: An already authenticated LAContext
    ///   - authenticationMessage: message to which is displayed in authentication prompt.
    ///
    /// Supplying an authentication context is the preferred way to initialize the encryption keys
    /// and takes precedence over the authentication prompt.
    public init(account: Account, context: LAContext? = nil, authenticationMessage: String? = nil) throws {
        self.publicKey = try Self.fetchItem(.publicKey(account))
        self.privateKey = try Self.fetchItem(.privateKey(account, context, authenticationMessage))
        self.databaseKey = try VolatileData(from: Self.decryptDatabaseKey(Self.fetchItem(.databaseKey(account)), privateKey: privateKey))
    }

    init(publicKey: SecKey, privateKey: SecKey, databaseKey: Data) {
        self.publicKey = publicKey
        self.privateKey = privateKey
        self.databaseKey = VolatileData(from: databaseKey)
    }

    // MARK: Create & Destroy keys

    /// Create all encryption keys and store them in the keychain.
    ///
    /// - Parameters:
    ///   -  account Account for which the encryption keys should created
    public static func createKeys(for account: Account) throws -> EncryptionKeys {
        let (privateKey, publicKey) = try generateAccountKey(identifier: .privateKey(account, nil, nil))
        let databaseKey = try generateDatabaseKey()

        try storeItem(.publicKey(account), value: publicKey)
        try storeItem(.databaseKey(account), value: encryptDatabaseKey(databaseKey, publicKey: publicKey))

        return EncryptionKeys(publicKey: publicKey, privateKey: privateKey, databaseKey: databaseKey)
    }

    /// Delete all encryption keys and from the keychain.
    ///
    /// - Parameters:
    ///   -  account Account for which the encryption keys should deleted
    public static func deleteKeys(for account: Account) throws {
        try deleteItem(.publicKey(account))
        try deleteItem(.privateKey(account, nil, nil))
        try deleteItem(.databaseKey(account))
    }

    // MARK: Account key

    /// Fetch the public key associated with an account
    public static func publicKey(for account: Account) throws -> SecKey {
        try fetchItem(.publicKey(account))
    }

    private static func generateAccountKey(identifier: KeychainItem) throws -> (SecKey, SecKey) {
        #if targetEnvironment(simulator)
            return try generateSimulatorAccountKey(identifier: identifier)
        #else
            return try generateSecureEnclaveAccountKey(identifier: identifier)
        #endif
    }

    private static func generateSecureEnclaveAccountKey(identifier: KeychainItem) throws -> (SecKey, SecKey) {
        var accessError: Unmanaged<CFError>?
        guard let access = SecAccessControlCreateWithFlags(kCFAllocatorDefault,
                                                     kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
                                                     [.privateKeyUsage, .userPresence],
                                                     &accessError)
            else {
                let error = accessError!.takeRetainedValue() as Error
                throw EncryptionKeysError.failedToGenerateAccountKey(underlyingError: error)
        }

        let attributes: [CFString: Any] = [
          kSecAttrKeyType: kSecAttrKeyTypeECSECPrimeRandom,
          kSecAttrKeySizeInBits: 256,
          kSecAttrTokenID: kSecAttrTokenIDSecureEnclave,
          kSecPrivateKeyAttrs: [
            kSecAttrIsPermanent: true,
            kSecAttrAccessControl: access,
            kSecAttrLabel: identifier.tag
          ]
        ]

        var error: Unmanaged<CFError>?
        guard let privateKey = SecKeyCreateRandomKey(attributes as CFDictionary, &error) else {
            let error = error!.takeRetainedValue() as Error
            throw EncryptionKeysError.failedToGenerateAccountKey(underlyingError: error)
        }

        guard let publicKey = SecKeyCopyPublicKey(privateKey) else {
            throw EncryptionKeysError.failedToCopyPublicAccountKey
        }

        return (privateKey, publicKey)
    }

    private static func generateSimulatorAccountKey(identifier: KeychainItem) throws -> (SecKey, SecKey) {
        var accessError: Unmanaged<CFError>?
        guard let access = SecAccessControlCreateWithFlags(kCFAllocatorDefault,
                                                           kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
                                                           [.userPresence],
                                                           &accessError)
            else {
                let error = accessError!.takeRetainedValue() as Error
                throw EncryptionKeysError.failedToGenerateAccountKey(underlyingError: error)
        }

        let attributes: [CFString: Any] = [
          kSecAttrKeyType: kSecAttrKeyTypeECSECPrimeRandom,
          kSecAttrKeySizeInBits: 256,
          kSecPrivateKeyAttrs: [
            kSecAttrIsPermanent: true,
            kSecAttrAccessControl: access,
            kSecAttrLabel: identifier.tag
          ]
        ]

        var error: Unmanaged<CFError>?
        guard let privateKey = SecKeyCreateRandomKey(attributes as CFDictionary, &error) else {
            // Notice: accessError is nil when test with iOS 15 simulator. ref:https://wearezeta.atlassian.net/browse/SQCORE-1188
            let error = accessError?.takeRetainedValue()
            throw EncryptionKeysError.failedToGenerateAccountKey(underlyingError: error)
        }

        guard let publicKey = SecKeyCopyPublicKey(privateKey) else {
            throw EncryptionKeysError.failedToCopyPublicAccountKey
        }

        return (privateKey, publicKey)
    }

    // MARK: - Database key

    private static func generateDatabaseKey() throws -> Data {
        var databaseKey = [UInt8](repeating: 0, count: 32)
        let status = SecRandomCopyBytes(kSecRandomDefault, databaseKey.count, &databaseKey)

        guard status == errSecSuccess else {
            throw EncryptionKeysError.failedToGenerateDatabaseKey(status)
        }

        return Data(databaseKey)
    }

    private static func encryptDatabaseKey(_ databaseKey: Data, publicKey: SecKey) throws -> Data {
        var error: Unmanaged<CFError>?
        guard let wrappedDatabaseKey = SecKeyCreateEncryptedData(publicKey,
                                                                 databaseKeyAlgorithm,
                                                                 databaseKey as CFData, &error) else {
            let error = error!.takeRetainedValue() as Error
            throw EncryptionKeysError.failedToEncryptDatabaseKey(underlyingError: error)
        }

        return wrappedDatabaseKey as Data
    }

    private static func decryptDatabaseKey(_ wrappedDatabaseKey: Data, privateKey: SecKey) throws -> Data {
        var error: Unmanaged<CFError>?
        guard let decryptedDatabaseKey = SecKeyCreateDecryptedData(privateKey,
                                                                   databaseKeyAlgorithm,
                                                                   wrappedDatabaseKey as CFData,
                                                                   &error)
            else {
                let error = error!.takeRetainedValue() as Error
                throw EncryptionKeysError.failedToDecryptDatabaseKey(underlyingError: error)
        }

        return decryptedDatabaseKey as Data
    }

    // MARK: - Keychain access

    private static func storeItem<T>(_ item: KeychainItem, value: T) throws {
        let status = SecItemAdd(item.setQuery(value: value) as CFDictionary, nil)

        guard status == errSecSuccess else {
            throw EncryptionKeysError.failedToStoreItemInKeychain(status)
        }
    }

    private static func fetchItem<T>(_ item: KeychainItem) throws -> T {
        var value: CFTypeRef?
        let status = SecItemCopyMatching(item.getQuery as CFDictionary, &value)

        guard status == errSecSuccess else {
            throw EncryptionKeysError.failedToFetchItemFromKeychain(status)
        }

        return value as! T
    }

    private static func deleteItem(_ item: KeychainItem) throws {
        let status = SecItemDelete(item.getQuery as CFDictionary)

        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw EncryptionKeysError.failedToDeleteItemFromKeychain(status)
        }
    }

}

// MARK: - Equatable

extension EncryptionKeys: Equatable {

    public static func == (lhs: EncryptionKeys, rhs: EncryptionKeys) -> Bool {
        return
            lhs.publicKey == rhs.publicKey &&
            lhs.privateKey == rhs.privateKey &&
            lhs.databaseKey._storage == rhs.databaseKey._storage
    }
}
