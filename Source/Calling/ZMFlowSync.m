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
// along with this program. If not, see <http://www.gnu.org/licenses/>.


@import ZMCSystem;
@import ZMUtilities;

#import "ZMFlowSync.h"
#import <zmessaging/NSManagedObjectContext+zmessaging.h>
#import "ZMUpdateEvent.h"
#import "ZMConversation+Internal.h"
#import "ZMVoiceChannelNotifications+Internal.h"
#import "ZMUser+Internal.h"
#import "ZMTracing.h"
#import "ZMOperationLoop.h"
#import "ZMAVSBridge.h"
#import "ZMApplicationLaunchStatus.h"
#import <zmessaging/zmessaging-Swift.h>
#import "ZMUserSessionAuthenticationNotification.h"
#import "ZMOnDemandFlowManager.h"
#import "ZMVoiceChannel+VideoCalling.h"

static NSString * const DefaultMediaType = @"application/json";
id ZMFlowSyncInternalDeploymentEnvironmentOverride;


@interface ZMFlowSync ()

@property (nonatomic, readonly) NSMutableArray *requestStack; ///< inverted FIFO
@property (nonatomic) ZMOnDemandFlowManager *onDemandFlowManager;
@property (nonatomic, readonly) id mediaManager;
@property (nonatomic) NSNotificationQueue *voiceGainNotificationQueue;
@property (nonatomic, readonly) NSArray *eventTypesToForward;
@property (nonatomic) BOOL pushChannelIsOpen;
@property (nonatomic, readonly) NSManagedObjectContext *uiManagedObjectContext;
@property (nonatomic, readonly, weak) ZMApplicationLaunchStatus * applicationLaunchStatus;
@property (nonatomic) id authenticationObserverToken;
@property (nonatomic, strong) dispatch_queue_t avsLogQueue;
@end



@interface ZMFlowSync (FlowManagerDelegate) <AVSFlowManagerDelegate>
@end



@implementation ZMFlowSync

- (instancetype)initWithMediaManager:(id)mediaManager
                 onDemandFlowManager:(ZMOnDemandFlowManager *)onDemandFlowManager
             applicationLaunchStatus:(ZMApplicationLaunchStatus *)applicationLaunchStatus
            syncManagedObjectContext:(NSManagedObjectContext *)syncManagedObjectContext
              uiManagedObjectContext:(NSManagedObjectContext *)uiManagedObjectContext
{
    self = [super initWithManagedObjectContext:syncManagedObjectContext];
    if(self != nil) {
        _uiManagedObjectContext = uiManagedObjectContext;
        _mediaManager = mediaManager;
        _requestStack = [NSMutableArray array];
        _applicationLaunchStatus = applicationLaunchStatus;
        
        self.voiceGainNotificationQueue = [[NSNotificationQueue alloc] initWithNotificationCenter:[NSNotificationCenter defaultCenter]];

        self.onDemandFlowManager = onDemandFlowManager;
        if (applicationLaunchStatus.currentState == ZMApplicationLaunchStateForeground) {
            [self.onDemandFlowManager initializeFlowManagerWithDelegate:self];
        }
        
        [self createEventTypesToForward];
        [self configureAVSLogging];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pushChannelDidChange:) name:ZMPushChannelStateChangeNotificationName object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
        
        ZM_WEAK(self);
        self.authenticationObserverToken = [ZMUserSessionAuthenticationNotification addObserverWithBlock:^(ZMUserSessionAuthenticationNotification *note){
            ZM_STRONG(self);
            if (note.type == ZMAuthenticationNotificationAuthenticationDidSuceeded) {
                [self registerSelfUser];
            }
        }];
        self.pushChannelIsOpen = NO;
        self.avsLogQueue = dispatch_queue_create("AVSLog", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

- (void)appWillEnterForeground:(NSNotification *)note
{
    NOT_USED(note);
    ZMBackgroundActivity *activity = [ZMBackgroundActivity beginBackgroundActivityWithName:@"enter foreground"];
    [self.managedObjectContext performGroupedBlock:^{
        [self.onDemandFlowManager initializeFlowManagerWithDelegate:self];

        [activity endActivity];
    }];
}

- (void)tearDown;
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [ZMUserSessionAuthenticationNotification removeObserver:self.authenticationObserverToken];
    [super tearDown];
}

- (AVSFlowManager *)flowManager
{
    return self.onDemandFlowManager.flowManager;
}

- (void)configureAVSLogging;
{
    ZMDeploymentEnvironment *env = ZMFlowSyncInternalDeploymentEnvironmentOverride ?: [[ZMDeploymentEnvironment alloc] init];
    ZMDeploymentEnvironmentType type = env.environmentType;
    if (type == ZMDeploymentEnvironmentTypeInternal) {
        if(!zm_isTesting()) {
            ZMLogWarn(@"AVS is configured for environment Internal");
        }
        [self.flowManager setEnableLogging:YES];
        [self.flowManager setEnableMetrics:YES];
    } else {
        if(!zm_isTesting()) {
            ZMLogWarn(@"AVS is configured for environment unknown/public");
        }
        [self.flowManager setEnableLogging:NO];
        [self.flowManager setEnableMetrics:NO];
    }
}

- (void)createEventTypesToForward;
{
    NSMutableArray *types = [NSMutableArray array];
    for (NSString *name in self.flowManager.events) {
        ZMUpdateEventType type = [ZMUpdateEvent updateEventTypeForEventTypeString:name];
        if (type != ZMUpdateEventUnknown) {
            [types addObject:@(type)];
        }
    }
    _eventTypesToForward = [types copy];
}

- (BOOL)isSlowSyncDone
{
    return YES;
}

- (NSArray *)contextChangeTrackers
{
    return @[];
}

- (void)setNeedsSlowSync
{
    // no-op
}

- (NSArray *)requestGenerators;
{
    return @[self];
}

- (ZMTransportRequest *)nextRequest
{
    if (!self.pushChannelIsOpen) {
        return nil;
    }
    if (self.applicationLaunchStatus == ZMApplicationLaunchStateForeground && self.onDemandFlowManager.flowManager == nil) {
        [self.onDemandFlowManager initializeFlowManagerWithDelegate:self]; // this should not happen, but we should recover after all
    }
    id firstRequest = [self.requestStack lastObject];
    [firstRequest setDebugInformationTranscoder:self];
    [self.requestStack removeLastObject];
    return firstRequest;
}

- (void)processEvents:(NSArray<ZMUpdateEvent *> *)events
           liveEvents:(BOOL)liveEvents
       prefetchResult:(__unused ZMFetchRequestBatchResult *)prefetchResult;
{
    if(!liveEvents) {
        return;
    }
    if (self.applicationLaunchStatus.currentState == ZMApplicationLaunchStateForeground) {
        [self.onDemandFlowManager initializeFlowManagerWithDelegate:self];
    }
    for(ZMUpdateEvent *event in events) {
        if (! [self.eventTypesToForward containsObject:@(event.type)]) {
            return;
        }
        NSData *content = [NSJSONSerialization dataWithJSONObject:event.payload options:0 error:nil];
        [self.flowManager processEventWithMediaType:DefaultMediaType content:content];
    }
}

- (void)requestCompletedWithResponse:(ZMTransportResponse *)response forContext:(void const*)context
{
    NSData *contentData;
    if(response.payload != nil) {
        contentData = [NSJSONSerialization dataWithJSONObject:response.payload options:0 error:nil];
    }
    [self.flowManager processResponseWithStatus:(int) response.HTTPStatus reason:[NSString stringWithFormat:@"%ld", (long)response.HTTPStatus] mediaType:DefaultMediaType content:contentData context:context];
}

- (void)acquireFlowsForConversation:(ZMConversation *)conversation;
{
    if (self.applicationLaunchStatus.currentState == ZMApplicationLaunchStateForeground) {
        [self.onDemandFlowManager initializeFlowManagerWithDelegate:self];
    }
    
    NSString *identifier = conversation.remoteIdentifier.transportString;
    if (identifier == nil) {
        ZMLogError(@"Trying to acquire flow for a conversation without a remote ID.");
    } else {
        ZMTraceCallFlowAcquire(identifier);
        [self.flowManager acquireFlows:identifier];
    }
}

- (void)releaseFlowsForConversation:(ZMConversation *)conversation;
{
    NSString *identifier = conversation.remoteIdentifier.transportString;
    if (identifier == nil) {
        ZMLogError(@"Trying to release flow for a conversation without a remote ID.");
    } else {
        ZMTraceCallFlowRelease(identifier);
        [self.flowManager releaseFlows:identifier];
        conversation.isFlowActive = NO;
    }
}

- (void)setSessionIdentifier:(NSString *)sessionID forConversationIdentifier:(NSUUID *)conversationID;
{
    NSString *userID = [ZMUser selfUserInContext:self.managedObjectContext].remoteIdentifier.transportString ?: @"na";
    NSString *randomID = [NSUUID UUID].transportString;
    NSString *combinedID = [NSString stringWithFormat:@"%@_U-%@_D-%@", sessionID, userID, randomID];
    [self.flowManager setSessionId:combinedID forConversation:conversationID.transportString];
}

- (void)appendLogForConversationID:(NSUUID *)conversationID message:(NSString *)message;
{
    AVSFlowManager *flowManager = self.flowManager;
    dispatch_async(self.avsLogQueue, ^{
        [flowManager appendLogForConversation:conversationID.transportString message:message];
    });
}

- (void)pushChannelDidChange:(NSNotification *)note
{
    const BOOL oldValue = self.pushChannelIsOpen;
    BOOL newValue = [note.userInfo[ZMPushChannelIsOpenKey] boolValue];
    self.pushChannelIsOpen = newValue;
    
    if(self.pushChannelIsOpen) {
        [self.flowManager networkChanged];
    }
    
    if (!oldValue && newValue && self.requestStack.count > 0) {
        [ZMOperationLoop notifyNewRequestsAvailable:self];
    }
}

- (void)addJoinedCallParticipant:(ZMUser *)user inConversation:(ZMConversation *)conversation;
{
    [self.flowManager addUser:conversation.remoteIdentifier.transportString userId:user.remoteIdentifier.transportString name:user.name];
}

- (void)registerSelfUser
{
    NSString *selfUserID = [ZMUser selfUserInContext:self.managedObjectContext].remoteIdentifier.transportString;
    if (selfUserID == nil) {
        return;
    }
    [self.flowManager setSelfUser:selfUserID];
}

- (void)accessTokenDidChangeWithToken:(NSString *)token ofType:(NSString *)type;
{
    if (token != nil && type != nil) {
        [self.flowManager refreshAccessToken:token type:type];
    }
}

@end



@implementation ZMFlowSync (FlowManagerDelegate)

- (BOOL)requestWithPath:(NSString *)path
                 method:(NSString *)methodString
              mediaType:(NSString *)mtype
                content:(NSData *)content
                context:(void const *)ctx;
{
    VerifyActionString(path.length > 0,  return NO, "Path for AVSFlowManager request not set");
    VerifyActionString(methodString.length > 0, return NO, "Method for AVSFlowManager request not set");
    
    ZMTransportRequestMethod method = [ZMTransportRequest methodFromString:methodString];
    [self.managedObjectContext performBlock:^{
        ZMTransportRequest *request = [[ZMTransportRequest alloc] initWithPath:path method:method binaryData:content type:mtype contentDisposition:nil shouldCompress:YES];
        ZM_WEAK(self);
        
        [request addCompletionHandler:[ZMCompletionHandler handlerOnGroupQueue:self.managedObjectContext block:^(ZMTransportResponse *response) {
            ZM_STRONG(self);
            [self requestCompletedWithResponse:response forContext:ctx];
        }]];
        
        [self.requestStack insertObject:request atIndex:0];
        if (self.pushChannelIsOpen) {
            [ZMOperationLoop notifyNewRequestsAvailable:self];
        }
    }];
    return YES;
}

- (void)didEstablishMediaInConversation:(NSString *)conversationIdentifier;
{
    ZMTraceFlowManagerCategory(conversationIdentifier, 0);
    
    NSUUID *conversationUUID = conversationIdentifier.UUID;
    ZMConversation *conversation = [ZMConversation conversationWithRemoteID:conversationUUID createIfNeeded:NO inContext:self.managedObjectContext];
    
    BOOL canSendVideo = NO;
    if (conversation.isVideoCall) {
        if ([self.flowManager canSendVideoForConversation:conversationIdentifier]) {
            [self.flowManager setVideoSendState:FLOWMANAGER_VIDEO_SEND forConversation:conversationIdentifier];
            canSendVideo = YES;
        } else {
            // notify UI that a video call can not be established
            [CallingInitialisationNotification notifyCallingFailedWithErrorCode:ZMVoiceChannelErrorCodeVideoCallingNotSupported];
        }
    }
    
    [self.managedObjectContext performGroupedBlock:^{
        ZMTraceFlowManagerCategory(conversationIdentifier, 1);
        if (conversation.isVideoCall) {
            conversation.isSendingVideo = canSendVideo;
            if (canSendVideo) {
                // only sync the updated state when we can send video, otherwise it breaks compatibility with older clients
                [conversation syncLocalModificationsOfIsSendingVideo];
            }
        }
        conversation.isFlowActive = YES;
        [self.managedObjectContext saveOrRollback];
    }];
}

- (void)setFlowManagerActivityState:(AVSFlowActivityState)activityState;
{
    NOT_USED(activityState);
}

- (void)networkQuality:(float)q conversation:(NSString *)convid;
{
    NOT_USED(q);
    NOT_USED(convid);
}

- (void)mediaWarningOnConversation:(NSString *)conversationIdentifier;
{
    ZMTraceFlowManagerCategory(conversationIdentifier, 21);
    [self leaveCallInConversationWithRemoteID:conversationIdentifier reason:@"AVS Media warning"];
}

- (void)errorHandler:(int)err
      conversationId:(NSString *)conversationIdentifier
             context:(void const*)ctx;
{
    NOT_USED(err);
    NOT_USED(ctx);
    ZMTraceFlowManagerCategory(conversationIdentifier, 10);
    [self leaveCallInConversationWithRemoteID:conversationIdentifier reason:[NSString stringWithFormat:@"AVS error handler with error %i", err]];
}

- (void)leaveCallInConversationWithRemoteID:(NSString *)remoteIDString reason:(NSString *)reason
{
    NSUUID *conversationID = [remoteIDString UUID];
    [self.managedObjectContext performGroupedBlock:^{
        ZMConversation *conversation = [ZMConversation conversationWithRemoteID:conversationID createIfNeeded:NO inContext:self.managedObjectContext];
        conversation.isFlowActive = NO;
        
        if (conversation.isVideoCall) {
            [self.flowManager setVideoSendState:FLOWMANAGER_VIDEO_SEND_NONE forConversation:conversation.remoteIdentifier.transportString];
        }
        
        [self.managedObjectContext saveOrRollback];
        
        // We need to leave the voiceChannel on the uiContext, otherwise hasLocalModificationsForCallDeviceIsActive won't be set
        // and we won't sync the leave with the backend
        [self.uiManagedObjectContext performGroupedBlock:^{
            ZMConversation *uiConv = [ZMConversation conversationWithRemoteID:conversationID createIfNeeded:NO inContext:self.uiManagedObjectContext];
            [ZMUserSession appendAVSLogMessageForConversation:uiConv withMessage:[NSString stringWithFormat:@"Self user wants to leave voice channel. Reason: %@", reason]];
            if (uiConv.callDeviceIsActive) {
                [uiConv.voiceChannel leaveOnAVSError];
                [self.uiManagedObjectContext saveOrRollback];
            }
            else {
                [ZMUserSession appendAVSLogMessageForConversation:uiConv withMessage:@"Self user can't leave voice channel (callDeviceIsActive = NO)"];
            }
        }];
    }];
}

- (void)didUpdateVolume:(double)volume conversationId:(NSString *)convid participantId:(NSString *)participantId
{
    [self.managedObjectContext performGroupedBlock:^{
        NSUUID *conversationUUID = convid.UUID;
        ZMConversation *conversation = [ZMConversation conversationWithRemoteID:conversationUUID createIfNeeded:NO inContext:self.managedObjectContext];
        if (conversation == nil) {
            return;
        }
        ZMUser *user;
        if ([participantId isEqualToString:FlowManagerSelfUserParticipantIdentifier]) {
            user = [ZMUser selfUserInContext:self.managedObjectContext];
        }
        else if ([participantId isEqualToString:FlowManagerOtherUserParticipantIdentifier]) {
            user = conversation.connectedUser;
        }
        
        else {
            NSUUID *participantUUID = [participantId UUID];
            user = [ZMUser userWithRemoteID:participantUUID createIfNeeded:NO inContext:self.managedObjectContext];
        }
        if (user == nil) {
            return;
        }
        
        NSManagedObjectID *conversationID = conversation.objectID;
        NSManagedObjectID *userID = user.objectID;
        
        [self.uiManagedObjectContext performGroupedBlock:^{
            NSNotificationQueue *queue = self.voiceGainNotificationQueue;
            
            ZMConversation *uiConversation = (id) [self.uiManagedObjectContext objectWithID:conversationID];
            ZMUser *uiUser = (id) [self.uiManagedObjectContext objectWithID:userID];
            
            ZMTraceCallVoiceGain(uiConversation.remoteIdentifier, uiUser.remoteIdentifier, volume);
            ZMVoiceChannelParticipantVoiceGainChangedNotification *note = [ZMVoiceChannelParticipantVoiceGainChangedNotification notificationWithConversation:uiConversation participant:uiUser voiceGain:volume];
            
            [queue enqueueNotification:note postingStyle:NSPostWhenIdle coalesceMask:NSNotificationCoalescingOnSender | NSNotificationCoalescingOnName forModes:nil];
        }];
    }];
}

- (void)conferenceParticipantsDidChange:(NSArray *)participantIDStrings
                         inConversation:(NSString *)convId;
{
    [self.managedObjectContext performGroupedBlock:^{
        NSUUID *conversationUUID = convId.UUID;
        ZMConversation *conversation = [ZMConversation conversationWithRemoteID:conversationUUID createIfNeeded:NO inContext:self.managedObjectContext];
        NSArray *participants = [participantIDStrings mapWithBlock:^id(NSString *userID) {
            return  [ZMUser userWithRemoteID:userID.UUID createIfNeeded:NO inContext:self.managedObjectContext];
        }];

        [conversation.voiceChannel updateActiveFlowParticipants:participants];
        [self.managedObjectContext enqueueDelayedSave];
    }];
}


- (void)vmStatushandler:(BOOL)is_playing current_time:(int)cur_time_ms length:(int)file_length_ms;
{
    NOT_USED(is_playing);
    NOT_USED(cur_time_ms);
    NOT_USED(file_length_ms);
}

@end


