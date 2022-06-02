//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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

#import <XCTest/XCTest.h>

@import WireTesting;

@class SessionManager;
@class ZMTransportSession;
@class MockTransportSession;
@class ApplicationMock;
@class ZMUserSession;
@class UnauthenticatedSession;
@class MockUser;
@class MockTeam;
@class MockConversation;
@class MockConnection;
@class SearchDirectory;
@class PushRegistryMock;
@class UserNotificationCenterMock;
@class MockJailbreakDetector;
@class MockEnvironment;
@class MockMediaManager;
@class MockLoginDelegate;

@interface IntegrationTest : ZMTBaseTest

@property (nonatomic, null_unspecified) NSUUID *currentUserIdentifier;
@property (nonatomic, nullable) SessionManager *sessionManager;
@property (nonatomic, null_unspecified) MockEnvironment *mockEnvironment;
@property (nonatomic, null_unspecified) MockTransportSession *mockTransportSession;
@property (nonatomic, readonly, nullable) ZMTransportSession *transportSession;
@property (nonatomic, null_unspecified) MockMediaManager *mockMediaManager;
@property (nonatomic, nullable) ApplicationMock *application;
@property (nonatomic, nullable) ZMUserSession *userSession;
@property (nonatomic, null_unspecified) PushRegistryMock *pushRegistry;
@property (nonatomic, null_unspecified) NSURL *sharedContainerDirectory;
@property (nonatomic, readonly) BOOL useInMemoryStore;
@property (nonatomic, readonly) BOOL useRealKeychain;
@property (nonatomic, nullable) SearchDirectory *sharedSearchDirectory;
@property (nonatomic, nullable) UserNotificationCenterMock *notificationCenter;
@property (nonatomic, nullable) MockJailbreakDetector *jailbreakDetector;
@property (nonatomic, nullable) MockLoginDelegate *mockLoginDelegete;

@property (nonatomic, null_unspecified) MockUser *selfUser;
@property (nonatomic, null_unspecified) MockConversation *selfConversation;
@property (nonatomic, null_unspecified) MockUser *user1; // connected, with profile picture
@property (nonatomic, null_unspecified) MockUser *user2; // connected
@property (nonatomic, null_unspecified) MockUser *user3; // not connected, with profile picture, in a common group conversation
@property (nonatomic, null_unspecified) MockUser *user4; // not connected, with profile picture, no shared conversations
@property (nonatomic, null_unspecified) MockUser *user5; // not connected, no shared conversation

@property (nonatomic, null_unspecified) MockTeam *team;
@property (nonatomic, null_unspecified) MockUser *serviceUser;
@property (nonatomic, null_unspecified) MockUser *teamUser1;
@property (nonatomic, null_unspecified) MockUser *teamUser2;
@property (nonatomic, null_unspecified) MockConversation *groupConversationWithServiceUser;
@property (nonatomic, null_unspecified) MockConversation *groupConversationWithWholeTeam;

@property (nonatomic, null_unspecified) MockConversation *selfToUser1Conversation;
@property (nonatomic, null_unspecified) MockConversation *selfToUser2Conversation;
@property (nonatomic, null_unspecified) MockConversation *groupConversation;
@property (nonatomic, null_unspecified) MockConnection *connectionSelfToUser1;
@property (nonatomic, null_unspecified) MockConnection *connectionSelfToUser2;

@property (nonatomic, null_unspecified) NSString *appState;

@end
