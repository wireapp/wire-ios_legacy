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


@import CoreFoundation;
@import WireSystem;

#import "ZMEncodedNSUUIDWithTimestamp.h"
#import "NSUUID+Data.h"
#import <CommonCrypto/CommonCrypto.h>

static const uint8_t RANDOM_DATA_SIZE = 14;
static const uint8_t TIME_DATA_SIZE = 2;
static const uint8_t UUID_DATA_SIZE = 16;
static const uint8_t BUFFER_SIZE = RANDOM_DATA_SIZE + TIME_DATA_SIZE + UUID_DATA_SIZE;

static unsigned long HOUR_IN_SEC = 60 * 60;

static unsigned long ReferenceTimestamp = 1388534400; // 01 Jan 2014 00:00:00



@interface ZMEncodedNSUUIDWithTimestamp ()

@property (nonatomic) NSUUID *uuid;
@property (nonatomic) NSDate *timestampDate;
@property (nonatomic) NSData *encodedData;

@end



@implementation ZMEncodedNSUUIDWithTimestamp

- (instancetype)initWithEncodedData:(NSData *)data encryptionKey:(NSData *)encryptionKey;
{
    self = [super init];
    if(self) {
        self.encodedData = data;
        [self decodeDataWithKey:encryptionKey];
    }
    return self;
}

- (instancetype)initWithUUID:(NSUUID *)UUID timestampDate:(NSDate *)date encryptionKey:(NSData *)encryptionKey;
{
    self = [super init];
    if(self) {
        self.uuid = UUID;
        self.timestampDate = date;
        [self encodedDataWithKey:encryptionKey];
    }
    return self;
}

+ (uint16_t)hoursBetweenReferenceDateAndDate:(NSDate *)date
{
    NSTimeInterval diff = date.timeIntervalSince1970 - ReferenceTimestamp;
    return (uint16_t) floor(diff/HOUR_IN_SEC);
}

+ (NSDate *)dateFromHoursSinceReferenceDate:(uint16_t)hours
{
    return [NSDate dateWithTimeIntervalSince1970:ReferenceTimestamp + HOUR_IN_SEC * hours];
}

- (void)encodedDataWithKey:(NSData *)encryptionKey
{
    /*
     Encoding
     =========
     
     The initial data is:
     +-----------------------+--------------+--------------------------+
     | 14 bytes random data  | 2 bytes time | 16 bytes UUID            |
     +-----------------------+--------------+--------------------------+
     
     The initial data is then encoded with AES, no IV, no padding.
     
     Time is the number of hours since 01 Jan 2014 00:00 as a Big Endian unsigned int16.
     */
    
    RequireString((BUFFER_SIZE / kCCBlockSizeAES128 ) * kCCBlockSizeAES128 == BUFFER_SIZE, "Data to encrypt is not a multiple of the block size");
    
    RequireString(encryptionKey.length == kCCKeySizeAES256, "Encryption key has wrong length (%lu vs. expected %d)", (unsigned long)encryptionKey.length, kCCKeySizeAES256);

    uint8_t initialData[BUFFER_SIZE];
    
    // 14 bytes random data
    int result = SecRandomCopyBytes(kSecRandomDefault, RANDOM_DATA_SIZE, initialData);
    if (result != 0) {
        ZMLogError(@"ZMEncodedNSUUIDWithTimestamp cannot copy random bytes: %d", result);
        return;
    }
    
    // 2 bytes time
    uint16_t hours = [self.class hoursBetweenReferenceDateAndDate:self.timestampDate];
    uint16_t hours_BE = CFSwapInt16HostToBig(hours);
    if(!memcpy(initialData + RANDOM_DATA_SIZE, &hours_BE, TIME_DATA_SIZE)) {
        ZMLogError(@"ZMEncodedNSUUIDWithTimestamp setting hours fail");
        return;
    }
    
    // 16 bytes UUID
    if(self.uuid.data == nil || !memcpy(initialData + RANDOM_DATA_SIZE + TIME_DATA_SIZE, self.uuid.data.bytes, UUID_DATA_SIZE)) {
        ZMLogError(@"ZMEncodedNSUUIDWithTimestamp setting UUID fail");
        return;
    }
    
    // Encrypt with AES
    uint8_t encryptedData[BUFFER_SIZE];
    size_t numBytes = 0;
    CCCryptorStatus status = CCCrypt(kCCEncrypt, kCCAlgorithmAES, 0, encryptionKey.bytes, encryptionKey.length, nil, initialData, BUFFER_SIZE, &encryptedData, BUFFER_SIZE, &numBytes);

    RequireString(status == kCCSuccess, "Error in encryption: %d", status);
    self.encodedData = [NSData dataWithBytes:encryptedData length:numBytes];

}

- (void)decodeDataWithKey:(NSData *)encryptionKey
{
    
    if(self.encodedData.length != BUFFER_SIZE) {
        ZMLogWarn(@"Trying to decrypt data of invalid length");
    }
    RequireString((BUFFER_SIZE / kCCBlockSizeAES128 ) * kCCBlockSizeAES128 == BUFFER_SIZE, "Data to dencrypt is not a multiple of the block size");
    
    RequireString(encryptionKey.length == kCCKeySizeAES256, "Encryption key has wrong length (%lu vs. expected %d)", (unsigned long)encryptionKey.length, kCCKeySizeAES256);
    
    // Decrypt with AES
    uint8_t decryptedData[BUFFER_SIZE];
    size_t numBytes = 0;
    CCCryptorStatus status = CCCrypt(kCCDecrypt, kCCAlgorithmAES, 0, encryptionKey.bytes, encryptionKey.length, nil, self.encodedData.bytes, BUFFER_SIZE, &decryptedData, BUFFER_SIZE, &numBytes);
    
    if(status != kCCSuccess) {
        ZMLogError(@"Error in decryption: %d", status);
        self.timestampDate = [NSDate distantPast];
        self.uuid = nil;
        return;
    }
    
    // 14 bytes random data
    // 2 bytes time
    uint16_t hours_BE;
    memcpy(&hours_BE, decryptedData + RANDOM_DATA_SIZE, TIME_DATA_SIZE);
    uint16_t hours = CFSwapInt16BigToHost(hours_BE);
    self.timestampDate = [self.class dateFromHoursSinceReferenceDate:hours];
    
    // 16 bytes UUID
    NSUUID *uuid = [[NSUUID alloc] initWithUUIDBytes:(const unsigned char*)decryptedData + RANDOM_DATA_SIZE + TIME_DATA_SIZE];
    self.uuid = uuid;
    
}

+ (NSString *)URLSafeBase64WithoutPaddingEncodeData:(NSData *)data
{
    NSString *base64 = [data base64EncodedStringWithOptions:0];
    NSString *safeBase64 = [[base64 stringByReplacingOccurrencesOfString:@"/" withString:@"_"]
                            stringByReplacingOccurrencesOfString:@"+" withString:@"-"];
    
    // we know that there is always a = at the end, so we can remove it
    RequireString( [safeBase64 characterAtIndex:safeBase64.length-1] == '=', "No '=' at the end of the base64 encoded string");
    NSString *noPaddingSafeBase64 = [safeBase64 stringByReplacingOccurrencesOfString:@"=" withString:@""];
    RequireString( ! [noPaddingSafeBase64 containsString:@"="], "More than one = in base64 encoded string");
    return noPaddingSafeBase64;
}

+ (NSData *)URLSafeBase64WithoutPaddingDecodeString:(NSString *)safeBase64WithoutPadding
{
    VerifyReturnNil([safeBase64WithoutPadding characterAtIndex:safeBase64WithoutPadding.length-1] != '=');
    NSString *safeBase64 = [safeBase64WithoutPadding stringByAppendingString:@"="];
    NSString *base64 = [[safeBase64 stringByReplacingOccurrencesOfString:@"_" withString:@"/"]
                        stringByReplacingOccurrencesOfString:@"-" withString:@"+"];
    
    return [[NSData alloc] initWithBase64EncodedString:base64 options:0];
}


- (NSURL *)URLWithEncodedUUIDWithTimestampPrefixedWithString:(NSString *)prefix;
{
    
    NSString *base64EncodedIndentifier = [self.class URLSafeBase64WithoutPaddingEncodeData:self.encodedData];
    NSMutableCharacterSet *set = [[NSCharacterSet URLQueryAllowedCharacterSet] mutableCopy];
    [set removeCharactersInString:@"/=&+"];
    NSString *urlEncodedIdentifier = [base64EncodedIndentifier stringByAddingPercentEncodingWithAllowedCharacters:set];
    
    return [NSURL URLWithString:[prefix stringByAppendingString:urlEncodedIdentifier]];
}

- (instancetype)initWithSafeBase64EncodedToken:(NSString *)token withEncryptionKey:(NSData *)encryptionKey;
{
    if(token == nil) {
        return nil;
    }
    NSString *safeToken = [token stringByRemovingPercentEncoding];
    NSData *decodedData = [self.class URLSafeBase64WithoutPaddingDecodeString:safeToken];
    if(decodedData == nil) {
        return nil;
    }
    
    return [[ZMEncodedNSUUIDWithTimestamp alloc] initWithEncodedData:decodedData encryptionKey:encryptionKey];
}


@end

