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


#import <ZMCDataModel/ZMSearchUser.h>
#import <ZMUtilities/ZMAccentColor.h>

@class ZMUserSession;
@class ZMUser;
@class ZMAddressBookContact;
@class ManagedObjectContextObserver;


FOUNDATION_EXPORT NSString *const ZMSearchUserMutualFriendsKey;
FOUNDATION_EXPORT NSString *const ZMSearchUserTotalMutualFriendsKey;

@interface ZMSearchUser ()

- (instancetype)initWithName:(NSString *)name accentColor:(ZMAccentColor)color remoteID:(NSUUID *)remoteID user:(ZMUser *)user syncManagedObjectContext:(NSManagedObjectContext *)syncMOC uiManagedObjectContext:(NSManagedObjectContext *)uiMOC;

- (instancetype)initWithName:(NSString *)name accentColor:(ZMAccentColor)color remoteID:(NSUUID *)remoteID user:(ZMUser *)user userSession:(ZMUserSession *)userSession;

+ (NSArray <ZMSearchUser *> *)usersWithUsers:(NSArray <ZMUser *> *)users userSession:(ZMUserSession *)userSession;

- (instancetype)initWithPayload:(NSDictionary *)payload userSession:(ZMUserSession *)userSession globalCommonConnections:(NSOrderedSet *)connections;

+ (NSArray <ZMSearchUser *> *)usersWithPayloadArray:(NSArray <NSDictionary *> *)payloadArray userSession:(ZMUserSession *)userSession;

- (instancetype)initWithContact:(ZMAddressBookContact *)contact user:(ZMUser *)user userSession:(ZMUserSession *)userSession;

+ (NSOrderedSet *)commonConnectionsWithIds:(NSOrderedSet *)set inContext:(NSManagedObjectContext *)moc;

@property (nonatomic) NSUUID *remoteIdentifier;
/// Returns @c YES if the receiver has a local user or cached profile image data.
/// C.f. +searchUserToProfileImageCache
@property (nonatomic, readonly) BOOL isLocalOrHasCachedProfileImageData;

@property (nonatomic) NSUUID *mediumAssetID;

@property (nonatomic, readwrite) NSOrderedSet *topCommonConnections;
@property (nonatomic, readwrite) NSUInteger totalCommonConnections;

+ (NSCache *)searchUserToSmallProfileImageCache;
+ (NSCache *)searchUserToMediumImageCache;
+ (NSCache *)searchUserToMediumAssetIDCache;

- (void)notifyNewSmallImageData:(NSData *)data managedObjectContextObserver:(ManagedObjectContextObserver *)mocObserver;
- (void)setAndNotifyNewMediumImageData:(NSData *)data managedObjectContextObserver:(ManagedObjectContextObserver *)mocObserver;

@end
