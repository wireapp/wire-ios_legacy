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


#import "ZMExternalEncryptedDataWithKeys.h"

@import WireTransport;
@import WireUtilities;


#pragma mark - ZMEncryptionKeyWithChecksum


@interface ZMEncryptionKeyWithChecksum ()
@property (nonatomic, readwrite) NSData *aesKey;
@property (nonatomic, readwrite) NSData *sha256;
@end

@implementation ZMEncryptionKeyWithChecksum

- (instancetype)initWithAES:(NSData *)aesKey digest:(NSData *)sha256
{
    self = [super init];
    if (self)  {
        self.aesKey = aesKey;
        self.sha256 = sha256;
    }
    return self;
}

+ (ZMEncryptionKeyWithChecksum *)keyWithAES:(NSData *)aesKey digest:(NSData *)sha256
{
    return [[self alloc] initWithAES:aesKey digest:sha256];
}

- (BOOL)isEqual:(id)object
{
    if (! [object isKindOfClass:ZMEncryptionKeyWithChecksum.class]) {
        return NO;
    }
    
    ZMEncryptionKeyWithChecksum *other = object;
    return [self.aesKey isEqualToData:other.aesKey] && [self.sha256 isEqualToData:other.sha256];
}

@end


#pragma mark - ZMExternalEncryptedDataWithKeys


@interface ZMExternalEncryptedDataWithKeys ()
@property (nonatomic, readwrite) NSData *data;
@property (nonatomic, readwrite) ZMEncryptionKeyWithChecksum *keys;
@end

@implementation ZMExternalEncryptedDataWithKeys

- (instancetype)initWithData:(NSData *)data keys:(ZMEncryptionKeyWithChecksum *)keys
{
    self = [super init];
    if (self)  {
        self.data = data;
        self.keys = keys;
    }
    return self;
}

+ (ZMExternalEncryptedDataWithKeys *)dataWithKeysWithData:(NSData *)data keys:(ZMEncryptionKeyWithChecksum *)keys
{
    return [[self alloc] initWithData:data keys:keys];
}

- (BOOL)isEqual:(id)object
{
    if (! [object isKindOfClass:ZMExternalEncryptedDataWithKeys.class]) {
        return NO;
    }
    
    ZMExternalEncryptedDataWithKeys *other = object;
    return [self.data isEqualToData:other.data] && [self.keys isEqual:other.keys];
}

@end

