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


@import WireUtilities;
@import WireSystem;
@import WireTransport;
@import WireCryptobox;
@import WireDataModel;

#import "ZMOperationLoop+Private.h"
#import "ZMSyncStrategy+ManagedObjectChanges.h"

#import <libkern/OSAtomic.h>
#import <os/activity.h>
#import "WireSyncEngineLogs.h"
#import <WireSyncEngine/WireSyncEngine-Swift.h>

NSString * const ZMPushChannelIsOpenKey = @"pushChannelIsOpen";

static char* const ZMLogTag ZM_UNUSED = "OperationLoop";


@interface ZMOperationLoop ()
{
    int32_t _pendingEnqueueNextCount;
}

@property (nonatomic) NSNotificationQueue *enqueueNotificationQueue;
@property (nonatomic) id<TransportSessionType> transportSession;
@property (atomic) BOOL shouldStopEnqueueing;
@property (nonatomic) BOOL tornDown;
@property (nonatomic, weak) ApplicationStatusDirectory *applicationStatusDirectory;

@end


@interface ZMOperationLoop (NewRequests) <ZMRequestAvailableObserver>
@end


@implementation ZMOperationLoop

- (instancetype)initWithTransportSession:(id<TransportSessionType>)transportSession
                         requestStrategy:(id<RequestStrategy>)requestStrategy
                    updateEventProcessor:(id<UpdateEventProcessor>)updateEventProcessor
              applicationStatusDirectory:(ApplicationStatusDirectory *)applicationStatusDirectory
                                   uiMOC:(NSManagedObjectContext *)uiMOC
                                 syncMOC:(NSManagedObjectContext *)syncMOC
{
    Check(uiMOC != nil);
    Check(syncMOC != nil);
    
    self = [super init];
    if (self) {
        self.applicationStatusDirectory = applicationStatusDirectory;
        self.transportSession = transportSession;
        self.requestStrategy = requestStrategy;
        self.updateEventProcessor = updateEventProcessor;
        self.syncMOC = syncMOC;
        self.shouldStopEnqueueing = NO;
        applicationStatusDirectory.operationStatus.delegate = self;
        
        [ZMRequestAvailableNotification addObserver:self];
        
        NSManagedObjectContext *moc = self.syncMOC;
        // this is needed to avoid loading from syncMOC on the main queue
        [moc performGroupedBlock:^{
            [self.transportSession configurePushChannelWithConsumer:self groupQueue:moc];
            [self.transportSession.pushChannel setKeepOpen:applicationStatusDirectory.operationStatus.operationState == SyncEngineOperationStateForeground];
        }];
    }

    return self;
}

- (void)tearDown;
{
    self.tornDown = YES;
    self.shouldStopEnqueueing = YES;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [ZMRequestAvailableNotification removeObserver:self];
    
    self.transportSession = nil;
    ///TODO: 
//    RequireString([NSOperationQueue mainQueue] == [NSOperationQueue currentQueue],
//                  "Must call be called on the main queue.");
    __block BOOL didStop = NO;
    [self.syncMOC.dispatchGroup notifyOnQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0) block:^{
        didStop = YES;
    }];
    while (!didStop) {
        if (! [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.002]]) {
            [NSThread sleepForTimeInterval:0.002];
        }
    }
}

#if DEBUG
- (void)dealloc
{
    RequireString(self.tornDown, "Did not call tearDown %p", (__bridge void *) self);
}
#endif


- (APSSignalingKeysStore *)apsSignalKeyStore
{
    if (_apsSignalKeyStore == nil) {
        ZMUser *selfUser = [ZMUser selfUserInContext:self.syncMOC];
        if (selfUser.selfClient != nil) {
            _apsSignalKeyStore = [[APSSignalingKeysStore alloc] initWithUserClient:selfUser.selfClient];
        }
    }
    return _apsSignalKeyStore;
}

- (ZMTransportRequestGenerator)requestGenerator {
    
    ZM_WEAK(self);
    return ^ZMTransportRequest *(void) {
        ZM_STRONG(self);
        if (self == nil) {
            return nil;
        }

        APIVersionWrapper *apiVersion = [self currentAPIVersion];

        if (apiVersion == nil) {
            return nil;
        }

        ZMTransportRequest *request = [self.requestStrategy nextRequestForAPIVersion:apiVersion.value];

        [request addCompletionHandler:[ZMCompletionHandler handlerOnGroupQueue:self.syncMOC block:^(ZMTransportResponse *response) {
            ZM_STRONG(self);
            
            [self.syncMOC enqueueDelayedSaveWithGroup:response.dispatchGroup];
            
            // Check if there is something to do now and when the save completes
            [ZMRequestAvailableNotification notifyNewRequestsAvailable:self];
        }]];
        
        return request;
    };
    
}

- (void)executeNextOperation
{    
    if (self.shouldStopEnqueueing) {
        return;
    }
    
    // this generates the request
    ZMTransportRequestGenerator generator = [self requestGenerator];
    
    BackgroundActivity *enqueueActivity = [BackgroundActivityFactory.sharedFactory startBackgroundActivityWithName:@"executeNextOperation"];

    if (!enqueueActivity) {
        return;
    }

    ZM_WEAK(self);
    [self.syncMOC performGroupedBlock:^{
        ZM_STRONG(self);
        BOOL enqueueMore = YES;
        while (self && enqueueMore && !self.shouldStopEnqueueing) {
            ZMTransportEnqueueResult *result = [self.transportSession attemptToEnqueueSyncRequestWithGenerator:generator];
            enqueueMore = result.didGenerateNonNullRequest && result.didHaveLessRequestThanMax;
        }
        [BackgroundActivityFactory.sharedFactory endBackgroundActivity:enqueueActivity];
    }];
}

- (PushNotificationStatus *)pushNotificationStatus
{
    return self.applicationStatusDirectory.pushNotificationStatus;
}

- (CallEventStatus *)callEventStatus {
    return self.applicationStatusDirectory.callEventStatus;
}

- (SyncStatus *)syncStatus {
    return self.applicationStatusDirectory.syncStatus;
}

@end


@implementation ZMOperationLoop (NewRequests)

- (void)newRequestsAvailable
{
    [self executeNextOperation];
}

@end
