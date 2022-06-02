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

@import WireDataModel;
#import "MockEntity.h"

@implementation MockEntity

@dynamic field, field2, field3;
@dynamic testUUID;
@dynamic mockEntities;
@dynamic modifiedKeys;

static NSPredicate *_predicateForObjectsThatNeedToBeUpdatedUpstream = nil;
+ (void)setPredicateForObjectsThatNeedToBeUpdatedUpstream:(NSPredicate *)predicateForObjectsThatNeedToBeUpdatedUpstream
{
    _predicateForObjectsThatNeedToBeUpdatedUpstream = predicateForObjectsThatNeedToBeUpdatedUpstream;
}

+ (NSPredicate *)predicateForObjectsThatNeedToBeUpdatedUpstream
{
    return _predicateForObjectsThatNeedToBeUpdatedUpstream;
}

+(NSString *)sortKey {
    return @"field";
}

+(NSString *)entityName {
    return @"MockEntity";
}

+(NSString *)remoteIdentifierDataKey {
    return @"remoteIdentifier_data";
}

- (NSUUID *)testUUID;
{
    return [self transientUUIDForKey:@"testUUID"];
}

- (void)setTestUUID:(NSUUID *)remoteIdentifier;
{
    [self setTransientUUID:remoteIdentifier forKey:@"testUUID"];
}

- (NSUUID *)remoteIdentifier;
{
    return [self transientUUIDForKey:@"remoteIdentifier"];
}

- (void)setRemoteIdentifier:(NSUUID *)remoteIdentifier;
{
    [self setTransientUUID:remoteIdentifier forKey:@"remoteIdentifier"];
}

+ (NSArray *)sortDescriptorsForUpdating;
{
    return [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"field" ascending:YES]];
}

@end
