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



#import "ZMDownstreamObjectSyncWithWhitelist.h"
#import "ZMDownstreamObjectSync.h"
#import <WireDataModel/ZMManagedObject.h>

@interface ZMDownstreamObjectSyncWithWhitelist () <ZMDownstreamTranscoder>

@property (nonatomic) NSMutableSet *whitelist;
@property (nonatomic) ZMDownstreamObjectSync *innerDownstreamSync;
@property (nonatomic, weak) id<ZMDownstreamTranscoder> transcoder;

@end

@implementation ZMDownstreamObjectSyncWithWhitelist

- (instancetype)initWithTranscoder:(id<ZMDownstreamTranscoder>)transcoder
                        entityName:(NSString *)entityName
     predicateForObjectsToDownload:(NSPredicate *)predicateForObjectsToDownload
              managedObjectContext:(NSManagedObjectContext *)moc
{
    self = [super init];
    if(self) {
        self.transcoder = transcoder;
        self.innerDownstreamSync = [[ZMDownstreamObjectSync alloc] initWithTranscoder:self entityName:entityName predicateForObjectsToDownload:predicateForObjectsToDownload filter:nil managedObjectContext:moc];
        self.whitelist = [NSMutableSet set];
    }
    return self;
}

- (void)whiteListObject:(ZMManagedObject *)object;
{
    [self.whitelist addObject:object];
    [self.innerDownstreamSync objectsDidChange:[NSSet setWithObject:object]];
}

- (void)objectsDidChange:(NSSet *)objects;
{
    NSMutableSet *whitelistedObjectsThatChanges = [self.whitelist mutableCopy];
    [whitelistedObjectsThatChanges intersectSet:objects];
    [self.innerDownstreamSync objectsDidChange:whitelistedObjectsThatChanges];
}

- (NSFetchRequest *)fetchRequestForTrackedObjects
{
    // I don't want to fetch. Only objects that are whitelisted should go through
    return nil;
}

- (void)addTrackedObjects:(NSSet __unused *)objects;
{
    // no-op
}

- (BOOL)hasOutstandingItems
{
    return self.innerDownstreamSync.hasOutstandingItems;
}

- (ZMTransportRequest *)nextRequestForAPIVersion:(APIVersion)apiVersion
{
    return [self.innerDownstreamSync nextRequestForAPIVersion:apiVersion];
}

- (ZMTransportRequest *)requestForFetchingObject:(ZMManagedObject *)object downstreamSync:(id<ZMObjectSync> __unused)downstreamSync apiVersion:(APIVersion)apiVersion
{
    return [self.transcoder requestForFetchingObject:object downstreamSync:self apiVersion:apiVersion];
}

- (void)deleteObject:(ZMManagedObject *)object withResponse:(ZMTransportResponse *)response downstreamSync:(id<ZMObjectSync> __unused)downstreamSync
{
    return [self.transcoder deleteObject:object withResponse:response downstreamSync:self];
}

- (void)updateObject:(ZMManagedObject *)object withResponse:(ZMTransportResponse *)response downstreamSync:(id<ZMObjectSync> __unused)downstreamSync
{
    return [self.transcoder updateObject:object withResponse:response downstreamSync:self];
}

@end
