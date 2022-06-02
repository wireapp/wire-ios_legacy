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


#import "MessagingTest.h"
#import "ZMSyncStrategy.h"
#import "Tests-Swift.h"
#import "MockModelObjectContextFactory.h"
#import "ZMOperationLoop+Private.h"
#import "ZMSyncStrategy+Internal.h"
#import "ZMSyncStrategy+ManagedObjectChanges.h"
#import "ZMOperationLoopTests.h"

@implementation ZMOperationLoopTests;

- (void)setUp
{
    [super setUp];
    self.pushChannelNotifications = [NSMutableArray array];
    
    self.cookieStorage = [[FakeCookieStorage alloc] init];
    self.mockPushChannel = [[MockPushChannel alloc] init];
    self.mockTransportSesssion = [[RecordingMockTransportSession alloc] initWithCookieStorage:self.cookieStorage
                                                                                  pushChannel:self.mockPushChannel];
            
    self.mockSyncDelegate = [[MockSyncStateDelegate alloc] init];
    self.mockRequestStrategy = [[MockRequestStrategy alloc] init];
    self.mockUpdateEventProcessor = [[MockUpdateEventProcessor alloc] init];
    self.mockRequestCancellation = [[MockRequestCancellation alloc] init];
    
    self.applicationStatusDirectory = [[ApplicationStatusDirectory alloc] initWithManagedObjectContext:self.syncMOC
                                                                                         cookieStorage:self.cookieStorage
                                                                                   requestCancellation:self.mockRequestCancellation
                                                                                           application:self.application
                                                                                     syncStateDelegate:self.mockSyncDelegate
                                                                                             analytics:nil];
    
    self.syncStatus = self.applicationStatusDirectory.syncStatus;
    self.callEventStatus = self.applicationStatusDirectory.callEventStatus;
    self.pushNotificationStatus = self.applicationStatusDirectory.pushNotificationStatus;
        
    self.sut = [[ZMOperationLoop alloc] initWithTransportSession:self.mockTransportSesssion
                                                 requestStrategy:self.mockRequestStrategy
                                            updateEventProcessor:self.mockUpdateEventProcessor
                                      applicationStatusDirectory:self.applicationStatusDirectory
                                                           uiMOC:self.uiMOC
                                                         syncMOC:self.syncMOC];
    self.pushChannelObserverToken = [NotificationInContext addObserverWithName:ZMOperationLoop.pushChannelStateChangeNotificationName
                                       context:self.uiMOC.notificationContext
                                        object:nil
                                         queue:nil
                                         using:^(NotificationInContext * note) {
                                             [self pushChannelDidChange:note];
                                         }];

    [ZMOperationLoopTests setCurrentAPIVersion:APIVersionV0];
}

- (void)tearDown;
{
    WaitForAllGroupsToBeEmpty(0.5);
    self.pushChannelObserverToken = nil;
    self.callEventStatus = nil;
    self.pushNotificationStatus = nil;
    self.applicationStatusDirectory = nil;
    self.mockPushChannel = nil;
    self.mockTransportSesssion = nil;
    self.mockRequestStrategy = nil;
    self.mockUpdateEventProcessor = nil;
    [self.sut tearDown];
    self.sut = nil;
    [super tearDown];
}

- (void)pushChannelDidChange:(NotificationInContext *)note
{
    [self.pushChannelNotifications addObject:note];
}

- (void)testThatItNotifiesTheSyncStatus_WhenThePushChannelIsOpened
{
    // when
    [(id<ZMPushChannelConsumer>)self.sut pushChannelDidOpen];
    
    // then
    XCTAssertNotNil(self.syncStatus.pushChannelEstablishedDate);
}

- (void)testThatItNotifiesTheSyncStatus_WhenThePushChannelIsClosed
{
    // given
    [(id<ZMPushChannelConsumer>)self.sut pushChannelDidOpen];
    
    // when
    [(id<ZMPushChannelConsumer>)self.sut pushChannelDidClose];
    
    // then
    XCTAssertNil(self.syncStatus.pushChannelEstablishedDate);
}

- (void)testThatItInitializesThePushChannel
{
    // when
    ZMOperationLoop *op = [[ZMOperationLoop alloc] initWithTransportSession:self.mockTransportSesssion
                                                            requestStrategy:self.mockRequestStrategy
                                                       updateEventProcessor:self.mockUpdateEventProcessor
                                                 applicationStatusDirectory:self.applicationStatusDirectory
                                                                      uiMOC:self.uiMOC
                                                                    syncMOC:self.syncMOC];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    XCTAssertNotNil(op);
    XCTAssertTrue(self.mockTransportSesssion.didCallConfigurePushChannel);
    [op tearDown];
}



- (void)testThatItSendsTheNextOperation
{

    // given
    ZMTransportRequest *request = [[ZMTransportRequest alloc] initWithPath:@"/test"
                                                                   method:ZMMethodPOST
                                                                  payload:@{@"foo": @"bar"}
                                                                apiVersion:0];
    self.mockRequestStrategy.mockRequest = request;

    // when
    [ZMRequestAvailableNotification notifyNewRequestsAvailable:self];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    XCTAssertTrue(self.mockRequestStrategy.nextRequestCalled);
    XCTAssertEqualObjects(self.mockTransportSesssion.lastEnqueuedRequest, request);
}

- (void)testThatItDoesNotSendARequestIfThereAreNone
{
    // given
    self.mockRequestStrategy.mockRequest = nil;
    
    // when
    [ZMRequestAvailableNotification notifyNewRequestsAvailable:self];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    XCTAssertNil(self.mockTransportSesssion.lastEnqueuedRequest);
}

- (void)testThatItDoesNotSendARequestIfThereIsNoCurrentAPIVersion
{
    // given
    [ZMOperationLoopTests clearCurrentAPIVersion];
    XCTAssertNil(self.sut.currentAPIVersion);

    self.mockRequestStrategy.mockRequest = [[ZMTransportRequest alloc] initWithPath:@"/test"
                                                                             method:ZMMethodPOST
                                                                            payload:@{@"foo": @"bar"}
                                                                          apiVersion:0];

    // when
    [ZMRequestAvailableNotification notifyNewRequestsAvailable:self];
    WaitForAllGroupsToBeEmpty(0.5);

    // then
    XCTAssertFalse(self.mockRequestStrategy.nextRequestCalled);
    XCTAssertNil(self.mockTransportSesssion.lastEnqueuedRequest);
}

- (void)testThatItSendsAsManyCallsAsTheTransportSessionCanHandle
{
    // given
    ZMTransportRequest *request = [[ZMTransportRequest alloc] initWithPath:@"/test" method:ZMMethodPOST payload:@{} apiVersion:0];
    self.mockRequestStrategy.mockRequestQueue = @[request, request, request];

    // when
    [ZMRequestAvailableNotification notifyNewRequestsAvailable:self];
    WaitForAllGroupsToBeEmpty(0.5);

    // then
    XCTAssertEqual(self.mockRequestStrategy.mockRequestQueue.count, 0);
}

- (void)testThatExecuteNextOperationIsCalledWhenThePreviousRequestIsCompleted
{
    // given
    ZMTransportRequest *request = [ZMTransportRequest requestWithPath:@"/boo" method:ZMMethodGET payload:nil apiVersion:0];
    self.mockRequestStrategy.mockRequest = request;
    [ZMRequestAvailableNotification notifyNewRequestsAvailable:self]; // this will enqueue `request`
    WaitForAllGroupsToBeEmpty(0.5);
    
    // when
    self.mockRequestStrategy.nextRequestCalled = NO;
    [request completeWithResponse:[ZMTransportResponse responseWithPayload:@{} HTTPStatus:200 transportSessionError:nil apiVersion:0]];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    XCTAssertTrue(self.mockRequestStrategy.nextRequestCalled);

}

- (void)testThatItAsksSyncStrategyForNextOperationOnZMOperationLoopNewRequestAvailableNotification
{
    // when
    [ZMRequestAvailableNotification notifyNewRequestsAvailable:self];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    XCTAssertTrue(self.mockRequestStrategy.nextRequestCalled);
}


- (void)testThatPushChannelDataIsSplitAndForwardedToAllIndividualObjects
{
    // given
    NSString *eventType = @"user.update";
    
    NSDictionary *payload1 = @{
                               @"type" : eventType,
                               @"foo" : @"bar"
                               };
    NSDictionary *payload2 = @{
                               @"type" : eventType,
                               @"bar" : @"xxxxxxx"
                               };
    NSDictionary *payload3 = @{
                               @"type" : eventType,
                               @"baz" : @"barbar"
                               };
    
    NSDictionary *eventData = @{
                                @"id" : @"5cc1ab91-45f4-49ec-bb7a-a5517b7a4173",
                                @"payload" : @[payload1, payload2, payload3],
                                };
    
    NSMutableArray *expectedEvents = [NSMutableArray array];
    [expectedEvents addObjectsFromArray:[ZMUpdateEvent eventsArrayFromPushChannelData:eventData]];
    XCTAssertGreaterThan(expectedEvents.count, 0u);
    
    // when
    [(id<ZMPushChannelConsumer>)self.sut pushChannelDidReceiveTransportData:eventData];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    XCTAssertEqualObjects(self.mockUpdateEventProcessor.processedEvents, expectedEvents);
}

- (void)testThatProcessSyncDataIsNotForwardedToAllSyncObjectsIfItIsNotAnArray
{
    // given
    NSDictionary *eventdata = @{
                                @"id" : @"16be010d-c284-4fc0-b636-837bcebed654",
                                @"payload" : @{
                                        @"type" : @"yyy",
                                        @"cat" : @"dog"
                                        },
                                };
    
    // when
    [self performIgnoringZMLogError:^{
        [(id<ZMPushChannelConsumer>)self.sut pushChannelDidReceiveTransportData:eventdata];
        WaitForAllGroupsToBeEmpty(0.5);
    }];
    
    // then
    XCTAssertEqual(self.mockUpdateEventProcessor.processedEvents.count, 0);
}

- (void)testThatProcessSyncDataIsNotForwardedToAllSyncObjectsIfEventsAreInvalid
{
    // given
    NSArray *eventdata = @[ @{ @"id" : @"16be010d-c284-4fc0-b636-837bcebed654" } ];
    
    // when
    [self performIgnoringZMLogError:^{
        [(id<ZMPushChannelConsumer>)self.sut pushChannelDidReceiveTransportData:eventdata];
        WaitForAllGroupsToBeEmpty(0.5);
    }];
    
    // then
    XCTAssertEqual(self.mockUpdateEventProcessor.processedEvents.count, 0);
}

- (void)testThatItSendsANotificationWhenClosingThePushChannelAndRemovingConsumers
{
    // when
    [(id<ZMPushChannelConsumer>)self.sut pushChannelDidClose];
    
    // then
    XCTAssertEqual(self.pushChannelNotifications.count, 1u);
    NSNotification *note = self.pushChannelNotifications.firstObject;
    XCTAssertFalse([note.userInfo[ZMPushChannelIsOpenKey] boolValue]);
}

- (void)testThatItSendsANotificationWhenOpeningThePushChannel
{
    // when
    [(id<ZMPushChannelConsumer>)self.sut pushChannelDidOpen];
    
    // then
    XCTAssertEqual(self.pushChannelNotifications.count, 1u);
    NSNotification *note = self.pushChannelNotifications.firstObject;
    XCTAssertTrue([note.userInfo[ZMPushChannelIsOpenKey] boolValue]);
}

- (void)testThatItInformsTransportSessionWhenEnteringForeground
{
    // when
    [self.sut operationStatusDidChangeState:SyncEngineOperationStateForeground];
    
    // then
    XCTAssertTrue(self.mockTransportSesssion.didCallEnterForeground);
}

- (void)testThatItInformsTransportSessionWhenEnteringBackground
{
    // when
    [self.sut operationStatusDidChangeState:SyncEngineOperationStateBackground];
    
    // then
    XCTAssertTrue(self.mockTransportSesssion.didCallEnterBackground);
}

@end



#if TARGET_OS_IPHONE

@implementation ZMOperationLoopTests (Background)

- (APSSignalingKeysStore *)prepareSelfClientForAPSSignalingStore
{    
    NSString *macKey = @"OnuLUsjZT5ix8mebzewnNH7kVuLNYvDTxVFe8xiZ1u0=";
    NSString *encryptionKey = @"eiISyl78bYnFZaXsjvZh4v7d/mnNLDQNB+vRcsapovA=";
    
    NSData *macKeyData = [[NSData alloc] initWithBase64EncodedString:macKey options:0];
    NSData *encryptionKeyData = [[NSData alloc] initWithBase64EncodedString:encryptionKey options:0];
    
    UserClient *selfClient = [self createSelfClient];
    selfClient.apsDecryptionKey = encryptionKeyData;
    selfClient.apsVerificationKey = macKeyData;

    return [[APSSignalingKeysStore alloc] initWithUserClient:selfClient];
}

-(void)clearKeyChainData
{
    [ZMKeychain deleteAllKeychainItemsWithAccountName: @"APSVerificationKey"];
    [ZMKeychain deleteAllKeychainItemsWithAccountName: @"APSDecryptionKey"];
}

- (NSDictionary *)pushPayloadForEventPayload:(NSArray *)eventPayloads identifier:(NSUUID *)identifier
{
    return @{
             @"aps": @{ @"content-available": @1 },
             @"data": @{
                     @"type": @"plain",
                     @"data": @{
                             @"id": identifier.transportString,
                             @"payload": eventPayloads
                             }
                     }
             };
}

- (NSDictionary *)pushPayloadForEventPayload:(NSArray *)eventPayloads
{
    return [self pushPayloadForEventPayload:eventPayloads identifier:NSUUID.createUUID];
}

- (NSDictionary *)alertPushPayloadForEventPayload:(NSArray *)eventPayloads
{
    return @{
             @"aps": @{@"content-available": @1,
                       @"alert": @{@"foo": @"bar"}
                       },
             @"data": @{
                     @"type": @"plain",
                     @"data": @{
                             @"id": [[NSUUID createUUID] transportString],
                             @"payload": eventPayloads
                             }
                     }
             };
}

- (NSDictionary *)fallbackAPNSPayloadWithIdentifier:(NSUUID *)uuid
{
    return @{
             @"aps": @{
                     @"content-available": @1,
                     @"alert": @{ @"foo": @"bar" }
                     },
             @"data": @{
                     @"type": @"notice",
                     @"data": @{ @"id": uuid.transportString }
                     }
             };
}

- (NSDictionary *)payloadForMessageAddEvent
{
    return [self payloadForMessageAddEventWithNonce:NSUUID.createUUID];
}

- (NSDictionary *)payloadForMessageAddEventWithNonce:(NSUUID *)uuid
{
    return @{
            @"conversation": [[NSUUID createUUID] transportString],
            @"time": [NSDate date],
            @"data": @{
                    @"content": @"saf",
                    @"nonce": [uuid transportString],
                    },
            @"from": [[NSUUID createUUID] transportString],
            @"type": @"conversation.message-add"
            };
}

- (NSDictionary *)noticePushPayloadWithUUID:(NSUUID *)uuid
{
    return  @{@"aps" : @{},
              @"data" : @{
                      @"data" : @{ @"id" : uuid.transportString },
                      @"type" : @"notice"
                      }
              };
}

- (NSDictionary *)encryptedPushPayload
{
    return @{
             @"aps" : @{@"alert": @{@"loc-args": @[],
                                    @"loc-key": @"push.notification.new_message"}
                        },
             @"data": @{
                     @"data" : @"70XpQ4qri2D4YCU7lvSjaqk+SgN/s4dDv/J8uMUel0xY8quNetPF8cMXskAZwBI9EArjMY/NupWo8Bar14GHi9ISzlOswDsoQ6BQiFsEdnv4shT+ZpJ+wghmPF+sxWhys9048ny6WiSqywUNzsUPjDrudAAiG4bPjS2FjMou2/o7FpCg7+6p8fcSYCcvQllv6P8oidVbMlpnT1Bs7fK6fz9ceq6H3L+BKZai82H7gc6nxSS5Gjf56qvDqdc3J9jTowpdjyqHGO26YahMQtDf4tn6KuTSp4OG1qLPk6jFf4xO2q/WrxV2dnoXGXWbIZ4cnohkeA85QxMhpM9pIGAbZ58fRUt9fPXm6PmX3rqQY7MSv4TV1fLyb5Zqo/yqQbcE2qS/dJKRrzwW5MWlKVWfacuNRZnansMMGUYyt7iRpD/E8PdtSfW7QO/02Evureor7MqQ8AYf6Ivt3Ksf1wplXne0zl8CT5GMeExB7DLfyr8T1xK6H+u3y29FmI9/T01la5cbIq/E83Yh2LTNo3X4eOfZ6mhC0EIC8YEyo/0x2IHsLyCAjzvIFfTSD8tOpa1yQTBSQ3mGGDWiPJ3f6OypQFj+vY13Bq9WZoL9Q+UbYbxdzkaYILaX2UakZ5OafQ7nH0WslvfzjRsdYoruTGDV+E8mXB2JOZh9ij2PT8fWsyJJ9DqKg5Iw2EPfUlXBv3pXIpZuL6+g8c2von092bV2pHTWkPE4A2yvw3LTzI8e9puOr5K87JUQHdR7mfXYifErW+9TRrmBibF5wKZtVl97UOFOps4/ZXU9i6Lr0qKKMdX3iruo7o3fYcbJTajb+sZLttDPsKnJHnnMxJUB3D+I1UuA35hL6Fy2wLj2mRNAzWuitNj9MSDUhDHU42+bZnap",
                     @"mac": @"ZGe7fjgAEvTjfSSv2MuDHQe7BCRj2NT7qg8OAm8JZyI=",
                     @"type": @"cipher"
                     }
             };
}

- (void)testThatItForwardsEventsFromSilentPushesToThePushNotificationStatus
{
    // given
    NSUUID *identifier = NSUUID.timeBasedUUID;
    NSDictionary *eventPayload = [self payloadForMessageAddEvent];
    NSDictionary *pushPayload = [self pushPayloadForEventPayload:@[eventPayload] identifier:identifier];
    NSArray *events = [ZMUpdateEvent eventsArrayFromPushChannelData:pushPayload[@"data"][@"data"]];
    XCTAssertNotNil(events);
    
    // when
    [self.sut fetchEventsFromPushChannelPayload:pushPayload completionHandler:^{}];
    WaitForAllGroupsToBeEmpty(1.0);
    
    // then
    XCTAssertTrue(self.pushNotificationStatus.hasEventsToFetch);
}


- (void)testThatItForwardsEventsFromEncryptedPushesToThePushNotificationStatus
{
    // given
    self.sut.apsSignalKeyStore = [self prepareSelfClientForAPSSignalingStore];
    NSDictionary *pushPayload = [self encryptedPushPayload];
    
    // when
    [self.sut fetchEventsFromPushChannelPayload:pushPayload completionHandler:^{}];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    XCTAssertTrue(self.pushNotificationStatus.hasEventsToFetch);
    [self clearKeyChainData];
}

- (void)testThatItForwardsNoticeNotificationsToThePushNotificationStatus
{
    // given
    XCTAssertTrue([self.syncMOC saveOrRollback]);
    WaitForAllGroupsToBeEmpty(0.5);

    NSUUID *notificationID = NSUUID.timeBasedUUID;
    NSDictionary *pushPayload = [self noticePushPayloadWithUUID:notificationID];

    // when
    [self.sut fetchEventsFromPushChannelPayload:pushPayload completionHandler:^{}];
    WaitForAllGroupsToBeEmpty(1.0);

    // then
    XCTAssertTrue(self.pushNotificationStatus.hasEventsToFetch);
}

- (void)testThatItCallsCompletionHandlerWhenEventsAreDownloaded
{
    // given
    XCTAssertTrue([self.syncMOC saveOrRollback]);
    WaitForAllGroupsToBeEmpty(0.5);
    
    NSUUID *notificationID = NSUUID.timeBasedUUID;
    NSDictionary *pushPayload = [self noticePushPayloadWithUUID:notificationID];
    
    // expect
    XCTestExpectation *expectation = [self expectationWithDescription:@"Called completion handler"];
    [self.sut fetchEventsFromPushChannelPayload:pushPayload completionHandler:^{
        [expectation fulfill];
    }];
    WaitForAllGroupsToBeEmpty(1.0);
    
    // when
    [self.pushNotificationStatus didFetchEventIds:@[notificationID] lastEventId:notificationID finished:YES];
    
    XCTAssertTrue([self waitForCustomExpectationsWithTimeout:0.5]);
}

- (void)testThatItCallsCompletionHandlerAfterCallEventsHaveBeenProcessed
{
    // given
    XCTAssertTrue([self.syncMOC saveOrRollback]);
    WaitForAllGroupsToBeEmpty(0.5);
    
    NSUUID *notificationID = NSUUID.timeBasedUUID;
    NSDictionary *pushPayload = [self noticePushPayloadWithUUID:notificationID];
    
    // expect
    __block BOOL completionHandlerHasBeenCalled = NO;
    XCTestExpectation *expectation = [self expectationWithDescription:@"Called completion handler"];
    [self.sut fetchEventsFromPushChannelPayload:pushPayload completionHandler:^{
        [expectation fulfill];
        completionHandlerHasBeenCalled = YES;
    }];
    WaitForAllGroupsToBeEmpty(1.0);
    
    // when
    [self.callEventStatus scheduledCallEventForProcessing];
    [self.pushNotificationStatus didFetchEventIds:@[notificationID] lastEventId:notificationID finished:YES];
    WaitForAllGroupsToBeEmpty(1.0);
    
    XCTAssertFalse(completionHandlerHasBeenCalled);
    
    [self.callEventStatus finishedProcessingCallEvent];
    XCTAssertTrue([self waitForCustomExpectationsWithTimeout:0.5]);
}

@end

#endif
