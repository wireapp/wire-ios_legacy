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


@import WireSystem;
#import "NSData+ZMSCrypto.h"
#import <CommonCrypto/CommonCrypto.h>

static NSString* ZMLogTag ZM_UNUSED = @"SymmetricEncryption";


@implementation NSData (ZMMessageDigest)

- (NSData *)zmMD5Digest;
{
    __block CC_MD5_CTX ctx;
    CC_MD5_Init(&ctx);
    [self enumerateByteRangesUsingBlock:^(const void *bytes, NSRange byteRange, BOOL *stop) {
        NOT_USED(stop);
        CC_MD5_Update(&ctx, bytes, (CC_LONG) byteRange.length);
    }];
    NSMutableData *result = [NSMutableData dataWithLength:CC_MD5_DIGEST_LENGTH];
    CC_MD5_Final(result.mutableBytes, &ctx);
    return result;
}

- (NSData *)zmHMACSHA256DigestWithKey:(NSData *)key
{
    uint8_t hmac[CC_SHA256_DIGEST_LENGTH];
    CCHmac(kCCHmacAlgSHA256,
           key.bytes,
           key.length,
           self.bytes,
           self.length,
           &hmac);
    
    return [NSData dataWithBytes:hmac length:CC_SHA256_DIGEST_LENGTH];
}

+ (NSData *)zmRandomSHA256Key
{
    return [NSData secureRandomDataOfLength:kCCKeySizeAES256];
}

- (NSData *)zmSHA256Digest
{
    __block CC_SHA256_CTX ctx;
    CC_SHA256_Init(&ctx);
    [self enumerateByteRangesUsingBlock:^(const void *bytes, NSRange byteRange, BOOL *stop) {
        NOT_USED(stop);
        CC_SHA256_Update(&ctx, bytes, (CC_LONG) byteRange.length);
    }];
    NSMutableData *result = [NSMutableData dataWithLength:CC_SHA256_DIGEST_LENGTH];
    CC_SHA256_Final(result.mutableBytes, &ctx);
    return result;
}

@end



@implementation NSData (Base64Encoding)

- (NSString *)base64String;
{
    return [self base64EncodedStringWithOptions:0];
}

@end



@implementation NSData (ZMSCrypto)

+ (NSData *)randomEncryptionKey {
    return [NSData secureRandomDataOfLength:kCCKeySizeAES256];
}

+ (NSData *)secureRandomDataOfLength:(NSUInteger)length
{
    NSMutableData *randomData = [NSMutableData dataWithLength:length];
    int success = SecRandomCopyBytes(kSecRandomDefault, length, randomData.mutableBytes);
    Require(success == errSecSuccess);
    return randomData;
}

- (NSData *)zmEncryptPrefixingIVWithKey:(NSData *)key
{
    Require(key.length == kCCKeySizeAES256);
    
    __block CCCryptorStatus status = kCCSuccess;
    CCCryptorRef cryptorRef;
    
    status = CCCryptorCreate(kCCEncrypt, kCCAlgorithmAES, kCCOptionPKCS7Padding, key.bytes, kCCKeySizeAES256, NULL, &cryptorRef);
    if (status != kCCSuccess) {
        return nil;
    }
    
    size_t resultLength = self.length + 2 * kCCKeySizeAES256 + kCCBlockSizeAES128;
    NSMutableData * const result = [NSMutableData dataWithLength:resultLength];
    __block size_t byteCountWritten = 0;
    
    
    // First, encode some random data:
    {
        uint8_t random[kCCBlockSizeAES128];
        int success = SecRandomCopyBytes(kSecRandomDefault, sizeof(random), random);
        Require(success == errSecSuccess);
        size_t bytesWritten = 0;
        void * const dataOut = ((uint8_t *) [result mutableBytes]) + byteCountWritten;
        size_t const dataOutAvailable = resultLength - byteCountWritten;
        status = CCCryptorUpdate(cryptorRef, random, sizeof(random), dataOut, dataOutAvailable, &bytesWritten);
        Require(status == kCCSuccess);
        byteCountWritten += bytesWritten;
    }
    
    [self enumerateByteRangesUsingBlock:^(const void *bytes, NSRange byteRange, BOOL *stop) {
        size_t bytesWritten = 0;
        while (YES) {
            void * const dataOut = ((uint8_t *) [result mutableBytes]) + byteCountWritten;
            size_t const dataOutAvailable = resultLength - byteCountWritten;
            status = CCCryptorUpdate(cryptorRef, bytes, byteRange.length, dataOut, dataOutAvailable, &bytesWritten);
            if (status == kCCBufferTooSmall) {
                size_t const neededSize = CCCryptorGetOutputLength(cryptorRef, byteRange.length, false);
                size_t const additionalSize = neededSize - dataOutAvailable;
                result.length += additionalSize;
            } else {
                break;
            }
        }
        if (status != kCCSuccess) {
            *stop = YES;
            return;
        }
        byteCountWritten += bytesWritten;
    }];
    if (status != kCCSuccess) {
        CCCryptorRelease(cryptorRef);
        return nil;
    }
    
    {
        size_t bytesWritten = 0;
        while (YES) {
            void * const dataOut = ((uint8_t *) [result mutableBytes]) + byteCountWritten;
            size_t const dataOutAvailable = resultLength - byteCountWritten;
            status = CCCryptorFinal(cryptorRef, dataOut, dataOutAvailable, &bytesWritten);
            if (status == kCCBufferTooSmall) {
                size_t const neededSize = CCCryptorGetOutputLength(cryptorRef, self.length, true);
                size_t const additionalSize = neededSize - byteCountWritten;
                result.length += additionalSize;
            } else {
                break;
            }
        }
        if (status != kCCSuccess) {
            CCCryptorRelease(cryptorRef);
            return nil;
        }
        byteCountWritten += bytesWritten;
        
    }
    CCCryptorRelease(cryptorRef);
    
    result.length = byteCountWritten;
    return  result;
}

- (NSData *)zmDecryptPrefixedIVWithKey:(NSData *)key
{
    Require(key.length == kCCKeySizeAES256);
    
    __block CCCryptorStatus status = kCCSuccess;
    CCCryptorRef cryptorRef;
    
    status = CCCryptorCreate(kCCDecrypt, kCCAlgorithmAES, kCCOptionPKCS7Padding, key.bytes, kCCKeySizeAES256, NULL, &cryptorRef);
    if (status != kCCSuccess) {
        return nil;
    }
    
    size_t resultLength = self.length + 2 * kCCKeySizeAES256;
    NSMutableData * const result = [NSMutableData dataWithLength:resultLength];
    __block size_t byteCountWritten = 0;
    
    [self enumerateByteRangesUsingBlock:^(const void *bytes, NSRange byteRange, BOOL *stop) {
        size_t bytesWritten = 0;
        while (YES) {
            void * const dataOut = ((uint8_t *) [result mutableBytes]) + byteCountWritten;
            size_t const dataOutAvailable = resultLength - byteCountWritten;
            status = CCCryptorUpdate(cryptorRef, bytes, byteRange.length, dataOut, dataOutAvailable, &bytesWritten);
            if (status == kCCBufferTooSmall) {
                size_t const neededSize = CCCryptorGetOutputLength(cryptorRef, byteRange.length, false);
                size_t const additionalSize = neededSize - dataOutAvailable;
                result.length += additionalSize;
            } else {
                break;
            }
        }
        if (status != kCCSuccess) {
            *stop = YES;
            return;
        }
        byteCountWritten += bytesWritten;
    }];
    if (status != kCCSuccess) {
        CCCryptorRelease(cryptorRef);
        return nil;
    }
    
    {
        size_t bytesWritten = 0;
        while (YES) {
            void * const dataOut = ((uint8_t *) [result mutableBytes]) + byteCountWritten;
            size_t const dataOutAvailable = resultLength - byteCountWritten;
            status = CCCryptorFinal(cryptorRef, dataOut, dataOutAvailable, &bytesWritten);
            if (status == kCCBufferTooSmall) {
                size_t const neededSize = CCCryptorGetOutputLength(cryptorRef, self.length, true);
                size_t const additionalSize = neededSize - byteCountWritten;
                result.length += additionalSize;
            } else {
                break;
            }
        }
        if (status != kCCSuccess) {
            CCCryptorRelease(cryptorRef);
            return nil;
        }
        byteCountWritten += bytesWritten;
        
    }
    CCCryptorRelease(cryptorRef);
    
    result.length = byteCountWritten;
    
    VerifyReturnNil(result.length >= kCCBlockSizeAES128);
    return [result subdataWithRange:NSMakeRange(kCCBlockSizeAES128, result.length - kCCBlockSizeAES128)];
}

- (NSData *)zmEncryptPrefixingPlainTextIVWithKey:(NSData *)key
{
    Require(key.length == kCCKeySizeAES256);
    size_t copiedBytes = 0;
    NSMutableData *encryptedData = [NSMutableData dataWithLength:self.length+kCCBlockSizeAES128];
    NSData *IV = [NSData secureRandomDataOfLength:kCCBlockSizeAES128];

    ZMLogDebug(@"Encrypt: IV is %@, data is %lu", [IV base64EncodedStringWithOptions:0], (unsigned long)self.length);
    CCCryptorStatus status = CCCrypt(kCCEncrypt,
                                     kCCAlgorithmAES,
                                     kCCOptionPKCS7Padding,
                                     key.bytes,
                                     kCCKeySizeAES256,
                                     IV.bytes,
                                     self.bytes,
                                     self.length,
                                     encryptedData.mutableBytes,
                                     encryptedData.length,
                                     &copiedBytes);
    if(status != kCCSuccess) {
        ZMLogError(@"Error in encryption: %d", status);
        return nil;
    }
    
    encryptedData.length = copiedBytes;
    NSMutableData *finalData = [NSMutableData dataWithData:IV];
    [finalData appendData:encryptedData];
    ZMLogDebug(@"Encrypted: final data is %lu, copied: %lu", (unsigned long)finalData.length, (unsigned long)copiedBytes);
    return finalData;
}

- (NSData *)zmDecryptPrefixedPlainTextIVWithKey:(NSData *)key
{
    VerifyReturnNil(key.length == kCCKeySizeAES256);

    size_t copiedBytes = 0;
    NSMutableData *decryptedData = [NSMutableData dataWithLength:self.length+kCCBlockSizeAES128];
    NSData *dataWithoutIV = [NSData dataWithBytes:self.bytes+kCCBlockSizeAES128 length:self.length-kCCBlockSizeAES128];
    NSData *IV = [NSData dataWithBytes:self.bytes length:kCCBlockSizeAES128];
    
    ZMLogDebug(@"Decrypt: IV is %@. Data : %lu, Data w/out IV: %lu", [IV base64EncodedStringWithOptions:0], (unsigned long)self.length, (unsigned long)dataWithoutIV.length);
    
    CCCryptorStatus status = CCCrypt(kCCDecrypt,                    // basic operation kCCEncrypt or kCCDecrypt
                                     kCCAlgorithmAES,               // encryption algorithm
                                     kCCOptionPKCS7Padding,         // flags defining encryption
                                     key.bytes,      // Raw key material
                                     kCCKeySizeAES256,     // Length of key material
                                     IV.bytes,                      // Initialization vector for Cipher Block Chaining (CBC) mode (first 16 bytes)
                                     dataWithoutIV.bytes,           // Data to encrypt or decrypt
                                     dataWithoutIV.length,          // Length of data to encrypt or decrypt
                                     decryptedData.mutableBytes,    // Result is written here
                                     decryptedData.length,          // The size of the dataOut buffer in bytes
                                     &copiedBytes);                    // On successful return, the number of bytes written to dataOut.
    
    if(status != kCCSuccess) {
        ZMLogError(@"Error in decryption: %d", status);
        return nil;
    }
    
    decryptedData.length = copiedBytes;
    ZMLogDebug(@"Decrypted %lu bytes, dec length is: %lu", (unsigned long)copiedBytes, (unsigned long)decryptedData.length);
    
    return decryptedData;
}

@end

