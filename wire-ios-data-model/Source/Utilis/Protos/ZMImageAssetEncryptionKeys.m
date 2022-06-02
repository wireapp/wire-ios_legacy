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


#import "ZMImageAssetEncryptionKeys.h"
#import <WireDataModel/WireDataModel-Swift.h>

@import ImageIO;
@import MobileCoreServices;
@import WireImages;


@interface ZMImageAssetEncryptionKeys()

@property (nonatomic, copy) NSData *otrKey;
@property (nonatomic, copy) NSData *macKey;
@property (nonatomic, copy) NSData *mac;
@property (nonatomic, copy) NSData *sha256;

@end

@implementation ZMImageAssetEncryptionKeys

- (instancetype)initWithOtrKey:(NSData *)otrKey macKey:(NSData *)macKey mac:(NSData *)mac;
{
    self = [super init];
    if (self) {
        self.otrKey = [otrKey copy];
        self.macKey = [macKey copy];
        self.mac = [mac copy];
    }
    return self;
}

- (instancetype)initWithOtrKey:(NSData *)otrKey sha256:(NSData *)sha256;
{
    self = [super init];
    if (self) {
        self.otrKey = [otrKey copy];
        self.sha256 = sha256;
    }
    return self;
}

- (BOOL)hasHMACDigest
{
    return self.mac != nil;
}

- (BOOL)hasSHA256Digest
{
    return self.sha256 != nil;
}

@end
