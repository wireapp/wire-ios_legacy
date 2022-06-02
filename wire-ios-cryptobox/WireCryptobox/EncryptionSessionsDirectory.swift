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
import WireSystem
import WireUtilities

@objc enum EncryptionSessionError : Int {
    
    case unknown, encryptionFailed, decryptionFailed
    
    internal var userInfo : [String : AnyObject] {
        var info : String
        
        switch self {
        case .unknown:
            info = "Unknown EncryptionSessionError"
        case .encryptionFailed:
            info = "Encryption Failed"
        case .decryptionFailed:
            info = "Decryption Failed"
        }
        
        return [kCFErrorLocalizedDescriptionKey as String : info as AnyObject]
    }
    
    var error : NSError {
        return NSError(domain: "EncryptionSessionsDirectoryDomain", code: rawValue, userInfo: userInfo)
    }
    
}

class _CBoxSession : PointerWrapper {}

/// An encryption state that is usable to encrypt/decrypt messages
/// It maintains an in-memory cache of encryption sessions with other clients
/// that is persisted to disk as soon as it is deallocated.
public final class EncryptionSessionsDirectory : NSObject {
    
    /// Used for testing only. If set to true,
    /// will not try to validate with the generating context
    var debug_disableContextValidityCheck = false
    
    /// Set of session identifier that require full debugging logs
    let extensiveLoggingSessions: Set<EncryptionSessionIdentifier>
    
    /// Context that created this status
    fileprivate weak var generatingContext: EncryptionContext!
    
    /// Local fingerprint
    public var localFingerprint : Data
    
    fileprivate let encryptionPayloadCache: Cache<GenericHash, Data>
    
    /// Cache of transient sessions, indexed by client ID.
    /// Transient sessions are session that are (potentially) modified in memory
    /// and not yet committed to disk. When trying to load a session,
    /// and that session is already in the list of transient sessions,
    /// the transient session will be returned without any loading
    /// occurring. As soon as a session is saved, it is removed from the cache.
    ///
    /// - note: This is an optimization: instead of loading, decrypting,
    /// saving, unloading every time, if the same session is reused within
    /// the same execution block, we don't need to spend time reading
    /// and writing to disk every time we use the session, we can just
    /// load once and save once at the end.
    fileprivate var pendingSessionsCache : [EncryptionSessionIdentifier : EncryptionSession] = [:]
    
    init(
        generatingContext: EncryptionContext,
        encryptionPayloadCache: Cache<GenericHash, Data>,
        extensiveLoggingSessions: Set<EncryptionSessionIdentifier>
    ) {
        self.generatingContext = generatingContext
        self.localFingerprint = generatingContext.implementation.localFingerprint
        self.encryptionPayloadCache = encryptionPayloadCache
        self.extensiveLoggingSessions = extensiveLoggingSessions
        super.init()
        zmLog.safePublic("Loaded encryption status - local fingerprint \(localFingerprint)")
    }
    
    /// The underlying implementation of the box
    var box : _CBox {
        return self.generatingContext!.implementation
    }
    
    /// Checks whether self is in a valid state, i.e. the generating context is still open and
    /// this is the current status. If not, it means that we are using this status after
    /// the context was done using this status.
    /// Will assert if this is the case.
    fileprivate func validateContext() -> EncryptionContext {
        guard self.debug_disableContextValidityCheck || self.generatingContext.currentSessionsDirectory === self else {
            // If you hit this line, check if the status was stored in a variable for later use,
            // or if it was used from different threads - it should never be.
            fatalError("Using encryption status outside of a context")
        }
        return self.generatingContext!
    }
    
    deinit {
        self.commitCache()
    }
        
    private func hash(for data: Data, recipient: EncryptionSessionIdentifier) -> GenericHash {
        let builder = GenericHashBuilder()
        builder.append(data)
        builder.append(recipient.rawValue.data(using: .utf8)!)
        return builder.build()
    }
    
    /// Encrypts data for a client. Caches the encrypted payload based on `hash(data + recepient)` as the cache key.
    /// It invokes @c encrypt() in case of the cache miss.
    /// - throws: EncryptionSessionError in case no session with given recipient
    public func encryptCaching(_ plainText: Data, for recipientIdentifier: EncryptionSessionIdentifier) throws -> Data {
        let key = hash(for: plainText, recipient: recipientIdentifier)
        
        if let cachedObject = encryptionPayloadCache.value(for: key) {
            zmLog.safePublic("Encrypting, cache hit")
            return cachedObject
        }
        else {
            zmLog.debug("Encrypting, cache miss")
            let data = try encrypt(plainText, for: recipientIdentifier)
            let didPurgeData = encryptionPayloadCache.set(value: data, for: key, cost: data.count)
            
            if didPurgeData {
                zmLog.safePublic("Encrypting, cache limit reached")
            }
            
            return data
        }
    }
    
    /// Purges the cache of encrypted payloads created as the result of @c encryptCaching() call
    public func purgeEncryptedPayloadCache() {
        zmLog.safePublic("Encryption cache purged")
        encryptionPayloadCache.purge()
    }
}

// MARK: - Encryption sessions
public protocol EncryptionSessionManager {
    /// Migrate session to a new identifier, if a session with the old identifier exists
    /// and a session with the new identifier does not exist
    func migrateSession(from previousIdentifier: String, to newIdentifier: EncryptionSessionIdentifier)
    
    /// Creates a session to a client using a prekey of that client
    /// The session is not saved to disk until the cache is committed
    /// - throws: CryptoBox error in case of lower-level error
    func createClientSession(_ identifier: EncryptionSessionIdentifier, base64PreKeyString: String) throws
    
    /// Creates a session to a client using a prekey message from that client
    /// The session is not saved to disk until the cache is committed
    /// - returns: the plaintext
    /// - throws: CryptoBox error in case of lower-level error
    func createClientSessionAndReturnPlaintext(for identifier: EncryptionSessionIdentifier, prekeyMessage: Data) throws -> Data
    
    /// Deletes a session with a client
    func delete(_ identifier: EncryptionSessionIdentifier)
    
    /// Returns true if there is an existing session for this client ID
    func hasSession(for identifier: EncryptionSessionIdentifier) -> Bool
    
    /// Closes all transient sessions without saving them
    func discardCache()
    
    /// Returns the remote fingerprint of a encryption session
    func fingerprint(for identifier: EncryptionSessionIdentifier) -> Data?
}

extension EncryptionSessionsDirectory: EncryptionSessionManager {
    
    public func migrateSession(from previousIdentifier: String, to newIdentifier: EncryptionSessionIdentifier) {
        
        let previousSessionIdentifier = EncryptionSessionIdentifier(fromLegacyV1Identifier: previousIdentifier)
        // this scopes guarantee that `old` is released
        repeat {
            guard let old = clientSession(for: previousSessionIdentifier) else {
                return
            }
            
            // save and close old one
            old.save(self.box)
            self.discardFromCache(previousSessionIdentifier)
        } while(false)
        
        guard clientSession(for: newIdentifier) == nil else {
            // There is an old and a new, delete the old
            delete(previousSessionIdentifier)
            return
        }
        
        // copy to new one
        let oldPath = self.filePath(for: previousSessionIdentifier)
        let newPath = self.filePath(for: newIdentifier)
        
        guard FileManager.default.fileExists(atPath: oldPath.path) else {
            fatal("Can't migrate session \(previousSessionIdentifier) because file \(oldPath) does not exist")
        }
        
        guard let _ = try? FileManager.default.moveItem(at: oldPath, to: newPath) else {
            fatal("Can't migrate session \(newIdentifier) because the move failed")
        }
        
    }
    
    public func createClientSession(_ identifier: EncryptionSessionIdentifier, base64PreKeyString: String) throws {
        
        // validate
        guard let prekeyData = Data(base64Encoded: base64PreKeyString, options: []) else {
            fatal("String is not base64 encoded from client: \(identifier)")
        }
        let context = self.validateContext()

        // check if pre-existing
        if let session = clientSession(for: identifier) {
            zmLog.safePublic("Tried to create session for client \(identifier) with prekey but session already existed - fingerprint \(session.remoteFingerprint)")
            return
        }
        
        // init
        let cbsession = _CBoxSession()
        let result = prekeyData.withUnsafeBytes { (prekeyDataPointer : UnsafeRawBufferPointer) -> CBoxResult in
            cbox_session_init_from_prekey(context.implementation.ptr,
                                          identifier.rawValue,
                                          prekeyDataPointer.bindMemory(to: UInt8.self).baseAddress!,
                                          prekeyData.count,
                                          &cbsession.ptr)
        }
        
        try result.throwIfError()

        let session = EncryptionSession(id: identifier,
                                        session: cbsession,
                                        requiresSave: true,
                                        cryptoboxPath: self.generatingContext!.path,
                                        extensiveLogging: self.extensiveLoggingSessions.contains(identifier))
        self.pendingSessionsCache[identifier] = session
        
        zmLog.safePublic("Created session for client \(identifier) - fingerprint \(session.remoteFingerprint)")
    }
    
    public func createClientSessionAndReturnPlaintext(for identifier: EncryptionSessionIdentifier, prekeyMessage: Data) throws -> Data {
        let context = self.validateContext()
        let cbsession = _CBoxSession()
        var plainTextBacking : OpaquePointer? = nil
        
        let result = prekeyMessage.withUnsafeBytes { (prekeyMessagePointer : UnsafeRawBufferPointer) -> CBoxResult in
            cbox_session_init_from_message(context.implementation.ptr,
                                           identifier.rawValue,
                                           prekeyMessagePointer.baseAddress!.assumingMemoryBound(to: UInt8.self),
                                           prekeyMessage.count,
                                           &cbsession.ptr,
                                           &plainTextBacking)
        }

        let extensiveLogging = self.extensiveLoggingSessions.contains(identifier)
        if (extensiveLogging) {
            EncryptionSession.logSessionAndCyphertext(
                sessionId: identifier,
                reason: "decrypting prekey cyphertext",
                data: prekeyMessage,
                sessionURL: filePath(for: identifier)
            )
        }
        try result.throwIfError()
        
        let plainText = Data.moveFromCBoxVector(plainTextBacking)!
        let session = EncryptionSession(id: identifier,
                                        session: cbsession,
                                        requiresSave: true,
                                        cryptoboxPath: self.generatingContext!.path,
                                        extensiveLogging: extensiveLogging)
        self.pendingSessionsCache[identifier] = session

        zmLog.safePublic("Created session for client \(identifier) from prekey message - fingerprint \(session.remoteFingerprint)")

        return plainText
    }
    
    public func delete(_ identifier: EncryptionSessionIdentifier) {
        let context = self.validateContext()
        self.discardFromCache(identifier)
        let result = cbox_session_delete(context.implementation.ptr, identifier.rawValue)
        zmLog.safePublic("Delete session for client \(identifier)")

        guard result == CBOX_SUCCESS else {
            fatal("Error in deletion in cbox: \(result)")
        }
    }
    
    /// Returns an existing session for a client
    /// - returns: a session if it exists, or nil if not there
    fileprivate func clientSession(for identifier: EncryptionSessionIdentifier) -> EncryptionSession? {
        let context = self.validateContext()
        
        // check cache
        if let transientSession = self.pendingSessionsCache[identifier] {
            zmLog.safePublic("Tried to load session for client \(identifier), session was already loaded - fingerprint \(transientSession.remoteFingerprint)")
            return transientSession
        }
        
        let cbsession = _CBoxSession()
        let result = cbox_session_load(context.implementation.ptr, identifier.rawValue, &cbsession.ptr)
        switch(result) {
        case CBOX_SESSION_NOT_FOUND:
            zmLog.safePublic("Tried to load session for client \(identifier), no session found")
            return nil
        case CBOX_SUCCESS:
            let session = EncryptionSession(id: identifier,
                                            session: cbsession,
                                            requiresSave: false,
                                            cryptoboxPath: self.generatingContext!.path,
                                            extensiveLogging: self.extensiveLoggingSessions.contains(identifier))
            self.pendingSessionsCache[identifier] = session
            zmLog.safePublic("Loaded session for client \(identifier) - fingerprint \(session.remoteFingerprint)")
            return session
        default:
            fatalError("Error in loading from cbox: \(result)")
        }
    }
    
    public func hasSession(for identifier: EncryptionSessionIdentifier) -> Bool {
        return (clientSession(for: identifier) != nil)
    }
    
    public func discardCache() {
        zmLog.safePublic("Discarded all sessions from cache")
        self.pendingSessionsCache = [:]
    }
    
    /// Save and unload all transient sessions
    fileprivate func commitCache() {
        for (_, session) in self.pendingSessionsCache {
            session.save(self.box)
        }
        discardCache()
    }
    
    /// Closes a transient session. Any unsaved change will be lost
    fileprivate func discardFromCache(_ identifier: EncryptionSessionIdentifier) {
        zmLog.safePublic("Discarded session \(identifier) from cache")
        self.pendingSessionsCache.removeValue(forKey: identifier)
    }
    
    /// Saves the cached session for a client and removes it from the cache
    fileprivate func saveSession(_ identifier: EncryptionSessionIdentifier) {
        guard let session = pendingSessionsCache[identifier] else {
            return
        }
        session.save(self.box)
        discardFromCache(identifier)
    }
    
    public func fingerprint(for identifier: EncryptionSessionIdentifier) -> Data? {
        guard let session = self.clientSession(for: identifier) else {
            return nil
        }
        return session.remoteFingerprint
    }
}

public protocol PrekeyGeneratorType {
    func generatePrekey(_ id: UInt16) throws -> String
    func generateLastPrekey() throws -> String
    func generatePrekeys(_ range: CountableRange<UInt16>) throws -> [(id: UInt16, prekey: String)]
    func generatePrekeys(_ nsRange: NSRange) throws -> [[String : AnyObject]]
}

// MARK: - Prekeys
extension EncryptionSessionsDirectory: PrekeyGeneratorType {
    
    /// Generates one prekey of the given ID. If the prekey exists already,
    /// it will replace that prekey
    /// - returns: base 64 encoded string
    public func generatePrekey(_ id: UInt16) throws -> String {
        guard id <= CBOX_LAST_PREKEY_ID else {
            // this should never happen, as CBOX_LAST_PREKEY_ID is UInt16.max
            fatal("Prekey out of bound \(id)")
        }
        var vectorBacking : OpaquePointer?
        let context = self.validateContext()
        let result = cbox_new_prekey(context.implementation.ptr, id, &vectorBacking)
        let prekey = Data.moveFromCBoxVector(vectorBacking)
        zmLog.debug("Generate prekey \(id)")
        
        try result.throwIfError()
        
        return prekey!.base64EncodedString(options: [])
    }
    
    /// Generates the last prekey. If the prekey exists already,
    /// it will replace that prekey
    public func generateLastPrekey() throws -> String {
        return try generatePrekey(CBOX_LAST_PREKEY_ID)
    }
    
    /// Generates prekeys from a range of IDs. If prekeys with those IDs exist already,
    /// they will be replaced
    public func generatePrekeys(_ range: CountableRange<UInt16>) throws -> [(id: UInt16, prekey: String)] {
        return try range.map {
            let prekey = try self.generatePrekey($0)
            return (id: $0, prekey: prekey)
        }
    }
    
    /// Generates prekeys from a range of IDs. If prekeys with those IDs exist already,
    /// they will be replaced
    /// This method wraps the Swift only method generatePrekeys(range: Range<UInt16>) for objC interoparability
    @objc public func generatePrekeys(_ nsRange: NSRange) throws -> [[String : AnyObject]] {
        let prekeys = try generatePrekeys(UInt16(nsRange.location)..<UInt16(nsRange.length))
        return prekeys.map{ ["id": NSNumber(value: $0.id as UInt16), "prekey": $0.prekey as AnyObject] }
    }
    
    /// Extracts the fingerprint from a prekey
    ///
    /// - returns: HEX encoded fingerprint
    @objc(fingerprintFromPrekey:)
    public static func fingerprint(fromPrekey prekey: Data) -> Data? {
        return prekey.withUnsafeBytes({
            let bytes = $0.baseAddress?.assumingMemoryBound(to: UInt8.self)
            var vectorBacking : OpaquePointer? = nil
            let result = cbox_fingerprint_prekey(bytes, $0.count, &vectorBacking)
            
            guard result == CBOX_SUCCESS else {
                return nil
            }
            
            return Data.moveFromCBoxVector(vectorBacking)!
        })
    }
}

// MARK: - Fingerprint
extension _CBox {
    
    /// Local fingerprint
    fileprivate var localFingerprint : Data {
        var vectorBacking : OpaquePointer? = nil
        let result = cbox_fingerprint_local(self.ptr, &vectorBacking)
        guard result == CBOX_SUCCESS else {
            fatal("Can't get local fingerprint") // this is so rare, that we don't even throw
        }
        return Data.moveFromCBoxVector(vectorBacking)!
    }
}

/// A cryptographic session used to encrypt/decrypt data send to and received from
/// another client
/// - note: This class is private because we want to make sure that no one can use
/// sessions outside of a status, that only dirty sessions are kept in memory, and
/// that sessions are unloaded as soon as possible, and that sessions are closed as soon
/// as they are unloaded.
/// We let the status manages closing sessions as there is no
/// other easy way to enforce (other than asserting) that we don't use a session to encrypt/decrypt
/// after it has been closed, and there is no easy way to ensure that sessions are always closed.
/// By hiding the implementation inside this file, only code in this file has the chance to screw up!
class EncryptionSession {
    
    /// Whether this session has changes that require saving
    var hasChanges : Bool
    
    /// client ID
    let id: EncryptionSessionIdentifier
    
    /// Underlying C-style implementation
    let implementation: _CBoxSession
    
    /// The fingerpint of the client
    let remoteFingerprint: Data
    
    /// Path of the containing cryptobox (used for debugging)
    let cryptoboxPath : URL
    
    /// Whether to log additional information
    let isExtensiveLoggingEnabled: Bool
    
    /// Creates a session from a C-level session pointer
    /// - parameter id: id of the client
    /// - parameter requiresSave: if true, mark this session as having pending changes to save
    init(id: EncryptionSessionIdentifier,
         session: _CBoxSession,
         requiresSave: Bool,
         cryptoboxPath: URL,
         extensiveLogging: Bool
        ) {
        self.id = id
        self.implementation = session
        self.remoteFingerprint = session.remoteFingerprint
        self.hasChanges = requiresSave
        self.cryptoboxPath = cryptoboxPath
        self.isExtensiveLoggingEnabled = extensiveLogging
    }
    
    /// Closes the session in CBox
    fileprivate func closeInCryptobox() {
        zmLog.safePublic("Closing cryptobox session \(id)")
        cbox_session_close(self.implementation.ptr)
    }
    
    /// Save the session to disk
    fileprivate func save(_ cryptobox: _CBox) {
        if self.hasChanges {
            zmLog.safePublic("Saving cryptobox session \(id)")
            let result = cbox_session_save(cryptobox.ptr, self.implementation.ptr)
            switch(result) {
            case CBOX_SUCCESS:
                return
            default:
                fatal("Can't save session: error \(result)")
            }
        }
    }
    
    deinit {
        closeInCryptobox()
    }
}

// MARK: - Logging
extension EncryptionSession {
    
    func logSessionAndCyphertext(
        reason: SanitizedString,
        data: Data
    )
    {
        EncryptionSession.logSessionAndCyphertext(
            sessionId: self.id,
            reason: reason,
            data: data,
            sessionURL: self.path)
    }
    
    static func logSessionAndCyphertext(
        sessionId: EncryptionSessionIdentifier,
        reason: SanitizedString,
        data: Data,
        sessionURL: URL
    ) {
        let encodedData = HexDumpUnsafeLoggingData(data: data)
        let sessionContent = (try? Data(contentsOf: sessionURL))
            .map { HexDumpUnsafeLoggingData(data: $0) }
        zmLog.safePublic(
            SanitizedString("Extensive logging (session \(sessionId)): ") +
            SanitizedString("\(reason): cyphertext: \(encodedData); ") +
            SanitizedString("session content: \(sessionContent)"),
            level: .public)
    }
}

// MARK: - Encryption
public protocol Encryptor: class {
    /// Encrypts data for a client
    /// It immediately saves the session
    /// - throws: EncryptionSessionError in case no session with given recipient
    func encrypt(_ plainText: Data, for recipientIdentifier: EncryptionSessionIdentifier) throws -> Data
}

// MARK: - Decryption
public protocol Decryptor: class {
    /// Decrypts data from a client
    /// The session is not saved to disk until the cache is committed
    /// - throws: EncryptionSessionError in case no session with given recipient
    func decrypt(_ cypherText: Data, from senderIdentifier: EncryptionSessionIdentifier) throws -> Data
}

extension EncryptionSessionsDirectory: Encryptor, Decryptor {

    public func encrypt(_ plainText: Data, for recipientIdentifier: EncryptionSessionIdentifier) throws -> Data {
        _ = self.validateContext()
        guard let session = self.clientSession(for: recipientIdentifier) else {
            zmLog.safePublic("Can't find session to encrypt for client \(recipientIdentifier)")
            throw EncryptionSessionError.encryptionFailed.error
        }
        let cypherText = try session.encrypt(plainText)
        self.saveSession(recipientIdentifier)
        return cypherText
    }
    
    public func decrypt(_ cypherText: Data, from senderIdentifier: EncryptionSessionIdentifier) throws -> Data {
        _ = self.validateContext()
        guard let session = self.clientSession(for: senderIdentifier) else {
            zmLog.safePublic("Can't find session to decrypt for client \(senderIdentifier)")
            throw EncryptionSessionError.decryptionFailed.error
        }
        return try session.decrypt(cypherText)
    }
}


extension EncryptionSession {
    
    /// Decrypts data using the session. This function modifies the session
    /// and it should be saved later
    fileprivate func decrypt(_ cypher: Data) throws -> Data {
        var vectorBacking : OpaquePointer? = nil

        zmLog.safePublic("Decrypting with session \(id)")

        let result = cypher.withUnsafeBytes { (cypherPointer: UnsafeRawBufferPointer) -> CBoxResult in
            cbox_decrypt(self.implementation.ptr,
                         cypherPointer.baseAddress!.assumingMemoryBound(to: UInt8.self),
                         cypher.count,
                         &vectorBacking)
        }
        
        let resultRequiresLogging = result != CBOX_DUPLICATE_MESSAGE && result != CBOX_SUCCESS
        if (resultRequiresLogging || self.isExtensiveLoggingEnabled) {
            if (self.isExtensiveLoggingEnabled) {
                self.logSessionAndCyphertext(
                    reason: "decrypting cyphertext: result \(result)",
                    data: cypher
                )
            } else {
                let encodedData = HexDumpUnsafeLoggingData(data: cypher)
                zmLog.safePublic("Failed to decrypt cyphertext: session \(id): \(encodedData)", level: .public)
            }
        }
        
        try result.throwIfError()

        self.hasChanges = true
        return Data.moveFromCBoxVector(vectorBacking)!
    }
    
    /// Encrypts data using the session. This function modifies the session
    /// and it should be saved later
    fileprivate func encrypt(_ plainText: Data) throws -> Data {
        var vectorBacking : OpaquePointer? = nil
        
        zmLog.safePublic("Encrypting with session \(id)")
        let result = plainText.withUnsafeBytes { (plainTextPointer: UnsafeRawBufferPointer) -> CBoxResult in
            cbox_encrypt(self.implementation.ptr,
                         plainTextPointer.baseAddress!.assumingMemoryBound(to: UInt8.self),
                         plainText.count,
                         &vectorBacking)
        }
                
        try result.throwIfError()

        self.hasChanges = true
        let data = Data.moveFromCBoxVector(vectorBacking)!
        
        if (self.isExtensiveLoggingEnabled) {
            self.logSessionAndCyphertext(
                reason: "encrypted to cyphertext",
                data: data
            )
        }
        return data
    }
}

// MARK: - Fingerprint
extension _CBoxSession {
    
    /// Returns the remote fingerprint associated with a session
    fileprivate var remoteFingerprint : Data {
        var backingVector : OpaquePointer? = nil
        let result = cbox_fingerprint_remote(self.ptr, &backingVector)
        guard result == CBOX_SUCCESS else {
            fatal("Can't access remote fingerprint of session \(result)")
        }
        return Data.moveFromCBoxVector(backingVector)!
    }
}

// MARK: - Backing files
extension EncryptionSession {
    
    /// Returns the expected path of the session file, given the root folder
    fileprivate static func expectedPath(root: URL, for identifier: EncryptionSessionIdentifier) -> URL {
        return root.appendingPathComponent("sessions").appendingPathComponent(identifier.rawValue)
    }
    
    /// Returns the expected path of this session
    var path : URL {
        return EncryptionSession.expectedPath(root: self.cryptoboxPath, for: self.id)
    }
}

extension EncryptionSessionsDirectory {
    
    /// Returns the file path where the session with the given identifier would be saved
    fileprivate func filePath(for identifier: EncryptionSessionIdentifier) -> URL {
        return EncryptionSession.expectedPath(root: self.generatingContext.path, for: identifier)
    }
}

// MARK: - Session identifier
public struct EncryptionSessionIdentifier : Hashable, Equatable {
    
    private let userId: String
    private let clientId: String
    private let domain: String
    
    public var rawValue: String {
        guard !userId.isEmpty else {
            return clientId
        }
        guard !domain.isEmpty else {
            return "\(userId)_\(clientId)"
        }

        return "\(domain)_\(userId)_\(clientId)"
    }
    
    public init(domain: String? = nil, userId: String, clientId: String) {
        self.userId = userId
        self.clientId = clientId
        self.domain = domain ?? ""
    }

    /// Use when migrating from old session identifier to new session identifier
    init(fromLegacyV1Identifier clientId: String) {
        self.userId = String()
        self.clientId = clientId
        self.domain = String()
    }
    
    public var hashValue: Int {
        return self.rawValue.hashValue
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(hashValue)
    }
}

public func ==(lhs: EncryptionSessionIdentifier, rhs: EncryptionSessionIdentifier) -> Bool {
    return lhs.rawValue == rhs.rawValue
}

extension EncryptionSessionIdentifier: SafeForLoggingStringConvertible {
    public var safeForLoggingDescription: String {
        return "<\(domain.readableHash)>_<\(userId.readableHash)>_<\(clientId.readableHash)>"
    }
}
