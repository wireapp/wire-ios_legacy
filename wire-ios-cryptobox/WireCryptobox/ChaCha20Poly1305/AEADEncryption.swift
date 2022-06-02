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

public extension ChaCha20Poly1305 {

    /// AEAD Encryption wrapper for IETF ChaCha20-Poly1305 construction.
    /// 
    /// See https://libsodium.gitbook.io/doc/secret-key_cryptography/aead/chacha20-poly1305/ietf_chacha20-poly1305_construction

    enum AEADEncryption {

        // MARK: - Public Functions

        /// Encrypts a message with a key.
        ///
        /// - Parameters:
        ///  - message: The message data to encrypt.
        ///  - context: Publicly known contextual data to be bound to the ciphertext.
        ///  - key: The key used to encrypt.
        ///
        /// - Returns: The ciphertext and public nonce used in the encryption.

        public static func encrypt(message: Data, context: Data, key: Data) throws -> (ciphertext: Data, nonce: Data) {
            try initializeSodium()

            let keyBytes = key.bytes
            try verifyKey(bytes: keyBytes)

            let messageBytes = message.bytes
            let messageLength = UInt64(messageBytes.count)

            let contextBytes = context.bytes
            let contextLength = UInt64(contextBytes.count)

            let nonceBytes = generateRandomNonceBytes()

            var ciphertextBytes = createByteArray(length: ciphertextLength(forMessageLength: Int(messageLength)))
            var actualCiphertextLength: UInt64 = 0

            crypto_aead_chacha20poly1305_ietf_encrypt(
                &ciphertextBytes,          // buffer in which enrypted data is written to
                &actualCiphertextLength,   // actual size of encrypted data
                messageBytes,              // message to encrypt
                messageLength,             // length of message to encrypt
                contextBytes,              // additional (non encrypted) data
                contextLength,             // additional data length
                nil,                       // nsec, not used by this function
                nonceBytes,                // unique nonce used as initizalization vector
                keyBytes                   // key used to encrypt the message
            )

            try verifyCiphertext(length: actualCiphertextLength, messageLength: messageLength)

            return (ciphertextBytes.data, nonceBytes.data)
        }

        /// Decrypts a ciphertext with a public nonce and a key.
        ///
        /// - Parameters:
        ///  - ciphertext: The data to decrypt.
        ///  - nonce: The public nonce used to encrypt the original message.
        ///  - context: The public contextual data bound to the ciphertext.
        ///  - key: The key used to encrypt the original message.
        ///
        /// - Returns: The plaintext message data.

        public static func decrypt(ciphertext: Data, nonce: Data, context: Data, key: Data) throws -> Data {
            try initializeSodium()

            let keyBytes = key.bytes
            try verifyKey(bytes: keyBytes)

            let nonceBytes = nonce.bytes
            try verifyNonce(bytes: nonceBytes)

            let ciphertextBytes = ciphertext.bytes
            let ciphertextLength = UInt64(ciphertextBytes.count)

            let contextBytes = context.bytes
            let contextLength = UInt64(contextBytes.count)

            var messageBytes = createByteArray(length: messageLength(forCiphertextLength: Int(ciphertextLength)))
            var actualMessageLength: UInt64 = 0

            let result = crypto_aead_chacha20poly1305_ietf_decrypt(
                &messageBytes,              // buffer in which decrypted data is written to
                &actualMessageLength,       // actual size of decrypted data
                nil,                        // nsec, not used by this function
                ciphertextBytes,            // ciphertext to decrypt
                ciphertextLength,           // length of ciphertext
                contextBytes,               // additional (non encrypted) data
                contextLength,              // additional data length
                nonceBytes,                 // the unique nonce used to encrypt the original message
                keyBytes                    // the key used to encrypt the original message
            )

            guard result == 0 else { throw EncryptionError.failedToDecrypt }

            return Data(messageBytes)
        }

        public enum EncryptionError: LocalizedError {

            case failedToInitializeSodium
            case malformedKey
            case malformedNonce
            case malformedCiphertext
            case failedToDecrypt

            public var errorDescription: String? {
                switch self {
                case .failedToInitializeSodium:
                    return "Failed to initialize sodium."
                case .malformedKey:
                    return "Encountered a malformed key."
                case .malformedNonce:
                    return "Encountered a malformed nonce."
                case .malformedCiphertext:
                    return "Encountered a malformed ciphertext."
                case .failedToDecrypt:
                    return "Failed to decrypt, possible due to incorrect key or malformed ciphertext."
                }
            }

        }

        // MARK: - Private Helpers

        private static func initializeSodium() throws {
            guard sodium_init() >= 0 else { throw EncryptionError.failedToInitializeSodium }
        }

        // MARK: - Verification

        private static func verifyKey(bytes: [Byte]) throws {
            guard bytes.count == keyLength else { throw EncryptionError.malformedKey }
        }

        private static func verifyNonce(bytes: [Byte]) throws {
            guard bytes.count == nonceLength else { throw EncryptionError.malformedNonce }
        }

        private static func verifyCiphertext(length: UInt64, messageLength: UInt64) throws {
            guard length == messageLength + UInt64(authenticationBytesLength) else {
                throw EncryptionError.malformedCiphertext
            }
        }

        // MARK: - Buffer Lengths

        private static let keyLength = Int(crypto_aead_chacha20poly1305_IETF_KEYBYTES)
        private static let nonceLength = Int(crypto_aead_chacha20poly1305_IETF_NPUBBYTES)
        private static let authenticationBytesLength = Int(crypto_aead_chacha20poly1305_IETF_ABYTES)

        private static func ciphertextLength(forMessageLength messageLength: Int) -> Int {
            return messageLength + authenticationBytesLength
        }

        private static func messageLength(forCiphertextLength ciphertextLength: Int) -> Int {
            return ciphertextLength - authenticationBytesLength
        }


        // MARK: - Buffer creation

        static func generateRandomNonceBytes() -> [Byte] {
            var nonce = createByteArray(length: nonceLength)
            randombytes_buf(&nonce, nonce.count)
            return nonce
        }

        private static func createByteArray(length: Int) -> [Byte] {
            return [Byte](repeating: 0, count: length)
        }

    }

}
