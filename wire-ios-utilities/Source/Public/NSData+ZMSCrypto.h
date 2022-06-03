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


@import Foundation;

@interface NSData (ZMMessageDigest)

/// Calculates MD5 digest of the data
- (NSData *)zmMD5Digest;

/// Calculates HMAC digest of the data using SHA256
- (NSData *)zmHMACSHA256DigestWithKey:(NSData *)key;

/// Returns a random key to be used for SHA256
+ (NSData *)zmRandomSHA256Key;

/// Calculates SHA256 digest of the data
- (NSData *)zmSHA256Digest;

@end


@interface NSData (Base64Encoding)

- (NSString *)base64String;

@end


@interface NSData (ZMSCrypto)

/// Encodes the data using AES256 CBC Padding prefixing a random IV to the plain text data before encryption
/// This function keeps both original and encrypted data in memory. Do not use for large amount of data.
- (NSData *)zmEncryptPrefixingIVWithKey:(NSData *)key;

/// Decodes data using AES256 CBC Padding assuming that the first block is the encrypted IV
/// This function keeps both original and encrypted data in memory. Do not use for large amount of data.
- (NSData *)zmDecryptPrefixedIVWithKey:(NSData *)key;

/// Encodes the data using AES256 CBC Padding prefixing a random IV to the encrypted data
/// This function keeps both original and encrypted data in memory. Do not use for large amount of data.
- (NSData *)zmEncryptPrefixingPlainTextIVWithKey:(NSData *)key;

/// Decodes the data using AES256 CBC Padding assuming that the first block is the plaintext IV
/// This function keeps both original and encrypted data in memory. Do not use for large amount of data.
- (NSData *)zmDecryptPrefixedPlainTextIVWithKey:(NSData *)key;

/// Returns cryptograpically random data of a given length
+ (NSData *)secureRandomDataOfLength:(NSUInteger)length;

/// Returns a random key to be used as a AES256
+ (NSData *)randomEncryptionKey;

@end
