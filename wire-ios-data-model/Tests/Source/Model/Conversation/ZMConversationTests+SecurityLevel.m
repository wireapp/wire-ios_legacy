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


#import "ZMConversationTests.h"
#import "ZMConversation+Transport.h"
#import "MessagingTest+EventFactory.h"
@import WireTransport;

@interface ZMConversationSecurityTests : ZMConversationTestsBase

@end

@implementation ZMConversationSecurityTests

- (NSArray<ZMUser *> *)createUsersWithClientsOnSyncMOCWithCount:(NSUInteger)count
{
    self.selfUser = [ZMUser selfUserInContext:self.syncMOC];
    NSMutableArray *users = [NSMutableArray array];
    for (NSUInteger i = 0; i < count; i++) {
        ZMUser *user1 = [ZMUser insertNewObjectInManagedObjectContext:self.syncMOC];
        UserClient *user1Client = [UserClient insertNewObjectInManagedObjectContext:self.syncMOC];
        ZMConnection *user1Connection = [ZMConnection insertNewSentConnectionToUser:user1];
        user1Connection.status = ZMConnectionStatusAccepted;
        user1Client.user = user1;
        [users addObject:user1];
    }
    return users;
}

- (void)testThatConversationInitialSecurityLevelIsNotSecured
{
    [self.syncMOC performGroupedBlockAndWait:^{
        // given
        NSArray *users = [self createUsersWithClientsOnSyncMOCWithCount:2];
        ZMConversation *conversation = [ZMConversation insertGroupConversationIntoManagedObjectContext:self.syncMOC withParticipants:users];
        
        // then
        XCTAssertEqual(conversation.securityLevel, ZMConversationSecurityLevelNotSecure);
    }];
}

- (void)testThatItIncreasesSecurityLevelIfAllClientsInConversationAreTrusted
{
    [self.syncMOC performGroupedBlockAndWait:^{
        // given
        NSArray<ZMUser *> *users = [self createUsersWithClientsOnSyncMOCWithCount:2];
        ZMConversation *conversation = [ZMConversation insertGroupConversationIntoManagedObjectContext:self.syncMOC withParticipants:users];
        UserClient *selfClient = [self createSelfClientOnMOC:self.syncMOC];
        
        // when
        [selfClient trustClients:[NSSet setWithObjects:[[users.firstObject clients] anyObject], [[users.lastObject clients] anyObject], nil]];

        // then
        XCTAssertEqual(conversation.securityLevel, ZMConversationSecurityLevelSecure);
    }];
}

- (void)testThatItDoesNotIncreaseTheSecurityLevelIfAConversationContainsUsersWithoutAConnection
{
    [self.syncMOC performGroupedBlockAndWait:^{
        // given
        NSArray<ZMUser *> *users = [self createUsersWithClientsOnSyncMOCWithCount:2];
        
        ZMUser *unconnectedUser = users.firstObject, *connectedUser = users.lastObject;
        unconnectedUser.connection.status = ZMConnectionStatusSent;
        
        ZMConversation *conversation = [ZMConversation insertGroupConversationIntoManagedObjectContext:self.syncMOC withParticipants:users];
        UserClient *selfClient = [self createSelfClientOnMOC:self.syncMOC];
        
        // when
        [selfClient trustClients:connectedUser.clients];
        
        // then
        XCTAssertFalse(conversation.allUsersTrusted);
        XCTAssertEqual(conversation.securityLevel, ZMConversationSecurityLevelNotSecure);
        
        // when
        unconnectedUser.connection.status = ZMConnectionStatusAccepted;
        [selfClient trustClients:unconnectedUser.clients];
        
        // then
        XCTAssertTrue(conversation.allUsersTrusted);
        XCTAssertEqual(conversation.securityLevel, ZMConversationSecurityLevelSecure);
        
        ZMUser *newUnconnectedUser = [ZMUser insertNewObjectInManagedObjectContext:self.syncMOC];
        UserClient *unconnectedUserClient = [UserClient insertNewObjectInManagedObjectContext:self.syncMOC];
        unconnectedUserClient.user = newUnconnectedUser;
        
        // when adding a new participant
        [conversation internalAddParticipants:@[newUnconnectedUser]];
        
        // then the conversation should degrade
        XCTAssertEqual(conversation.lastServerSyncedActiveParticipants.count, 4);
        XCTAssertEqual(conversation.activeParticipants.count, 4);
        XCTAssertFalse(conversation.allUsersTrusted);
        XCTAssertEqual(conversation.securityLevel, ZMConversationSecurityLevelSecureWithIgnored);
        
        // when
        [conversation internalRemoveParticipants:@[newUnconnectedUser] sender:self.selfUser];

        // then
        XCTAssertEqual(conversation.lastServerSyncedActiveParticipants.count, 2);
        XCTAssertEqual(conversation.activeParticipants.count, 3);
        XCTAssertTrue(conversation.allUsersTrusted);
        XCTAssertEqual(conversation.securityLevel, ZMConversationSecurityLevelSecure);
    }];
}

- (void)testThatItIncreaseTheSecurityLevelIfAConversationContainsUsersWithoutAConnection_Wireless
{
    [self.syncMOC performGroupedBlockAndWait:^{
        // given
        NSArray<ZMUser *> *users = [self createUsersWithClientsOnSyncMOCWithCount:2];
        
        ZMUser *unconnectedUser = users.firstObject, *connectedUser = users.lastObject;
        unconnectedUser.expiresAt = [NSDate dateWithTimeIntervalSinceNow:60];
        unconnectedUser.connection = nil;
        
        XCTAssertTrue(unconnectedUser.isWirelessUser);
        XCTAssertFalse(unconnectedUser.isConnected);
        XCTAssertNil(unconnectedUser.team);
        
        ZMConversation *conversation = [ZMConversation insertGroupConversationIntoManagedObjectContext:self.syncMOC withParticipants:users];
        UserClient *selfClient = [self createSelfClientOnMOC:self.syncMOC];
        
        // when
        [selfClient trustClients:connectedUser.clients];
        [selfClient trustClients:unconnectedUser.clients];

        // then
        XCTAssertTrue(conversation.allUsersTrusted);
        XCTAssertEqual(conversation.securityLevel, ZMConversationSecurityLevelSecure);
    }];
}

- (void)testThatItDoesDecreaseTheSecurityLevelWhenAskedToMakeNotSecure
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.conversationType = ZMConversationTypeOneOnOne;
    conversation.securityLevel = ZMConversationSecurityLevelSecureWithIgnored;
    
    // when
    [conversation acknowledgePrivacyWarningWithResendIntent:NO];
    
    // then
    XCTAssertEqual(conversation.securityLevel, ZMConversationSecurityLevelNotSecure);
}

- (void)testThatItInsertsAnIgnoredClientsSystemMessageWhenAddingAConversationParticipantInASecuredConversation
{
    [self.syncMOC performGroupedBlockAndWait:^{
        // given
        NSArray<ZMUser *> *users = [self createUsersWithClientsOnSyncMOCWithCount:2];
        
        ZMConversation *conversation = [ZMConversation insertGroupConversationIntoManagedObjectContext:self.syncMOC withParticipants:users];
        UserClient *selfClient = [self createSelfClientOnMOC:self.syncMOC];
        
        // when
        [selfClient trustClients:users.firstObject.clients];
        [selfClient trustClients:users.lastObject.clients];

        // then
        XCTAssertTrue(conversation.allUsersTrusted);
        XCTAssertEqual(conversation.securityLevel, ZMConversationSecurityLevelSecure);
        
        // when adding a new participant
        ZMUser *user3 = [self createUsersWithClientsOnSyncMOCWithCount:1].lastObject;
        [conversation internalAddParticipants:@[user3]];
        
        // then the conversation should degrade
        XCTAssertFalse(conversation.allUsersTrusted);
        XCTAssertEqual(conversation.securityLevel, ZMConversationSecurityLevelSecureWithIgnored);
        
        // Conversation degraded message
        ZMSystemMessage *conversationDegradedMessage = (ZMSystemMessage *)conversation.lastMessage;
        XCTAssertEqual(conversationDegradedMessage.systemMessageType, ZMSystemMessageTypeNewClient);
        XCTAssertEqualObjects(conversationDegradedMessage.addedUsers, [NSSet setWithObject:user3]);
        XCTAssertEqualObjects(conversationDegradedMessage.users, [NSSet setWithObject:user3]);
        
        // when
        [conversation internalRemoveParticipants:@[user3] sender:self.selfUser];
        
        // then
        XCTAssertTrue(conversation.allUsersTrusted);
        XCTAssertEqual(conversation.securityLevel, ZMConversationSecurityLevelSecure);
        ZMSystemMessage *message2 = (ZMSystemMessage *)conversation.lastMessage;
        XCTAssertEqual(message2.systemMessageType, ZMSystemMessageTypeConversationIsSecure);
    }];
}

- (void)testThatItDoesNotIncreaseSecurityLevelIfNotAllClientsAreTrusted
{
    [self.syncMOC performGroupedBlockAndWait:^{
        // given
        NSArray<ZMUser *> *users = [self createUsersWithClientsOnSyncMOCWithCount:2];
        ZMConversation *conversation = [ZMConversation insertGroupConversationIntoManagedObjectContext:self.syncMOC withParticipants:users];
        UserClient *selfClient = [self createSelfClientOnMOC:self.syncMOC];
        
        // when
        [selfClient trustClients:[NSSet setWithObjects:[[users.firstObject clients] anyObject], nil]];

        // then
        XCTAssertEqual(conversation.securityLevel, ZMConversationSecurityLevelNotSecure);
    }];
}

- (void)testThatItDoesNotIncreaseSecurityLevelIfNotAllUsersHaveClients
{
    [self.syncMOC performGroupedBlockAndWait:^{
        // given
        ZMUser *userWithoutClients = [ZMUser insertNewObjectInManagedObjectContext:self.syncMOC];
        NSArray<ZMUser *> *users = [[self createUsersWithClientsOnSyncMOCWithCount:2] arrayByAddingObject:userWithoutClients];
        ZMConversation *conversation = [ZMConversation insertGroupConversationIntoManagedObjectContext:self.syncMOC withParticipants:users];
        UserClient *selfClient = [self createSelfClientOnMOC:self.syncMOC];
        
        NSMutableSet *allClients = [NSMutableSet set];
        for(ZMUser *user in users) {
            for(UserClient *client in user.clients) {
                [allClients addObject:client];
            }
        }
        
        // when
        [selfClient trustClients:allClients];
        
        // then
        XCTAssertEqual(conversation.securityLevel, ZMConversationSecurityLevelNotSecure);
    }];
}

- (void)testThatItDecreaseSecurityLevelIfSomeOfTheClientsIsIgnored
{
    [self.syncMOC performGroupedBlockAndWait:^{
        // given
        NSArray<ZMUser *> *users = [self createUsersWithClientsOnSyncMOCWithCount:2];
        ZMConversation *conversation = [ZMConversation insertGroupConversationIntoManagedObjectContext:self.syncMOC withParticipants:users];
        UserClient *selfClient = [self createSelfClientOnMOC:self.syncMOC];
        
        // when
        [selfClient trustClients:[NSSet setWithObjects:[[users.firstObject clients] anyObject], [[users.lastObject clients] anyObject], nil]];
        [selfClient ignoreClients:[NSSet setWithObjects:[[users.firstObject clients] anyObject], nil]];
        
        // then
        XCTAssertEqual(conversation.securityLevel, ZMConversationSecurityLevelSecureWithIgnored);
    }];
}

- (void)testThatItDoesNotDecreaseSecurityLevelIfItIsInPartialSecureLevel
{
    [self.syncMOC performGroupedBlockAndWait:^{
        // given
        NSArray<ZMUser *> *users = [self createUsersWithClientsOnSyncMOCWithCount:2];
        ZMConversation *conversation = [ZMConversation insertGroupConversationIntoManagedObjectContext:self.syncMOC withParticipants:users];
        UserClient *selfClient = [self createSelfClientOnMOC:self.syncMOC];
        
        // when
        [selfClient trustClients:[NSSet setWithObjects:[[users.firstObject clients] anyObject], [[users.lastObject clients] anyObject], nil]];
        [selfClient ignoreClient:users.firstObject.clients.anyObject];
        
        // then
        XCTAssertEqual(conversation.securityLevel, ZMConversationSecurityLevelSecureWithIgnored);
        
        // and when
        [selfClient ignoreClient:users.lastObject.clients.anyObject];
        
        // then we should not change the security level as we were already ignored
        XCTAssertEqual(conversation.securityLevel, ZMConversationSecurityLevelSecureWithIgnored);
    }];
}

- (void)testThatItCorrectlySetsNeedUpdatingUsersFlagOnPotentialGapSystemMessage
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.remoteIdentifier = NSUUID.createUUID;
    [conversation appendNewPotentialGapSystemMessageWithUsers:nil timestamp:[NSDate date]];

    // then
    ZMSystemMessage *fetchedMessage = [ZMSystemMessage fetchLatestPotentialGapSystemMessageInConversation:conversation];
    XCTAssertEqual(conversation.allMessages.count, 1lu);
    XCTAssertNotNil(fetchedMessage);
    XCTAssertTrue(fetchedMessage.needsUpdatingUsers);
    
    // when
    [conversation updatePotentialGapSystemMessagesIfNeededWithUsers:nil];
    
    // then
    XCTAssertFalse(fetchedMessage.needsUpdatingUsers);
    fetchedMessage = [ZMSystemMessage fetchLatestPotentialGapSystemMessageInConversation:conversation];
    XCTAssertEqual(conversation.allMessages.count, 1lu);
    XCTAssertNil(fetchedMessage);
}

- (void)testThatItNotifiesWhenAllClientAreVerified;
{
    __block NSManagedObjectID *conversationObjectID = nil;
    __block id token = nil;
    [self.syncMOC performGroupedBlockAndWait:^{
        // given
        NSArray<ZMUser *> *users = [self createUsersWithClientsOnSyncMOCWithCount:2];
        ZMConversation *conversation = [ZMConversation insertGroupConversationIntoManagedObjectContext:self.syncMOC withParticipants:users];
        UserClient *selfClient = [self createSelfClientOnMOC:self.syncMOC];
        
        // expect
        XCTestExpectation *expectation = [self expectationWithDescription:@"Notified"];
        token = [NotificationInContext addObserverWithName:ZMConversation.isVerifiedNotificationName
                                                      context:self.uiMOC.notificationContext
                                                       object:nil
                                                        queue:nil
                                                        using:^(NotificationInContext * notification) {
                                                            XCTAssertEqualObjects(notification.object, conversation);
                                                            [expectation fulfill];
                                                        }];

        
        // when
        XCTAssertNotEqual(conversation.securityLevel, ZMConversationSecurityLevelSecure);
        [selfClient trustClients:[NSSet setWithObjects:[[users.firstObject clients] anyObject], [[users.lastObject clients] anyObject], nil]];
        
        conversationObjectID = conversation.objectID;
        [self.syncMOC saveOrRollback];
    }];

    // then
    ZMConversation *uiConversation = [self.uiMOC existingObjectWithID:conversationObjectID error:nil];
    XCTAssertEqual(uiConversation.securityLevel, ZMConversationSecurityLevelSecure);
    XCTAssertTrue([self waitForCustomExpectationsWithTimeout:0.5]);
    token = nil;
}

- (void)testThatIncreasesSecurityLevelOfCreatedGroupConversationWithAllParticipantsAlreadyTrusted
{
    
    [self.syncMOC performGroupedBlockAndWait:^{
        // given
        NSArray <ZMUser *> *users = [self createUsersWithClientsOnSyncMOCWithCount:2];
        NSSet *clients = [users.firstObject.clients setByAddingObjectsFromSet:users.lastObject.clients];
        UserClient *selfClient = [self createSelfClientOnMOC:self.syncMOC];
        [selfClient trustClients:clients];
        
        // when
        ZMConversation *conversation = [ZMConversation insertGroupConversationIntoManagedObjectContext:self.syncMOC withParticipants:users];

        // then
        XCTAssertEqual(conversation.securityLevel, ZMConversationSecurityLevelSecure);
        ZMMessage *message = conversation.lastMessage;
        XCTAssertNotNil(message);
        XCTAssertTrue([message isKindOfClass:[ZMSystemMessage class]]);
        XCTAssertEqual(message.systemMessageData.systemMessageType, ZMSystemMessageTypeConversationIsSecure);
        XCTAssertEqualObjects(message.systemMessageData.clients, [clients setByAddingObject:selfClient]);
    }];
    
    XCTAssertTrue([self waitForCustomExpectationsWithTimeout:0.5]);
}

- (void)testThatItDoesNotIncreaseSecurityLevelOfCreatedGroupConversationWithAllParticipantsIfNotAlreadyTrusted
{
    [self.syncMOC performGroupedBlockAndWait:^{
        // given
        NSArray <ZMUser *> *users = [self createUsersWithClientsOnSyncMOCWithCount:2];
        UserClient *selfClient = [self createSelfClientOnMOC:self.syncMOC];
        [selfClient trustClients:users.firstObject.clients];
        
        // when
        ZMConversation *conversation = [ZMConversation insertGroupConversationIntoManagedObjectContext:self.syncMOC withParticipants:users];
        
        // then
        XCTAssertEqual(conversation.securityLevel, ZMConversationSecurityLevelNotSecure);
        ZMSystemMessage *message = (ZMSystemMessage *)conversation.lastMessage;
        XCTAssertNotEqual(message.systemMessageType, ZMSystemMessageTypeConversationIsSecure);
    }];
    
    XCTAssertTrue([self waitForCustomExpectationsWithTimeout:0.5]);
}

- (ZMUser *)insertUserInConversation:(ZMConversation *)conversation userIsTrusted:(BOOL)trusted managedObjectContext:(NSManagedObjectContext *)moc
{
    [self createSelfClient];
    [self.uiMOC refreshAllObjects];
    
    UserClient *selfClient = [ZMUser selfUserInContext:moc].selfClient;
    ZMUser *user = [ZMUser insertNewObjectInManagedObjectContext:moc];
    [conversation addWithUser:user isFromLocal:NO];
    UserClient *client = [UserClient insertNewObjectInManagedObjectContext:moc];
    client.user  = user;
    if (trusted) {
        [selfClient trustClient:client];
    } else {
        [selfClient ignoreClient:client];
    }
    return user;
}

- (void)testThatItReturns_HasUntrustedClients_YES_ifThereAreUntrustedClients
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.conversationType = ZMConversationTypeGroup;

    // when
    [self insertUserInConversation:conversation userIsTrusted:NO managedObjectContext:self.uiMOC];
    BOOL hasUntrustedClients = conversation.hasUntrustedClients;
    
    // then
    XCTAssertTrue(hasUntrustedClients);

}

- (void)testThatItReturns_HasUntrustedClients_NO_ifThereAreNoUntrustedClients
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.conversationType = ZMConversationTypeGroup;
    
    // when
    [self insertUserInConversation:conversation userIsTrusted:YES managedObjectContext:self.uiMOC];
    BOOL hasUntrustedClients = conversation.hasUntrustedClients;
    
    // then
    XCTAssertFalse(hasUntrustedClients);
}

- (void)testThatItReturns_HasUntrustedClients_NO_ifThereAreNoOtherClients
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.conversationType = ZMConversationTypeGroup;
    ZMUser *user = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    [conversation addWithUser:user isFromLocal:NO];

    // when
    BOOL hasUntrustedClients = conversation.hasUntrustedClients;
    
    // then
    XCTAssertFalse(hasUntrustedClients);
}


- (void)testThatItReturns_HasUntrustedClients_NO_ifThereAreNoOtherUsers
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.conversationType = ZMConversationTypeGroup;
    
    // when
    BOOL hasUntrustedClients = conversation.hasUntrustedClients;
    
    // then
    XCTAssertFalse(hasUntrustedClients);
}

- (void)testThatSystemMessageAppendedToAEmptyConversationStillHasATimestamp
{
    // given
    [self createSelfClient];
    [self.uiMOC refreshAllObjects];
    
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.conversationType = ZMConversationTypeGroup;
    conversation.lastModifiedDate = [NSDate new];
    
    // when
    [conversation appendStartedUsingThisDeviceMessage];
    
    // then
    ZMSystemMessage *message = (ZMSystemMessage *)conversation.lastMessage;
    XCTAssertNotNil(message.serverTimestamp);
}

- (void)testThatItAppendsASystemMessageOfTypeRemoteIDChangedForCBErrorCodeRemoteIdentityChanged
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.conversationType = ZMConversationTypeGroup;
    ZMUser *user = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    user.name = @"Fancy One";
    
    // when
    [conversation appendDecryptionFailedSystemMessageAtTime:[NSDate date] sender:user client:nil errorCode:CBOX_REMOTE_IDENTITY_CHANGED];
    
    // then
    ZMSystemMessage *lastMessage = (ZMSystemMessage *)conversation.lastMessage;
    XCTAssertEqual(lastMessage.systemMessageType, ZMSystemMessageTypeDecryptionFailed_RemoteIdentityChanged);
}

- (void)testThatItAppendsASystemMessageOfGeneralTypeForCBErrorCodeInvalidMessage
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.conversationType = ZMConversationTypeGroup;
    ZMUser *user = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    user.name = @"Fancy One";
    
    // when
    [conversation appendDecryptionFailedSystemMessageAtTime:[NSDate date] sender:user client:nil errorCode:CBOX_INVALID_MESSAGE];
    
    // then
    ZMSystemMessage *lastMessage = (ZMSystemMessage *)conversation.lastMessage;
    XCTAssertEqual(lastMessage.systemMessageType, ZMSystemMessageTypeDecryptionFailed);
}

- (void)testThatContinuedUsingDeviceSystemMessageAppendedAfterLastMessage
{
    // given
    [self createSelfClient];
    [self.uiMOC refreshAllObjects];
    
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.conversationType = ZMConversationTypeGroup;
    conversation.lastModifiedDate = [NSDate new];
    ZMMessage *previousMessage = (id)[conversation appendMessageWithText:@"test"];
    
    // when
    [conversation appendContinuedUsingThisDeviceMessage];
    
    // then
    ZMSystemMessage *message = (ZMSystemMessage *)conversation.lastMessage;
    XCTAssertNotNil(message.serverTimestamp);
    XCTAssertLessThan([previousMessage.serverTimestamp timeIntervalSince1970], [message.serverTimestamp timeIntervalSince1970]);
    XCTAssertEqualWithAccuracy([[NSDate date] timeIntervalSince1970], [message.serverTimestamp timeIntervalSince1970], 1.0);

}

- (void)testThatAConversationIsNotTrustedIfItHasNoOtherParticipants
{
    // GIVEN
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.conversationType = ZMConversationTypeGroup;
    
    // THEN
    XCTAssertFalse(conversation.allUsersTrusted);
}

- (void)testThatAConversationIsTrustedIfItHasTeamUsers
{
    [self.syncMOC performGroupedBlockAndWait:^{
        // GIVEN
        ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.syncMOC];
        conversation.conversationType = ZMConversationTypeGroup;
        
        ZMUser *selfUser = [ZMUser selfUserInContext:self.syncMOC];
        [conversation addWithUser:selfUser isFromLocal:YES];
        
        Team *mainTeam = [Team fetchOrCreateTeamWithRemoteIdentifier:[[NSUUID alloc] init]
                                                      createIfNeeded:YES
                                                           inContext:self.syncMOC
                                                             created:NULL];
        
        ZM_UNUSED Member *selfMembership = [Member getOrCreateMemberForUser:selfUser inTeam:mainTeam context:self.syncMOC];
        // WHEN
        ZMUser *user = [self insertUserInConversation:conversation userIsTrusted:YES managedObjectContext:self.syncMOC];
        ZM_UNUSED Member *userMembership = [Member getOrCreateMemberForUser:user inTeam:mainTeam context:self.syncMOC];
        // THEN
        XCTAssertTrue(conversation.allUsersTrusted);
    }];
}

- (void)testThatAConversationIsNotTrustedIfItExternalUsers
{
    [self.syncMOC performGroupedBlockAndWait:^{
        // GIVEN
        ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.syncMOC];
        conversation.conversationType = ZMConversationTypeGroup;
        
        ZMUser *selfUser = [ZMUser selfUserInContext:self.syncMOC];
        
        Team *mainTeam = [Team fetchOrCreateTeamWithRemoteIdentifier:[[NSUUID alloc] init]
                                                      createIfNeeded:YES
                                                           inContext:self.syncMOC
                                                             created:NULL];
        
        ZM_UNUSED Member *selfMembership = [Member getOrCreateMemberForUser:selfUser inTeam:mainTeam context:self.syncMOC];
        // WHEN
        ZM_UNUSED ZMUser *user = [self insertUserInConversation:conversation userIsTrusted:YES managedObjectContext:self.syncMOC];

        // THEN
        XCTAssertFalse(conversation.allUsersTrusted);
    }];
}

- (void)testThatAConversationIsNotTrustedIfNotAMemberAnymore
{
    // GIVEN
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.conversationType = ZMConversationTypeGroup;
    ZMUser *otherUser = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    [conversation internalAddParticipants:@[otherUser]];
    UserClient *client = [UserClient insertNewObjectInManagedObjectContext:self.uiMOC];
    client.user = otherUser;
    ZMUser *selfUser = [ZMUser selfUserInContext:self.uiMOC];
    [[selfUser selfClient] trustClient:client];
    
    // WHEN
    [conversation internalRemoveParticipants:@[selfUser] sender:otherUser];
    
    // THEN
    XCTAssertFalse(conversation.allUsersTrusted);
}

@end

#pragma mark - Resending / cancelling messages in degraded conversation
@implementation ZMConversationSecurityTests (ResendingMessages)

- (void)testItExpiresAllMessagesAfterTheCurrentOneWhenAUserCausesDegradation
{
    [self.syncMOC performGroupedBlockAndWait:^{
        
        // GIVEN
        [self createSelfClient];
        ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.syncMOC];
        conversation.conversationType = ZMConversationTypeGroup;
        conversation.securityLevel = ZMConversationSecurityLevelSecure;
        
        ZMUser *user = [ZMUser insertNewObjectInManagedObjectContext:self.syncMOC];
        [conversation addWithUser:user isFromLocal:NO];
        
        ZMOTRMessage *message1 = (ZMOTRMessage *)[conversation appendMessageWithImageData:[self verySmallJPEGData]];
        [NSThread sleepForTimeInterval:0.05]; // cause system time to advance
        ZMOTRMessage *message2 = (ZMOTRMessage *)[conversation appendMessageWithText:@"foo 2" fetchLinkPreview:NO];
        
        UserClient *client = [UserClient insertNewObjectInManagedObjectContext:self.syncMOC];
        client.remoteIdentifier = @"aabbccdd";
        client.user = user;
        
        // WHEN
        [conversation decreaseSecurityLevelIfNeededAfterDiscoveringClients:[NSSet setWithObject:client] causedByAddedUsers:[NSSet setWithObject:user]];
        
        // THEN
        XCTAssertTrue(message1.isExpired);
        XCTAssertTrue(message1.causedSecurityLevelDegradation);
        XCTAssertTrue(message2.isExpired);
        XCTAssertTrue(message2.causedSecurityLevelDegradation);
        XCTAssertFalse(conversation.allUsersTrusted);
        XCTAssertEqual(conversation.securityLevel, ZMConversationSecurityLevelSecureWithIgnored);
    }];
}

- (void)testItExpiresAllMessagesAfterTheCurrentOneWhenAMessageCausesDegradation
{
    [self.syncMOC performGroupedBlockAndWait:^{
        
        // GIVEN
        [self createSelfClient];
        ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.syncMOC];
        conversation.conversationType = ZMConversationTypeGroup;
        ZMUser *user = [self insertUserInConversation:conversation userIsTrusted:YES managedObjectContext:self.syncMOC];
        conversation.securityLevel = ZMConversationSecurityLevelSecure;
        
        ZMOTRMessage *message1 = (ZMOTRMessage *)[conversation appendMessageWithImageData:[self verySmallJPEGData]];
        [NSThread sleepForTimeInterval:0.05]; // cause system time to advance
        ZMOTRMessage *message2 = (ZMOTRMessage *)[conversation appendMessageWithText:@"foo 2" fetchLinkPreview:NO];
        [NSThread sleepForTimeInterval:0.05]; // cause system time to advance
        ZMOTRMessage *message3 = (ZMOTRMessage *)[conversation appendMessageWithText:@"foo 3" fetchLinkPreview:NO];
        [NSThread sleepForTimeInterval:0.05]; // cause system time to advance
        ZMOTRMessage *message4 = (ZMOTRMessage *)[conversation appendMessageWithText:@"foo 4" fetchLinkPreview:NO];
        [NSThread sleepForTimeInterval:0.05]; // cause system time to advance
        ZMOTRMessage *message5 = (ZMOTRMessage *)[conversation appendMessageWithImageData:[self verySmallJPEGData]];
        
        
        UserClient *client = [UserClient insertNewObjectInManagedObjectContext:self.syncMOC];
        client.remoteIdentifier = @"aabbccdd";
        client.user = user;
        
        // WHEN
        [conversation decreaseSecurityLevelIfNeededAfterDiscoveringClients:[NSSet setWithObject:client] causedByMessage:message3];
        
        // THEN
        XCTAssertTrue(message1.isExpired);
        XCTAssertTrue(message1.causedSecurityLevelDegradation);
        XCTAssertTrue(message2.isExpired);
        XCTAssertTrue(message2.causedSecurityLevelDegradation);
        XCTAssertTrue(message3.isExpired);
        XCTAssertTrue(message3.causedSecurityLevelDegradation);
        XCTAssertTrue(message4.isExpired);
        XCTAssertTrue(message4.causedSecurityLevelDegradation);
        XCTAssertTrue(message5.isExpired);
        XCTAssertTrue(message5.causedSecurityLevelDegradation);
        XCTAssertFalse(conversation.allUsersTrusted);
        XCTAssertEqual(conversation.securityLevel, ZMConversationSecurityLevelSecureWithIgnored);
    }];
}

- (void)testItCancelsAllMessagesThatCausedDegradation
{
    __block ZMConversation *conversation;
    __block ZMOTRMessage *message1;
    __block ZMOTRMessage *message2;
    __block ZMOTRMessage *message3;
    [self.syncMOC performGroupedBlockAndWait:^{
        
        // GIVEN
        [self createSelfClient];
        conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.syncMOC];
        conversation.conversationType = ZMConversationTypeGroup;
        ZMUser *user = [self insertUserInConversation:conversation userIsTrusted:YES managedObjectContext:self.syncMOC];
        conversation.securityLevel = ZMConversationSecurityLevelSecure;
        
        message1 = (ZMOTRMessage *)[conversation appendMessageWithText:@"foo 2" fetchLinkPreview:NO];
        [NSThread sleepForTimeInterval:0.05]; // cause system time to advance
        message2 = (ZMOTRMessage *)[conversation appendMessageWithText:@"foo 3" fetchLinkPreview:NO];
        [NSThread sleepForTimeInterval:0.05]; // cause system time to advance
        message3 = (ZMOTRMessage *)[conversation appendMessageWithImageData:[self verySmallJPEGData]];
        
        
        UserClient *client = [UserClient insertNewObjectInManagedObjectContext:self.syncMOC];
        client.remoteIdentifier = @"aabbccdd";
        client.user = user;
        [conversation decreaseSecurityLevelIfNeededAfterDiscoveringClients:[NSSet setWithObject:client] causedByMessage:message2];
        [self.syncMOC saveOrRollback];
    }];
    
    // WHEN
    ZMConversation *uiConversation = (ZMConversation *)[self.uiMOC existingObjectWithID:conversation.objectID error:nil];
    [uiConversation acknowledgePrivacyWarningWithResendIntent:NO];
    
    [self.syncMOC performGroupedBlockAndWait:^{
        
        // THEN
        XCTAssertTrue(message1.isExpired);
        XCTAssertFalse(message1.causedSecurityLevelDegradation);
        XCTAssertTrue(message2.isExpired);
        XCTAssertFalse(message2.causedSecurityLevelDegradation);
        XCTAssertEqual(message2.deliveryState, ZMDeliveryStateFailedToSend);
        XCTAssertTrue(message3.isExpired);
        XCTAssertFalse(message3.causedSecurityLevelDegradation);
        XCTAssertEqual(message3.deliveryState, ZMDeliveryStateFailedToSend);
        XCTAssertFalse(conversation.allUsersTrusted);
        XCTAssertEqual(conversation.securityLevel, ZMConversationSecurityLevelNotSecure);
    }];
}

- (void)testItMarksConversationAsNotSecureAfterResendMessages
{
    __block ZMConversation *conversation;
    [self.syncMOC performGroupedBlockAndWait:^{
        // GIVEN
        conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.syncMOC];
        conversation.conversationType = ZMConversationTypeGroup;
        conversation.securityLevel = ZMConversationSecurityLevelSecureWithIgnored;
        [self.syncMOC saveOrRollback];
    }];
    
    // WHEN
    ZMConversation *uiConversation = (ZMConversation *)[self.uiMOC existingObjectWithID:conversation.objectID error:nil];
    [uiConversation acknowledgePrivacyWarningWithResendIntent:YES];
    [self.uiMOC saveOrRollback];
    [self.syncMOC performGroupedBlockAndWait:^{
        [self.syncMOC refreshAllObjects];
        
        // THEN
        XCTAssertEqual(conversation.securityLevel, ZMConversationSecurityLevelNotSecure);
    }];
}

- (void)testItResendsAllMessagesThatCausedDegradation
{
    __block ZMConversation *conversation;
    __block ZMOTRMessage *message1;
    __block ZMOTRMessage *message2;
    __block ZMOTRMessage *message3;
    [self.syncMOC performGroupedBlockAndWait:^{
        
        // GIVEN
        [self createSelfClient];
        conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.syncMOC];
        conversation.conversationType = ZMConversationTypeGroup;
        ZMUser *user = [self insertUserInConversation:conversation userIsTrusted:YES managedObjectContext:self.syncMOC];
        conversation.securityLevel = ZMConversationSecurityLevelSecure;
        
        message1 = (ZMOTRMessage *)[conversation appendMessageWithText:@"foo 2" fetchLinkPreview:NO];
        [NSThread sleepForTimeInterval:0.05]; // cause system time to advance
        message2 = (ZMOTRMessage *)[conversation appendMessageWithText:@"foo 3" fetchLinkPreview:NO];
        [NSThread sleepForTimeInterval:0.05]; // cause system time to advance
        message3 = (ZMOTRMessage *)[conversation appendMessageWithImageData:[self verySmallJPEGData]];
        
        
        UserClient *client = [UserClient insertNewObjectInManagedObjectContext:self.syncMOC];
        client.remoteIdentifier = @"aabbccdd";
        client.user = user;
        [conversation decreaseSecurityLevelIfNeededAfterDiscoveringClients:[NSSet setWithObject:client] causedByMessage:message2];
        [self.syncMOC saveOrRollback];
        
        XCTAssertTrue(message1.isExpired);
        XCTAssertTrue(message1.causedSecurityLevelDegradation);
        XCTAssertTrue(message2.isExpired);
        XCTAssertTrue(message2.causedSecurityLevelDegradation);
        XCTAssertTrue(message3.isExpired);
        XCTAssertTrue(message3.causedSecurityLevelDegradation);
    }];
    
    // WHEN
    ZMConversation *uiConversation = (ZMConversation *)[self.uiMOC existingObjectWithID:conversation.objectID error:nil];
    [uiConversation acknowledgePrivacyWarningWithResendIntent:YES];
    
    [self.syncMOC performGroupedBlockAndWait:^{
        
        // THEN
        XCTAssertFalse(message1.isExpired);
        XCTAssertFalse(message1.causedSecurityLevelDegradation);
        XCTAssertFalse(message2.isExpired);
        XCTAssertFalse(message3.causedSecurityLevelDegradation);
        XCTAssertEqual(message2.deliveryState, ZMDeliveryStatePending);
        XCTAssertFalse(message3.isExpired);
        XCTAssertFalse(message3.causedSecurityLevelDegradation);
        XCTAssertEqual(message3.deliveryState, ZMDeliveryStatePending);
        XCTAssertFalse(conversation.allUsersTrusted);
        XCTAssertNotEqual(conversation.securityLevel, ZMConversationSecurityLevelSecure);
    }];
}

@end

#pragma mark - Hotfix
@implementation ZMConversationSecurityTests (HotFix)

- (void)testThatItUpdatesFirstNewClientSystemMessage
{
    // given
    [self createSelfClient];
    [self.uiMOC refreshAllObjects];
    
    ZMUser *selfUser = [ZMUser selfUserInContext:self.uiMOC];
    UserClient *selfClient = selfUser.selfClient;
    XCTAssertNotNil(selfClient);
    
    ZMConversation *conv = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conv.conversationType = ZMConversationTypeOneOnOne;
    
    ZMSystemMessage *systemMessage = [[ZMSystemMessage alloc] initWithNonce:NSUUID.createUUID managedObjectContext:self.uiMOC];
    systemMessage.visibleInConversation = conv;
    systemMessage.systemMessageType = ZMSystemMessageTypeNewClient;
    systemMessage.sender = selfUser;
    systemMessage.clients = [NSSet setWithObject:selfClient];
    systemMessage.serverTimestamp = [NSDate date];
    
    // when
    [conv replaceNewClientMessageIfNeededWithNewDeviceMesssage];
    
    // then
    XCTAssertEqual(systemMessage.systemMessageType, ZMSystemMessageTypeUsingNewDevice);
}

@end

@interface ZMConversationSecurityTests (AddRemoveParticipant)

@end

@implementation ZMConversationSecurityTests (AddRemoveParticipant)

// Adding participants

- (ZMSystemMessage *)simulateAdding:(NSSet<ZMUser *>*)usersToAdd to:(ZMConversation *)conv by:(ZMUser *)actionUser
{
    NSSet *userIDs = [usersToAdd mapWithBlock:^NSString *(ZMUser *user) {
        return user.remoteIdentifier.transportString;
    }];
    
    NSDictionary *data = @{@"user_ids": userIDs.allObjects};
    NSDictionary *payload = [self payloadForMessageInConversation:conv type:EventConversationMemberJoin data:data time:[NSDate date] fromUser:actionUser];
    ZMUpdateEvent *event = [ZMUpdateEvent eventFromEventStreamPayload:payload uuid:nil];
    __block ZMSystemMessage *result = nil;
    [self performPretendingUiMocIsSyncMoc:^{
        [usersToAdd enumerateObjectsUsingBlock:^(ZMUser * _Nonnull obj, BOOL * _Nonnull stop __unused) {
            [conv addWithUser:obj isFromLocal:NO];
        }];
        result = [ZMSystemMessage createOrUpdateMessageFromUpdateEvent:event
                                                inManagedObjectContext:conv.managedObjectContext
                                                        prefetchResult:nil];
    }];

    return result;
}

- (ZMSystemMessage *)simulateRemoving:(NSSet<ZMUser *>*)usersToRemove from:(ZMConversation *)conv by:(ZMUser *)actionUser
{
    NSSet *userIDs = [usersToRemove mapWithBlock:^NSString *(ZMUser *user) {
        return user.remoteIdentifier.transportString;
    }];
    
    NSDictionary *data = @{@"user_ids": userIDs.allObjects};
    NSDictionary *payload = [self payloadForMessageInConversation:conv type:EventConversationMemberLeave data:data time:[NSDate date] fromUser:actionUser];
    ZMUpdateEvent *event = [ZMUpdateEvent eventFromEventStreamPayload:payload uuid:nil];
    __block ZMSystemMessage *result = nil;
    [self performPretendingUiMocIsSyncMoc:^{
        [usersToRemove enumerateObjectsUsingBlock:^(ZMUser * _Nonnull obj, BOOL * _Nonnull stop __unused) {
            [conv minusWithUserSet: [NSSet setWithObject:obj] isFromLocal:NO];
        }];
        result = [ZMSystemMessage createOrUpdateMessageFromUpdateEvent:event
                                                inManagedObjectContext:conv.managedObjectContext
                                                        prefetchResult:nil];
    }];
    
    return result;
}

- (ZMConversation *)setupVerifiedConversation
{
    ZMUser *selfUser = [ZMUser selfUserInContext:self.uiMOC];
    selfUser.remoteIdentifier = [NSUUID new];
    UserClient *selfClient = [self createSelfClientOnMOC:self.uiMOC];
    
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.conversationType = ZMConversationTypeGroup;
    conversation.remoteIdentifier = [NSUUID new];
    [conversation addWithUser:selfUser isFromLocal:YES];
    
    ZMUser *verifiedUser = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    verifiedUser.remoteIdentifier = [NSUUID new];
    ZMConnection *verifiedUserConnection = [ZMConnection insertNewSentConnectionToUser:verifiedUser];
    verifiedUserConnection.status = ZMConnectionStatusAccepted;
    
    UserClient *verifiedUserClient = [UserClient insertNewObjectInManagedObjectContext:self.uiMOC];
    verifiedUserClient.user = verifiedUser;
    
    [conversation internalAddParticipants:@[verifiedUser]];
    
    [selfClient trustClients:[NSSet setWithObject:verifiedUserClient]];
    [conversation increaseSecurityLevelIfNeededAfterTrustingClients:[NSSet setWithObject:verifiedUserClient]];
    
    return conversation;
}

- (NSSet<ZMUser *> *)setupUnverifiedUsers:(NSUInteger)count
{
    NSMutableSet<ZMUser *> *result = [[NSMutableSet alloc] init];
    
    for (NSUInteger i = 0; i < count; i++) {
        ZMUser *unverifiedUser = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
        ZMConnection *unverifiedUserConnection = [ZMConnection insertNewSentConnectionToUser:unverifiedUser];
        unverifiedUserConnection.status = ZMConnectionStatusAccepted;
        unverifiedUser.remoteIdentifier = [NSUUID new];
        [result addObject:unverifiedUser];
    }
    
    return result;
}

- (void)testThatItDoesNotInsertDegradedMessageWhenAddingVerifiedUsers
{
    // GIVEN
    ZMConversation *conversation = [self setupVerifiedConversation];
    ZMUser *selfUser = [ZMUser selfUserInContext:self.uiMOC];
    [conversation addWithUser:selfUser isFromLocal:YES];

    // WHEN
    ZMUser *verifiedUser = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    verifiedUser.remoteIdentifier = [NSUUID new];
    ZMConnection *verifiedUserConnection = [ZMConnection insertNewSentConnectionToUser:verifiedUser];
    verifiedUserConnection.status = ZMConnectionStatusAccepted;
    
    UserClient *verifiedUserClient = [UserClient insertNewObjectInManagedObjectContext:self.uiMOC];
    verifiedUserClient.user = verifiedUser;
    [selfUser.selfClient trustClients:[NSSet setWithObject:verifiedUserClient]];

    [conversation internalAddParticipants:@[verifiedUser]];
    
    // THEN
    XCTAssertTrue([conversation.lastMessage isKindOfClass:[ZMSystemMessage class]]);
    XCTAssertEqual(((ZMSystemMessage *)conversation.lastMessage).systemMessageType, ZMSystemMessageTypeConversationIsSecure);
    
    // WHEN
    [self simulateAdding:[NSSet setWithObject:verifiedUser] to:conversation by:verifiedUser];
    
    // THEN
    XCTAssertTrue([conversation.lastMessage isKindOfClass:[ZMSystemMessage class]]);
    XCTAssertEqual(((ZMSystemMessage *)conversation.lastMessage).systemMessageType, ZMSystemMessageTypeParticipantsAdded);
}

- (void)testThatItDoesNotMoveExistingDegradedMessageWhenRemoteParticpantsAdd_OtherParticipants
{
    // GIVEN
    ZMConversation *conversation = [self setupVerifiedConversation];
    ZMUser *selfUser = [ZMUser selfUserInContext:self.uiMOC];
    
    // WHEN
    NSSet<ZMUser *> *unverifiedUsers = [self setupUnverifiedUsers:1];
    [conversation internalAddParticipants:unverifiedUsers.allObjects];
    
    NSSet<ZMUser *> *otherUnverifiedUsers = [self setupUnverifiedUsers:1];

    
    // THEN
    XCTAssertEqual(conversation.allMessages.count, (NSUInteger)2);
    XCTAssertEqual(((ZMSystemMessage *)conversation.lastMessage).systemMessageType, ZMSystemMessageTypeNewClient);
    XCTAssertTrue([((ZMSystemMessage *)conversation.lastMessage).addedUsers isEqualToSet:unverifiedUsers]);
        
    // WHEN
    [self simulateAdding:otherUnverifiedUsers to:conversation by:selfUser];
    
    // THEN
    XCTAssertEqual(conversation.allMessages.count, (NSUInteger)3);
    XCTAssertEqual(((ZMSystemMessage *)conversation.lastMessage).systemMessageType, ZMSystemMessageTypeParticipantsAdded);
}

- (void)testThatAddingABlockedUserThatAlreadyIsMemberOfTheConversationDoesNotDegradeTheConversation
{
    // This happens when we are blocking a user in a 1on1: We recieve a conversation update from the backend as a response to blocking the user, which then "readds" the user. Since the user is already part of the conversation it should not degrade the conversation.
    
    // given
    ZMConversation *conversation = [self setupVerifiedConversation];
    ZMUser *participant = [conversation.lastServerSyncedActiveParticipants anyObject];
    XCTAssertNotNil(participant);
    XCTAssertEqual(conversation.securityLevel, ZMConversationSecurityLevelSecure);
    [participant block];
    
    // when
    [conversation internalAddParticipants:@[participant]];
    
    // then
    XCTAssertEqual(conversation.securityLevel, ZMConversationSecurityLevelSecure);
}

@end
