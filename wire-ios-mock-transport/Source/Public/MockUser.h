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
@import WireUtilities;
@import WireSystem;
@import WireTransport;
@import CoreData;

@class MockPicture;
@class MockUserClient;
@class MockPreKey;
@class MockConversation;

extern NSString * _Nonnull const ZMSearchUserMutualFriendsKey;
extern NSString * _Nonnull const ZMSearchUserTotalMutualFriendsKey;


@interface MockUser : NSManagedObject

@property (nonatomic, nullable) NSString *email;
@property (nonatomic, nullable) NSString *password;
@property (nonatomic, nullable) NSString *phone;
@property (nonatomic, nullable) NSString *handle;
@property (nonatomic) int16_t accentID;
@property (nonatomic, nullable) NSString *name;
@property (nonatomic, nonnull) NSString *identifier;
@property (nonatomic, nonnull) NSOrderedSet *pictures;
@property (nonatomic) BOOL isEmailValidated;
@property (nonatomic) BOOL isSendingVideo;
@property (nonatomic, nullable) MockConversation *ignoredCallConversation;

@property (nonatomic, nonnull) NSOrderedSet *connectionsFrom;
@property (nonatomic, nonnull) NSOrderedSet *connectionsTo;
@property (nonatomic, nonnull) NSOrderedSet *activeCallConversations;

@property (nonatomic, nonnull) NSMutableSet *clients;

@property (nonatomic, nonnull) NSOrderedSet *invitations;

- (nonnull id<ZMTransportData>)transportData;
- (nonnull id<ZMTransportData>)transportDataWhenNotConnected;

+ (nonnull NSFetchRequest *)sortedFetchRequest;
+ (nonnull NSFetchRequest *)sortedFetchRequestWithPredicate:(nonnull NSPredicate *)predicate;
- (nullable NSString *)mediumImageIdentifier;
- (nullable NSString *)smallProfileImageIdentifier;
- (nullable MockPicture *)smallProfileImage;
- (nullable MockPicture *)mediumImage;


@end
