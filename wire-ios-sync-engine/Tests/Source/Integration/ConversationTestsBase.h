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
@import WireMockTransport;
@import WireSyncEngine;
@import WireDataModel;

#import "NotificationObservers.h"
#import <WireSyncEngine/WireSyncEngine-Swift.h>
#import "IntegrationTest.h"


@interface ConversationTestsBase : IntegrationTest

- (void)testThatItAppendsMessageToConversation:(MockConversation *)mockConversation
                                     withBlock:(NSArray *(^)(MockTransportSession<MockTransportSessionObjectCreation> *session))appendMessages
                                        verify:(void(^)(ZMConversation *))verifyConversation;

- (void)testThatItSendsANotificationInConversation:(MockConversation *)mockConversation
                                    ignoreLastRead:(BOOL)ignoreLastRead
                        onRemoteMessageCreatedWith:(void(^)(void))createMessage
                                            verify:(void(^)(ZMConversation *))verifyConversation;

- (void)testThatItSendsANotificationInConversation:(MockConversation *)mockConversation
                        onRemoteMessageCreatedWith:(void(^)(void))createMessage
                                verifyWithObserver:(void(^)(ZMConversation *, ConversationChangeObserver *))verifyConversation;

- (void)testThatItSendsANotificationInConversation:(MockConversation *)mockConversation
                                   afterLoginBlock:(void(^)(void))afterLoginBlock
                        onRemoteMessageCreatedWith:(void(^)(void))createMessage
                                verifyWithObserver:(void(^)(ZMConversation *, ConversationChangeObserver *))verifyConversation;

- (NSURL *)createTestFile:(NSString *)name;
- (void)makeConversationSecured:(ZMConversation *)conversation;
- (void)setupInitialSecurityLevel:(ZMConversationSecurityLevel)initialSecurityLevel inConversation:(ZMConversation *)conversation;

@property (nonatomic) MockConversation *groupConversationWithOnlyConnected;
@property (nonatomic) MockConversation *emptyGroupConversation;

@end
