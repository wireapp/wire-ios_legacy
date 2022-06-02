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
@import WireUtilities;
@import WireTransport;

#import <CommonCrypto/CommonCrypto.h>
#import "ZMAPSMessageDecoder.h"


static NSString * const DataKey = @"data";
static NSString * const MacKey = @"mac";

//static const uint8_t IV_DATA_SIZE = 16;

@interface ZMAPSMessageDecoder ()

@property (nonatomic) NSData *encryptionKey;
@property (nonatomic) NSData *macKey;

@end



@implementation ZMAPSMessageDecoder

- (instancetype)initWithEncryptionKey:(NSData *)encryptionKey macKey:(NSData *)macKey;
{
    self = [super init];
    if(self) {
        RequireString(encryptionKey.length == kCCKeySizeAES256, "Encryption key has wrong length (%lu vs. expected %d)", (unsigned long)encryptionKey.length, kCCKeySizeAES256);

        self.encryptionKey = encryptionKey;
        self.macKey = macKey;
    }
    return self;
}

- (NSDictionary *)decodeAPSPayload:(NSDictionary *)payload
{
    NSString *hashString = [payload optionalStringForKey:MacKey];
    NSString *dataString = [payload optionalStringForKey:DataKey];
    
    NSData *hashData = [[NSData alloc] initWithBase64EncodedString:hashString options:0];
    NSData *encodedData = [[NSData alloc] initWithBase64EncodedString:dataString options:0];
    
    if (![self isValidHash:hashData encodedData:encodedData]) {
        ZMLogError(@"Provided invalid hash: %@ for data: %@ with mac key: %@ encryption key: %@", hashString, dataString, self.macKey, self.encryptionKey);
        return nil;
    }
    
    NSData *decodedData = [self decodeData:encodedData];
    if (decodedData == nil){
        ZMLogError(@"Invalid payload in APS: %@", payload);
        return nil;
    }
    
    NSError *error;
    NSDictionary *eventPayload = [NSJSONSerialization JSONObjectWithData:decodedData options:0 error:&error];
    if (error != nil) {
        ZMLogError(@"Unable to create JSON from payload in APS with error: %@", error);
        return nil;
    }
    return eventPayload;
}

- (BOOL)isValidHash:(NSData *)expectedHash encodedData:(NSData *)encodedData
{
    NSData *calculatedMac = [self hashDataForEncodedData:encodedData];
    if ([calculatedMac isEqualToData:expectedHash]) {
        return YES;
    }
    return NO;
}

- (NSData *)hashDataForEncodedData:(NSData *)encodedData
{
    return [encodedData zmHMACSHA256DigestWithKey:self.macKey];
}

- (NSData *)decodeData:(NSData *)data
{
    return [data zmDecryptPrefixedPlainTextIVWithKey:self.encryptionKey];
}

@end

