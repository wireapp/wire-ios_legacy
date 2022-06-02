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

#import "ConversationTestsBase.h"
#import "NotificationObservers.h"
#import <WireSyncEngine/WireSyncEngine-Swift.h>
#import "Tests-Swift.h"

@import WireDataModel;
@import WireUtilities;
@import WireRequestStrategy;

@interface ConversationTestsOTR : ConversationTestsBase
@end

@implementation ConversationTestsOTR

- (void)testThatItDeliversOTRAssetIfNoMissingClients
{
    __block ZMAssetClientMessage *message;
    
    XCTAssertTrue([self login]);
    
    ZMConversation *conversation = [self conversationForMockConversation:self.selfToUser1Conversation];

    // when
    [self.userSession performChanges:^{
        message = (id)[conversation appendImageFromData:[self verySmallJPEGData] nonce:[NSUUID createUUID]];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    MockPushEvent *lastEvent = self.mockTransportSession.updateEvents.lastObject;
    
    
    NSDictionary *lastEventPayload = lastEvent.payload.asDictionary;
    ZMUpdateEventType lastEventType = [MockEvent typeFromString:lastEventPayload[@"type"]];
    
    XCTAssertEqual(lastEventType, ZMUpdateEventTypeConversationOtrMessageAdd);
    XCTAssertEqual(message.deliveryState, ZMDeliveryStateSent);
    
    ZMUser *selfUser = [ZMUser selfUserInContext:self.userSession.syncManagedObjectContext];
    UserClient *selfClient = selfUser.selfClient;
    XCTAssertEqual(selfClient.missingClients.count, 0u);
    XCTAssertFalse([message hasLocalModificationsForKey:@"uploadState"]);
    XCTAssertEqual(message.transferState, AssetTransferStateUploaded);
}

- (void)testThatItAsksForMissingClientsKeysWhenDeliveringOtrMessage
{
    NSString *messageText = @"Hey!";

    __block BOOL askedForPreKeys = NO;
    [self.mockTransportSession setResponseGeneratorBlock:^ ZMTransportResponse *(ZMTransportRequest *__unused request) {
        if ([request.path.pathComponents containsObject:@"prekeys"]) {
            askedForPreKeys = YES;
            return ResponseGenerator.ResponseNotCompleted;
        }
        return nil;
    }];

    XCTAssertTrue([self login]);
    
    ZMConversation *conversation = [self conversationForMockConversation:self.selfToUser1Conversation];
    
    __block ZMMessage *message;
    // when
    [self.userSession performChanges:^{
        message = (id)[conversation appendText:messageText mentions:@[] fetchLinkPreview:YES nonce:[NSUUID createUUID]];
    }];
    
    WaitForAllGroupsToBeEmpty(0.5);
    
    MockPushEvent *lastEvent = self.mockTransportSession.updateEvents.lastObject;
    NSDictionary *lastEventPayload = lastEvent.payload.asDictionary;
    ZMUpdateEventType lastEventType = [MockEvent typeFromString:lastEventPayload[@"type"]];
    
    XCTAssertNotEqual(lastEventType, ZMUpdateEventTypeConversationOtrMessageAdd);
    XCTAssertEqual(message.deliveryState, ZMDeliveryStatePending);
    
    ZMUser *selfUser = [ZMUser selfUserInContext:self.userSession.syncManagedObjectContext];
    UserClient *selfClient = selfUser.selfClient;
    
    XCTAssertTrue(selfClient.missingClients.count > 0);
    XCTAssertTrue(askedForPreKeys);
}

- (void)testThatItDeliversOTRAssetAfterMissingClientsAreFetched
{
    // given
    XCTAssertTrue([self login]);
    
    ZMConversation *conversation = [self conversationForMockConversation:self.selfToUser1Conversation];
    __block ZMAssetClientMessage *message;

    // when
    [self.userSession performChanges:^{
        message = (id)[conversation appendImageFromData:[self verySmallJPEGData] nonce:[NSUUID createUUID]];
    }];
    
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    MockPushEvent *lastEvent = self.mockTransportSession.updateEvents.lastObject;
    //check that recipient can read this message
    NSDictionary *lastEventPayload = lastEvent.payload.asDictionary;
    ZMUpdateEventType lastEventType = [MockEvent typeFromString:lastEventPayload[@"type"]];
    
    XCTAssertEqual(lastEventType, ZMUpdateEventTypeConversationOtrMessageAdd);
    XCTAssertEqual(message.deliveryState, ZMDeliveryStateSent);
    
    ZMUser *selfUser = [ZMUser selfUserInContext:self.userSession.syncManagedObjectContext];
    UserClient *selfClient = selfUser.selfClient;
    XCTAssertEqual(selfClient.missingClients.count, 0u);
}


- (void)testThatItResetsKeysIfClientUnknown
{
    // given
    XCTAssertTrue([self login]);
    
    ZM_WEAK(self);
    self.mockTransportSession.responseGeneratorBlock = ^ ZMTransportResponse *(ZMTransportRequest *__unused request) {
        ZM_STRONG(self);
        if ([request.path.pathComponents containsObject:@"assets"]) {
            self.mockTransportSession.responseGeneratorBlock = nil;
            return [ZMTransportResponse responseWithPayload:@{ @"label" : @"unknown-client"} HTTPStatus:403 transportSessionError:nil apiVersion:0];
        }
        return nil;
    };
    
    ZMConversation *conversation = [self conversationForMockConversation:self.selfToUser1Conversation];
    
    __block ZMAssetClientMessage *message;
    // when
    [self.userSession performChanges:^{
        message = (id)[conversation appendImageFromData:[self verySmallJPEGData] nonce:[NSUUID createUUID]];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    MockPushEvent *lastEvent = self.mockTransportSession.updateEvents.lastObject;
    NSDictionary *lastEventPayload = lastEvent.payload.asDictionary;
    ZMUpdateEventType lastEventType = [MockEvent typeFromString:lastEventPayload[@"type"]];
    
    XCTAssertNotEqual(lastEventType, ZMUpdateEventTypeConversationOtrMessageAdd);
    XCTAssertEqual(message.deliveryState, ZMDeliveryStateFailedToSend);
    
    XCTAssertFalse([message hasLocalModificationsForKey:@"uploadState"]);
    XCTAssertEqual(message.transferState, AssetTransferStateUploadingFailed);
    
}

- (void)testThatItNotifiesIfThereAreNewRemoteClients
{
    // GIVEN
    XCTAssertTrue([self login]);
    
    ZMUser *selfUser = [ZMUser selfUserInContext:self.userSession.managedObjectContext];
    UserChangeObserver *observer = [[UserChangeObserver alloc] initWithUser:selfUser];
    ZMConversation *conversation = [self conversationForMockConversation:self.selfToUser1Conversation];
    
    [self.mockTransportSession performRemoteChanges:^(id<MockTransportSessionObjectCreation> _Nonnull session) {
        [session registerClientForUser:self.selfUser];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // WHEN
    [self.userSession performChanges:^{
        [conversation appendImageFromData:[self verySmallJPEGData] nonce:[NSUUID createUUID]];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // THEN
    XCTAssertTrue([observer.notifications.firstObject clientsChanged]);
}

- (void)testThatItDeliversTwoOTRAssetMessages
{
    // given
    XCTAssertTrue([self login]);
    
    //register other users clients
    [self.mockTransportSession performRemoteChanges:^ (id<MockTransportSessionObjectCreation>  _Nonnull __strong session) {
        for(int i = 0; i < 7; ++i) {
            MockUser *user = [session insertUserWithName:[NSString stringWithFormat:@"TestUser %d", i+1]];
            user.email = [NSString stringWithFormat:@"user%d@example.com", i+1];
            user.accentID = 4;
            [self.groupConversation addUsersByUser:user addedUsers:@[user]];
        }
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    ZMConversation *conversation = [self conversationForMockConversation:self.groupConversation];
    
    __block ZMMessage *imageMessage1;
    // when
    [self.userSession performChanges:^{
        imageMessage1 = (id)[conversation appendImageFromData:[self verySmallJPEGData] nonce:[NSUUID createUUID]];
    }];
    
    __block ZMMessage *textMessage;
    [self.userSession performChanges:^{
        textMessage = (id)[conversation appendText:@"foobar" mentions:@[] fetchLinkPreview:YES nonce:[NSUUID createUUID]];
    }];
    
    __block ZMMessage *imageMessage2;
    // and when
    [self.userSession performChanges:^{
        imageMessage2 = (id)[conversation appendImageFromData:[self verySmallJPEGData] nonce:[NSUUID createUUID]];
        
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    XCTAssertEqual(imageMessage1.deliveryState, ZMDeliveryStateSent);
    XCTAssertEqual(textMessage.deliveryState, ZMDeliveryStateSent);
    XCTAssertEqual(imageMessage2.deliveryState, ZMDeliveryStateSent);
}

- (void)testThatItOTRMessagesCanExpire
{
    // given
    XCTAssertTrue([self login]);
    
    NSTimeInterval defaultExpirationTime = [ZMMessage defaultExpirationTime];
    [ZMMessage setDefaultExpirationTime:0.3];

    self.mockTransportSession.doNotRespondToRequests = YES;
    
    ZMConversation *conversation = [self conversationForMockConversation:self.selfToUser1Conversation];
    
    __block ZMClientMessage *message;
    
    // when
    [self.userSession performChanges:^{
        message = (id)[conversation appendText:@"I can't hear you, Claudy" mentions:@[] fetchLinkPreview:YES nonce:[NSUUID createUUID]];
    }];
    
    XCTAssertTrue([self waitOnMainLoopUntilBlock:^BOOL{
        return message.isExpired;
    } timeout:0.5]);
    
    // then
    XCTAssertEqual(message.deliveryState, ZMDeliveryStateFailedToSend);
    XCTAssertEqual(conversation.conversationListIndicator, ZMConversationListIndicatorExpiredMessage);

    [ZMMessage setDefaultExpirationTime:defaultExpirationTime];

}

- (void)testThatItOTRAssetCanExpire
{
    // given
    XCTAssertTrue([self login]);
    
    NSTimeInterval defaultExpirationTime = [ZMMessage defaultExpirationTime];
    [ZMMessage setDefaultExpirationTime:0.3];
    
    self.mockTransportSession.doNotRespondToRequests = YES;
    
    ZMConversation *conversation = [self conversationForMockConversation:self.selfToUser1Conversation];
    
    __block ZMAssetClientMessage *message;
    
    // when
    [self.userSession performChanges:^{
        message = (id)[conversation appendImageFromData:[self verySmallJPEGData] nonce:[NSUUID createUUID]];
    }];
    
    [self spinMainQueueWithTimeout:0.5];
    
    // then
    XCTAssertTrue(message.isExpired);
    XCTAssertEqual(message.deliveryState, ZMDeliveryStateFailedToSend);
    XCTAssertEqual(conversation.conversationListIndicator, ZMConversationListIndicatorExpiredMessage);

    [ZMMessage setDefaultExpirationTime:defaultExpirationTime];
    
    WaitForAllGroupsToBeEmpty(0.5);
}

@end

#pragma mark - Trust
@implementation ConversationTestsOTR (Trust)

- (ZMClientMessage *)sendOtrMessageWithInitialSecurityLevel:(ZMConversationSecurityLevel)securityLevel
                                           numberOfMessages:(NSUInteger)numberOfMessages
                                     createAdditionalClient:(BOOL)createAdditionalClient
                            handleSecurityLevelNotification:(void(^)(ConversationChangeInfo *))handler
{
    return [self sendOtrMessageWithInitialSecurityLevel:securityLevel
                                       numberOfMessages:numberOfMessages
                                secureGroupConversation:NO
                                 createAdditionalClient:createAdditionalClient
                        handleSecurityLevelNotification:handler];
}

- (ZMClientMessage *)sendOtrMessageWithInitialSecurityLevel:(ZMConversationSecurityLevel)securityLevel
                                           numberOfMessages:(NSUInteger)numberOfMessages
                                    secureGroupConversation:(BOOL)secureGroupConversation
                                     createAdditionalClient:(BOOL)createAdditionalClient
                            handleSecurityLevelNotification:(void(^)(ConversationChangeInfo *))handler
{
    // login if needed
    if(!self.userSession.isLoggedIn) {
        XCTAssertTrue([self login]);
    }
    
    //register other users clients
    if([self userForMockUser:self.user1].clients.count == 0) {
        [self establishSessionWithMockUser:self.user1];
        WaitForAllGroupsToBeEmpty(0.5);
    }
    
    ZMConversation *conversation = [self conversationForMockConversation:self.selfToUser1Conversation];
    
    // Setup security level
    [self setupInitialSecurityLevel:securityLevel inConversation:conversation];
    
    // make secondary group conversation trusted if needed
    if (secureGroupConversation) {
        ZMConversation *groupLocalConversation = [self conversationForMockConversation:self.groupConversationWithOnlyConnected];
        if(groupLocalConversation.securityLevel != ZMConversationSecurityLevelSecure) {
            for(MockUser* user in self.groupConversationWithOnlyConnected.activeUsers) {
                if(user != self.selfUser && user.clients.count == 0) {
                    [self establishSessionWithMockUser:user];
                    WaitForAllGroupsToBeEmpty(0.5);
                }
                XCTAssert(user.clients.count > 0);
            }
            [self.userSession.syncManagedObjectContext saveOrRollback];
            [self.userSession.managedObjectContext saveOrRollback];
            [self makeConversationSecured:groupLocalConversation];
        }
    }
    
    if (createAdditionalClient) {
        [self.mockTransportSession performRemoteChanges:^(id<MockTransportSessionObjectCreation> _Nonnull session) {
            [session registerClientForUser:self.user1];
        }];
    }
    
    __block ConversationChangeObserver *observer;
    observer = [[ConversationChangeObserver alloc] initWithConversation:conversation];
    observer.notificationCallback = ^(NSObject *note) {
        ConversationChangeInfo *changeInfo = (ConversationChangeInfo *)note;
        if ([changeInfo securityLevelChanged]) {
            if (handler) {
                [self.userSession performChanges:^{
                    handler(changeInfo);
                }];
            }
        }
    };
    [observer clearNotifications];

    // when
    __block ZMClientMessage* message;
    [self.userSession performChanges:^{
        for (NSUInteger i = 0; i < numberOfMessages; i++) {
            message = (id)[conversation appendText:[NSString stringWithFormat:@"Hey %lu", conversation.allMessages.count] mentions:@[] fetchLinkPreview:YES nonce:[NSUUID createUUID]];
            [NSThread sleepForTimeInterval:0.1];
        }
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    return message;
}

- (void)testThatItChangesTheSecurityLevelIfUnconnectedUntrustedParticipantIsAdded
{
    XCTAssertTrue([self login]);
    
    // register other users clients
    [self establishSessionWithMockUser:self.user1];
    [self establishSessionWithMockUser:self.user2];
    WaitForAllGroupsToBeEmpty(0.5);
    
    ZMConversation *conversation = [self conversationForMockConversation:self.groupConversationWithOnlyConnected];
    [self makeConversationSecured:conversation];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // when
    [self.mockTransportSession performRemoteChanges:^ (id<MockTransportSessionObjectCreation>  _Nonnull __strong session) {
        NOT_USED(session);
        [self.groupConversationWithOnlyConnected addUsersByUser:self.user1 addedUsers:@[self.user5]];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    ZMUser *addedUser = [self userForMockUser:self.user5];
    XCTAssertTrue([conversation.localParticipants containsObject:addedUser]);
    XCTAssertNil(addedUser.connection);
    
    XCTAssertFalse(conversation.allUsersTrusted);
    XCTAssertEqual(conversation.securityLevel, ZMConversationSecurityLevelSecureWithIgnored);
    
    // when
    [self.mockTransportSession performRemoteChanges:^ (id<MockTransportSessionObjectCreation>  _Nonnull __strong session) {
        MockConversation *selfToUser5Conversation = [session insertOneOnOneConversationWithSelfUser:self.selfUser otherUser:self.user5];
        selfToUser5Conversation.creator = self.selfUser;
        MockConnection *connectionSelfToUser5 = [session insertConnectionWithSelfUser:self.selfUser toUser:self.user5];
        connectionSelfToUser5.status = @"accepted";
        connectionSelfToUser5.lastUpdate = [NSDate dateWithTimeIntervalSinceNow:-3];
        connectionSelfToUser5.conversation = selfToUser5Conversation;
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    XCTAssertEqual(conversation.securityLevel, ZMConversationSecurityLevelSecureWithIgnored);
    
    [self establishSessionWithMockUser:self.user5];
    WaitForAllGroupsToBeEmpty(0.5);

    ZMUser *user = [self userForMockUser:self.user5];

    [self.userSession performChanges:^{
        ZMUser *selfUser = [self userForMockUser:self.selfUser];
        [selfUser.selfClient trustClients:user.clients];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    XCTAssertTrue(conversation.allUsersTrusted);
    XCTAssertEqual(conversation.securityLevel, ZMConversationSecurityLevelSecure);
}

- (void)testThatItDeliversOTRMessageIfAllClientsAreTrustedAndNoMissingClients
{
    //given
    XCTAssertTrue([self login]);
    
    MockConversation *mockConversation = self.selfToUser1Conversation;
    ZMConversation *conversation = [self conversationForMockConversation:mockConversation];
    
    {
        // send a message to fetch all the missing client
        [self.userSession performChanges:^{
            [conversation appendText:[NSString stringWithFormat:@"Hey %lu", conversation.allMessages.count] mentions:@[] fetchLinkPreview:YES nonce:[NSUUID createUUID]];
        }];
        WaitForAllGroupsToBeEmpty(0.5);
    }
    
    [self makeConversationSecured:conversation];
    
    // when
    __block ZMClientMessage* message;
    [self.userSession performChanges:^{
        message = (id)[conversation appendText:[NSString stringWithFormat:@"Hey %lu", conversation.allMessages.count] mentions:@[] fetchLinkPreview:YES nonce:[NSUUID createUUID]];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    MockPushEvent *lastEvent = self.mockTransportSession.updateEvents.lastObject;
    NSDictionary *lastEventPayload = lastEvent.payload.asDictionary;
    ZMUpdateEventType lastEventType = [MockEvent typeFromString:lastEventPayload[@"type"]];
    
    XCTAssertEqual(lastEventType, ZMUpdateEventTypeConversationOtrMessageAdd);
    XCTAssertEqual(message.deliveryState, ZMDeliveryStateSent);
    
    XCTAssertEqual(message.conversation.securityLevel, ZMConversationSecurityLevelSecure);
}


- (void)testThatItDeliversOTRMessageAfterIgnoringAndResending
{
    __block BOOL notificationRecieved = NO;
    //given
    XCTAssertTrue([self login]);
    
    MockConversation *mockConversation = self.selfToUser1Conversation;
    ZMConversation *conversation = [self conversationForMockConversation:mockConversation];
    
    {
        // send a message to fetch all the missing client
        [self.userSession performChanges:^{
            [conversation appendText:[NSString stringWithFormat:@"Hey %lu", conversation.allMessages.count] mentions:@[] fetchLinkPreview:YES nonce:[NSUUID createUUID]];
        }];
        WaitForAllGroupsToBeEmpty(0.5);
    }
    [self makeConversationSecured:conversation];
    
    //when
    [self.mockTransportSession performRemoteChanges:^ (id<MockTransportSessionObjectCreation>  _Nonnull __strong session) {
        [session registerClientForUser:self.user1];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    __block ConversationChangeObserver *observer;
    observer = [[ConversationChangeObserver alloc] initWithConversation:conversation];
    observer.notificationCallback = ^(NSObject *note) {
        ConversationChangeInfo *changeInfo = (ConversationChangeInfo *)note;
        if (changeInfo.securityLevelChanged && changeInfo.causedByConversationPrivacyChange) {
            notificationRecieved = YES;
            [self.userSession performChanges:^{
                if (changeInfo.conversation.securityLevel == ZMConversationSecurityLevelSecureWithIgnored) {
                    [changeInfo.conversation acknowledgePrivacyWarningWithResendIntent:YES];
                }
            }];
        }
    };
    [observer clearNotifications];
    
    // when
    __block ZMClientMessage* message;
    [self.userSession performChanges:^{
        message = (id)[conversation appendText:[NSString stringWithFormat:@"Hey %lu", conversation.allMessages.count] mentions:@[] fetchLinkPreview:YES nonce:[NSUUID createUUID]];
    }];
    [message.managedObjectContext saveOrRollback];
    WaitForAllGroupsToBeEmpty(0.5);
    
    XCTAssertTrue(notificationRecieved);
    XCTAssertEqual(message.deliveryState, ZMDeliveryStateSent);
    
    XCTAssertEqual(message.visibleInConversation, message.conversation);
    XCTAssertEqual(message.conversation.securityLevel, ZMConversationSecurityLevelNotSecure);
    
}

- (void)testThatItDoesNotDeliversOTRMessageAfterIgnoringExpiring
{
    __block BOOL notificationRecieved = NO;
    
    // when
    ZMClientMessage *message1 = [self sendOtrMessageWithInitialSecurityLevel:ZMConversationSecurityLevelSecure
                                                            numberOfMessages:1
                                                      createAdditionalClient:YES
                                             handleSecurityLevelNotification:^(ConversationChangeInfo *changeInfo) {
                                                 notificationRecieved = YES;
                                                 if (changeInfo.conversation.securityLevel == ZMConversationSecurityLevelSecureWithIgnored) {
                                                     XCTAssertTrue(changeInfo.causedByConversationPrivacyChange);
                                                 }
                                             }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    XCTAssertTrue(notificationRecieved);
    
    XCTAssertEqual(message1.deliveryState, ZMDeliveryStateFailedToSend);
    
    XCTAssertEqual(message1.conversation.securityLevel, ZMConversationSecurityLevelSecureWithIgnored);
}


- (void)testThatItDoesNotDeliverOriginalOTRMessageAfterIgnoringExpiringAndThenSendingAnotherOne
{
    // GIVEN
    __block BOOL notificationRecieved = NO;
    XCTAssertTrue([self login]);
    ZMConversation *conversation = [self conversationForMockConversation:self.selfToUser1Conversation];
    
    [self.userSession performChanges:^ {
        [conversation appendText:[NSString stringWithFormat:@"Hey %lu", conversation.allMessages.count] mentions:@[] fetchLinkPreview:YES nonce:[NSUUID createUUID]];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    [self makeConversationSecured:conversation];
    
    // add extra user, that will cause conversation degradation
    [self.mockTransportSession performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        [session registerClientForUser:self.user1];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    __block ConversationChangeObserver *observer;
    observer = [[ConversationChangeObserver alloc] initWithConversation:conversation];
    observer.notificationCallback = ^(NSObject *note) {
        ConversationChangeInfo *changeInfo = (ConversationChangeInfo *)note;
        if ([changeInfo securityLevelChanged]) {
            notificationRecieved = YES;
            if (changeInfo.conversation.securityLevel == ZMConversationSecurityLevelSecureWithIgnored) {
                XCTAssertTrue(changeInfo.causedByConversationPrivacyChange);
                [changeInfo.conversation acknowledgePrivacyWarningWithResendIntent:NO];
            }
        }
    };
    [observer clearNotifications];
    
    // WHEN
    __block ZMClientMessage* message1;
    [self.userSession performChanges:^{ // this should cause conversation to degrade
        message1 = (id)[conversation appendText:[NSString stringWithFormat:@"Hey %lu", conversation.allMessages.count] mentions:@[] fetchLinkPreview:YES nonce:[NSUUID createUUID]];
    }];
    
    // THEN
    WaitForAllGroupsToBeEmpty(0.5);
    XCTAssertTrue(notificationRecieved);
    XCTAssertNotNil(message1);
    XCTAssertEqual(message1.deliveryState, ZMDeliveryStateFailedToSend);
    XCTAssertEqual(message1.conversation.securityLevel, ZMConversationSecurityLevelNotSecure);
    WaitForAllGroupsToBeEmpty(0.5);
    
    // GIVEN
    observer.notificationCallback = ^(NSObject *note) {
        ConversationChangeInfo *changeInfo = (ConversationChangeInfo *)note;
        if ([changeInfo securityLevelChanged]) {
            notificationRecieved &= YES;
            if (changeInfo.conversation.securityLevel == ZMConversationSecurityLevelSecureWithIgnored) {
                XCTAssertTrue(changeInfo.causedByConversationPrivacyChange);
                [self.userSession performChanges:^{
                    [changeInfo.conversation acknowledgePrivacyWarningWithResendIntent:YES];
                }];
            }
        }
    };
    [observer clearNotifications];

    // WHEN
    __block ZMClientMessage* message2;
    [self.userSession performChanges:^{
        message2 = (id)[conversation appendText:[NSString stringWithFormat:@"Hey %lu", conversation.allMessages.count] mentions:@[] fetchLinkPreview:YES nonce:[NSUUID createUUID]];
    }];

    
    // THEN
    WaitForAllGroupsToBeEmpty(0.5);
    XCTAssertTrue(notificationRecieved);
    XCTAssertEqual(message2.deliveryState, ZMDeliveryStateSent);
    XCTAssertNotNil(message2);
    XCTAssertEqual(message2.conversation.securityLevel, ZMConversationSecurityLevelNotSecure);
    XCTAssertEqual(message1.deliveryState, ZMDeliveryStateFailedToSend);
}

- (void)testThatItInsertsNewClientSystemMessageWhenReceivedMissingClients
{
    ZMClientMessage *message = [self sendOtrMessageWithInitialSecurityLevel:ZMConversationSecurityLevelSecure
                                                           numberOfMessages:1
                                                     createAdditionalClient:YES
                                            handleSecurityLevelNotification:nil];
    
    WaitForAllGroupsToBeEmpty(0.5);
    
    ZMConversation *conversation = message.conversation;
    ZMSystemMessage *lastMessage = (ZMSystemMessage *)[conversation lastMessagesWithLimit:10][1]; // second to last message
    XCTAssertTrue([lastMessage isKindOfClass:[ZMSystemMessage class]]);
    
    NSArray<ZMUser *> *expectedUsers = @[[self userForMockUser:self.user1]];
    
    AssertArraysContainsSameObjects(lastMessage.users.allObjects, expectedUsers);
    XCTAssertEqual(lastMessage.systemMessageType, ZMSystemMessageTypeNewClient);
}

- (void)testThatItInsertsNewClientSystemMessageWhenReceivedMissingClientsEvenIfSeveralMessagesAppendedAfter
{
    ZMClientMessage *message = [self sendOtrMessageWithInitialSecurityLevel:ZMConversationSecurityLevelSecure
                                                           numberOfMessages:5
                                                     createAdditionalClient:YES
                                            handleSecurityLevelNotification:nil];
    
    WaitForAllGroupsToBeEmpty(0.5);
    
    ZMConversation *conversation = message.conversation;
    ZMSystemMessage *lastMessage = (ZMSystemMessage *)[conversation lastMessagesWithLimit:10][5];
    XCTAssertTrue([lastMessage isKindOfClass:[ZMSystemMessage class]]);
    
    NSArray<ZMUser *> *expectedUsers = @[[self userForMockUser:self.user1]];
    
    AssertArraysContainsSameObjects(lastMessage.users.allObjects, expectedUsers);
    XCTAssertEqual(lastMessage.systemMessageType, ZMSystemMessageTypeNewClient);
}

- (void)testThatInsertsSecurityLevelDecreasedMessageInTheEndIfMessageCausedIsInOtherConversation
{
    XCTAssertTrue([self login]);
    
    //register other users clients
    
    void (^secureConversationBlock)(ZMConversation *) = ^(ZMConversation *conversation) {
        // send a message to fetch all the missing client
        [self.userSession performChanges:^{
            [conversation appendText:[NSString stringWithFormat:@"Hey %lu", conversation.allMessages.count] mentions:@[] fetchLinkPreview:YES nonce:[NSUUID createUUID]];
        }];
        WaitForAllGroupsToBeEmpty(0.5);
        [self makeConversationSecured:conversation];

    };
    
    ZMConversation *conversation = [self conversationForMockConversation:self.selfToUser1Conversation];
    ZMConversation *groupLocalConversation = [self conversationForMockConversation:self.groupConversationWithOnlyConnected];

    secureConversationBlock(conversation);
    secureConversationBlock(groupLocalConversation);
    
    [self.mockTransportSession performRemoteChanges:^(id<MockTransportSessionObjectCreation> session){
        [session registerClientForUser:self.user1];
    }];
    
    // when
    __block ZMClientMessage* message;
    [self.userSession performChanges:^{
        message = (id)[conversation appendText:[NSString stringWithFormat:@"Hey %lu", conversation.allMessages.count] mentions:@[] fetchLinkPreview:YES nonce:[NSUUID createUUID]];
    }];
    [message.managedObjectContext saveOrRollback];
    WaitForAllGroupsToBeEmpty(0.5);
    
    XCTAssertNotNil(message.conversation);
    
    ZMSystemMessage *lastMessage = (ZMSystemMessage *)groupLocalConversation.lastMessage;
    XCTAssertTrue([lastMessage isKindOfClass:[ZMSystemMessage class]]);
    
    XCTAssertEqual(message.conversation, conversation);
    NSArray<ZMUser *> *expectedUsers = @[[self userForMockUser:self.user1]];
    
    AssertArraysContainsSameObjects(lastMessage.users.allObjects, expectedUsers);
    XCTAssertEqual(lastMessage.systemMessageType, ZMSystemMessageTypeNewClient);
}

- (void)testThatInsertsSecurityLevelDecreasedMessageInTheEndOfConversationIfNotCausedByMessage
{
    // given
    XCTAssertTrue([self login]);
    
    UserClient *selfClient = [ZMUser selfUserInUserSession:self.userSession].selfClient;
    [self establishSessionWithMockUser:self.user1];
    WaitForAllGroupsToBeEmpty(0.5);
    
    ZMConversation *conversation = [self conversationForMockConversation:self.selfToUser1Conversation];
    [self makeConversationSecured:conversation];
    
    // when
    ZMUser *localUser1 = [self userForMockUser:self.user1];
    [selfClient ignoreClient:localUser1.clients.anyObject];
    
    // then
    ZMSystemMessage *lastMessage = (ZMSystemMessage *)conversation.lastMessage;
    XCTAssertTrue([lastMessage isKindOfClass:[ZMSystemMessage class]]);
    
    NSArray<ZMUser *> *expectedUsers = @[localUser1];
    
    AssertArraysContainsSameObjects(lastMessage.users.allObjects, expectedUsers);
    XCTAssertEqual(lastMessage.systemMessageType, ZMSystemMessageTypeIgnoredClient);

}

- (void)testThatItChangesSecurityLevelToInsecureBecauseFailedMessageAttemptWhenSelfTriesToSendMessageInDegradingConversation
{
    // GIVEN
    XCTAssertTrue([self login]);
    [self establishSessionWithMockUser:self.user1];
    ZMConversation *conversation = [self conversationForMockConversation:self.selfToUser1Conversation];
    [self makeConversationSecured:conversation];
    [self.mockTransportSession performRemoteChanges:^(id<MockTransportSessionObjectCreation> _Nonnull session) {
        [session registerClientForUser:self.user1];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // WHEN
    [self.userSession performChanges:^{
        [conversation appendText:@"Hello" mentions:@[] fetchLinkPreview:YES nonce:NSUUID.createUUID];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // THEN
    ZMSystemMessage *lastMessage = (ZMSystemMessage *)[conversation lastMessagesWithLimit:10][1]; // second to last message
    XCTAssertEqual(conversation.securityLevel, ZMConversationSecurityLevelSecureWithIgnored);
    XCTAssertEqual(conversation.allMessages.count, 3lu); // 2x system message (secured & new client) + appended client message
    XCTAssertEqual(lastMessage.systemMessageData.systemMessageType, ZMSystemMessageTypeNewClient);
}

- (void)checkThatItShouldInsertIgnoredSystemMessageAfterIgnoring:(BOOL)shouldInsert
                                       shouldChangeSecurityLevel:(BOOL)shouldChangeSecurityLevel
                                         forInitialSecurityLevel:(ZMConversationSecurityLevel)initialSecurityLevel
                                           expectedSecurityLevel:(ZMConversationSecurityLevel)expectedSecurityLevel
{
    XCTAssertTrue([self login]);
    
    [self establishSessionWithMockUser:self.user1];
    WaitForAllGroupsToBeEmpty(0.5);
    
    XCTAssertFalse(self.user1.clients.isEmpty);
    ZMConversation *conversation = [self conversationForMockConversation:self.selfToUser1Conversation];
    
    [self setupInitialSecurityLevel:initialSecurityLevel inConversation:conversation];
    
    NSUInteger messageCountAfterSetup = conversation.allMessages.count;
    
    // when
    ConversationChangeObserver *observer = [[ConversationChangeObserver alloc] initWithConversation:conversation];
    [observer clearNotifications];
    
    UserClient *selfClient = [ZMUser selfUserInUserSession:self.userSession].selfClient;
    ZMUser *user1 = [self userForMockUser:self.user1];
    
    [self.userSession performChanges:^{
        if (initialSecurityLevel == ZMConversationSecurityLevelSecure) {
            [selfClient ignoreClients:user1.clients];
        } else {
            UserClient *trusted = [user1.clients.allObjects firstObjectMatchingWithBlock:^BOOL(UserClient *obj) {
                return [obj.trustedByClients containsObject:selfClient];
            }];
            if (nil != trusted) {
                [selfClient ignoreClient:trusted];
            }
        }
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    if (shouldChangeSecurityLevel) {
        ConversationChangeInfo *note = observer.notifications.firstObject;
        XCTAssertNotNil(note);
        XCTAssertTrue(note.securityLevelChanged);
    }
    else {
        ConversationChangeInfo *note = observer.notifications.firstObject;
        if (note) {
            XCTAssertFalse(note.securityLevelChanged);
        }
    }
    
    XCTAssertEqual(conversation.securityLevel, expectedSecurityLevel);
    
    if (shouldInsert) {
        __block ZMSystemMessage *systemMessage;
        [[conversation lastMessagesWithLimit:50] enumerateObjectsUsingBlock:^(id  _Nonnull msg, NSUInteger __unused idx, BOOL * _Nonnull stop) {
            if([msg isKindOfClass:ZMSystemMessage.class]) {
                systemMessage = msg;
                *stop = YES;
            }
        }];
        XCTAssertNotNil(systemMessage);
        
        NSArray<ZMUser *> *expectedUsers = @[[self userForMockUser:self.user1]];
        
        AssertArraysContainsSameObjects(systemMessage.users.allObjects, expectedUsers);
        XCTAssertEqual(systemMessage.systemMessageType, ZMSystemMessageTypeIgnoredClient);
    }
    else {
        XCTAssertEqual(messageCountAfterSetup, conversation.allMessages.count);
    }
    
}

- (void)testThatItInsertsIgnoredSystemMessageWhenIgnoringClientFromSecuredConversation;
{
    [self checkThatItShouldInsertIgnoredSystemMessageAfterIgnoring:YES
                                         shouldChangeSecurityLevel:YES
                                           forInitialSecurityLevel:ZMConversationSecurityLevelSecure
                                             expectedSecurityLevel:ZMConversationSecurityLevelSecureWithIgnored];
}


- (void)testThatItDoesNotAppendsIgnoredSytemMessageWhenIgnoringClientFromNotSecuredConversation;
{
    [self checkThatItShouldInsertIgnoredSystemMessageAfterIgnoring:NO
                                         shouldChangeSecurityLevel:NO
                                           forInitialSecurityLevel:ZMConversationSecurityLevelNotSecure
                                             expectedSecurityLevel:ZMConversationSecurityLevelNotSecure];
    
}

- (void)testThatItInsertsSystemMessageWhenAllClientsBecomeTrusted
{
    XCTAssertTrue([self login]);
    
    [self establishSessionWithMockUser:self.user1];
    WaitForAllGroupsToBeEmpty(0.5);
    
    ZMConversation *conversation = [self conversationForMockConversation:self.selfToUser1Conversation];
    ConversationChangeObserver *observer = [[ConversationChangeObserver alloc] initWithConversation:conversation];
    [observer clearNotifications];
    
    // when
    [self makeConversationSecured:conversation];
    
    // then
    XCTAssertEqual(observer.notifications.count, 1u);
    ConversationChangeInfo *note = observer.notifications.firstObject;
    XCTAssertNotNil(note);
    XCTAssertTrue(note.securityLevelChanged);

    XCTAssertEqual(conversation.securityLevel, ZMConversationSecurityLevelSecure);
    
    ZMSystemMessage *lastMessage = (ZMSystemMessage *)conversation.lastMessage;
    XCTAssertTrue([lastMessage isKindOfClass:[ZMSystemMessage class]]);
    
    XCTAssertEqual(lastMessage.systemMessageType, ZMSystemMessageTypeConversationIsSecure);
}

- (void)testThatItInsertsSystemMessageWhenAllSelfUserClientsBecomeTrusted
{
    // given
    XCTAssertTrue([self login]);
    
    [self.mockTransportSession performRemoteChanges:^ (id<MockTransportSessionObjectCreation>  _Nonnull __strong session) {
        [session registerClientForUser:self.selfUser];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    ZMConversation *conversation = [self conversationForMockConversation:self.selfToUser1Conversation];
    [self.userSession performChanges:^{
        [conversation appendText:@"Hey you" mentions:@[] fetchLinkPreview:NO nonce:[NSUUID createUUID]];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    UserClient *selfClient = [ZMUser selfUserInUserSession:self.userSession].selfClient;
    WaitForAllGroupsToBeEmpty(0.5);
    
    ZMUser *user1 = [self userForMockUser:self.user1];
    [self.userSession performChanges:^{
        [selfClient trustClient:user1.clients.anyObject];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    
    NSArray *clients = selfClient.user.clients.allObjects;
    UserClient *otherClient = [clients firstObjectMatchingWithBlock:^BOOL(UserClient *client) {
        return client.remoteIdentifier != selfClient.remoteIdentifier;
    }];
    XCTAssertNotNil(otherClient);
    XCTAssertEqual(conversation.securityLevel, ZMConversationSecurityLevelNotSecure);
    
    ConversationChangeObserver *observer = [[ConversationChangeObserver alloc] initWithConversation:conversation];
    [observer clearNotifications];
    
    // when
    [self.userSession performChanges:^{
        [selfClient trustClient:otherClient];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    XCTAssertEqual(observer.notifications.count, 1u);
    ConversationChangeInfo *note = observer.notifications.firstObject;
    XCTAssertNotNil(note);
    XCTAssertTrue(note.securityLevelChanged);
    
    XCTAssertEqual(conversation.securityLevel, ZMConversationSecurityLevelSecure);
    
    ZMSystemMessage *lastMessage = (ZMSystemMessage *)conversation.lastMessage;
    XCTAssertTrue([lastMessage isKindOfClass:[ZMSystemMessage class]]);
    
    XCTAssertEqual(lastMessage.systemMessageType, ZMSystemMessageTypeConversationIsSecure);
}

- (void)testThatItInsertsSystemMessageWhenTheSelfUserDeletesAnUntrustedClient
{
    // given
    XCTAssertTrue([self login]);
    
    [self.mockTransportSession performRemoteChanges:^ (id<MockTransportSessionObjectCreation>  _Nonnull __strong session) {
        [session registerClientForUser:self.selfUser];
    }];
    WaitForAllGroupsToBeEmpty(0.5);

    ZMConversation *conversation = [self conversationForMockConversation:self.selfToUser1Conversation];
    
    ZMUser *otherUser = [self userForMockUser:self.user1];
    ZMUser *selfUser = [ZMUser selfUserInUserSession:self.userSession];

    XCTAssertEqual(conversation.securityLevel, ZMConversationSecurityLevelNotSecure);

    // (1) trust local client of user1
    {
        // adding a message to fetch client
        [self.userSession performChanges:^{
            [conversation appendText:[NSString stringWithFormat:@"Hey %lu", conversation.allMessages.count] mentions:@[] fetchLinkPreview:YES nonce:[NSUUID createUUID]];
        }];
        WaitForAllGroupsToBeEmpty(0.5);
        
        UserClient *selfClient = selfUser.selfClient;
        
        [self.userSession performChanges:^{
            for (UserClient *client in otherUser.clients) {
                [selfClient trustClient:client];
            }
        }];
        WaitForAllGroupsToBeEmpty(0.5);
        
        // then
        XCTAssertEqual(conversation.securityLevel, ZMConversationSecurityLevelNotSecure); // we do not trust one of our own devices,
    }
    
    NSArray *clients = selfUser.clients.allObjects;
    UserClient *otherSelfClient = [clients firstObjectMatchingWithBlock:^BOOL(UserClient *client) {
        return client.remoteIdentifier != selfUser.selfClient.remoteIdentifier;
    }];

    
    ConversationChangeObserver *observer = [[ConversationChangeObserver alloc] initWithConversation:conversation];
    [observer clearNotifications];
    
    NSUInteger currentMessageCount = conversation.allMessages.count;
    
    // when
    // (2) selfUser deletes remote selfUser client
    {
        [self.userSession performChanges:^{
            [self.userSession deleteClient:otherSelfClient withCredentials:[ZMEmailCredentials credentialsWithEmail:IntegrationTest.SelfUserEmail password:IntegrationTest.SelfUserPassword]];
        }];
        WaitForAllGroupsToBeEmpty(0.5);
        
        // then
        XCTAssertEqual(observer.notifications.count, 1u);
        ConversationChangeInfo *note = observer.notifications.firstObject;
        XCTAssertNotNil(note);
        XCTAssertTrue(note.securityLevelChanged);
        
        XCTAssertEqual(conversation.securityLevel, ZMConversationSecurityLevelSecure);
        if (conversation.allMessages.count > currentMessageCount) {
            ZMSystemMessage *lastMessage = (ZMSystemMessage *)conversation.lastMessage;
            XCTAssertTrue([lastMessage isKindOfClass:[ZMSystemMessage class]]);
            
            XCTAssertEqual(lastMessage.systemMessageType, ZMSystemMessageTypeConversationIsSecure);
        }
        else {
            XCTFail(@"Did not create system message");
        }
    }
}

- (void)testThatItInsertsSystemMessageWhenTheOtherUserDeletesAnUntrustedClient
{
    // given
    XCTAssertTrue([self login]);
    
    ZMConversation *conversation = [self conversationForMockConversation:self.selfToUser1Conversation];
    ZMUser *otherUser = [self userForMockUser:self.user1];
    
    __block NSString *trustedRemoteID;
    // (1) trust local client of user1
    {
        // adding a message
        [self.userSession performChanges:^{
            [conversation appendText:[NSString stringWithFormat:@"Hey %lu", conversation.allMessages.count] mentions:@[] fetchLinkPreview:YES nonce:[NSUUID createUUID]];
        }];
        WaitForAllGroupsToBeEmpty(0.5);
        [self makeConversationSecured:conversation];
        trustedRemoteID = [otherUser.clients.anyObject remoteIdentifier];

        // then
        XCTAssertEqual(otherUser.clients.count, 1u);
        XCTAssertEqual(conversation.securityLevel, ZMConversationSecurityLevelSecure);
    }
    ConversationChangeObserver *observer = [[ConversationChangeObserver alloc] initWithConversation:conversation];
    [observer clearNotifications];
    
    __block MockUserClient *additionalUserClient;
    // (2) insert new client for user 1
    {
        [self.mockTransportSession performRemoteChanges:^ (id<MockTransportSessionObjectCreation>  _Nonnull __strong session) {
            additionalUserClient = [session registerClientForUser:self.user1];
        }];
        WaitForAllGroupsToBeEmpty(0.5);
        
        [self.userSession performChanges:^{
            [otherUser fetchUserClients];
        }];
        WaitForAllGroupsToBeEmpty(0.5);
        XCTAssertEqual(otherUser.clients.count, 2u);
        
        XCTAssertEqual(observer.notifications.count, 1u);
        ConversationChangeInfo *note = observer.notifications.firstObject;
        XCTAssertNotNil(note);
        XCTAssertTrue(note.securityLevelChanged);
        
        XCTAssertEqual(conversation.securityLevel, ZMConversationSecurityLevelSecureWithIgnored);
        
        ZMSystemMessage *lastMessage = (ZMSystemMessage *)conversation.lastMessage;
        XCTAssertTrue([lastMessage isKindOfClass:[ZMSystemMessage class]]);
        
        XCTAssertEqual(lastMessage.systemMessageType, ZMSystemMessageTypeNewClient);
    }
    
    [observer clearNotifications];
    
    
    // (3) remove inserted client for user1
    {
        [self.mockTransportSession performRemoteChanges:^(id<MockTransportSessionObjectCreation>  _Nonnull __strong __unused session) {
            [self.user1.clients removeObject:additionalUserClient];
        }];
        WaitForAllGroupsToBeEmpty(0.5);

        // when
        [self.userSession performChanges:^{
            [otherUser fetchUserClients];
        }];
        WaitForAllGroupsToBeEmpty(0.5);
        XCTAssertEqual(otherUser.clients.count, 1u);
        
        // then
        XCTAssertEqual(observer.notifications.count, 1u);
        ConversationChangeInfo *note = observer.notifications.firstObject;
        XCTAssertNotNil(note);
        XCTAssertTrue(note.securityLevelChanged);
        
        XCTAssertEqual(conversation.securityLevel, ZMConversationSecurityLevelSecure);
        
        ZMSystemMessage *lastMessage = (ZMSystemMessage *)conversation.lastMessage;
        XCTAssertTrue([lastMessage isKindOfClass:[ZMSystemMessage class]]);
        
        XCTAssertEqual(lastMessage.systemMessageType, ZMSystemMessageTypeConversationIsSecure);
    }
}

- (void)testThatItDoesNotSetAllConversationsToSecureWhenTrustingSelfUserClients
{
    // given
    XCTAssertTrue([self login]);
    
    [self.mockTransportSession performRemoteChanges:^ (id<MockTransportSessionObjectCreation>  _Nonnull __strong session) {
        [session registerClientForUser:self.selfUser];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    ZMConversation *conversation1 = [self conversationForMockConversation:self.selfToUser1Conversation];
    ZMConversation *conversation2 = [self conversationForMockConversation:self.selfToUser2Conversation];
    
    [self.userSession performChanges:^{
        [conversation1 appendText:@"Hey!" mentions:@[] fetchLinkPreview:NO nonce:[NSUUID createUUID]];
    }];
    WaitForAllGroupsToBeEmpty(0.5);

    ZMUser *selfUser = [self userForMockUser:self.selfUser];
    ZMUser *user1 = [self userForMockUser:self.user1];

    // when
    [self.userSession performChanges:^{
        for (UserClient *client in selfUser.clients){
            [selfUser.selfClient trustClient:client];
        }
        [selfUser.selfClient trustClient:user1.clients.anyObject];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    XCTAssertEqual(conversation1.securityLevel, ZMConversationSecurityLevelSecure);
    XCTAssertEqual(conversation2.securityLevel, ZMConversationSecurityLevelNotSecure);
}

- (void)testThatItDoesNotSetAllConversationsToSecureWhenDeletingATrustedSelfUserClients
{
    // given
    XCTAssertTrue([self login]);
    
    ZMConversation *conversation1 = [self conversationForMockConversation:self.selfToUser1Conversation];
    [self.userSession performChanges:^{
        // this will eventually create a session with user1.client
        [conversation1 appendText:@"Please establish session" mentions:@[] fetchLinkPreview:NO nonce:[NSUUID createUUID]];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    [self.mockTransportSession performRemoteChanges:^ (id<MockTransportSessionObjectCreation>  _Nonnull __strong session) {
        // this creates an extra client for self user
        [session registerClientForUser:self.selfUser];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    
    ZMUser *selfUser = [self userForMockUser:self.selfUser];
    XCTAssertEqual(selfUser.clients.count, 2u);
    UserClient *notSelfClient = [selfUser.clients.allObjects firstObjectMatchingWithBlock:^BOOL(UserClient *obj) {
       return obj.remoteIdentifier != selfUser.selfClient.remoteIdentifier;
    }];
    ZMUser *user1 = [self userForMockUser:self.user1];
    XCTAssertNotNil(notSelfClient);
    
    // when
    [self.userSession performChanges:^{
        [selfUser.selfClient trustClient:user1.clients.anyObject];
    }];
    WaitForAllGroupsToBeEmpty(1.0);
    
    [self.userSession performChanges:^{
        [self.userSession deleteClient:notSelfClient withCredentials:[ZMEmailCredentials credentialsWithEmail:IntegrationTest.SelfUserEmail password:IntegrationTest.SelfUserPassword]];
    }];
    WaitForAllGroupsToBeEmpty(1.0);
    
    // then
    ZMConversation *conversation2 = [self conversationForMockConversation:self.selfToUser2Conversation];
    XCTAssertEqual(conversation1.securityLevel, ZMConversationSecurityLevelSecure);
    XCTAssertEqual(conversation2.securityLevel, ZMConversationSecurityLevelNotSecure);
}

- (void)testThatItDoesNotSendMessagesWhenThereAreIgnoredClients
{
    // given
    XCTAssertTrue([self login]);

    void (^secureConversationBlock)(ZMConversation *) = ^(ZMConversation *conversation) {
        // send a message to fetch all the missing client
        [self.userSession performChanges:^{
            [conversation appendText:[NSString stringWithFormat:@"Hey %lu", conversation.allMessages.count] mentions:@[] fetchLinkPreview:YES nonce:[NSUUID createUUID]];
        }];
        WaitForAllGroupsToBeEmpty(0.5);
        [self makeConversationSecured:conversation];
        
    };

    ZMConversation *conversation1 = [self conversationForMockConversation:self.selfToUser1Conversation];
    ZMConversation *conversation2 = [self conversationForMockConversation:self.selfToUser2Conversation];
    
    secureConversationBlock(conversation1);
    secureConversationBlock(conversation2);

    ZMUser *user1 = [self userForMockUser:self.user1];
    
    // add additional client for user1 remotely
    [self.mockTransportSession performRemoteChanges:^ (id<MockTransportSessionObjectCreation>  _Nonnull __strong session) {
        [session registerClientForUser:self.user1];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    [self.userSession performChanges:^{
        [user1 fetchUserClients];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    XCTAssertEqual(user1.clients.count, 2u);

    [self.mockTransportSession resetReceivedRequests];
    
    // send a message in the trusted conversation
    [self.userSession performChanges:^{
        [conversation2 appendMessageWithText:@"Hello"];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    XCTAssertEqual(self.mockTransportSession.receivedRequests.count, 1u);
    [self.mockTransportSession resetReceivedRequests];

    // and when sending a message in the not safe conversation
    [self.userSession performChanges:^{
        [conversation1 appendMessageWithText:@"Hello"];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    XCTAssertEqual(self.mockTransportSession.receivedRequests.count, 0u);
}

@end

#pragma mark - Unable to decrypt message
@implementation ConversationTestsOTR (UnableToDecrypt)


- (void)testThatItInsertsASystemMessageWhenItCanNotDecryptAMessage {
    
    // given
    XCTAssertTrue([self login]);
    ZMConversation *conversation = [self conversationForMockConversation:self.selfToUser1Conversation];
    [self establishSessionWithMockUser:self.user1];
    
    // when
    [self performIgnoringZMLogError:^{
        [self.mockTransportSession performRemoteChanges:^(id<MockTransportSessionObjectCreation>  _Nonnull __strong __unused session) {
            [self.selfToUser1Conversation insertOTRMessageFromClient:self.user1.clients.anyObject
                                                            toClient:self.selfUser.clients.anyObject
                                                                data:[@"😱" dataUsingEncoding:NSUTF8StringEncoding]];
        }];

        WaitForAllGroupsToBeEmpty(5);
    }];
    
    // then
    id<ZMConversationMessage> lastMessage = conversation.lastMessage;
    XCTAssertNotNil(lastMessage.systemMessageData);
    XCTAssertEqual(lastMessage.systemMessageData.systemMessageType, ZMSystemMessageTypeDecryptionFailed);
}

- (void)testThatItNotifiesWhenInsertingCannotDecryptMessage {
    
    // given
    XCTAssertTrue([self login]);
    ZMConversation *conversation = [self conversationForMockConversation:self.selfToUser1Conversation];
    [self establishSessionWithMockUser:self.user1];
    
    // expect
    XCTestExpectation *expectation = [self expectationWithDescription:@"It should call the observer"];
    
    id token = [NotificationInContext addObserverWithName:ZMConversation.failedToDecryptMessageNotificationName
                                       context:self.userSession.managedObjectContext.notificationContext
                                        object:nil
                                         queue:nil
                                         using:^(NotificationInContext * note) {
                                             XCTAssertEqualObjects(conversation.remoteIdentifier, [(ZMConversation *)note.object remoteIdentifier]);
                                             XCTAssertNotNil(note.userInfo[@"cause"]);
                                             XCTAssertEqualObjects(note.userInfo[@"cause"], @3);
                                             [expectation fulfill];
                                         }];
    
    // when
    [self performIgnoringZMLogError:^{
        [self.mockTransportSession performRemoteChanges:^(id<MockTransportSessionObjectCreation>  _Nonnull __strong __unused session) {
            [self.selfToUser1Conversation insertOTRMessageFromClient:self.user1.clients.anyObject
                                                            toClient:self.selfUser.clients.anyObject
                                                                data:[@"😱" dataUsingEncoding:NSUTF8StringEncoding]];
        }];

        WaitForAllGroupsToBeEmpty(0.5);
    }];
    
    XCTAssertTrue([self waitForCustomExpectationsWithTimeout:5]);
    
    // then
    token = nil;
}

@end
