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


#import "ZMManagedObject.h"
#import <WireUtilities/ZMAccentColor.h>

@class ZMConversation;
@class UserClient;
@class ZMAddressBookContact;
@class AddressBookEntry;
@class Member;
@class Team;
@class ParticipantRole;

extern NSString * _Nonnull const ZMPersistedClientIdKey;

typedef NS_ENUM(int16_t, ZMBlockState) {
    ZMBlockStateNone = 0,
    ZMBlockStateBlocked, ///< We have blocked this user
    ZMBlockStateBlockedMissingLegalholdConsent, ///< The user is blocked due to legal hold missing consent
};

@interface ZMUser : ZMManagedObject

@property (nonatomic, readonly, nullable) NSString *emailAddress;
@property (nonatomic, readonly, nullable) NSString *phoneNumber;
@property (nonatomic, nullable) AddressBookEntry *addressBookEntry;

@property (nonatomic, readonly) NSSet<UserClient *> * _Nonnull clients;

/// New self clients which the self user hasn't been informed about (only valid for the self user)
@property (nonatomic, readonly) NSSet<UserClient *> * _Nonnull clientsRequiringUserAttention;

@property (nonatomic, readonly, nullable) NSString *connectionRequestMessage;

@property (nonatomic, nonnull) NSSet<ParticipantRole *> *  participantRoles;

/// The full name
@property (nonatomic, readonly, nullable) NSString *name;

/// The "@name" handle
@property (nonatomic, readonly, nullable) NSString *handle;

///// Is YES if we can send a connection request to this user.
@property (nonatomic, readonly) BOOL canBeConnected;

/// whether this is the self user
@property (nonatomic, readonly) BOOL isSelfUser;

/// return true if this user is a serviceUser
@property (nonatomic, readonly) BOOL isServiceUser;

@property (nonatomic, readonly, nullable) NSString *smallProfileImageCacheKey;
@property (nonatomic, readonly, nullable) NSString *mediumProfileImageCacheKey;

@property (nonatomic, readonly) BOOL isConnected;
@property (nonatomic, readonly) ZMAccentColor accentColorValue;

@property (nonatomic, readonly, nullable) NSData *imageMediumData;
@property (nonatomic, readonly, nullable) NSData *imageSmallProfileData;

@property (nonatomic, readonly) BOOL managedByWire;

@property (nonatomic, readonly) BOOL isTeamMember;

/// Request a refresh of the user data from the backend.
/// This is useful for non-connected user, that we will otherwise never refetch
- (void)refreshData;


@end


@protocol ZMEditableUser;

@interface ZMUser (Utilities)

+ (ZMUser<ZMEditableUser> *_Nonnull)selfUserInUserSession:(id<ContextProvider> _Nonnull)session;

@end



@interface ZMUser (Connections)

@property (nonatomic, readonly) BOOL isBlocked;
@property (nonatomic, readonly) ZMBlockState blockState;
@property (nonatomic, readonly) BOOL isIgnored;
@property (nonatomic, readonly) BOOL isPendingApprovalBySelfUser;
@property (nonatomic, readonly) BOOL isPendingApprovalByOtherUser;

@end



@interface ZMUser (KeyValueValidation)

+ (BOOL)validateName:(NSString * __nullable * __nullable)ioName error:(NSError * __nullable * __nullable)outError;
+ (BOOL)validateAccentColorValue:(NSNumber * __nullable * __nullable)ioAccent error:(NSError * __nullable * __nullable)outError;
+ (BOOL)validateEmailAddress:(NSString * __nullable * __nullable)ioEmailAddress error:(NSError * __nullable * __nullable)outError;
+ (BOOL)validatePhoneNumber:(NSString *__nullable * __nullable)ioPhoneNumber error:(NSError * __nullable * __nullable)outError;
+ (BOOL)validatePassword:(NSString * __nullable * __nullable)ioPassword error:(NSError * __nullable * __nullable)outError;
+ (BOOL)validatePhoneVerificationCode:(NSString * __nullable * __nullable)ioVerificationCode error:(NSError * __nullable * __nullable)outError;

+ (BOOL)isValidName:(NSString * _Nullable)name;
+ (BOOL)isValidEmailAddress:(NSString * _Nullable)emailAddress;
+ (BOOL)isValidPassword:(NSString * _Nullable)password;
+ (BOOL)isValidPhoneNumber:(NSString * _Nullable)phoneNumber;
+ (BOOL)isValidPhoneVerificationCode:(NSString * _Nullable)phoneVerificationCode;

@end
