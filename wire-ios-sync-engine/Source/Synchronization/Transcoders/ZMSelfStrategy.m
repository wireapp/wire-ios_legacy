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


@import WireImages;
@import WireSystem;
@import WireTransport;

#import "ZMSelfStrategy+Internal.h"
#import "ZMSyncStrategy.h"
#import "ZMClientRegistrationStatus.h"
#import <WireSyncEngine/WireSyncEngine-Swift.h>

static NSString *SelfPath = @"/self";

static NSString * const AccentColorValueKey = @"accentColorValue";
static NSString * const NameKey = @"name";

static NSString * const PreviewProfileAssetIdentifierKey = @"previewProfileAssetIdentifier";
static NSString * const CompleteProfileAssetIdentifierKey = @"completeProfileAssetIdentifier";

NSTimeInterval ZMSelfStrategyPendingValidationRequestInterval = 5;

@interface ZMSelfStrategy ()

@property (nonatomic) ZMUpstreamModifiedObjectSync *upstreamObjectSync;
@property (nonatomic) ZMSingleRequestSync *downstreamSelfUserSync;
@property (nonatomic) NSPredicate *needsToBeUdpatedFromBackend;
@property (nonatomic, weak) ZMClientRegistrationStatus *clientStatus;
@property (nonatomic, weak) SyncStatus *syncStatus;
@property (nonatomic) BOOL didCheckNeedsToBeUdpatedFromBackend;
@end

@interface ZMSelfStrategy (SingleRequestTranscoder) <ZMSingleRequestTranscoder>
@end

@interface ZMSelfStrategy (UpstreamTranscoder) <ZMUpstreamTranscoder>
@end



@implementation ZMSelfStrategy

- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext *)moc
                           applicationStatus:(id<ZMApplicationStatus>)applicationStatus
                    clientRegistrationStatus:(ZMClientRegistrationStatus *)clientRegistrationStatus
                                  syncStatus:(SyncStatus *)syncStatus
{
    NSArray<NSString *> *keysToSync = @[NameKey, AccentColorValueKey, PreviewProfileAssetIdentifierKey, CompleteProfileAssetIdentifierKey];
    
    ZMUpstreamModifiedObjectSync *upstreamObjectSync = [[ZMUpstreamModifiedObjectSync alloc]
                                                        initWithTranscoder:self
                                                        entityName:ZMUser.entityName
                                                        keysToSync:keysToSync
                                                        managedObjectContext:moc];
    
    return [self initWithManagedObjectContext:moc applicationStatus:applicationStatus clientRegistrationStatus:clientRegistrationStatus syncStatus: syncStatus upstreamObjectSync:upstreamObjectSync];
}

- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext *)moc
                           applicationStatus:(id<ZMApplicationStatus>)applicationStatus
                    clientRegistrationStatus:(ZMClientRegistrationStatus *)clientRegistrationStatus
                                  syncStatus:(SyncStatus *)syncStatus
                          upstreamObjectSync:(ZMUpstreamModifiedObjectSync *)upstreamObjectSync
{
    self = [super initWithManagedObjectContext:moc applicationStatus:applicationStatus];
    if(self) {
        self.clientStatus = clientRegistrationStatus;
        self.syncStatus = syncStatus;
        self.upstreamObjectSync = upstreamObjectSync;
        NSAssert(self.upstreamObjectSync != nil, @"upstreamObjectSync is nil");
        self.downstreamSelfUserSync = [[ZMSingleRequestSync alloc] initWithSingleRequestTranscoder:self groupQueue:self.managedObjectContext];
        self.needsToBeUdpatedFromBackend = [ZMUser predicateForNeedingToBeUpdatedFromBackend];
        _timedDownstreamSync = [[ZMTimedSingleRequestSync alloc] initWithSingleRequestTranscoder:self everyTimeInterval:ZMSelfStrategyPendingValidationRequestInterval groupQueue:self.managedObjectContext];
    }
    return self;
}

- (ZMStrategyConfigurationOption)configuration
{
    return ZMStrategyConfigurationOptionAllowsRequestsWhileUnauthenticated
         | ZMStrategyConfigurationOptionAllowsRequestsWhileOnline
         | ZMStrategyConfigurationOptionAllowsRequestsDuringSlowSync;
}

- (NSArray *)contextChangeTrackers
{
    return @[self.upstreamObjectSync, self];
}

- (void)tearDown
{
    [self.timedDownstreamSync invalidate];
    self.clientStatus = nil;
    self.syncStatus = nil;
}

- (SyncPhase)expectedSyncPhase
{
    return SyncPhaseFetchingSelfUser;
}

- (BOOL)isSyncing
{
    return self.syncStatus.currentSyncPhase == self.expectedSyncPhase;
}

- (ZMTransportRequest *)nextRequestIfAllowedForAPIVersion:(APIVersion)apiVersion;
{
    ZMClientRegistrationStatus *clientStatus = self.clientStatus;
    ZMUser *selfUser = [ZMUser selfUserInContext:self.managedObjectContext];
    
    if (clientStatus.currentPhase == ZMClientRegistrationPhaseWaitingForEmailVerfication) {
        [self.timedDownstreamSync readyForNextRequestIfNotBusy];
        return [self.timedDownstreamSync nextRequestForAPIVersion:apiVersion];
    }
    if (clientStatus.currentPhase == ZMClientRegistrationPhaseWaitingForSelfUser || self.isSyncing) {
        if (! selfUser.needsToBeUpdatedFromBackend) {
            selfUser.needsToBeUpdatedFromBackend = YES;
            [self.managedObjectContext enqueueDelayedSave];
            [self.downstreamSelfUserSync readyForNextRequestIfNotBusy];
        }
        if (selfUser.needsToBeUpdatedFromBackend) {
            return [self.downstreamSelfUserSync nextRequestForAPIVersion:apiVersion];
        }
    }
    else if (clientStatus.currentPhase == ZMClientRegistrationPhaseRegistered) {
        return [@[self.downstreamSelfUserSync, self.upstreamObjectSync] nextRequestForAPIVersion:apiVersion];
    }
    return nil;
}


- (void)checkIfNeedsToBeUdpatedFromBackend;
{
    if (!self.didCheckNeedsToBeUdpatedFromBackend) {
        self.didCheckNeedsToBeUdpatedFromBackend = YES;
        ZMUser *selfUser = [ZMUser selfUserInContext:self.managedObjectContext];
        if ([self.needsToBeUdpatedFromBackend evaluateWithObject:selfUser]) {
            [self.downstreamSelfUserSync readyForNextRequest];
        }
    }
}

- (BOOL)isSelfUserComplete
{
    ZMUser *selfUser = [ZMUser selfUserInContext:self.managedObjectContext];
    return selfUser.remoteIdentifier != nil;
}

@end



@implementation ZMSelfStrategy (UpstreamTranscoder)

- (BOOL)shouldProcessUpdatesBeforeInserts;
{
    return NO;
}

- (ZMUpstreamRequest *)requestForUpdatingObject:(ZMManagedObject *)managedObject forKeys:(NSSet *)keys apiVersion:(APIVersion)apiVersion;
{
    ZMUser *user = (ZMUser *)managedObject;
    Require(user.isSelfUser);

    if ([keys containsObject:AccentColorValueKey] ||
        [keys containsObject:NameKey] ||
        ([keys containsObject:PreviewProfileAssetIdentifierKey] && [keys containsObject:CompleteProfileAssetIdentifierKey])) {
        return [self requestForSettingBasicProfileDataOfUser:user changedKeys:keys apiVersion:apiVersion];
    }
    ZMTrapUnableToGenerateRequest(keys, self);
    return nil;
}

- (ZMUpstreamRequest *)requestForSettingBasicProfileDataOfUser:(ZMUser *)user changedKeys:(NSSet *)keys apiVersion:(APIVersion)apiVersion
{
    NSMutableDictionary *payload = [NSMutableDictionary dictionary];
    
    if([keys containsObject:NameKey]) {
        payload[@"name"] = user.name;
    }
    if([keys containsObject:AccentColorValueKey]) {
        payload[@"accent_id"] = @(user.accentColorValue);
    }
    if([keys containsObject:PreviewProfileAssetIdentifierKey] && [keys containsObject:CompleteProfileAssetIdentifierKey]) {
        payload[@"assets"] = [self profilePictureAssetsPayloadForUser:user];
    }
    
    ZMTransportRequest *request = [ZMTransportRequest requestWithPath:@"/self" method:ZMMethodPUT payload:payload apiVersion:apiVersion];
    return [[ZMUpstreamRequest alloc] initWithKeys:keys transportRequest:request];
}

- (NSArray *)profilePictureAssetsPayloadForUser:(ZMUser *)user {
    return @[
             @{
                 @"size" : @"preview",
                 @"key" : user.previewProfileAssetIdentifier,
                 @"type" : @"image"
                 },
             @{
                 @"size" : @"complete",
                 @"key" : user.completeProfileAssetIdentifier,
                 @"type" : @"image"
                 },
      ];
}

- (ZMUpstreamRequest *)requestForInsertingObject:(ZMManagedObject *)managedObject forKeys:(NSSet *)keys apiVersion:(APIVersion)apiVersion;
{
    NOT_USED(managedObject);
    NOT_USED(keys);
    return nil;
}

- (BOOL)updateUpdatedObject:(ZMUser *__unused )selfUser
            requestUserInfo:(NSDictionary *__unused )requestUserInfo
                   response:(ZMTransportResponse *__unused)response
                keysToParse:(NSSet *__unused )keysToParse
{
    return NO;
}
- (void)updateInsertedObject:(ZMManagedObject * __unused)managedObject request:(ZMUpstreamRequest *__unused)upstreamRequest response:(ZMTransportResponse *__unused)response;
{
    // we will never create a user on the backend with this sync
}

- (ZMManagedObject *)objectToRefetchForFailedUpdateOfObject:(ZMManagedObject *__unused)managedObject;
{
    return nil;
}

@end



@implementation ZMSelfStrategy (SingleRequestTranscoder)


- (ZMTransportRequest *)requestForSingleRequestSync:(ZMSingleRequestSync *)sync apiVersion:(APIVersion)apiVersion;
{
    NOT_USED(sync);
    return [ZMTransportRequest requestGetFromPath:SelfPath apiVersion:apiVersion];
}

- (void)didReceiveResponse:(ZMTransportResponse *)response forSingleRequest:(ZMSingleRequestSync *)sync;
{
    NOT_USED(sync);
    ZMUser *selfUser = [ZMUser selfUserInContext:self.managedObjectContext];
    SyncStatus *syncStatus = self.syncStatus;
    
    if (response.result == ZMTransportResponseStatusSuccess) {
        
        ZMClientRegistrationStatus *clientStatus = self.clientStatus;
        ZMClientRegistrationPhase clientPhase = clientStatus.currentPhase;
        
        NSDictionary *payload = [response.payload asDictionary];
        [selfUser updateWithTransportData:payload authoritative:YES];
        
        // TODO: Write tests for all cases
        BOOL selfUserHasEmail = (selfUser.emailAddress != nil);
        BOOL needToNotifyAuthState = (clientPhase == ZMClientRegistrationPhaseWaitingForSelfUser) ||
                                     (clientPhase == ZMClientRegistrationPhaseWaitingForEmailVerfication);

        if (needToNotifyAuthState) {
            [clientStatus didFetchSelfUser];
        }
        
        if (sync == self.timedDownstreamSync) {
            if(!selfUserHasEmail) {
                if(self.timedDownstreamSync.timeInterval != ZMSelfStrategyPendingValidationRequestInterval) {
                    self.timedDownstreamSync.timeInterval = ZMSelfStrategyPendingValidationRequestInterval;
                }
            }
            else {
                self.timedDownstreamSync.timeInterval = 0;
            }
        }
        
        // Save to ensure self user is update to date when sync finishes
        [self.managedObjectContext saveOrRollback];
        
        if (self.isSyncing) {
            [syncStatus finishCurrentSyncPhaseWithPhase:self.expectedSyncPhase];
        }
    } else if (response.result == ZMTransportResponseStatusPermanentError && self.isSyncing) {
        [syncStatus failCurrentSyncPhaseWithPhase:self.expectedSyncPhase];
    }
}

@end



@implementation ZMSelfStrategy (ContextChangeTracker)

- (NSFetchRequest *)fetchRequestForTrackedObjects
{
    [self checkIfNeedsToBeUdpatedFromBackend];
    return [self.upstreamObjectSync fetchRequestForTrackedObjects];
}

- (void)addTrackedObjects:(NSSet *)objects;
{
    [self.upstreamObjectSync addTrackedObjects:objects];
}

- (void)objectsDidChange:(NSSet *)objects
{
    ZMUser *selfUser = [ZMUser selfUserInContext:self.managedObjectContext];
    if ([objects containsObject:selfUser] && selfUser.needsToBeUpdatedFromBackend) {
        [self.downstreamSelfUserSync readyForNextRequest];
    }
}

@end
