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
@import WireMockTransport;
@import WireDataModel;

#import "Tests-Swift.h"


@class BackgroundTests;

static NSTimeInterval zmMessageExpirationTimer = 0.3;


@interface BackgroundTests : IntegrationTest

@end


@implementation BackgroundTests

- (void)setUp
{
    [super setUp];
    
    [self createSelfUserAndConversation];
    [self createExtraUsersAndConversations];
}

- (void)tearDown
{
    self.mockTransportSession.disableEnqueueRequests = NO;
    [ZMMessage resetDefaultExpirationTime];
    
    [super tearDown];
}

- (void)testThatItSendsUILocalNotificationsForExpiredMessageRequestsWhenGoingToTheBackground
{
    // given
    XCTAssertTrue([self login]);
    self.mockTransportSession.responseGeneratorBlock = ^ZMTransportResponse *(ZMTransportRequest *request) {
        (void)request;
        return ResponseGenerator.ResponseNotCompleted;
    };
    
    ZMConversation *conversation = [self conversationForMockConversation:self.groupConversation];
    
    // when
    [self.userSession performChanges:^{
        [conversation appendMessageWithText:@"foo"];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // background
    [self.application simulateApplicationDidEnterBackground];
    [self.application setBackground];
    
    [self.mockTransportSession expireAllBlockedRequests];
    WaitForAllGroupsToBeEmpty(0.5);

    // then
    XCTAssertEqual(self.notificationCenter.scheduledRequests.count, 1u);
}

- (void)testThatItSendsUILocalNotificationsForExpiredMessageNotPickedUpForRequestWhenGoingToTheBackground
{
    // given
    [ZMMessage setDefaultExpirationTime:zmMessageExpirationTimer];
    XCTAssertTrue([self login]);
    
    self.mockTransportSession.disableEnqueueRequests = YES;
    ZMConversation *conversation = [self conversationForMockConversation:self.groupConversation];
    
    // when
    [self.userSession performChanges:^{
        [conversation appendMessageWithText:@"foo"];
    }];
    
    // background
    [self.application simulateApplicationDidEnterBackground];
    [self.application setBackground];
    [self spinMainQueueWithTimeout:zmMessageExpirationTimer + 0.1];
    
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    XCTAssertEqual(self.notificationCenter.scheduledRequests.count, 1u);
}

- (void)testThatItDoesNotCreateNotificationsForMessagesInTheSelfConversation
{
    // given
    [ZMMessage setDefaultExpirationTime:zmMessageExpirationTimer];
    XCTAssertTrue([self login]);
    
    self.mockTransportSession.disableEnqueueRequests = YES;
    ZMConversation *conversation = [self conversationForMockConversation:self.selfConversation];
    
    // when
    [self.userSession performChanges:^{
        [conversation appendMessageWithText:@"foo"];
    }];
    
    // background
    [self.application simulateApplicationDidEnterBackground];
    [self spinMainQueueWithTimeout:zmMessageExpirationTimer + 0.1];
    
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    XCTAssertEqual(self.notificationCenter.scheduledRequests.count, 0u);
}

@end
