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
@import WireTransport;
@import WireRequestStrategy;

#import "ZMMissingUpdateEventsTranscoder+Internal.h"
#import <WireSyncEngine/WireSyncEngine-Swift.h>
#import "WireSyncEngineLogs.h"


static NSString * const LastUpdateEventIDStoreKey = @"LastUpdateEventID";
static NSString * const NotificationsKey = @"notifications";
static NSString * const NotificationsPath = @"/notifications";
static NSString * const StartKey = @"since";

NSUInteger const ZMMissingUpdateEventsTranscoderListPageSize = 500;

@interface ZMMissingUpdateEventsTranscoder ()

@property (nonatomic, weak) id<UpdateEventProcessor> eventProcessor;
@property (nonatomic, weak) id<PreviouslyReceivedEventIDsCollection> previouslyReceivedEventIDsCollection;
@property (nonatomic) PushNotificationStatus *pushNotificationStatus;
@property (nonatomic, weak) SyncStatus* syncStatus;
@property (nonatomic, weak) OperationStatus* operationStatus;
@property (nonatomic, weak) id<ClientRegistrationDelegate> clientRegistrationDelegate;
@property (nonatomic) NotificationsTracker *notificationsTracker;
@property (nonatomic) BOOL useLegacyPushNotifications;


- (void)appendPotentialGapSystemMessageIfNeededWithResponse:(ZMTransportResponse *)response;

@end


@interface ZMMissingUpdateEventsTranscoder (Pagination) <ZMSimpleListRequestPaginatorSync>
@end


@implementation ZMMissingUpdateEventsTranscoder

- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
                        notificationsTracker:(NotificationsTracker *)notificationsTracker
                              eventProcessor:(id<UpdateEventProcessor>)eventProcessor
        previouslyReceivedEventIDsCollection:(id<PreviouslyReceivedEventIDsCollection>)eventIDsCollection
                           applicationStatus:(id<ZMApplicationStatus>)applicationStatus
                      pushNotificationStatus:(PushNotificationStatus *)pushNotificationStatus
                                  syncStatus:(SyncStatus *)syncStatus
                             operationStatus:(OperationStatus *)operationStatus
                  useLegacyPushNotifications:(BOOL)useLegacyPushNotifications

{
    self = [super initWithManagedObjectContext:managedObjectContext applicationStatus:applicationStatus];
    if(self) {
        self.eventProcessor = eventProcessor;
        self.notificationsTracker = notificationsTracker;
        self.previouslyReceivedEventIDsCollection = eventIDsCollection;
        self.pushNotificationStatus = pushNotificationStatus;
        self.syncStatus = syncStatus;
        self.operationStatus = operationStatus;
        self.useLegacyPushNotifications = useLegacyPushNotifications;
        self.listPaginator = [[ZMSimpleListRequestPaginator alloc] initWithBasePath:NotificationsPath
                                                                           startKey:StartKey
                                                                           pageSize:ZMMissingUpdateEventsTranscoderListPageSize
                                                                managedObjectContext:self.managedObjectContext
                                                                    includeClientID:YES
                                                                         transcoder:self];
    }
    return self;
}

- (ZMStrategyConfigurationOption)configuration
{
    return ZMStrategyConfigurationOptionAllowsRequestsDuringQuickSync
         | ZMStrategyConfigurationOptionAllowsRequestsWhileInBackground
         | ZMStrategyConfigurationOptionAllowsRequestsWhileOnline
         | ZMStrategyConfigurationOptionAllowsRequestsWhileWaitingForWebsocket;
}

- (BOOL)isDownloadingMissingNotifications
{
    return self.listPaginator.hasMoreToFetch;
}

- (BOOL)isFetchingStreamForAPNS
{
    return self.pushNotificationStatus.hasEventsToFetch;
}

- (BOOL)isFetchingStreamInBackground
{
    return self.operationStatus.operationState == SyncEngineOperationStateBackgroundFetch;
}

- (NSUUID *)lastUpdateEventID
{
    return self.managedObjectContext.zm_lastNotificationID;
}

- (void)setLastUpdateEventID:(NSUUID *)lastUpdateEventID
{
    self.managedObjectContext.zm_lastNotificationID = lastUpdateEventID;
}

- (void)appendPotentialGapSystemMessageIfNeededWithResponse:(ZMTransportResponse *)response
{
    // A 404 by the BE means we can't get all notifications as they are not stored anymore
    // and we want to issue a system message. We still might have a payload with notifications that are newer
    // than the commissioning time, the system message should be inserted between the old messages and the potentional
    // newly received ones in the payload.
    if (response.HTTPStatus == 404) {
        NSDate *timestamp = nil;
        const NSTimeInterval offset = 0.1f;
        
        NSArray *eventsDictionaries = [ZMMissingUpdateEventsTranscoder eventDictionariesFromPayload:response.payload];
        if (nil != eventsDictionaries && nil != eventsDictionaries.firstObject) {
            ZMUpdateEvent *event = [ZMUpdateEvent eventsArrayFromPushChannelData:eventsDictionaries.firstObject].firstObject;
            // In case we receive a payload together with the 404 we set the timestamp of the system message
            // to be 1/10th of a second older than the oldest received notification for it to appear above it.
            timestamp = [event.timestamp dateByAddingTimeInterval:-offset];
        }
        
        NSArray <ZMConversation *> *conversations = [self.managedObjectContext executeFetchRequestOrAssert:[ZMConversation sortedFetchRequest]];
        for (ZMConversation *conversation in conversations) {
            if (nil == timestamp) {
                // In case we did not receive a payload we will add 1/10th to the last modified date of
                // the conversation to make sure it appears below the last message
                timestamp = [conversation.lastModifiedDate dateByAddingTimeInterval:offset] ?: [NSDate date];
            }
            [conversation appendNewPotentialGapSystemMessageWithUsers:conversation.localParticipants
                                                            timestamp:timestamp];
        }
    }
}

- (void)updateServerTimeDeltaWithTimestamp:(NSString *)timestamp {
    NSDate *serverTime = [NSDate dateWithTransportString:timestamp];
    NSTimeInterval serverTimeDelta = [serverTime timeIntervalSinceNow];
    self.managedObjectContext.serverTimeDelta = serverTimeDelta;
}

+ (NSArray<NSDictionary *> *)eventDictionariesFromPayload:(id<ZMTransportData>)payload
{
    return [payload.asDictionary optionalArrayForKey:@"notifications"].asDictionaries;
}

- (NSUUID *)processUpdateEventsAndReturnLastNotificationIDFromPayload:(id<ZMTransportData>)payload
{
    ZMSTimePoint *tp = [ZMSTimePoint timePointWithInterval:10 label:NSStringFromClass(self.class)];
    NSArray *eventsDictionaries = [self.class eventDictionariesFromPayload:payload];
    
    NSMutableArray<ZMUpdateEvent *> *parsedEvents = [NSMutableArray array];
    NSMutableArray<NSUUID *> *eventIds = [NSMutableArray array];
    NSUUID *latestEventId = nil;
    ZMUpdateEventSource source = self.isFetchingStreamForAPNS || self.isFetchingStreamInBackground ? ZMUpdateEventSourcePushNotification : ZMUpdateEventSourceDownload;
    for (NSDictionary *eventDictionary in eventsDictionaries) {
        NSArray *events = [ZMUpdateEvent eventsArrayFromTransportData:eventDictionary source:source];
        
        for (ZMUpdateEvent *event in events) {
            [event appendDebugInformation:@"From missing update events transcoder, processUpdateEventsAndReturnLastNotificationIDFromPayload"];
            [parsedEvents addObject:event];
            [eventIds addObject:event.uuid];
            
            if (!event.isTransient) {
                latestEventId = event.uuid;
            }
        }
    }
    
    ZMLogWithLevelAndTag(ZMLogLevelInfo, ZMTAG_EVENT_PROCESSING, @"Downloaded %lu event(s)", (unsigned long)parsedEvents.count);
    
    [self.eventProcessor storeUpdateEvents:parsedEvents ignoreBuffer:YES];
    [self.pushNotificationStatus didFetchEventIds:eventIds lastEventId:latestEventId finished:!self.listPaginator.hasMoreToFetch];
    
    [tp warnIfLongerThanInterval];
    return latestEventId;
}

- (void)updateBackgroundFetchResultWithResponse:(ZMTransportResponse *)response {
    UIBackgroundFetchResult result;
    if (response.result == ZMTransportResponseStatusSuccess) {
        if ([self.class eventDictionariesFromPayload:response.payload].count > 0) {
            result = UIBackgroundFetchResultNewData;
        } else {
            result = UIBackgroundFetchResultNoData;
        }
    } else {
        result = UIBackgroundFetchResultFailed;
    }
    
    [self.operationStatus finishBackgroundFetchWithFetchResult:result];
}

- (BOOL)hasLastUpdateEventID
{
    return self.lastUpdateEventID != nil;
}

- (void)startDownloadingMissingNotifications
{
    [self.listPaginator resetFetching];
}

- (NSArray *)contextChangeTrackers
{
    return @[];
}

- (NSArray *)requestGenerators;
{
    return @[self.listPaginator];
}

- (void)processEvents:(NSArray<ZMUpdateEvent *> *)events
           liveEvents:(BOOL)liveEvents
       prefetchResult:(__unused ZMFetchRequestBatchResult *)prefetchResult;
{
    
    if (!liveEvents) {
        return;
    }
    
    for (ZMUpdateEvent *event in events) {
        if (event.uuid != nil && ! event.isTransient && event.source != ZMUpdateEventSourcePushNotification) {
            self.lastUpdateEventID = event.uuid;
        }
    }
}

- (ZMTransportRequest *)nextRequestIfAllowedForAPIVersion:(APIVersion)apiVersion
{
    /// There are multiple scenarios in which this class will create a new request:
    ///
    /// 1.) We received a push notification and want to fetch the notification stream (if we use the old implementation without the Notification service extension).
    /// 2.) The OS awoke the application to perform a background fetch (the operation state will indicate this).
    /// 3.) The application came to the foreground and is performing a quick-sync (c.f. `isSyncing`).

    // We want to create a new request if we are either currently fetching the paginated stream
    // or if we have a new notification ID that requires a pingback.
    if ((self.isFetchingStreamForAPNS && self.useLegacyPushNotifications) || self.isFetchingStreamInBackground || self.isSyncing) {
        
        // We only reset the paginator if it is neither in progress nor has more pages to fetch.
        if (self.listPaginator.status != ZMSingleRequestInProgress && !self.listPaginator.hasMoreToFetch) {
            [self.listPaginator resetFetching];
        }

        ZMTransportRequest *request = [self.listPaginator nextRequestForAPIVersion:apiVersion];

        if (self.isFetchingStreamForAPNS && nil != request) {
            [request forceToVoipSession];
            [self.notificationsTracker registerStartStreamFetching];
            [request addCompletionHandler:[ZMCompletionHandler handlerOnGroupQueue:self.managedObjectContext block:^(__unused ZMTransportResponse * _Nonnull response) {
                [self.notificationsTracker registerFinishStreamFetching];
            }]];
        }

        return request;
    } else {
        return nil;
    }
}

- (SyncPhase)expectedSyncPhase
{
    return SyncPhaseFetchingMissedEvents;
}

- (BOOL)isSyncing
{
    return self.syncStatus.currentSyncPhase == self.expectedSyncPhase;
}

@end


@implementation ZMMissingUpdateEventsTranscoder (Pagination)

- (NSUUID *)nextUUIDFromResponse:(ZMTransportResponse *)response forListPaginator:(ZMSimpleListRequestPaginator *)paginator
{

    NOT_USED(paginator);
    SyncStatus *syncStatus = self.syncStatus;
    OperationStatus *operationStatus = self.operationStatus;
    
    NSString *timestamp = ((NSString *) response.payload.asDictionary[@"time"]);
    if (timestamp) {
        [self updateServerTimeDeltaWithTimestamp:timestamp];
    }

    NSUUID *latestEventId = [self processUpdateEventsAndReturnLastNotificationIDFromPayload:response.payload];

    if (operationStatus.operationState == SyncEngineOperationStateBackgroundFetch) {
        // This call affects the `isFetchingStreamInBackground` property and should never preceed
        // the call to `processUpdateEventsAndReturnLastNotificationIDFromPayload:syncStrategy`.
        [self updateBackgroundFetchResultWithResponse:response];
    }
    
    if (latestEventId != nil) {
        if (response.HTTPStatus == 404 && self.isSyncing) {
            // If we fail during quick sync we need to re-enter slow sync and should not store the lastUpdateEventID until after the slowSync has been completed
            // Otherwise, if the device crashes or is restarted during slow sync, we lose the information that we need to perform a slow sync
            [syncStatus updateLastUpdateEventIDWithEventID:latestEventId];
            // TODO Sabine: What happens when we receive a 404 when we are fetching the notification for a push notification? In theory we would have to enter slow sync as well or at least not store the lastUpdateEventID until the next proper sync in the foreground
        }
        else {
            self.lastUpdateEventID = latestEventId;
        }
    }
    
    if (!self.listPaginator.hasMoreToFetch) {
        [self.previouslyReceivedEventIDsCollection discardListOfAlreadyReceivedPushEventIDs];
    }
    
    [self appendPotentialGapSystemMessageIfNeededWithResponse:response];
    
    if (response.result == ZMTransportResponseStatusPermanentError) {
        [syncStatus failedFetchingNotificationStream];
    } else if (!self.listPaginator.hasMoreToFetch) {
        [syncStatus completedFetchingNotificationStreamFetchBeganAt:self.listPaginator.lastResetFetchDate];
    }
    
    return self.lastUpdateEventID;
}

- (NSUUID *)startUUID
{
    return self.lastUpdateEventID;
}

- (BOOL)shouldParseErrorForResponse:(ZMTransportResponse *)response
{
    [self.pushNotificationStatus didFailToFetchEvents];
    
    if (response.HTTPStatus == 404) {
        return YES;
    }
    
    return NO;
}

@end
