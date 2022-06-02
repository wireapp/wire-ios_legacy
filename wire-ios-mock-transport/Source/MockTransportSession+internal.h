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


#import "MockTransportSession.h"

@class ZMTransportRequest;
@class MockPushEvent;


@interface MockTransportSession (Internal)

@property (nonatomic, readonly) NSMutableArray<MockPushEvent *>* generatedPushEvents;
@property (nonatomic) MockUser* selfUser;

- (MockConnection *)fetchConnectionFrom:(MockUser *)userID to:(MockUser *)otherUserID;
- (ZMTransportResponse *)errorResponseWithCode:(NSInteger)code reason:(NSString *)reason apiVersion:(APIVersion)apiVersion;
- (MockEvent *)eventIfNeededByUser:(MockUser *)byUser type:(ZMUpdateEventType)type data:(id<ZMTransportData>)data;

- (void)generateEmailVerificationCode;
- (MockConnection *)connectionFromUserIdentifier:(NSString *)fromUserIdentifier toUserIdentifier:(NSString *)toUserIdentifier;

@property (nonatomic, readonly) NSMutableSet *whitelistedEmails;
@property (nonatomic, readonly) NSMutableSet *phoneNumbersWaitingForVerificationForRegistration;
@property (nonatomic, readonly) NSMutableSet *phoneNumbersWaitingForVerificationForLogin;
@property (nonatomic, readonly) NSMutableSet *phoneNumbersWaitingForVerificationForProfile;

@property (nonatomic, readonly) NSMutableSet *emailsWaitingForVerificationForRegistration;

@property (atomic, weak, readonly) id<ZMPushChannelConsumer> pushChannelConsumer;
@property (atomic) BOOL clientCompletedLogin;

@end



@interface MockTransportSession (MockTransportSessionObjectCreation) <MockTransportSessionObjectCreation>
@end
