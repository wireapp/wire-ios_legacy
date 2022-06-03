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


#import "NSUUID+WireTesting.h"
#import <CommonCrypto/CommonCrypto.h>
#import <stdatomic.h>

@implementation NSUUID (WireTesting)

static uuid_t uuidBase;
static atomic_int uuidCounter;

- (NSUUID *)createUUID;
{
    return [[self class] createUUID];
}

+ (NSUUID *)createUUID;
{
    uuid_t bytes;
    uuid_copy(bytes, uuidBase);
    atomic_fetch_add_explicit(&uuidCounter, 1, memory_order_relaxed);
    int32_t c = atomic_load(&uuidCounter);
    bytes[14] = (c >> 8) & 0xff;
    bytes[15] = c & 0xff;
    NSUUID *uuid = [[NSUUID alloc] initWithUUIDBytes:bytes];
    return uuid;
}

+ (void)reseedUUID:(NSString *)testName;
{
    NSData *data = [testName dataUsingEncoding:NSUTF8StringEncoding];
    uint8_t md[CC_SHA1_DIGEST_LENGTH];
    CC_SHA1(data.bytes, (CC_LONG) data.length, md);
    memcpy(uuidBase, md, sizeof(uuidBase));
    uuidBase[6] = (uuidBase[6] & 0xf) | 0x40;
    uuidBase[8] = (uuidBase[8] & 0xf) | 0xA0;
    uuidBase[14] = 0;
    uuidBase[15] = 0;
    
    uuidCounter = 0;
}

@end
