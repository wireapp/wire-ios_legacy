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


@import WireTransport;

#import "ZMLastUpdateEventIDTranscoder+Internal.h"
#import "ZMMissingUpdateEventsTranscoder+Internal.h"
#import <WireSyncEngine/WireSyncEngine-Swift.h>

@interface ZMLastUpdateEventIDTranscoder ()

@property (nonatomic) ZMSingleRequestSync *lastUpdateEventIDSync;
@property (nonatomic) NSUUID *lastUpdateEventID;
@property (nonatomic, weak) SyncStatus *syncStatus;

@end


@implementation ZMLastUpdateEventIDTranscoder

- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext *)moc
                           applicationStatus:(id<ZMApplicationStatus>)applicationStatus
                                  syncStatus:(SyncStatus *)syncStatus
{
    self = [super initWithManagedObjectContext:moc applicationStatus:applicationStatus];
    if(self) {
        self.syncStatus = syncStatus;
        self.lastUpdateEventIDSync = [[ZMSingleRequestSync alloc] initWithSingleRequestTranscoder:self groupQueue:moc];
    }
    return self;
}

- (ZMStrategyConfigurationOption)configuration
{
    return ZMStrategyConfigurationOptionAllowsRequestsDuringSlowSync;
}

- (void)startRequestingLastUpdateEventIDWithoutPersistingIt
{
    [self.lastUpdateEventIDSync resetCompletionState];
    [self.lastUpdateEventIDSync readyForNextRequest];
}

- (void)persistLastUpdateEventID
{
    if(self.lastUpdateEventID != nil) {
        self.managedObjectContext.zm_lastNotificationID = self.lastUpdateEventID;
    }
    self.lastUpdateEventID = nil;
}

- (BOOL)isDownloadingLastUpdateEventID
{
    return self.lastUpdateEventIDSync.status == ZMSingleRequestInProgress;
}

- (SyncPhase)expectedSyncPhase
{
    return SyncPhaseFetchingLastUpdateEventID;
}

- (SyncPhase)isSyncing
{
    return self.syncStatus.currentSyncPhase == self.expectedSyncPhase;
}

- (ZMTransportRequest *)nextRequestIfAllowedForAPIVersion:(APIVersion)apiVersion
{
    if (self.isSyncing && !self.isDownloadingLastUpdateEventID) {
        [self startRequestingLastUpdateEventIDWithoutPersistingIt];
        return [self.requestGenerators nextRequestForAPIVersion:apiVersion];
    }
    
    return nil;
}

- (NSArray *)requestGenerators;
{
    return @[self.lastUpdateEventIDSync];
}

- (NSArray *)contextChangeTrackers
{
    return @[];
}

- (void)processEvents:(NSArray<ZMUpdateEvent *> __unused *)events
           liveEvents:(BOOL __unused)liveEvents
       prefetchResult:(ZMFetchRequestBatchResult __unused *)prefetchResult;
{
    // no op
}

- (ZMTransportRequest *)requestForSingleRequestSync:(ZMSingleRequestSync *)sync apiVersion:(APIVersion)apiVersion
{
    NOT_USED(sync);
    NSURLComponents *components = [NSURLComponents componentsWithString:@"/notifications/last"];
    
    UserClient *selfClient = [ZMUser selfUserInContext:self.managedObjectContext].selfClient;
    if (selfClient.remoteIdentifier != nil) {
        components.queryItems = @[[NSURLQueryItem queryItemWithName:@"client" value:selfClient.remoteIdentifier]];
    }
    
    return [ZMTransportRequest requestGetFromPath:components.string apiVersion:apiVersion];
}

- (void)didReceiveResponse:(ZMTransportResponse *)response forSingleRequest:(ZMSingleRequestSync *)sync
{
    NOT_USED(sync);
    SyncStatus *status = self.syncStatus;
    
    NSUUID *lastNotificationID = [[response.payload asDictionary] optionalUuidForKey:@"id"];
    
    if (response.HTTPStatus == 404 && status.currentSyncPhase == self.expectedSyncPhase) {
        [status finishCurrentSyncPhaseWithPhase:self.expectedSyncPhase];
    }
    else if (lastNotificationID != nil) {
        self.lastUpdateEventID = lastNotificationID;
        if (status.currentSyncPhase == self.expectedSyncPhase) {
            [status updateLastUpdateEventIDWithEventID:lastNotificationID];
            [status finishCurrentSyncPhaseWithPhase:self.expectedSyncPhase];
        }
    }
    
}

@end
