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
@import WireRequestStrategy;

#import <Foundation/Foundation.h>

#import "MessagingTest.h"
#import "ZMMissingUpdateEventsTranscoder+Internal.h"
#import <WireSyncEngine/WireSyncEngine-Swift.h>
#import "Tests-Swift.h"


static NSString * const LastUpdateEventIDStoreKey = @"LastUpdateEventID";

@interface ZMMissingUpdateEventsTranscoderTests : MessagingTest

@property (nonatomic, readonly) ZMMissingUpdateEventsTranscoder *sut;
@property (nonatomic, readonly) id<PreviouslyReceivedEventIDsCollection> mockEventIDsCollection;
@property (nonatomic) id mockPushNotificationStatus;
@property (nonatomic) id requestSync;
@property (nonatomic) BOOL mockHasPushNotificationEventsToFetch;
@property (nonatomic) MockSyncStatus *mockSyncStatus;
@property (nonatomic) OperationStatus *mockOperationStatus;
@property (nonatomic) MockUpdateEventProcessor *mockUpdateEventProcessor;
@property (nonatomic) id syncStateDelegate;
@property (nonatomic) id mockApplicationDirectory;

@end

@implementation ZMMissingUpdateEventsTranscoderTests

- (void)setUp {
    [super setUp];
    
    self.requestSync = [OCMockObject mockForClass:ZMSingleRequestSync.class];
    self.syncStateDelegate = [OCMockObject niceMockForProtocol:@protocol(ZMSyncStateDelegate)];
    self.mockSyncStatus = [[MockSyncStatus alloc] initWithManagedObjectContext:self.syncMOC syncStateDelegate:self.syncStateDelegate];
    self.mockSyncStatus.mockPhase = SyncPhaseDone;
    self.mockOperationStatus = [[OperationStatus alloc] init];
    self.mockOperationStatus.isInBackground = NO;
    self.mockPushNotificationStatus = [OCMockObject niceMockForClass:PushNotificationStatus.class];
    self.mockUpdateEventProcessor = [[MockUpdateEventProcessor alloc] init];
    
    self.mockApplicationDirectory = [OCMockObject niceMockForClass:ApplicationStatusDirectory.class];
    [[[self.mockApplicationDirectory stub] andReturnValue:@(ZMSynchronizationStateQuickSyncing)] synchronizationState];
    [[[self.mockApplicationDirectory stub] andReturn:self.mockOperationStatus] operationStatus];
    [[[self.mockApplicationDirectory stub] andReturn:self.mockSyncStatus] syncStatus];
    [[[self.mockApplicationDirectory stub] andReturn:self.mockPushNotificationStatus] pushNotificationStatus];
    [[[self.mockPushNotificationStatus stub] andDo:^(NSInvocation *invocation) {
        BOOL value = self.mockHasPushNotificationEventsToFetch;
        [invocation setReturnValue:&value];
    }] hasEventsToFetch];
    
    _mockEventIDsCollection = OCMProtocolMock(@protocol(PreviouslyReceivedEventIDsCollection));

    [self verifyMockLater:self.mockPushNotificationStatus];
    
    _sut = [[ZMMissingUpdateEventsTranscoder alloc] initWithManagedObjectContext:self.uiMOC
                                                            notificationsTracker:nil
                                                                  eventProcessor:self.mockUpdateEventProcessor
                                            previouslyReceivedEventIDsCollection:(id)self.mockEventIDsCollection
                                                               applicationStatus:self.mockApplicationDirectory
                                                          pushNotificationStatus:self.mockPushNotificationStatus
                                                                      syncStatus:self.mockSyncStatus
                                                                 operationStatus:self.mockOperationStatus
                                                      useLegacyPushNotifications:NO];
}

- (void)tearDown {
    _mockEventIDsCollection = nil;
    
    self.mockUpdateEventProcessor = nil;
    
    [self.mockPushNotificationStatus stopMocking];
    _mockPushNotificationStatus = nil;

    _requestSync = nil;
    _mockSyncStatus = nil;
    _mockOperationStatus = nil;
    
    [_syncStateDelegate stopMocking];
    _syncStateDelegate = nil;
    
    [_mockApplicationDirectory stopMocking];
    _mockApplicationDirectory = nil;
    
    _sut = nil;
    
    [super tearDown];
}

@end


@implementation ZMMissingUpdateEventsTranscoderTests (MissingNotifications)

- (NSUUID *)olderNotificationID {
    return [NSUUID uuidWithTransportString:@"a6526b00-000a-11e5-a837-0800200c9a66"];
}

- (NSUUID *)newNotificationID {
    return [NSUUID uuidWithTransportString:@"54ad4672-be09-11e5-9912-ba0be0483c18"];
}

- (void)testThatItGenerateARequestToFetchNotificationStreamWhenSyncing
{
    // given
    self.mockSyncStatus.mockPhase = SyncPhaseFetchingMissedEvents;
    
    // when
    ZMTransportRequest *request = [self.sut nextRequestForAPIVersion:APIVersionV0];
    
    // then
    XCTAssertEqualObjects(request.path, @"/notifications?size=500");
}

- (void)testThatItFinishCurrentSyncPhaseIfThereIsNoMoreNotificationsToFetch
{
    // given
    self.mockSyncStatus.mockPhase = SyncPhaseFetchingMissedEvents;
    
    // when
    ZMTransportRequest *request = [self.sut nextRequestForAPIVersion:APIVersionV0];
    [request completeWithResponse:[self responseForSettingLastUpdateEventID:[NSUUID createUUID] hasMore:NO]];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    XCTAssertTrue(self.mockSyncStatus.didCallFinishCurrentSyncPhase);
}

- (void)testThatItforwardsToDownstreamSyncOnStartDownloadingMissingNotifications
{
    // expect
    id missingUpdateEventsTranscoder = [OCMockObject partialMockForObject:self.sut.listPaginator];
    [[missingUpdateEventsTranscoder expect] resetFetching];
    
    // when
    [self.sut startDownloadingMissingNotifications];
    [missingUpdateEventsTranscoder verify];
}

- (void)testThatItGetsRequestFromDownstreamSync
{
    // given
    self.mockHasPushNotificationEventsToFetch = YES;
    [self.application setBackground];
    
    id missingUpdateEventsTranscoder = [OCMockObject partialMockForObject:self.sut.listPaginator];
    ZMTransportRequest *expectedRequest = [ZMTransportRequest requestGetFromPath:@"555555" apiVersion:0];
    
    // expect
    [[[missingUpdateEventsTranscoder expect] andReturn:expectedRequest] nextRequestForAPIVersion:APIVersionV0];
    
    // when
    ZMTransportRequest *request = [self.sut nextRequestForAPIVersion:APIVersionV0];
    
    // then
    XCTAssertEqual(request, expectedRequest);
    [missingUpdateEventsTranscoder verify];
}

- (void)testThatIsDownloadingWhenTheDownstreamSyncIsInProgress
{
    // given
    id missingUpdateEventsTranscoder = [OCMockObject partialMockForObject:self.sut.listPaginator];
    (void)[ (ZMSimpleListRequestPaginator *) [[missingUpdateEventsTranscoder stub] andReturnValue:OCMOCK_VALUE(YES)] hasMoreToFetch];
    
    // when
    XCTAssertTrue(self.sut.isDownloadingMissingNotifications);
}

- (void)testThatIsNotDownloadingWhenTheDownstreamSyncIsIdle
{
    // given
    id missingUpdateEventsTranscoder = [OCMockObject partialMockForObject:self.sut.listPaginator];
    (void)[ (ZMSimpleListRequestPaginator *) [[missingUpdateEventsTranscoder stub] andReturnValue:OCMOCK_VALUE(NO)] hasMoreToFetch];
    
    // when
    XCTAssertFalse(self.sut.isDownloadingMissingNotifications);
}

- (void)testThatItReturnANotificationRequestWhenAskedToStartDownload
{
    // when
    [self.sut startDownloadingMissingNotifications];
    ZMTransportRequest *request = [self.sut.listPaginator nextRequestForAPIVersion:APIVersionV0];
    
    // then
    XCTAssertNotNil(request);
    XCTAssertEqualObjects([NSURLComponents componentsWithString:request.path].path, @"/notifications");
    XCTAssertEqual(request.method, ZMMethodGET);
}

- (void)testThatItPassesTheDownloadedEventsToEventProcessorOnSuccess
{
    // when
    NSDictionary *payload1 = @{
                               @"id" : [NSUUID createUUID].transportString,
                               @"payload" : @[
                                       @{
                                           @"type" : @"conversation.message-add",
                                           },
                                       ]
                              };
    NSDictionary *payload2 = @{
                               @"id" : [NSUUID createUUID].transportString,
                               @"payload" : @[
                                       @{
                                           @"type" : @"conversation.message-add",
                                           },
                                       ]
                               };
    
    NSDictionary *payload = @{@"notifications" : @[payload1, payload2]};
    
    NSMutableArray *expectedEvents = [NSMutableArray array];
    [expectedEvents addObjectsFromArray:[ZMUpdateEvent eventsArrayFromPushChannelData:payload1]];
    [expectedEvents addObjectsFromArray:[ZMUpdateEvent eventsArrayFromPushChannelData:payload2]];
    
    // when
    [(id)self.sut.listPaginator didReceiveResponse:[ZMTransportResponse responseWithPayload:payload HTTPStatus:200 transportSessionError:nil apiVersion:0] forSingleRequest:self.requestSync];
    
    // then
    XCTAssertEqualObjects(self.mockUpdateEventProcessor.storedEvents, expectedEvents);
    
}

- (void)testThatItPassesTheDownloadedEventsToTheEventProcessorOn404
{
    // when
    NSDictionary *payload1 = @{
                               @"id" : [NSUUID createUUID].transportString,
                               @"payload" : @[
                                       @{
                                           @"type" : @"conversation.message-add",
                                           @"time" : [NSDate date].transportString
                                           },
                                       ]
                               };
    NSDictionary *payload2 = @{
                               @"id" : [NSUUID createUUID].transportString,
                               @"payload" : @[
                                       @{
                                           @"type" : @"conversation.message-add",
                                           @"time" : [NSDate date].transportString
                                           },
                                       ]
                               };
    
    NSDictionary *payload = @{@"notifications" : @[payload1, payload2]};
    
    NSMutableArray *expectedEvents = [NSMutableArray array];
    [expectedEvents addObjectsFromArray:[ZMUpdateEvent eventsArrayFromPushChannelData:payload1]];
    [expectedEvents addObjectsFromArray:[ZMUpdateEvent eventsArrayFromPushChannelData:payload2]];
    
    // when
    [(id)self.sut.listPaginator didReceiveResponse:[ZMTransportResponse responseWithPayload:payload HTTPStatus:404 transportSessionError:nil apiVersion:0] forSingleRequest:self.requestSync];
    
    // then
    XCTAssertEqualObjects(self.mockUpdateEventProcessor.storedEvents, expectedEvents);
    
}

- (void)testThatHasNoLastUpdateEventIDOnStartup
{
    XCTAssertFalse(self.sut.hasLastUpdateEventID);
}

- (void)setLastUpdateEventID:(NSUUID *)uuid hasMore:(BOOL)hasMore
{
    // given
    ZMTransportResponse *response = [self responseForSettingLastUpdateEventID:uuid hasMore:hasMore];
    
    // when
    [(id)self.sut.listPaginator didReceiveResponse:response forSingleRequest:self.requestSync];
}


- (ZMTransportResponse *)responseForSettingLastUpdateEventID:(NSUUID *)uuid hasMore:(BOOL)hasMore
{
    // given
    NSDictionary *innerPayload = @{
                                   @"id" : uuid.transportString,
                                   @"payload" : @[
                                           @{
                                               @"type" : @"conversation.message-add",
                                               },
                                           ]
                                   };
    
    
    NSDictionary *payload = @{@"notifications" : @[innerPayload],
                              @"has_more" : @(hasMore)
                              };
    
    return [ZMTransportResponse responseWithPayload:payload HTTPStatus:200 transportSessionError:nil apiVersion:0];
}

- (void)testThatItHasALastUpdateEventIDAfterFetchingNotifications
{
    
    // given
    [self setLastUpdateEventID:[NSUUID createUUID] hasMore:NO];
    
    // then
    XCTAssertTrue(self.sut.hasLastUpdateEventID);
}


- (void)testThatItDoesNotHaveALastUpdateEventIDAfterFailingToFetchNotifications
{
    // given
    NSDictionary *innerPayload = @{
                                   @"id" : [NSUUID createUUID].transportString,
                                   @"payload" : @[
                                           @{
                                               @"type" : @"conversation.message-add",
                                               },
                                           ]
                                   };
    
    
    NSDictionary *payload = @{@"notifications" : @[innerPayload]};
    
    NSMutableArray *expectedEvents = [NSMutableArray array];
    [expectedEvents addObjectsFromArray:[ZMUpdateEvent eventsArrayFromPushChannelData:innerPayload]];
    
    // when
    [(id)self.sut.listPaginator didReceiveResponse:[ZMTransportResponse responseWithPayload:payload HTTPStatus:400 transportSessionError:nil apiVersion:0] forSingleRequest:self.requestSync];

    
    // then
    XCTAssertFalse(self.sut.hasLastUpdateEventID);
}


- (void)testThatItPaginatesTheRequests
{
    // given
    NSUUID *lastUpdateEventID = [NSUUID createUUID];
    NSNumber *pageSize = @(ZMMissingUpdateEventsTranscoderListPageSize);
    
    // when
    // the lastUpdateEventTranscoder might persist the lastUpdateEventID
    [self setLastUpdateEventID:lastUpdateEventID hasMore:NO];
    [self.sut startDownloadingMissingNotifications];
    
    WaitForAllGroupsToBeEmpty(0.5);
    
    ZMTransportRequest *request = [self.sut.listPaginator nextRequestForAPIVersion:APIVersionV0];
    
    // then
    NSURLComponents *components = [NSURLComponents componentsWithString:request.path];
    XCTAssertTrue([components.queryItems containsObject:[NSURLQueryItem queryItemWithName:@"size" value:[pageSize stringValue]]], @"missing valid since parameter");
}

- (void)testThatWhenItHasALastUpdateEventIDItUsesItInTheRequest
{
    // given
    NSUUID *lastUpdateEventID = [NSUUID createUUID];
    
    // when
    // the lastUpdateEventTranscoder might persist the lastUpdateEventID
    [self setLastUpdateEventID:lastUpdateEventID hasMore:NO];
    [self.sut startDownloadingMissingNotifications];

    WaitForAllGroupsToBeEmpty(0.5);
    
    ZMTransportRequest *request = [self.sut.listPaginator nextRequestForAPIVersion:APIVersionV0];
    
    // then
    NSURLComponents *components = [NSURLComponents componentsWithString:request.path];
    XCTAssertTrue([components.queryItems containsObject:[NSURLQueryItem queryItemWithName:@"since" value:lastUpdateEventID.transportString]], @"missing valid since parameter");
}

- (void)testThatTheLastUpdateEventIDIsReadFromTheManagedObjectContext
{
    // given
    NSUUID *lastUpdateEventID = [NSUUID createUUID];

    [self.syncMOC setPersistentStoreMetadata:lastUpdateEventID.UUIDString forKey:LastUpdateEventIDStoreKey];
    [self.syncMOC saveOrRollback];
    WaitForAllGroupsToBeEmpty(0.5);

    // when
    ZMMissingUpdateEventsTranscoder *sut = [[ZMMissingUpdateEventsTranscoder alloc] initWithManagedObjectContext:self.syncMOC
                                                                                            notificationsTracker:nil
                                                                                                  eventProcessor:self.mockUpdateEventProcessor
                                                                            previouslyReceivedEventIDsCollection:(id)self.mockEventIDsCollection
                                                                                               applicationStatus:self.mockApplicationDirectory
                                                                                          pushNotificationStatus:self.mockPushNotificationStatus
                                                                                                      syncStatus:self.mockSyncStatus
                                                                                                 operationStatus:self.mockOperationStatus
                                                                                      useLegacyPushNotifications:NO];
    
    WaitForAllGroupsToBeEmpty(0.5);
    [sut.listPaginator resetFetching];
    ZMTransportRequest *request = [sut.listPaginator nextRequestForAPIVersion:APIVersionV0];
    
    // then
    NSURLComponents *components = [NSURLComponents componentsWithString:request.path];
    XCTAssertTrue([components.queryItems containsObject:[NSURLQueryItem queryItemWithName:@"since" value:lastUpdateEventID.transportString]], @"missing valid since parameter");
}

- (void)testThatTheClientIDFromTheUserClientIsIncludedInRequest
{
    // Given
    UserClient *userClient = [self setupSelfClientInMoc:self.uiMOC];
    [self.sut startDownloadingMissingNotifications];
    
    // when
    ZMTransportRequest *request = [self.sut.listPaginator nextRequestForAPIVersion:APIVersionV0];
    
    // then
    NSURLComponents *components = [NSURLComponents componentsWithString:request.path];
    XCTAssertTrue([components.queryItems containsObject:[NSURLQueryItem queryItemWithName:@"client" value:userClient.remoteIdentifier]], @"missing client parameter");
}


- (void)testThatItStoresTheLastUpdateEventIDWhenDownloadingNotifications
{
    // when
    NSUUID *expectedLastUpdateEventID = [NSUUID createUUID];
    [self setLastUpdateEventID:expectedLastUpdateEventID hasMore:NO];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    NSUUID *lastUpdateEventID = [[self.uiMOC persistentStoreMetadataForKey:LastUpdateEventIDStoreKey] UUID];
    XCTAssertEqualObjects(lastUpdateEventID, expectedLastUpdateEventID);
}

- (void)testThatItStoresTheLastUpdateEventIDWhenItIsAMoreRecentType1
{
    // given
    [self setLastUpdateEventID:[self olderNotificationID] hasMore:NO];
    
    // when
    [self setLastUpdateEventID:[self newNotificationID] hasMore:NO];
    
    // then
    NSUUID *lastUpdateEventID = [[self.uiMOC persistentStoreMetadataForKey:LastUpdateEventIDStoreKey] UUID];
    XCTAssertEqualObjects(lastUpdateEventID, [self newNotificationID]);
}

- (void)testThatItDoesNotStoreTheLastUpdateEventIDWhenItIsNotAMoreRecentType1
{
    // given
    [self setLastUpdateEventID:[self newNotificationID] hasMore:NO];
    
    // when
    [self setLastUpdateEventID:[self olderNotificationID] hasMore:NO];
    
    // then
    NSUUID *lastUpdateEventID = [[self.uiMOC persistentStoreMetadataForKey:LastUpdateEventIDStoreKey] UUID];
    XCTAssertEqualObjects(lastUpdateEventID, [self newNotificationID]);
}

- (void)testThatItStoresTheLastUpdateEventIDWhenItIsNotAType1
{
    // given
    NSUUID *secondUUID = [NSUUID createUUID];
    [self setLastUpdateEventID:[self newNotificationID] hasMore:NO];
    
    // when
    [self setLastUpdateEventID:secondUUID hasMore:NO];
    
    // then
    NSUUID *lastUpdateEventID = [[self.uiMOC persistentStoreMetadataForKey:LastUpdateEventIDStoreKey] UUID];
    XCTAssertEqualObjects(lastUpdateEventID, secondUUID);
}

- (void)testThatItStoresTheLastUpdateEventIDWhenThePreviousOneIsNotAType1
{
    // given
    NSUUID *firstUUID = [NSUUID createUUID];
    [self setLastUpdateEventID:firstUUID hasMore:NO];
    
    // when
    [self setLastUpdateEventID:[self newNotificationID] hasMore:NO];
    
    // then
    NSUUID *lastUpdateEventID = [[self.uiMOC persistentStoreMetadataForKey:LastUpdateEventIDStoreKey] UUID];
    XCTAssertEqualObjects(lastUpdateEventID, [self newNotificationID]);
}

- (void)testThatItStoresTheLastUpdateEventIDWhenReceivingNonTransientUpdateEvents
{
    // given
    NSUUID *expectedLastUpdateEventID = [NSUUID createUUID];
    id <ZMTransportData> payload = [self updateEventTransportDataWithID:expectedLastUpdateEventID];
    ZMUpdateEvent *event = [ZMUpdateEvent eventsArrayFromPushChannelData:payload].firstObject;
    
    // when
    [self.sut processEvents:@[event] liveEvents:YES prefetchResult:nil];
    
    // then
    NSUUID *lastUpdateEventID = [[self.uiMOC persistentStoreMetadataForKey:LastUpdateEventIDStoreKey] UUID];
    XCTAssertEqualObjects(lastUpdateEventID, expectedLastUpdateEventID);
}

- (void)testThatItDoesStoreTheLastUpdateEventIDWhenEventIDSourceIsWebsocketOrDownload
{
    // given
    NSUUID *websocketUpdateEventID = NSUUID.createUUID;
    NSUUID *downstreamUpdateEventID = NSUUID.createUUID;
    NSUUID *notificationUpdateEventID = NSUUID.createUUID;
    
    ZMUpdateEvent *websocketEvent = [self updateEventWithIdentifier:websocketUpdateEventID source:ZMUpdateEventSourceWebSocket];
    ZMUpdateEvent *downloadedEvent = [self updateEventWithIdentifier:downstreamUpdateEventID source:ZMUpdateEventSourceDownload];
    ZMUpdateEvent *pushNotificationEvent = [self updateEventWithIdentifier:notificationUpdateEventID source:ZMUpdateEventSourcePushNotification];
    
    // when
    [self.sut processEvents:@[websocketEvent] liveEvents:YES prefetchResult:nil];
    
    // then
    NSUUID *lastUpdateEventID = [[self.uiMOC persistentStoreMetadataForKey:LastUpdateEventIDStoreKey] UUID];
    XCTAssertEqualObjects(lastUpdateEventID, websocketUpdateEventID);
    
    // when
    [self.sut processEvents:@[downloadedEvent] liveEvents:YES prefetchResult:nil];
    
    // then
    lastUpdateEventID = [[self.uiMOC persistentStoreMetadataForKey:LastUpdateEventIDStoreKey] UUID];
    XCTAssertEqualObjects(lastUpdateEventID, downstreamUpdateEventID);
    
    // when
    [self.sut processEvents:@[pushNotificationEvent] liveEvents:YES prefetchResult:nil];
    
    // then
    lastUpdateEventID = [[self.uiMOC persistentStoreMetadataForKey:LastUpdateEventIDStoreKey] UUID];
    XCTAssertNotEqualObjects(lastUpdateEventID, notificationUpdateEventID);
    XCTAssertEqualObjects(lastUpdateEventID, downstreamUpdateEventID);
}

- (void)testThatItDoesNotStoreTheLastUpdateEventIDWhenReceivingTransientUpdateEvents
{
    // given
    NSUUID *initialLastUpdateEventID = [NSUUID createUUID];
    [self setLastUpdateEventID:initialLastUpdateEventID hasMore:NO];
    NSUUID *expectedLastUpdateEventID = [NSUUID createUUID];
    
    id <ZMTransportData> payload = [self updateEventTransportDataWithID:expectedLastUpdateEventID transient:YES];
    ZMUpdateEvent *event = [ZMUpdateEvent eventsArrayFromPushChannelData:payload].firstObject;
    XCTAssertTrue(event.isTransient);
    // when
    
    [self.sut processEvents:@[event] liveEvents:YES prefetchResult:nil];
    
    // then
    NSUUID *lastUpdateEventID = [[self.uiMOC persistentStoreMetadataForKey:LastUpdateEventIDStoreKey] UUID];
    XCTAssertEqualObjects(lastUpdateEventID, initialLastUpdateEventID);
}

- (void)testThatItDoesNotStoreTheLastUpdateEventIDWhenReceivingTransientUpdateEvents_FromNotificationStream
{
    // given
    NSUUID *initialLastUpdateEventID = [NSUUID createUUID];
    [self setLastUpdateEventID:initialLastUpdateEventID hasMore:NO];
    NSUUID *expectedLastUpdateEventID = [NSUUID createUUID];
    NSUUID *lastTransientUpdateEventID = [NSUUID createUUID];

    
    id <ZMTransportData> payloadExpectedLast = [self updateEventTransportDataWithID:expectedLastUpdateEventID transient:NO];
    id <ZMTransportData> payloadTransientLast = [self updateEventTransportDataWithID:lastTransientUpdateEventID transient:YES];
    NSDictionary *payload = @{@"notifications" : @[payloadExpectedLast, payloadTransientLast],
                              @"has_more" : @(NO)
                              };
    
    ZMTransportResponse* response = [ZMTransportResponse responseWithPayload:payload HTTPStatus:200 transportSessionError:nil apiVersion:0];
    
    // when

    [(id)self.sut.listPaginator didReceiveResponse:response forSingleRequest:self.requestSync];

    // then
    NSUUID *lastUpdateEventID = [[self.uiMOC persistentStoreMetadataForKey:LastUpdateEventIDStoreKey] UUID];
    XCTAssertEqualObjects(lastUpdateEventID, expectedLastUpdateEventID);
}

- (void)testThatItDoesNotStoreTheLastUpdateEventIDWhenReceivingTransientUpdateEvents_FromOnlyTransientNotificationStream
{
    // given
    NSUUID *initialLastUpdateEventID = [NSUUID createUUID];
    [self setLastUpdateEventID:initialLastUpdateEventID hasMore:NO];
    NSUUID *firstTransientUpdateEventID = [NSUUID createUUID];
    NSUUID *lastTransientUpdateEventID = [NSUUID createUUID];
    
    id <ZMTransportData> payloadFirstTransient = [self updateEventTransportDataWithID:firstTransientUpdateEventID transient:YES];
    id <ZMTransportData> payloadLastTransient = [self updateEventTransportDataWithID:lastTransientUpdateEventID transient:YES];
    NSDictionary *payload = @{@"notifications" : @[payloadFirstTransient, payloadLastTransient],
                              @"has_more" : @(NO)
                              };
    
    ZMTransportResponse* response = [ZMTransportResponse responseWithPayload:payload HTTPStatus:200 transportSessionError:nil apiVersion:0];
    
    // when
    
    [(id)self.sut.listPaginator didReceiveResponse:response forSingleRequest:self.requestSync];
    
    // then
    NSUUID *lastUpdateEventID = [[self.uiMOC persistentStoreMetadataForKey:LastUpdateEventIDStoreKey] UUID];
    XCTAssertEqualObjects(lastUpdateEventID, initialLastUpdateEventID);
}

- (ZMUpdateEvent *)updateEventWithIdentifier:(NSUUID *)identifier source:(ZMUpdateEventSource)source
{
    id <ZMTransportData> payload = [self updateEventTransportDataWithID:identifier];
    return [ZMUpdateEvent eventsArrayFromTransportData:payload source:source].firstObject;
}

- (id <ZMTransportData>)updateEventTransportDataWithID:(NSUUID *)identifier
{
    return [self updateEventTransportDataWithID:identifier transient:NO];
}

- (id <ZMTransportData>)updateEventTransportDataWithID:(NSUUID *)identifier transient:(BOOL)transient
{
    return @{
             @"id" : identifier.transportString,
             @"transient": @(transient),
             @"payload" : @[
                     @{
                         @"time" : @"2014-06-20T14:04:37.870Z",
                         @"type" : @"conversation.member-update"
                         }
                     ]
             };
}

@end



@implementation ZMMissingUpdateEventsTranscoderTests (Pagination)

- (void)testThatItUsesLastStoredEventIDWhenFetchingNextNotifications
{
    // given
    NSUUID *lastUpdateEventID1 = [NSUUID createUUID];
    NSUUID *lastUpdateEventID2 = [NSUUID createUUID];

    [self setLastUpdateEventID:lastUpdateEventID1 hasMore:NO];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // when
    [self.sut startDownloadingMissingNotifications];
    ZMTransportRequest *request1 = [self.sut.listPaginator nextRequestForAPIVersion:APIVersionV0];
    [request1 completeWithResponse:[self responseForSettingLastUpdateEventID:lastUpdateEventID2 hasMore:NO]];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    XCTAssertNotNil(request1);
    NSURLComponents *components1 = [NSURLComponents componentsWithString:request1.path];
    XCTAssertTrue([components1.queryItems containsObject:[NSURLQueryItem queryItemWithName:@"since" value:lastUpdateEventID1.transportString]]);
    
    // and when
    // when has_more == NO it should not create further requests
    ZMTransportRequest *request2 = [self.sut.listPaginator nextRequestForAPIVersion:APIVersionV0];
    // then
    XCTAssertNil(request2);
    
    // and when
    // fetching the next notifications, it should use the new updateEventID
    [self.sut startDownloadingMissingNotifications];
    ZMTransportRequest *request3 = [self.sut.listPaginator nextRequestForAPIVersion:APIVersionV0];
    
    // then
    XCTAssertNotNil(request3);
    NSURLComponents *components3 = [NSURLComponents componentsWithString:request3.path];
    XCTAssertTrue([components3.queryItems containsObject:[NSURLQueryItem queryItemWithName:@"since" value:lastUpdateEventID2.transportString]]);
}

- (void)testThatItDiscardsThePreviouslyReceivedEventIDsWhenReachingTheEndOfPagination
{
    // given
    NSUUID *lastUpdateEventID1 = [NSUUID createUUID];
    NSUUID *lastUpdateEventID2 = [NSUUID createUUID];
    
    [self setLastUpdateEventID:lastUpdateEventID1 hasMore:NO];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // when
    [self.sut startDownloadingMissingNotifications];
    ZMTransportRequest *request1 = [self.sut.listPaginator nextRequestForAPIVersion:APIVersionV0];
    [request1 completeWithResponse:[self responseForSettingLastUpdateEventID:lastUpdateEventID2 hasMore:NO]];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    OCMVerify([self.mockEventIDsCollection discardListOfAlreadyReceivedPushEventIDs]);
}

- (void)testThatItDoesNotDiscardsThePreviouslyReceivedEventIDsWhenNotReachingTheEndOfPagination
{
    // given
    NSUUID *lastUpdateEventID1 = [NSUUID createUUID];
    NSUUID *lastUpdateEventID2 = [NSUUID createUUID];
    
    [self setLastUpdateEventID:lastUpdateEventID1 hasMore:NO];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // expect
    OCMReject([self.mockEventIDsCollection discardListOfAlreadyReceivedPushEventIDs]);

    // when
    [self.sut startDownloadingMissingNotifications];
    ZMTransportRequest *request1 = [self.sut.listPaginator nextRequestForAPIVersion:APIVersionV0];
    [request1 completeWithResponse:[self responseForSettingLastUpdateEventID:lastUpdateEventID2 hasMore:YES]];
    WaitForAllGroupsToBeEmpty(0.5);
}

@end


@implementation ZMMissingUpdateEventsTranscoderTests (FallbackCancellation)

- (void)expectMockPushNotificationStatusHasEventsToFetch:(BOOL)hasEventsToFetch
                                            inBackground:(BOOL)backgrounded
{
    self.application.applicationState = backgrounded ? UIApplicationStateBackground : UIApplicationStateActive;
    self.mockHasPushNotificationEventsToFetch = hasEventsToFetch;
}

- (void)testThatItDoesNotReturnARequestItselfFromAPushWhenThePushNotificationStatusIsNotInProgress
{
    // given
    [self expectMockPushNotificationStatusHasEventsToFetch:NO inBackground:YES];

    // then
    XCTAssertNil([self.sut nextRequestForAPIVersion:APIVersionV0]);
}

- (void)testThatItDoesReturnARequestItselfFromAPushWhen
{
    // given
    [self expectMockPushNotificationStatusHasEventsToFetch:YES inBackground:YES];

    // then
    XCTAssertNotNil([self.sut nextRequestForAPIVersion:APIVersionV0]);
}

- (void)testThatItForcesTheRequestToTheVoIPSession
{
    // given
    [self expectMockPushNotificationStatusHasEventsToFetch:YES inBackground:YES];

    // when
    ZMTransportRequest *request = [self.sut nextRequestForAPIVersion:APIVersionV0];

    // then
    XCTAssertNotNil(request);
    XCTAssertTrue(request.shouldUseVoipSession);
}

- (void)testThatItDoesNotifyThePushNotificationStatusWhenEventsAreFetched
{
    // given
    [self expectMockPushNotificationStatusHasEventsToFetch:YES inBackground:YES];

    // when
    ZMTransportResponse *response = [self responseForSettingLastUpdateEventID:NSUUID.createUUID hasMore:NO];
    ZMTransportRequest *request = [self.sut nextRequestForAPIVersion:APIVersionV0];

    [(id)self.sut.listPaginator didReceiveResponse:[ZMTransportResponse responseWithPayload:@{} HTTPStatus:400 transportSessionError:nil apiVersion:request.apiVersion] forSingleRequest:self.requestSync];

    id <ZMTransportData> payload = response.payload.asDictionary[@"notifications"][0];
    NSArray<ZMUpdateEvent *> *expectedEvents = [ZMUpdateEvent eventsArrayFromPushChannelData:payload];
    NSArray<NSUUID *> *eventIds = [expectedEvents mapWithBlock:^id(ZMUpdateEvent *event) {
        return event.uuid;
    }];

    // expect
    [(PushNotificationStatus *)[self.mockPushNotificationStatus expect] didFetchEventIds:eventIds lastEventId:OCMOCK_ANY finished:YES];

    XCTAssertNotNil(request);

    [(id)self.sut.listPaginator didReceiveResponse:response forSingleRequest:self.requestSync];
    WaitForAllGroupsToBeEmpty(0.5);
}

- (void)testThatItDoesNotifyThePushNotificationStatusWhenEventsAreFetched_MultiplePages
{
    // first batch
    {
        [self expectMockPushNotificationStatusHasEventsToFetch:YES inBackground:YES];

        ZMTransportResponse *response = [self responseForSettingLastUpdateEventID:NSUUID.createUUID hasMore:YES];
        ZMTransportRequest *request = [self.sut nextRequestForAPIVersion:APIVersionV0];
        id <ZMTransportData> payload = response.payload.asDictionary[@"notifications"][0];
        NSArray <ZMUpdateEvent *> *expectedEvents = [ZMUpdateEvent eventsArrayFromPushChannelData:payload];
        NSArray<NSUUID *> *eventIds = [expectedEvents mapWithBlock:^id(ZMUpdateEvent *event) {
            return event.uuid;
        }];

        // expect
        [(PushNotificationStatus *)[self.mockPushNotificationStatus expect] didFetchEventIds:eventIds lastEventId:OCMOCK_ANY finished:NO];

        XCTAssertNotNil(request);
        [request completeWithResponse:response];
        WaitForAllGroupsToBeEmpty(0.5);
    }

    // second batch
    {
        [self expectMockPushNotificationStatusHasEventsToFetch:YES inBackground:YES];
        ZMTransportResponse *response = [self responseForSettingLastUpdateEventID:NSUUID.createUUID hasMore:NO];
        ZMTransportRequest *request = [self.sut nextRequestForAPIVersion:APIVersionV0];
        id <ZMTransportData> payload = response.payload.asDictionary[@"notifications"][0];
        NSArray <ZMUpdateEvent *> *expectedEvents = [ZMUpdateEvent eventsArrayFromPushChannelData:payload];
        NSArray<NSUUID *> *eventIds = [expectedEvents mapWithBlock:^id(ZMUpdateEvent *event) {
            return event.uuid;
        }];

        // expect
        [(PushNotificationStatus *)[self.mockPushNotificationStatus expect] didFetchEventIds:eventIds lastEventId:OCMOCK_ANY finished:YES];

        XCTAssertNotNil(request);
        [request completeWithResponse:response];
        WaitForAllGroupsToBeEmpty(0.5);
    }
}

- (void)testThatItUpdatesTheLastNotificationIdWhenStartedThroughAPush
{
    // given
    [self expectMockPushNotificationStatusHasEventsToFetch:YES inBackground:YES];

    // when
    NSUUID *expectedLastUpdateEventID = NSUUID.createUUID;
    ZMTransportResponse *response = [self responseForSettingLastUpdateEventID:expectedLastUpdateEventID hasMore:NO];
    ZMTransportRequest *request = [self.sut nextRequestForAPIVersion:APIVersionV0];
    [request completeWithResponse:response];
    WaitForAllGroupsToBeEmpty(0.5);

    // then
    NSUUID *lastUpdateEventID = [[self.uiMOC persistentStoreMetadataForKey:LastUpdateEventIDStoreKey] UUID];
    XCTAssertEqualObjects(lastUpdateEventID, expectedLastUpdateEventID);
    XCTAssertEqualObjects(self.sut.lastUpdateEventID, expectedLastUpdateEventID);
}

- (void)testThatItReportsWhenItIsFetchingFromAPushNotification
{
    // given
    self.mockHasPushNotificationEventsToFetch = YES;

    // then
    XCTAssertTrue(self.sut.isFetchingStreamForAPNS);
}

- (void)testThatItDoesNotReportThatItIsFetchingFromAPushNotificationWhenTheApplicationIsActive
{
    // given
    self.application.applicationState = UIApplicationStateActive;

    // then
    XCTAssertFalse(self.sut.isFetchingStreamForAPNS);
}

- (void)testThatItDoesNotReportThatItIsFetchingFromAPushNotificationWhenNoPushNotificationIsInProgress
{
    // given
    self.mockHasPushNotificationEventsToFetch = NO;
    self.application.applicationState = UIApplicationStateBackground;

    // then
    XCTAssertFalse(self.sut.isFetchingStreamForAPNS);
}

- (void)testThatItNotifiesThePushNotificationStatusInCaseOfAFailure
{
    // given
    [self expectMockPushNotificationStatusHasEventsToFetch:YES inBackground:YES];

    // when
    ZMTransportRequest *request = [self.sut nextRequestForAPIVersion:APIVersionV0];
    ZMTransportResponse *response = [ZMTransportResponse responseWithPayload:nil HTTPStatus:400 transportSessionError:nil apiVersion:request.apiVersion];
    [(PushNotificationStatus *)[self.mockPushNotificationStatus expect] didFailToFetchEvents];

    [request completeWithResponse:response];
    WaitForAllGroupsToBeEmpty(0.5);
}

- (void)testThatIUsesTheLastNotificationIdToRequestTheNotificationStreamFromAPush
{
    // given
    NSUUID *lastID = NSUUID.createUUID;
    // sync strategy is mocked to return the uiMOC when asked for the syncMOC
    self.uiMOC.zm_lastNotificationID = lastID;
    [self expectMockPushNotificationStatusHasEventsToFetch:YES inBackground:YES];

    // when
    ZMTransportRequest *request = [self.sut nextRequestForAPIVersion:APIVersionV0];

    // then
    XCTAssertNotNil(request);
    BOOL hasSinceQuery = NO;
    NSArray <NSURLQueryItem *> *items = [NSURLComponents componentsWithString:request.path].queryItems;
    for (NSURLQueryItem *item in items) {
        if ([item.name isEqualToString:@"since"]) {
            hasSinceQuery = YES;
            XCTAssertEqualObjects(item.value, lastID.transportString);
        }
    }

    XCTAssertTrue(hasSinceQuery);
}

@end


@implementation ZMMissingUpdateEventsTranscoderTests (ServerTimeDelta)

- (void)testThatServerTimeDeltaIsUpdatedWhenTimeFieldIsPresent
{
    // given
    NSTimeInterval delta = 500;
    NSDate *localTime = [NSDate date];
    NSDate *serverTime = [localTime dateByAddingTimeInterval:delta];
    
    NSDictionary *payload = @{@"time": [serverTime transportString],
                              @"notifications" : @[]};
    
    // when
    [self performPretendingUiMocIsSyncMoc:^{
        [(id)self.sut.listPaginator didReceiveResponse:[ZMTransportResponse responseWithPayload:payload HTTPStatus:200 transportSessionError:nil apiVersion:0] forSingleRequest:self.requestSync];
    }];
    
    // then
    [self performPretendingUiMocIsSyncMoc:^{
        XCTAssertEqualWithAccuracy(self.sut.managedObjectContext.serverTimeDelta, delta, 1);
    }];
}

@end
