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

@import WireDataModel;
@import WireSyncEngine;

#import "ZMOperationLoop+Private.h"
#import "ZMSyncStrategy.h"
#import "Tests-Swift.h"
#import "APNSTestsBase.h"

@interface APNSTests : APNSTestsBase
@end

@implementation APNSTests

- (void)testThatItFetchesTheNotificationStreamWhenReceivingNotificationOfTypeNotice
{
    XCTAssertTrue([self login]);
    
    [self closePushChannelAndWaitUntilClosed]; // do not use websocket
    
    ZMUser *selfUser = [self userForMockUser:self.selfUser];
    XCTAssertEqual(selfUser.clients.count, 1u);

    __block NSDictionary *conversationTransportData;
    
    __block NSString *convIdentifier;
    [self.mockTransportSession performRemoteChanges:^ (id<MockTransportSessionObjectCreation>  _Nonnull __strong session) {
        MockConversation *conversation = [session insertGroupConversationWithSelfUser:self.selfUser otherUsers:@[self.user1]];
        conversationTransportData = (NSDictionary *)conversation.transportData;
        convIdentifier = conversation.identifier;
    }];
    WaitForAllGroupsToBeEmpty(0.2);
    NSUUID *notificationID = NSUUID.timeBasedUUID;
    
    NSDictionary *eventPayload = [self conversationCreatePayloadWithNotificationID:notificationID
                                                                    conversationID:convIdentifier
                                                                     transportData:conversationTransportData
                                                                          senderID:self.user1.identifier];
    NSDictionary *notificationStreamPayload = [self notificationStreamPayloadWithNotifications:@[eventPayload]];
    NSDictionary *noticePayload = [self noticePayloadWithIdentifier:notificationID];

    [self.application setBackground];
    
    // when
    XCTestExpectation *fetchingExpectation = [self expectationWithDescription:@"fetching notification"];
    NSUUID *lastNotificationId = self.userSession.syncManagedObjectContext.zm_lastNotificationID;

    self.mockTransportSession.responseGeneratorBlock = ^ZMTransportResponse *(ZMTransportRequest *request) {
        NSString *path = [NSString stringWithFormat:@"/notifications?size=500&since=%@&client=%@", lastNotificationId.transportString ,selfUser.selfClient.remoteIdentifier];
        if ([request.path isEqualToString:path] && request.method == ZMMethodGET) {
            [fetchingExpectation fulfill];
            return [ZMTransportResponse responseWithPayload:notificationStreamPayload HTTPStatus:200 transportSessionError:nil apiVersion:0];
        };
        return nil;
    };
    
    [self.mockTransportSession resetReceivedRequests];
    NSDictionary *apnsPayload = noticePayload;
    [self.userSession receivedPushNotificationWith:apnsPayload completion:^{}];
    
    XCTAssert([self waitForCustomExpectationsWithTimeout:0.5]);
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    XCTAssertEqualObjects(self.userSession.managedObjectContext.zm_lastNotificationID, notificationID);
}

- (void)testThatItFetchesTheNotificationStreamWhenReceivingNotificationOfTypeNotice_TriesAgainWhenReceiving_401
{
    XCTAssertTrue([self login]);
    
    [self closePushChannelAndWaitUntilClosed]; // do not use websocket
    
    ZMUser *selfUser = [self userForMockUser:self.selfUser];
    XCTAssertEqual(selfUser.clients.count, 1u);
    
    __block NSDictionary *conversationTransportData;
    
    __block NSString *convIdentifier;
    [self.mockTransportSession performRemoteChanges:^ (id<MockTransportSessionObjectCreation>  _Nonnull __strong session) {
        MockConversation *conversation = [session insertGroupConversationWithSelfUser:self.selfUser otherUsers:@[self.user1]];
        conversationTransportData = (NSDictionary *)conversation.transportData;
        convIdentifier = conversation.identifier;
    }];
    WaitForAllGroupsToBeEmpty(0.2);
    NSUUID *notificationID = NSUUID.timeBasedUUID;
    
    NSDictionary *eventPayload = [self conversationCreatePayloadWithNotificationID:notificationID
                                                                    conversationID:convIdentifier
                                                                     transportData:conversationTransportData
                                                                          senderID:self.user1.identifier];
    NSDictionary *notificationStreamPayload = [self notificationStreamPayloadWithNotifications:@[eventPayload]];
    NSDictionary *noticePayload = [self noticePayloadWithIdentifier:notificationID];

    [self.application setBackground];
    
    // when
    XCTestExpectation *fetchingExpectation = [self expectationWithDescription:@"fetching notification"];
    
    __block NSUInteger requestCount = 0;
    NSUUID *lastNotificationId = self.userSession.syncManagedObjectContext.zm_lastNotificationID;
    self.mockTransportSession.responseGeneratorBlock = ^ZMTransportResponse *(ZMTransportRequest *request) {
        NSString *path = [NSString stringWithFormat:@"/notifications?size=500&since=%@&client=%@", lastNotificationId.transportString, selfUser.selfClient.remoteIdentifier];
        if ([request.path isEqualToString:path] && request.method == ZMMethodGET) {
            if (++requestCount == 2) {
                [fetchingExpectation fulfill];
                return [ZMTransportResponse responseWithPayload:notificationStreamPayload HTTPStatus:200 transportSessionError:nil apiVersion:0];
            } else {
                return [ZMTransportResponse responseWithTransportSessionError:NSError.tryAgainLaterError apiVersion:0];
            }
        };
        return nil;
    };
    
    [self.mockTransportSession resetReceivedRequests];
    NSDictionary *apnsPayload = noticePayload;
    [self.userSession receivedPushNotificationWith:apnsPayload completion:^{}];
    XCTAssert([self waitForCustomExpectationsWithTimeout:0.5]);
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    XCTAssertEqual(requestCount, 2lu);
    XCTAssertEqualObjects(self.userSession.managedObjectContext.zm_lastNotificationID, notificationID);
}

#pragma mark - Helper

- (NSDictionary *)conversationCreatePayloadWithNotificationID:(NSUUID *)notificationID
                                               conversationID:(NSString *)conversationID
                                                transportData:(NSDictionary *)transportData
                                                     senderID:(NSString *)senderID
{
    return @{
             @"id" :notificationID.transportString,
             @"payload" : @[
                     @{
                         @"conversation" : conversationID,
                         @"data" : transportData,
                         @"from" : senderID,
                         @"time" : @"2015-03-11T09:34:00.436Z",
                         @"type" : @"conversation.create"
                         }
                     ]
             };
}

- (NSDictionary *)notificationStreamPayloadWithNotifications:(NSArray <NSDictionary *>*)notifications
{
    return @{
             @"notifications": notifications,
             @"hasMore": @NO
             };
}

- (NSDictionary *)APNSPayloadForNotificationPayload:(NSDictionary *)notificationPayload identifier:(NSUUID *)identifier {
    
    return @{ @"aps" :
                  @{
                      @"content-available" : @(1)
                      },
              @"data" :
                  @{
                      @"type": @"plain",
                      @"data": @{
                              @"id" : identifier ? identifier.transportString : @"bf96c4ce-c7d1-11e4-8001-22000a5a00c8",
                              @"payload" : @[notificationPayload],
                              @"transient" : @(0)
                              }
                      }
              };
    
}


- (NSDictionary *)APNSPayloadForNotificationPayload:(NSDictionary *)notificationPayload {
    
    return [self APNSPayloadForNotificationPayload:notificationPayload identifier:nil];
    
}



@end
