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


@import Foundation;
@import WireSyncEngine;
#import "MockLoader.h"
#import "MockUserClient.h"

@class MockConversation;

@interface MockUser : NSObject<UserType, Mockable>
+ (NSArray <ZMUser *> *)mockUsers;
+ (NSArray <MockUser *> *)realMockUsers;
+ (MockUser *)mockSelfUser;
+ (MockUser *)mockServiceUser;
+ (MockUser *)mockUserFor:(ZMUser *)user;
+ (ZMUser<ZMEditableUser> *)selfUserInUserSession:(ZMUserSession *)session;

+ (void)setMockSelfUser:(id<UserType>)newMockUser;

@property (nonatomic, readwrite, copy) NSString *name;
@property (nonatomic, readwrite) NSString *emailAddress;
@property (nonatomic, readwrite) NSString *phoneNumber;
@property (nonatomic, readwrite, copy) NSString *handle;
@property (nonatomic) ZMAccentColor accentColorValue;
@property (nonatomic, readwrite) BOOL isBlocked;
@property (nonatomic, readwrite) BOOL isIgnored;
@property (nonatomic, readwrite) BOOL isPendingApprovalByOtherUser;
@property (nonatomic, readwrite) BOOL isPendingApprovalBySelfUser;
@property (nonatomic, readwrite) BOOL isConnected;
@property (nonatomic, readwrite) BOOL untrusted;
@property (nonatomic, readwrite) BOOL trusted;
@property (nonatomic, readwrite) NSUInteger totalCommonConnections;
@property (nonatomic, readwrite) NSTimeInterval expiresAfter;
@property (nonatomic, assign) BOOL isSelfUser;
@property (nonatomic, assign) BOOL isServiceUser;
@property (nonatomic, readwrite) BOOL isTeamMember;
@property (nonatomic, assign) BOOL isGuestInConversation;
@property (nonatomic, readwrite) BOOL canManageTeam;
@property (nonatomic, readwrite) BOOL hasTeam;
@property (nonatomic, readwrite) NSString *expirationDisplayString;
@property (nonatomic, readwrite) BOOL isWirelessUser;
@property (nonatomic, readwrite) BOOL usesCompanyLogin;
@property (nonatomic, readwrite) BOOL readReceiptsEnabled;
@property (nonatomic) ZMUser * user;

@property (nonatomic) NSSet <id<UserClientType>> * clients;
@property (nonatomic) ZMConnection *connection;
@property (nonatomic) ZMAddressBookContact *contact;
@property (nonatomic) AddressBookEntry *addressBookEntry;
@property (nonatomic) NSUUID *remoteIdentifier;
@property (nonatomic, readwrite) Availability availability;
@property (nonatomic, readonly) NSSet<UserClient *> * clientsRequiringUserAttention;

- (NSArray<MockUserClient *> *)featureWithUserClients:(NSUInteger)numClients;
- (NSString *)displayNameInConversation:(MockConversation *)conversation;
- (void)fetchUserClients;

@end
