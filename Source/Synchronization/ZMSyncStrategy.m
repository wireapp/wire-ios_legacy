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


@import UIKit;
@import zimages;
@import ZMUtilities;
@import ZMTransport;
@import ZMCDataModel;

#import "ZMBadge.h"
#import "ZMSyncStrategy+Internal.h"
#import "ZMUserSession.h"
#import "ZMUserSession+Internal.h"
#import "ZMConnectionTranscoder.h"
#import "ZMUserTranscoder.h"
#import "ZMSelfTranscoder.h"
#import "ZMConversationTranscoder.h"
#import "ZMMessageTranscoder.h"
#import "ZMKnockTranscoder.h"
#import "ZMAssetTranscoder.h"
#import "ZMUserImageTranscoder.h"
#import "ZMContextChangeTracker.h"
#import "ZMSyncStateMachine.h"
#import "ZMAuthenticationStatus.h"
#import "ZMMissingUpdateEventsTranscoder.h"
#import "ZMLastUpdateEventIDTranscoder.h"
#import "ZMRegistrationTranscoder.h"
#import "ZMFlowSync.h"
#import "ZMPushTokenTranscoder.h"
#import "ZMLoginTranscoder.h"
#import "ZMTracing.h"
#import "ZMSearchUserImageTranscoder.h"
#import "ZMTypingTranscoder.h"
#import "ZMCallStateTranscoder.h"
#import "ZMOperationLoop.h"
#import "ZMChangeTrackerBootstrap.h"
#import "ZMRemovedSuggestedPeopleTranscoder.h"
#import "ZMPhoneNumberVerificationTranscoder.h"
#import "ZMLoginCodeRequestTranscoder.h"
#import "ZMUserProfileUpdateTranscoder.h"
#import "ZMessagingLogs.h"
#import "ZMClientMessageTranscoder.h"
#import "ZMClientRegistrationStatus.h"
#import "ZMOnDemandFlowManager.h"
#import <zmessaging/zmessaging-Swift.h>


@interface ZMSyncStrategy ()
{
    dispatch_once_t _didFetchObjects;
}

@property (nonatomic) NSManagedObjectContext *syncMOC;
@property (nonatomic, weak) NSManagedObjectContext *uiMOC;

@property (nonatomic) ZMBadge *badge;

@property (nonatomic) ZMConnectionTranscoder *connectionTranscoder;
@property (nonatomic) ZMUserTranscoder *userTranscoder;
@property (nonatomic) ZMSelfTranscoder *selfTranscoder;
@property (nonatomic) ZMConversationTranscoder *conversationTranscoder;
@property (nonatomic) ZMMessageTranscoder *systemMessageTranscoder;
@property (nonatomic) ZMMessageTranscoder *clientMessageTranscoder;
@property (nonatomic) ZMKnockTranscoder *knockTranscoder;
@property (nonatomic) ZMAssetTranscoder *assetTranscoder;
@property (nonatomic) ZMUserImageTranscoder *userImageTranscoder;
@property (nonatomic) ZMMissingUpdateEventsTranscoder *missingUpdateEventsTranscoder;
@property (nonatomic) ZMLastUpdateEventIDTranscoder *lastUpdateEventIDTranscoder;
@property (nonatomic) ZMRegistrationTranscoder *registrationTranscoder;
@property (nonatomic) ZMPhoneNumberVerificationTranscoder *phoneNumberVerificationTranscoder;
@property (nonatomic) ZMLoginTranscoder *loginTranscoder;
@property (nonatomic) ZMLoginCodeRequestTranscoder *loginCodeRequestTranscoder;
@property (nonatomic) ZMFlowSync *flowTranscoder;
@property (nonatomic) ZMPushTokenTranscoder *pushTokenTranscoder;
@property (nonatomic) ZMCallStateTranscoder *callStateTranscoder;
@property (nonatomic) ZMSearchUserImageTranscoder *searchUserImageTranscoder;
@property (nonatomic) ZMTypingTranscoder *typingTranscoder;
@property (nonatomic) ZMRemovedSuggestedPeopleTranscoder *removedSuggestedPeopleTranscoder;
@property (nonatomic) ZMUserProfileUpdateTranscoder *userProfileUpdateTranscoder;
@property (nonatomic) PingBackRequestStrategy *pingBackRequestStrategy;
@property (nonatomic) PushNoticeRequestStrategy *pushNoticeFetchStrategy;
@property (nonatomic) LinkPreviewAssetUploadRequestStrategy *linkPreviewAssetUploadRequestStrategy;

@property (nonatomic) ZMSyncStateMachine *stateMachine;
@property (nonatomic) ZMUpdateEventsBuffer *eventsBuffer;
@property (nonatomic) ZMChangeTrackerBootstrap *changeTrackerBootStrap;
@property (nonatomic) ConversationStatusStrategy *conversationStatusSync;
@property (nonatomic) UserClientRequestStrategy *userClientRequestStrategy;
@property (nonatomic) FileUploadRequestStrategy *fileUploadRequestStrategy;
@property (nonatomic) LinkPreviewAssetDownloadRequestStrategy *linkPreviewAssetDownloadRequestStrategy;


@property (nonatomic) NSArray *allChangeTrackers;

@property (nonatomic) NSArray *requestStrategies;

@property (atomic) BOOL tornDown;
@property (nonatomic) BOOL contextMergingDisabled;



@end



@implementation ZMSyncStrategy

ZM_EMPTY_ASSERTING_INIT()


- (instancetype)initWithAuthenticationCenter:(ZMAuthenticationStatus *)authenticationStatus
                     userProfileUpdateStatus:(ZMUserProfileUpdateStatus *)userProfileStatus
                    clientRegistrationStatus:(ZMClientRegistrationStatus *)clientRegistrationStatus
                          clientUpdateStatus:(ClientUpdateStatus *)clientUpdateStatus
                          proxiedRequestStatus:(ProxiedRequestsStatus *)proxiedRequestStatus
                               accountStatus:(ZMAccountStatus *)accountStatus
                backgroundAPNSPingBackStatus:(BackgroundAPNSPingBackStatus *)backgroundAPNSPingBackStatus
                                mediaManager:(id<AVSMediaManager>)mediaManager
                         onDemandFlowManager:(ZMOnDemandFlowManager *)onDemandFlowManager
                                     syncMOC:(NSManagedObjectContext *)syncMOC
                                       uiMOC:(NSManagedObjectContext *)uiMOC
                           syncStateDelegate:(id<ZMSyncStateDelegate>)syncStateDelegate
                       backgroundableSession:(id<ZMBackgroundable>)backgroundableSession
                localNotificationsDispatcher:(ZMLocalNotificationDispatcher *)localNotificationsDispatcher
                    taskCancellationProvider:(id <ZMRequestCancellation>)taskCancellationProvider
                                       badge:(ZMBadge *)badge;

{
    self = [super init];
    if (self) {
        
        self.syncMOC = syncMOC;
        self.uiMOC = uiMOC;
        self.badge = badge;
        
        [self createTranscodersWithClientRegistrationStatus:clientRegistrationStatus
                                    userProfileUpdateStatus:userProfileStatus
                               localNotificationsDispatcher:localNotificationsDispatcher
                                       authenticationStatus:authenticationStatus
                               backgroundAPNSPingBackStatus:backgroundAPNSPingBackStatus
                                              accountStatus:accountStatus
                                               mediaManager:mediaManager
                                        onDemandFlowManager:onDemandFlowManager
                                   taskCancellationProvider:taskCancellationProvider];
        
        self.stateMachine = [[ZMSyncStateMachine alloc] initWithAuthenticationStatus:authenticationStatus
                                                            clientRegistrationStatus:clientRegistrationStatus
                                                             objectStrategyDirectory:self
                                                                   syncStateDelegate:syncStateDelegate
                                                               backgroundableSession:backgroundableSession];
        self.eventsBuffer = [[ZMUpdateEventsBuffer alloc] initWithUpdateEventConsumer:self];
        self.userClientRequestStrategy = [[UserClientRequestStrategy alloc] initWithAuthenticationStatus:authenticationStatus
                                                                                clientRegistrationStatus:clientRegistrationStatus
                                                                                      clientUpdateStatus:clientUpdateStatus
                                                                                                 context:self.syncMOC];
        
        self.requestStrategies = @[self.userClientRequestStrategy,
                                   [[ProxiedRequestStrategy alloc] initWithRequestsStatus:proxiedRequestStatus
                                                                     managedObjectContext:self.syncMOC],
                                   [[DeleteAccountRequestStrategy alloc] initWithAuthStatus:authenticationStatus
                                                                       managedObjectContext:self.syncMOC],
                                   [[AssetDownloadRequestStrategy alloc] initWithAuthStatus:authenticationStatus
                                                                   taskCancellationProvider:taskCancellationProvider
                                                                       managedObjectContext:self.syncMOC],
                                   [[AddressBookUploadRequestStrategy alloc] initWithAuthenticationStatus:authenticationStatus
                                                                                 clientRegistrationStatus:clientRegistrationStatus
                                                                                                      moc:self.syncMOC],
                                   self.pingBackRequestStrategy,
                                   self.pushNoticeFetchStrategy,
                                   self.fileUploadRequestStrategy,
                                   self.linkPreviewAssetDownloadRequestStrategy,
                                   self.linkPreviewAssetUploadRequestStrategy
                                   ];
        
        self.changeTrackerBootStrap = [[ZMChangeTrackerBootstrap alloc] initWithManagedObjectContext:self.syncMOC changeTrackers:self.allChangeTrackers];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(managedObjectContextDidSave:) name:NSManagedObjectContextDidSaveNotification object:self.syncMOC];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(managedObjectContextDidSave:) name:NSManagedObjectContextDidSaveNotification object:uiMOC];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appTerminated:) name:UIApplicationWillTerminateNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
    }
    return self;
}

- (void)createTranscodersWithClientRegistrationStatus:(ZMClientRegistrationStatus *)clientRegistrationStatus
                              userProfileUpdateStatus:(ZMUserProfileUpdateStatus *)userProfileStatus
                         localNotificationsDispatcher:(ZMLocalNotificationDispatcher *)localNotificationsDispatcher
                                 authenticationStatus:(ZMAuthenticationStatus *)authenticationStatus
                         backgroundAPNSPingBackStatus:(BackgroundAPNSPingBackStatus *)backgroundAPNSPingBackStatus
                                        accountStatus:(ZMAccountStatus *)accountStatus
                                         mediaManager:(id<AVSMediaManager>)mediaManager
                                  onDemandFlowManager:(ZMOnDemandFlowManager *)onDemandFlowManager
                             taskCancellationProvider:(id <ZMRequestCancellation>)taskCancellationProvider
{
    NSManagedObjectContext *uiMOC = self.uiMOC;
    NSOperationQueue *imageProcessingQueue = [ZMImagePreprocessor createSuitableImagePreprocessingQueue];
    
    self.connectionTranscoder = [[ZMConnectionTranscoder alloc] initWithManagedObjectContext:self.syncMOC];
    self.userTranscoder = [[ZMUserTranscoder alloc] initWithManagedObjectContext:self.syncMOC];
    self.selfTranscoder = [[ZMSelfTranscoder alloc] initWithClientRegistrationStatus:clientRegistrationStatus managedObjectContext:self.syncMOC];
    self.conversationTranscoder = [[ZMConversationTranscoder alloc] initWithManagedObjectContext:self.syncMOC authenticationStatus:authenticationStatus accountStatus:accountStatus syncStrategy:self];
    self.systemMessageTranscoder = [ZMMessageTranscoder systemMessageTranscoderWithManagedObjectContext:self.syncMOC localNotificationDispatcher:localNotificationsDispatcher];
    self.clientMessageTranscoder = [[ZMClientMessageTranscoder alloc ] initWithManagedObjectContext:self.syncMOC localNotificationDispatcher:localNotificationsDispatcher clientRegistrationStatus:clientRegistrationStatus];
    self.knockTranscoder = [[ZMKnockTranscoder alloc] initWithManagedObjectContext:self.syncMOC];
    self.registrationTranscoder = [[ZMRegistrationTranscoder alloc] initWithManagedObjectContext:self.syncMOC authenticationStatus:authenticationStatus];
    self.missingUpdateEventsTranscoder = [[ZMMissingUpdateEventsTranscoder alloc] initWithSyncStrategy:self];
    self.lastUpdateEventIDTranscoder = [[ZMLastUpdateEventIDTranscoder alloc] initWithManagedObjectContext:self.syncMOC objectDirectory:self];
    self.flowTranscoder = [[ZMFlowSync alloc] initWithMediaManager:mediaManager onDemandFlowManager:onDemandFlowManager syncManagedObjectContext:self.syncMOC uiManagedObjectContext:uiMOC];
    self.pushTokenTranscoder = [[ZMPushTokenTranscoder alloc] initWithManagedObjectContext:self.syncMOC clientRegistrationStatus:clientRegistrationStatus];
    self.callStateTranscoder = [[ZMCallStateTranscoder alloc] initWithSyncManagedObjectContext:self.syncMOC uiManagedObjectContext:uiMOC objectStrategyDirectory:self];
    self.assetTranscoder = [[ZMAssetTranscoder alloc] initWithManagedObjectContext:self.syncMOC];
    self.userImageTranscoder = [[ZMUserImageTranscoder alloc] initWithManagedObjectContext:self.syncMOC imageProcessingQueue:imageProcessingQueue];
    self.loginTranscoder = [[ZMLoginTranscoder alloc] initWithManagedObjectContext:self.syncMOC authenticationStatus:authenticationStatus clientRegistrationStatus:clientRegistrationStatus];
    self.loginCodeRequestTranscoder = [[ZMLoginCodeRequestTranscoder alloc] initWithManagedObjectContext:self.syncMOC authenticationStatus:authenticationStatus];
    self.searchUserImageTranscoder = [[ZMSearchUserImageTranscoder alloc] initWithManagedObjectContext:self.syncMOC uiContext:uiMOC];
    self.typingTranscoder = [[ZMTypingTranscoder alloc] initWithManagedObjectContext:self.syncMOC userInterfaceContext:uiMOC];
    self.removedSuggestedPeopleTranscoder = [[ZMRemovedSuggestedPeopleTranscoder alloc] initWithManagedObjectContext:self.syncMOC];
    self.phoneNumberVerificationTranscoder = [[ZMPhoneNumberVerificationTranscoder alloc] initWithManagedObjectContext:self.syncMOC authenticationStatus:authenticationStatus];
    self.userProfileUpdateTranscoder = [[ZMUserProfileUpdateTranscoder alloc] initWithManagedObjectContext:self.syncMOC userProfileUpdateStatus:userProfileStatus];
    self.conversationStatusSync = [[ConversationStatusStrategy alloc] initWithManagedObjectContext:self.syncMOC];
    self.pingBackRequestStrategy = [[PingBackRequestStrategy alloc] initWithManagedObjectContext:self.syncMOC backgroundAPNSPingBackStatus:backgroundAPNSPingBackStatus authenticationStatus:authenticationStatus];
    self.pushNoticeFetchStrategy = [[PushNoticeRequestStrategy alloc] initWithManagedObjectContext:self.syncMOC backgroundAPNSPingBackStatus:backgroundAPNSPingBackStatus authenticationStatus:authenticationStatus];
    self.fileUploadRequestStrategy = [[FileUploadRequestStrategy alloc] initWithAuthenticationStatus:authenticationStatus clientRegistrationStatus:clientRegistrationStatus managedObjectContext:self.syncMOC taskCancellationProvider:taskCancellationProvider];
    self.linkPreviewAssetDownloadRequestStrategy = [[LinkPreviewAssetDownloadRequestStrategy alloc] initWithAuthStatus:authenticationStatus managedObjectContext:self.syncMOC];
    self.linkPreviewAssetUploadRequestStrategy = [[LinkPreviewAssetUploadRequestStrategy alloc] initWithAuthenticationStatus:authenticationStatus managedObjectContext:self.syncMOC];
}

- (void)appDidEnterBackground:(NSNotification *)note
{
    NOT_USED(note);
    ZMBackgroundActivity *activity = [[BackgroundActivityFactory sharedInstance] backgroundActivityWithName:@"enter background"];
    [self.syncMOC performGroupedBlock:^{
        [self.stateMachine enterBackground];
        [ZMOperationLoop notifyNewRequestsAvailable:self];
        [self updateBadgeCount];
        [activity endActivity];
    }];
}

- (void)appWillEnterForeground:(NSNotification *)note
{
    NOT_USED(note);
    ZMBackgroundActivity *activity = [[BackgroundActivityFactory sharedInstance] backgroundActivityWithName:@"enter foreground"];
    [self.syncMOC performGroupedBlock:^{
        [self.stateMachine enterForeground];
        [ZMOperationLoop notifyNewRequestsAvailable:self];
        [activity endActivity];
    }];
}

- (void)appTerminated:(NSNotification *)note
{
    NOT_USED(note);
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (NSManagedObjectContext *)moc
{
    return self.syncMOC;
}

- (void)didEstablishUpdateEventsStream
{
    [self.stateMachine didEstablishUpdateEventsStream];
}

- (void)didInterruptUpdateEventsStream
{
    [self.stateMachine didInterruptUpdateEventsStream];
}

- (void)tearDown
{
    self.tornDown = YES;
    [self.stateMachine tearDown];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self appTerminated:nil];
    
    for (ZMObjectSyncStrategy *s in [self.allTranscoders arrayByAddingObjectsFromArray:self.requestStrategies]) {
        if ([s respondsToSelector:@selector(tearDown)]) {
            [s tearDown];
        }
    }
    
    [self.conversationStatusSync tearDown];
    [self.pingBackRequestStrategy tearDown];
    [self.pushNoticeFetchStrategy tearDown];
    [self.fileUploadRequestStrategy tearDown];
}

- (void)processAllEventsInBuffer
{
    [self.eventsBuffer processAllEventsInBuffer];
    [self.syncMOC enqueueDelayedSave];
}


#if DEBUG
- (void)dealloc
{
    RequireString(self.tornDown, "Did not tear down %p", (__bridge void *) self);
}
#endif

- (void)startBackgroundFetchWithCompletionHandler:(ZMBackgroundFetchHandler)handler;
{
    [self.stateMachine startBackgroundFetchWithCompletionHandler:handler];
}

- (void)startBackgroundTaskWithCompletionHandler:(ZMBackgroundTaskHandler)handler;
{
    [self.stateMachine startBackgroundTaskWithCompletionHandler:handler];
}


- (void)logDidSaveNotification:(NSNotification *)note;
{
    NSManagedObjectContext * ZM_UNUSED moc = note.object;
    ZMLogWithLevelAndTag(ZMLogLevelDebug, ZMTAG_CORE_DATA, @"<%@: %p> did save. Context type = %@",
               moc.class, moc,
               moc.zm_isUserInterfaceContext ? @"UI" : moc.zm_isSyncContext ? @"Sync" : @"");
    NSSet *inserted = note.userInfo[NSInsertedObjectsKey];
    if (inserted.count > 0) {
        NSString * ZM_UNUSED description = [[inserted.allObjects mapWithBlock:^id(NSManagedObject *mo) {
            return mo.objectID.URIRepresentation;
        }] componentsJoinedByString:@", "];
        ZMLogWithLevelAndTag(ZMLogLevelDebug, ZMTAG_CORE_DATA, @"    Inserted: %@", description);
    }
    NSSet *updated = note.userInfo[NSUpdatedObjectsKey];
    if (updated.count > 0) {
        NSString * ZM_UNUSED description = [[updated.allObjects mapWithBlock:^id(NSManagedObject *mo) {
            return mo.objectID.URIRepresentation;
        }] componentsJoinedByString:@", "];
        ZMLogWithLevelAndTag(ZMLogLevelDebug, ZMTAG_CORE_DATA, @"    Updated: %@", description);
    }
    NSSet *deleted = note.userInfo[NSDeletedObjectsKey];
    if (deleted.count > 0) {
        NSString * ZM_UNUSED description = [[deleted.allObjects mapWithBlock:^id(NSManagedObject *mo) {
            return mo.objectID.URIRepresentation;
        }] componentsJoinedByString:@", "];
        ZMLogWithLevelAndTag(ZMLogLevelDebug, ZMTAG_CORE_DATA, @"    Deleted: %@", description);
    }
}

- (void)managedObjectContextDidSave:(NSNotification *)note;
{
    if(self.tornDown || self.contextMergingDisabled) {
        return;
    }
    
    if (ZMLogLevelIsActive(ZMTAG_CORE_DATA, ZMLogLevelDebug)) {
        [self logDidSaveNotification:note];
    }
    
    NSManagedObjectContext *mocThatSaved = note.object;
    NSManagedObjectContext *strongUiMoc = self.uiMOC;
    ZMCallState *callStateChanges = mocThatSaved.zm_callState.createCopyAndResetHasChanges;
    
    if (mocThatSaved.zm_isUserInterfaceContext && strongUiMoc != nil) {
        if(mocThatSaved != strongUiMoc) {
            RequireString(mocThatSaved == strongUiMoc, "Not the right MOC!");
        }
        
        NSSet *conversationsWithCallChanges = [callStateChanges allContainedConversationsInContext:strongUiMoc];
        if (conversationsWithCallChanges != nil) {
            [strongUiMoc.globalManagedObjectContextObserver notifyUpdatedCallState:conversationsWithCallChanges notifyDirectly:YES];
        }
        
        ZM_WEAK(self);
        [self.syncMOC performGroupedBlock:^{
            ZM_STRONG(self);
            if(self == nil || self.tornDown) {
                return;
            }
            NSSet *changedConversations = [self.syncMOC mergeCallStateChanges:callStateChanges];
            [self.syncMOC mergeChangesFromContextDidSaveNotification:note];
            
            [self processSaveWithInsertedObjects:[NSSet set] updateObjects:changedConversations];
            [self.syncMOC processPendingChanges]; // We need this because merging sometimes leaves the MOC in a 'dirty' state
        }];
    } else if (mocThatSaved.zm_isSyncContext) {
        RequireString(mocThatSaved == self.syncMOC, "Not the right MOC!");
        
        ZM_WEAK(self);
        [strongUiMoc performGroupedBlock:^{
            ZM_STRONG(self);
            if(self == nil || self.tornDown) {
                return;
            }
    
            NSSet *changedConversations = [strongUiMoc mergeCallStateChanges:callStateChanges];
            [strongUiMoc.globalManagedObjectContextObserver notifyUpdatedCallState:changedConversations notifyDirectly:[self shouldForwardCallStateChangeDirectlyForNote:note]];
           
            [strongUiMoc mergeChangesFromContextDidSaveNotification:note];
            [strongUiMoc processPendingChanges]; // We need this because merging sometimes leaves the MOC in a 'dirty' state
        }];
        [self.syncMOC.zm_cryptKeyStore.box saveSessionsRequiringSave];
    }
}

- (BOOL)shouldForwardCallStateChangeDirectlyForNote:(NSNotification *)note
{
    if ([(NSSet *)note.userInfo[NSInsertedObjectsKey] count] == 0 &&
        [(NSSet *)note.userInfo[NSDeletedObjectsKey] count] == 0 &&
        [(NSSet *)note.userInfo[NSUpdatedObjectsKey] count] == 0 &&
        [(NSSet *)note.userInfo[NSRefreshedObjectsKey] count] == 0) {
        return YES;
    }
    return NO;
}

- (NSArray *)allTranscoders;
{
    return @[
             self.connectionTranscoder,
             self.userTranscoder,
             self.selfTranscoder,
             self.conversationTranscoder,
             self.systemMessageTranscoder,
             self.clientMessageTranscoder,
             self.knockTranscoder,
             self.assetTranscoder,
             self.userImageTranscoder,
             self.missingUpdateEventsTranscoder,
             self.lastUpdateEventIDTranscoder,
             self.registrationTranscoder,
             self.flowTranscoder,
             self.callStateTranscoder,
             self.pushTokenTranscoder,
             self.searchUserImageTranscoder,
             self.typingTranscoder,
             self.removedSuggestedPeopleTranscoder,
             self.phoneNumberVerificationTranscoder,
             self.loginCodeRequestTranscoder,
             self.userProfileUpdateTranscoder,
             self.loginTranscoder,
             ];
}

- (NSArray *)allChangeTrackers
{
    if (_allChangeTrackers == nil) {
        _allChangeTrackers = [self.allTranscoders flattenWithBlock:^id(id<ZMObjectStrategy> objectSync) {
            return objectSync.contextChangeTrackers;
        }];
        
        _allChangeTrackers = [_allChangeTrackers arrayByAddingObjectsFromArray:[self.requestStrategies flattenWithBlock:^NSArray *(id <ZMObjectStrategy> objectSync) {
            if ([objectSync conformsToProtocol:@protocol(ZMContextChangeTrackerSource)]) {
                return objectSync.contextChangeTrackers;
            }
            return nil;
        }]];
        _allChangeTrackers = [_allChangeTrackers arrayByAddingObject:self.conversationStatusSync];
    }
    
    return _allChangeTrackers;
}


- (BOOL)processSaveWithInsertedObjects:(NSSet *)insertedObjects updateObjects:(NSSet *)updatedObjects
{
    NSSet *allObjects = [NSSet zmSetByCompiningSets:insertedObjects, updatedObjects, nil];

    for(id<ZMContextChangeTracker> tracker in self.allChangeTrackers)
    {
        [tracker objectsDidChange:allObjects];
    }
    
    return YES;
}

- (ZMTransportRequest *)nextRequest
{
    dispatch_once(&_didFetchObjects, ^{
        [self.changeTrackerBootStrap fetchObjectsForChangeTrackers];
    });
    
    if(self.tornDown) {
        return nil;
    }

    ZMTransportRequest* request = [self.stateMachine nextRequest];
    if(request == nil) {
        request = [self.requestStrategies firstNonNilReturnedFromSelector:@selector(nextRequest)];
    }
    return request;
}

- (void)processUpdateEvents:(NSArray *)events ignoreBuffer:(BOOL)ignoreBuffer;
{
    if(ignoreBuffer) {
        [self consumeUpdateEvents:events];
        [self.syncMOC enqueueDelayedSave]; // make sure we save at least once
        return;
    }
    
    NSArray *flowEvents = [events filterWithBlock:^BOOL(ZMUpdateEvent* event) {
        return event.isFlowEvent;
    }];
    if(flowEvents.count > 0) {
        [self consumeUpdateEvents:flowEvents];
    }
    NSArray *callstateEvents = [events filterWithBlock:^BOOL(ZMUpdateEvent* event) {
        return event.type == ZMUpdateEventCallState;
    }];
    NSArray *notFlowEvents = [events filterWithBlock:^BOOL(ZMUpdateEvent* event) {
        return !event.isFlowEvent;
    }];
    
    switch(self.stateMachine.updateEventsPolicy) {
        case ZMUpdateEventPolicyIgnore: {
            if(callstateEvents.count > 0) {
                [self consumeUpdateEvents:callstateEvents];
            }
            break;
        }
        case ZMUpdateEventPolicyBuffer: {
            for(ZMUpdateEvent *event in notFlowEvents) {
                [self.eventsBuffer addUpdateEvent:event];
            }
            break;
        }
        case ZMUpdateEventPolicyProcess: {
            if(notFlowEvents.count > 0) {
                [self consumeUpdateEvents:notFlowEvents];
            }
            break;
        }
    }
    [self.syncMOC enqueueDelayedSave]; // make sure we save at least once
}

- (ZMFetchRequestBatch *)fetchRequestBatchForEvents:(NSArray<ZMUpdateEvent *> *)events
{
    NSMutableSet <NSUUID *>*nonces = [NSMutableSet set];
    NSMutableSet <NSUUID *>*remoteIdentifiers = [NSMutableSet set];
    
    NSArray *allObjectStrategies = [self.allTranscoders arrayByAddingObjectsFromArray:self.requestStrategies];
    
    for(id<ZMObjectStrategy> obj in allObjectStrategies) {
        @autoreleasepool {
            if ([obj respondsToSelector:@selector(messageNoncesToPrefetchToProcessEvents:)]) {
                [nonces unionSet:[obj messageNoncesToPrefetchToProcessEvents:events]];
            }
            if ([obj respondsToSelector:@selector(conversationRemoteIdentifiersToPrefetchToProcessEvents:)]) {
                [remoteIdentifiers unionSet:[obj conversationRemoteIdentifiersToPrefetchToProcessEvents:events]];
            }
        }
    }
    
    ZMFetchRequestBatch *fetchRequestBatch = [[ZMFetchRequestBatch alloc] init];
    [fetchRequestBatch addNoncesToPrefetchMessages:nonces];
    [fetchRequestBatch addConversationRemoteIdentifiersToPrefetchConversations:remoteIdentifiers];
    
    return fetchRequestBatch;
}


- (NSArray <ZMUpdateEvent *>*)decryptUpdateEvents:(NSArray <ZMUpdateEvent *>*)events
{
    NSArray <ZMUpdateEvent *>*updatedEvents = events;
    NSArray *allObjectStrategies = [self.allTranscoders arrayByAddingObjectsFromArray:self.requestStrategies];
    
    for(id<ZMObjectStrategy> obj in allObjectStrategies) {
        @autoreleasepool {
            if ([obj conformsToProtocol:@protocol(ZMUpdateEventDecryptor)]) {
                id <ZMUpdateEventDecryptor> decryptor = (id <ZMUpdateEventDecryptor>)obj;
                updatedEvents = [decryptor decryptedUpdateEventsFromEvents:updatedEvents] ?: updatedEvents;
            }
        }
    }
    return updatedEvents;
}

- (void)consumeUpdateEvents:(NSArray<ZMUpdateEvent *>*)events
{
    NSArray <ZMUpdateEvent *>*decryptedEvents = [self decryptUpdateEvents:events];
    
    ZMFetchRequestBatch *fetchRequest = [self fetchRequestBatchForEvents:decryptedEvents];
    ZMFetchRequestBatchResult *prefetchResult = [self.moc executeFetchRequestBatchOrAssert:fetchRequest];
    NSArray *allObjectStrategies = [self.allTranscoders arrayByAddingObjectsFromArray:self.requestStrategies];
    
    for(id<ZMObjectStrategy> obj in allObjectStrategies) {
        @autoreleasepool {
            if ([obj conformsToProtocol:@protocol(ZMObjectStrategy)]) {
                [obj processEvents:decryptedEvents liveEvents:YES prefetchResult:prefetchResult];
            }
        }
    }
    
    [self.syncMOC saveIfTooManyChanges];
}

- (void)processDownloadedEvents:(NSArray <ZMUpdateEvent *>*)events;
{
    NSArray <ZMUpdateEvent *>*decryptedEvents = [self decryptUpdateEvents:events];
    
    ZMFetchRequestBatch *fetchRequest = [self fetchRequestBatchForEvents:decryptedEvents];
    ZMFetchRequestBatchResult *prefetchResult = [self.moc executeFetchRequestBatchOrAssert:fetchRequest];
    
    for(id<ZMObjectStrategy> obj in self.allTranscoders) {
        @autoreleasepool {
            ZMSTimePoint *tp = [ZMSTimePoint timePointWithInterval:5 label:[NSString stringWithFormat:@"Processing downloaded events in %@", [obj class]]];
            [obj processEvents:decryptedEvents liveEvents:NO prefetchResult:prefetchResult];
            [tp warnIfLongerThanInterval];
        }
    }
}

- (NSArray *)conversationIdsThatHaveBufferedUpdatesForCallState;
{
    return [[self.eventsBuffer updateEvents] mapWithBlock:^id(ZMUpdateEvent *event) {
        if (event.type == ZMUpdateEventCallState) {
            return event.conversationUUID;
        }
        return nil;
    }];
}

- (void)dataDidChange;
{
    [self.stateMachine dataDidChange];
}

- (void)transportSessionAccessTokenDidSucceedWithToken:(NSString *)token ofType:(NSString *)type;
{
    [self.flowTranscoder accessTokenDidChangeWithToken:token ofType:type];
}

- (void)updateBadgeCount;
{
    [self.badge setBadgeCount:[ZMConversation unreadConversationCountInContext:self.syncMOC]];
}

@end
