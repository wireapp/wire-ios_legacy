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


@import WireTesting;

#import "Tests-Swift.h"

@interface FakeClientObserver : NSObject <ZMClientUpdateObserver>
@property (nonatomic) NSArray *fetchedClients;
@property (nonatomic) NSArray *remainingClients;

@property (nonatomic) BOOL finishedFetching;
@property (nonatomic) BOOL failedFetching;
@property (nonatomic) BOOL finishedDeleting;
@property (nonatomic) BOOL failedDeleting;
@property (nonatomic) NSError *fetchError;
@property (nonatomic) NSError *deletionError;

@end

@implementation FakeClientObserver

- (void)finishedFetchingClients:(NSArray<UserClient *> *)userClients
{
    self.fetchedClients = userClients;
    self.finishedFetching = YES;
}

- (void)finishedDeletingClients:(NSArray *)remainingClients
{
    self.remainingClients = remainingClients;
    self.finishedDeleting = YES;
}

- (void)failedToFetchClientsWithError:(NSError *)error
{
    self.failedFetching = YES;
    self.fetchError = error;
}

- (void)failedToDeleteClientsWithError:(NSError *)error
{
    self.failedDeleting = YES;
    self.deletionError = error;
}

@end


@interface ClientManagementTests : IntegrationTest
@property (nonatomic) FakeClientObserver *observer;
@property (nonatomic) id token;
@end

@implementation ClientManagementTests

- (void)setUp
{
    [super setUp];
    
    [self createSelfUserAndConversation];
    [self createExtraUsersAndConversations];
    
    XCTAssert([self login]);
    
    self.observer = [[FakeClientObserver alloc] init];
    self.token = [self.userSession addClientUpdateObserver:self.observer];
}

- (void)tearDown
{
    self.observer = nil;
    self.token = nil;
    [super tearDown];
}

- (void)insertTwoSelfClientsOnMockTransporSession
{
    [self.mockTransportSession performRemoteChanges:^ (id<MockTransportSessionObjectCreation>  _Nonnull __strong session) {
        MockUserClient *client1 = [session registerClientForUser:self.selfUser label:@"foobar" type:@"permanent" deviceClass:@"phone"];
        client1.time = [NSDate dateWithTimeIntervalSince1970:124535];
        client1.deviceClass = @"iPhone";
        client1.model = @"iTV";
        client1.locationLongitude = 23;
        client1.locationLatitude = -14.43;
        MockUserClient *client2 = [session registerClientForUser:self.selfUser label:@"x456346" type:@"permanent" deviceClass:@"phone"];
        client2.time = [NSDate dateWithTimeIntervalSince1970:2132444];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
}

- (void)testThatItFetchesClientsFromTheSettingsMenu
{
    // given
    [self insertTwoSelfClientsOnMockTransporSession];
    
    // when
    [self.userSession performChanges:^{
        [self.userSession fetchAllClients];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    ZMUser *selfUser = [self userForMockUser:self.selfUser];
    NSArray *selfUserClients = selfUser.clients.allObjects;
    XCTAssertEqual(selfUserClients.count, 3u);

    NSArray *fetchedClients = self.observer.fetchedClients;
    
    XCTAssertNotEqualObjects(fetchedClients, selfUserClients);
    XCTAssertEqual(fetchedClients.count, 2u);
    XCTAssertFalse([fetchedClients containsObject:selfUser.selfClient]);
    XCTAssertNil(self.observer.fetchError);
    XCTAssertTrue(self.observer.finishedFetching);
}

- (void)testThatItCanDeleteClientsFromSettingsMenu
{
    // given
    ZMEmailCredentials *credentials = [ZMEmailCredentials credentialsWithEmail:IntegrationTest.SelfUserEmail password:IntegrationTest.SelfUserPassword];
    [self insertTwoSelfClientsOnMockTransporSession];

    [self.userSession performChanges:^{
        [self.userSession fetchAllClients];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    NSArray *fetchClients = self.observer.fetchedClients;
    XCTAssertEqual(fetchClients.count, 2u);
    XCTAssertTrue(self.observer.finishedFetching);
    XCTAssertNil(self.observer.fetchError);

    // when
    [self.userSession performChanges:^{
        [self.userSession deleteClient:fetchClients.firstObject withCredentials:credentials];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    XCTAssertEqual(self.observer.remainingClients.count, 1u);
    XCTAssertTrue(self.observer.finishedDeleting);
    XCTAssertNil(self.observer.deletionError);
}

@end

@implementation ClientManagementTests (PushNotifications)

- (void)testThatItAddsAUserClientWhenReceivingANotificationForANewClient
{
    // given
    ZMUser *selfUser = [ZMUser selfUserInUserSession:self.userSession];
    UserChangeObserver *observer = [[UserChangeObserver alloc] initWithUser:selfUser];
    
    // when
    __block MockUserClient *mockClient;
    [self.mockTransportSession performRemoteChanges:^ (id<MockTransportSessionObjectCreation>  _Nonnull __strong session) {
        mockClient = [session registerClientForUser:self.selfUser];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    XCTAssertEqual(observer.notifications.count, 1u);
    UserChangeInfo *firstChangeInfo = observer.notifications.firstObject;
    XCTAssertTrue(firstChangeInfo.clientsChanged);
    XCTAssertEqual(selfUser.clients.count, 2u);
    NSSet *newClients = [selfUser.clients objectsPassingTest:^BOOL(UserClient *client, BOOL * __unused stop) {
        return [client.remoteIdentifier isEqualToString:mockClient.identifier];
    }];
    XCTAssertEqual(newClients.count, 1u);
}

- (void)testThatItAddsAUserClientAndDegradesTheSecurityWhenReceivingANotificationForANewClient
{
    // given
    [self establishSessionWithMockUser:self.user1];
    ZMConversation *conversation = [self conversationForMockConversation:self.selfToUser1Conversation];
    UserClient *selfClient = [ZMUser selfUserInUserSession:self.userSession].selfClient;
    [self.userSession performChanges:^{
        for(UserClient *client in [self userForMockUser:self.user1].clients) {
            [selfClient trustClient:client];
        }
    }];
    XCTAssertEqual(conversation.securityLevel, ZMConversationSecurityLevelSecure);
    
    // when
    [self.mockTransportSession performRemoteChanges:^ (id<MockTransportSessionObjectCreation>  _Nonnull __strong session) {
        [session registerClientForUser:self.selfUser];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    XCTAssertEqual(conversation.securityLevel, ZMConversationSecurityLevelSecureWithIgnored);
    ZMSystemMessage *message = (ZMSystemMessage *)conversation.lastMessage;
    if(![message isKindOfClass:ZMSystemMessage.class]) {
        XCTFail(@"Expecting degraded message");
        return;
    }
    
    XCTAssertNotNil(message);
    XCTAssertEqual(message.systemMessageType, ZMSystemMessageTypeNewClient);
}

- (void)testThatItCanNotSendAMessageAfterReceivingANotificationForANewClient
{
    // given
    [self establishSessionWithMockUser:self.user1];
    ZMConversation *conversation = [self conversationForMockConversation:self.selfToUser1Conversation];
    UserClient *selfClient = [ZMUser selfUserInUserSession:self.userSession].selfClient;
    [self.userSession performChanges:^{
        for(UserClient *client in [self userForMockUser:self.user1].clients) {
            [selfClient trustClient:client];
        }
    }];
    XCTAssertEqual(conversation.securityLevel, ZMConversationSecurityLevelSecure);
    
    // when
    [self.mockTransportSession performRemoteChanges:^ (id<MockTransportSessionObjectCreation>  _Nonnull __strong session) {
        [session registerClientForUser:self.selfUser];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    XCTAssertEqual(conversation.securityLevel, ZMConversationSecurityLevelSecureWithIgnored);
    [self.mockTransportSession resetReceivedRequests];
    
    // and when
    __block id<ZMConversationMessage> message;
    [self.userSession performChanges:^{
        message = [conversation appendMessageWithText:@"ar! ar!"];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    XCTAssertEqual(message.deliveryState, ZMDeliveryStateFailedToSend);
    ZMTransportRequest *messageRequest = [self.mockTransportSession.receivedRequests firstObjectMatchingWithBlock:^BOOL(ZMTransportRequest *req) {
        return [req.path isEqualToString:[NSString stringWithFormat:@"/conversations/%@/otr/messages", conversation.remoteIdentifier.transportString]];
    }];
    XCTAssertNil(messageRequest);
}

- (void)testThatItRemovesAUserClientWhenReceivingANotificationForAClient
{
    // given
    ZMUser *selfUser = [ZMUser selfUserInUserSession:self.userSession];

    UserClient *currentSelfClient = selfUser.selfClient;
    __block MockUserClient *mockClient;
    [self.mockTransportSession performRemoteChanges:^ (id<MockTransportSessionObjectCreation>  _Nonnull __strong session) {
        mockClient = [session registerClientForUser:self.selfUser];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    XCTAssertEqual(selfUser.clients.count, 2u);

    UserChangeObserver *observer = [[UserChangeObserver alloc] initWithUser:selfUser];
    
    // when
    [self.mockTransportSession performRemoteChanges:^ (id<MockTransportSessionObjectCreation>  _Nonnull __strong session) {
        [session deleteUserClientWithIdentifier:mockClient.identifier forUser:self.selfUser];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    XCTAssertEqual(observer.notifications.count, 1u);
    UserChangeInfo *lastChangeInfo = observer.notifications.lastObject;
    XCTAssertTrue(lastChangeInfo.clientsChanged);
    XCTAssertEqualObjects(selfUser.clients, [NSSet setWithObject:currentSelfClient]);
    
}

@end
