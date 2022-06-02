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



#import "MockEntity2.h"

#import <WireDataModel/ZMManagedObject+Internal.h>

@implementation MockEntity2

@dynamic field;

+ (NSString *)entityName
{
    return @"MockEntity2";
}

+ (NSString *)sortKey
{
    return @"field";
}

+ (NSString *)remoteIdentifierDataKey
{
    return @"testUUID_data";
}

- (NSUUID *)testUUID;
{
    return [self transientUUIDForKey:@"testUUID"];
}

- (void)setTestUUID:(NSUUID *)remoteIdentifier;
{
    [self setTransientUUID:remoteIdentifier forKey:@"testUUID"];
}

@end
