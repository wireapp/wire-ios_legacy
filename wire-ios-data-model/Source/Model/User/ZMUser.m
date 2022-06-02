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


@import WireImages;
@import WireUtilities;
@import WireCryptobox;
@import WireProtos;
@import WireTransport;
@import Foundation;

#import "ZMManagedObject+Internal.h"
#import "ZMUser+Internal.h"
#import "NSManagedObjectContext+zmessaging.h"
#import "ZMUser+Internal.h"
#import "ZMConnection+Internal.h"
#import "ZMConversation+Internal.h"
#import "NSString+ZMPersonName.h"
#import <CommonCrypto/CommonKeyDerivation.h>
#import <CommonCrypto/CommonCryptoError.h>
#import "NSPredicate+ZMSearch.h"
#import "ZMAddressBookContact.h"
#import <WireDataModel/WireDataModel-Swift.h>


NSString *const SessionObjectIDKey = @"ZMSessionManagedObjectID";
NSString *const ZMPersistedClientIdKey = @"PersistedClientId";

static NSString *const AccentKey = @"accentColorValue";
static NSString *const SelfUserObjectIDAsStringKey = @"SelfUserObjectID";
static NSString *const SelfUserObjectIDKey = @"ZMSelfUserManagedObjectID";

static NSString *const SessionObjectIDAsStringKey = @"SessionObjectID";
static NSString *const SelfUserKey = @"ZMSelfUser";
static NSString *const NormalizedNameKey = @"normalizedName";
static NSString *const NormalizedEmailAddressKey = @"normalizedEmailAddress";
static NSString *const RemoteIdentifierKey = @"remoteIdentifier";

static NSString *const ConversationsCreatedKey = @"conversationsCreated";
static NSString *const ActiveCallConversationsKey = @"activeCallConversations";
static NSString *const ConnectionKey = @"connection";
static NSString *const EmailAddressKey = @"emailAddress";
static NSString *const PhoneNumberKey = @"phoneNumber";
static NSString *const NameKey = @"name";
static NSString *const HandleKey = @"handle";
static NSString *const SystemMessagesKey = @"systemMessages";
static NSString *const isAccountDeletedKey = @"isAccountDeleted";
static NSString *const ShowingUserAddedKey = @"showingUserAdded";
static NSString *const ShowingUserRemovedKey = @"showingUserRemoved";
NSString *const UserClientsKey = @"clients";
static NSString *const ReactionsKey = @"reactions";
static NSString *const AddressBookEntryKey = @"addressBookEntry";
static NSString *const MembershipKey = @"membership";
static NSString *const CreatedTeamsKey = @"createdTeams";
static NSString *const ServiceIdentifierKey = @"serviceIdentifier";
static NSString *const ProviderIdentifierKey = @"providerIdentifier";
NSString *const AvailabilityKey = @"availability";
static NSString *const ExpiresAtKey = @"expiresAt";
static NSString *const UsesCompanyLoginKey = @"usesCompanyLogin";
static NSString *const CreatedTeamMembersKey = @"createdTeamMembers";
NSString *const ReadReceiptsEnabledKey = @"readReceiptsEnabled";
NSString *const NeedsPropertiesUpdateKey = @"needsPropertiesUpdate";
NSString *const ReadReceiptsEnabledChangedRemotelyKey = @"readReceiptsEnabledChangedRemotely";

static NSString *const TeamIdentifierDataKey = @"teamIdentifier_data";
static NSString *const TeamIdentifierKey = @"teamIdentifier";

static NSString *const ManagedByKey = @"managedBy";
static NSString *const ExtendedMetadataKey = @"extendedMetadata";

static NSString *const RichProfileKey = @"richProfile";
static NSString *const NeedsRichProfileUpdateKey = @"needsRichProfileUpdate";

static NSString *const LegalHoldRequestKey = @"legalHoldRequest";
static NSString *const NeedsToAcknowledgeLegalHoldStatusKey = @"needsToAcknowledgeLegalHoldStatus";

static NSString *const NeedsToRefetchLabelsKey = @"needsToRefetchLabels";
static NSString *const ParticipantRolesKey = @"participantRoles";

static NSString *const AnalyticsIdentifierKey = @"analyticsIdentifier";

static NSString *const DomainKey = @"domain";

@interface ZMBoxedSelfUser : NSObject

@property (nonatomic, weak) ZMUser *selfUser;

@end



@implementation ZMBoxedSelfUser
@end

@interface ZMBoxedSession : NSObject

@property (nonatomic, weak) ZMSession *session;

@end



@implementation ZMBoxedSession
@end


@implementation ZMSession

@dynamic selfUser;

+ (NSArray *)defaultSortDescriptors;
{
    return nil;
}

+ (NSString *)entityName
{
    return @"Session";
}

+ (BOOL)isTrackingLocalModifications
{
    return NO;
}

@end


@interface ZMUser ()

@property (nonatomic) NSString *normalizedName;
@property (nonatomic, copy) NSString *name;
@property (nonatomic) ZMAccentColor accentColorValue;
@property (nonatomic, copy) NSString *emailAddress;
@property (nonatomic, copy) NSString *phoneNumber;
@property (nonatomic, copy) NSString *normalizedEmailAddress;
@property (nonatomic, copy) NSString *managedBy;
@property (nonatomic, readonly) UserClient *selfClient;

@end



@implementation ZMUser

- (BOOL)isServiceUser
{
    return self.serviceIdentifier != nil && self.providerIdentifier != nil;
}

+ (NSSet<NSString *> *)keyPathsForValuesAffectingIsServiceUser
{
    return [NSSet setWithObjects:ServiceIdentifierKey, ProviderIdentifierKey, nil];
}

- (BOOL)isSelfUser
{
    if ([self isZombieObject]) {
        return false;
    }
    
    return self == [self.class selfUserInContext:self.managedObjectContext];
}

+ (NSString *)entityName;
{
    return @"User";
}

+ (NSString *)sortKey
{
    return NormalizedNameKey;
}

- (void)awakeFromInsert;
{
    [super awakeFromInsert];
    // The UI can never insert users. A newly inserted user will always have to be sync'd
    // with data from the backend. Not that -updateWithTransportData:authoritative: will
    // clear this flag.
    self.needsToBeUpdatedFromBackend = YES;
}

@dynamic accentColorValue;
@dynamic emailAddress;
@dynamic name;
@dynamic normalizedEmailAddress;
@dynamic normalizedName;
@dynamic phoneNumber;
@dynamic clients;
@dynamic handle;
@dynamic addressBookEntry;
@dynamic managedBy;
@dynamic participantRoles;

- (UserClient *)selfClient
{
    NSString *persistedClientId = [self.managedObjectContext persistentStoreMetadataForKey:ZMPersistedClientIdKey];
    if (persistedClientId == nil) {
        return nil;
    }
    return [self.clients.allObjects firstObjectMatchingWithBlock:^BOOL(UserClient *aClient) {
        return [aClient.remoteIdentifier isEqualToString:persistedClientId];
    }];
}

- (NSData *)imageMediumData
{
    return [self imageDataforSize:ProfileImageSizeComplete];
}

- (NSData *)imageSmallProfileData
{
    return [self imageDataforSize:ProfileImageSizePreview];
}

- (NSString *)smallProfileImageCacheKey
{
    return [self imageCacheKeyFor:ProfileImageSizePreview];
}

- (NSString *)mediumProfileImageCacheKey
{
    return [self imageCacheKeyFor:ProfileImageSizeComplete];
}

- (BOOL) managedByWire {
    return self.managedBy == nil || [self.managedBy isEqualToString:@"wire"];
}

- (ZMConversation *)oneToOneConversation
{
    if (self.isSelfUser) {
        return [ZMConversation selfConversationInContext:self.managedObjectContext];
    } else if (self.isTeamMember) {
        return [ZMConversation fetchOrCreateOneToOneTeamConversationWithMoc:self.managedObjectContext
                                                        participant:self
                                                               team:self.team
                                                    participantRole:nil];
    } else {
        return self.connection.conversation;
    }
}

- (BOOL)canBeConnected;
{
    if (self.isServiceUser || self.isWirelessUser) {
        return NO;
    }
    return ! self.isConnected && ! self.isPendingApprovalByOtherUser;
}

- (BOOL)isConnected;
{
    return self.connection != nil && self.connection.status == ZMConnectionStatusAccepted;
}

- (BOOL)isTeamMember
{
    return nil != self.membership;
}

+ (NSSet *)keyPathsForValuesAffectingIsConnected
{
    return [NSSet setWithObjects:ConnectionKey, @"connection.status", nil];
}

+ (NSSet *)keyPathsForValuesAffectingConnectionRequestMessage {
    return [NSSet setWithObject:@"connection.message"];
}


- (NSSet<UserClient *> *)clientsRequiringUserAttention
{
    NSMutableSet *clientsRequiringUserAttention = [NSMutableSet set];
    
    ZMUser *selfUser = [ZMUser selfUserInContext:self.managedObjectContext];
    
    for (UserClient *userClient in self.clients) {
        if (userClient.needsToNotifyUser && ! [selfUser.selfClient.trustedClients containsObject:userClient]) {
            [clientsRequiringUserAttention addObject:userClient];
        }
    }
    
    return clientsRequiringUserAttention;
}

- (void)refreshData
{
    self.needsToBeUpdatedFromBackend = true;
}

@end



@implementation ZMUser (Internal)

@dynamic normalizedName;
@dynamic connection;
@dynamic showingUserAdded;
@dynamic showingUserRemoved;
@dynamic createdTeams;

- (NSSet *)keysTrackedForLocalModifications
{
    if(self.isSelfUser) {
        return [super keysTrackedForLocalModifications];
    }
    else {
        return [NSSet set];
    }
}

- (NSSet *)ignoredKeys;
{
    static NSSet *keys;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSMutableSet *ignoredKeys = [[super ignoredKeys] mutableCopy];
        [ignoredKeys addObjectsFromArray:@[
                                           AnalyticsIdentifierKey,
                                           NormalizedNameKey,
                                           ConversationsCreatedKey,
                                           ActiveCallConversationsKey,
                                           ConnectionKey,
                                           ConversationsCreatedKey,
                                           ParticipantRolesKey,
                                           NormalizedEmailAddressKey,
                                           SystemMessagesKey,
                                           UserClientsKey,
                                           ShowingUserAddedKey,
                                           ShowingUserRemovedKey,
                                           ReactionsKey,
                                           AddressBookEntryKey,
                                           HandleKey, // this is not set on the user directly
                                           MembershipKey,
                                           CreatedTeamsKey,
                                           ServiceIdentifierKey,
                                           ProviderIdentifierKey,
                                           ExpiresAtKey,
                                           TeamIdentifierDataKey,
                                           UsesCompanyLoginKey,
                                           NeedsPropertiesUpdateKey,
                                           ReadReceiptsEnabledChangedRemotelyKey,
                                           isAccountDeletedKey,
                                           ManagedByKey,
                                           RichProfileKey,
                                           NeedsRichProfileUpdateKey,
                                           CreatedTeamMembersKey,
                                           LegalHoldRequestKey,
                                           NeedsToAcknowledgeLegalHoldStatusKey,
                                           NeedsToRefetchLabelsKey,
                                           @"lastServerSyncedActiveConversations", // OBSOLETE
                                           DomainKey
                                           ]];
        keys = [ignoredKeys copy];
    });
    return keys;
}

+ (nullable instancetype)userWithEmailAddress:(NSString *)emailAddress inContext:(NSManagedObjectContext *)context
{
    RequireString(0 != emailAddress.length, "emailAddress required");
    
    NSFetchRequest *usersWithEmailFetch = [NSFetchRequest fetchRequestWithEntityName:[ZMUser entityName]];
    usersWithEmailFetch.predicate = [NSPredicate predicateWithFormat:@"%K = %@", EmailAddressKey, emailAddress];
    NSArray<ZMUser *> *users = [context executeFetchRequestOrAssert:usersWithEmailFetch];
    
    RequireString(users.count <= 1, "More than one user with the same email address");
    
    if (0 == users.count) {
        return nil;
    }
    else if (1 == users.count) {
        return users.firstObject;
    }
    else {
        return nil;
    }
}

+ (nullable instancetype)userWithPhoneNumber:(NSString *)phoneNumber inContext:(NSManagedObjectContext *)context
{
    RequireString(0 != phoneNumber.length, "phoneNumber required");
    
    NSFetchRequest *usersWithPhoneFetch = [NSFetchRequest fetchRequestWithEntityName:[ZMUser entityName]];
    usersWithPhoneFetch.predicate = [NSPredicate predicateWithFormat:@"%K = %@", PhoneNumberKey, phoneNumber];
    NSArray<ZMUser *> *users = [context executeFetchRequestOrAssert:usersWithPhoneFetch];
    
    RequireString(users.count <= 1, "More than one user with the same phone number");
    
    if (0 == users.count) {
        return nil;
    }
    else if (1 == users.count) {
        return users.firstObject;
    }
    else {
        return nil;
    }
}

+ (NSSet <ZMUser *> *)usersWithRemoteIDs:(NSSet <NSUUID *>*)UUIDs inContext:(NSManagedObjectContext *)moc;
{
    return [self fetchObjectsWithRemoteIdentifiers:UUIDs inManagedObjectContext:moc];
}

- (NSUUID *)remoteIdentifier;
{
    return [self transientUUIDForKey:@"remoteIdentifier"];
}

- (void)setRemoteIdentifier:(NSUUID *)remoteIdentifier;
{
    [self setTransientUUID:remoteIdentifier forKey:@"remoteIdentifier"];
}

- (NSUUID *)teamIdentifier;
{
    return [self transientUUIDForKey:@"teamIdentifier"];
}

- (void)setTeamIdentifier:(NSUUID *)teamIdentifier;
{
    [self setTransientUUID:teamIdentifier forKey:@"teamIdentifier"];
}

+ (ZMAccentColor)accentColorFromPayloadValue:(NSNumber *)payloadValue
{
    ZMAccentColor color = (ZMAccentColor) payloadValue.intValue;
    if ((color <= ZMAccentColorUndefined) || (ZMAccentColorMax < color)) {
        color = (ZMAccentColor) (arc4random_uniform(ZMAccentColorMax - 1) + 1);
    }
    return color;
}

// NB: This method is called with **partial** user info and @c authoritative set to false, when the update payload
// is received from the notification stream.
- (void)updateWithTransportData:(NSDictionary *)transportData authoritative:(BOOL)authoritative
{
    NSDictionary *serviceData = [transportData optionalDictionaryForKey:@"service"];
    if (serviceData != nil) {
        NSString *serviceIdentifier = [serviceData optionalStringForKey:@"id"];
        if (serviceIdentifier != nil) {
            self.serviceIdentifier = serviceIdentifier;
        }

        NSString *providerIdentifier = [serviceData optionalStringForKey:@"provider"];
        if (providerIdentifier != nil) {
            self.providerIdentifier = providerIdentifier;
        }
    }
    
    NSNumber *deleted = [transportData optionalNumberForKey:@"deleted"];
    if (deleted != nil && deleted.boolValue && !self.isAccountDeleted) {
        [self markAccountAsDeletedAt:[NSDate date]];
    }
    
    if ([transportData optionalDictionaryForKey:@"sso_id"] || authoritative) {
        NSDictionary *ssoData = [transportData optionalDictionaryForKey:@"sso_id"];
        NSString *subject = [ssoData optionalStringForKey:@"subject"];
        self.usesCompanyLogin = subject != nil && [subject length] > 0;
    }
    
    
    NSDictionary *qualifiedID = [transportData optionalDictionaryForKey:@"qualified_id"];
    if (qualifiedID != nil) {
        NSString *domain = [qualifiedID stringForKey:@"domain"];
        NSUUID *remoteIdentifier = [qualifiedID[@"id"] UUID];
        
        if (self.domain == nil) {
            self.domain = domain;
        } else {
            RequireString([self.domain isEqual:domain], "User domain do not match in update: %s vs. %s",
                          domain.UTF8String,
                          self.domain.UTF8String);
        }
        
        if (self.remoteIdentifier == nil) {
            self.remoteIdentifier = remoteIdentifier;
        } else {
            RequireString([self.remoteIdentifier isEqual:remoteIdentifier], "User ids do not match in update: %s vs. %s",
                          remoteIdentifier.transportString.UTF8String,
                          self.remoteIdentifier.transportString.UTF8String);
        }
        
    } else {
        NSUUID *remoteID = [transportData[@"id"] UUID];
        if (self.remoteIdentifier == nil) {
            self.remoteIdentifier = remoteID;
        } else {
            RequireString([self.remoteIdentifier isEqual:remoteID], "User ids do not match in update: %s vs. %s",
                          remoteID.transportString.UTF8String,
                          self.remoteIdentifier.transportString.UTF8String);
        }
    }
                                 
    NSString *name = [transportData optionalStringForKey:@"name"];
    if (!self.isAccountDeleted && (name != nil || authoritative)) {
        self.name = name;
    }
    
    NSString *managedBy = [transportData optionalStringForKey:@"managed_by"];
    if (managedBy != nil || authoritative) {
        self.managedBy = managedBy;
    }
    
    NSString *handle = [transportData optionalStringForKey:@"handle"];
    if (handle != nil || authoritative) {
        self.handle = handle;
    }
    
    if ([transportData objectForKey:@"team"] || authoritative) {
        self.teamIdentifier = [transportData optionalUuidForKey:@"team"];
        [self createOrDeleteMembershipIfBelongingToTeam];
    }
    
    NSString *email = [transportData optionalStringForKey:@"email"];
    if ([transportData objectForKey:@"email"] || authoritative) {
        self.emailAddress = email.stringByRemovingExtremeCombiningCharacters;
    }
    
    NSString *phone = [transportData optionalStringForKey:@"phone"];
    if ([transportData objectForKey:@"phone"] || authoritative) {
        self.phoneNumber = phone.stringByRemovingExtremeCombiningCharacters;
    }
    
    NSNumber *accentId = [transportData optionalNumberForKey:@"accent_id"];
    if (accentId != nil || authoritative) {
        self.accentColorValue = [ZMUser accentColorFromPayloadValue:accentId];
    }
    
    NSDate *expiryDate = [transportData optionalDateForKey:@"expires_at"];
    if (nil != expiryDate) {
        self.expiresAt = expiryDate;
    }
    
    NSArray *assets = [transportData optionalArrayForKey:@"assets"];
    [self updateAssetDataWith:assets authoritative:authoritative];
    
    // We intentionally ignore the preview data.
    //
    // Need to see if we're changing the resolution, but it's currently way too small
    // to be of any use.
    
    if (authoritative) {
        self.needsToBeUpdatedFromBackend = NO;
    }
    
    [self updatePotentialGapSystemMessagesIfNeeded];
}

- (void)updatePotentialGapSystemMessagesIfNeeded
{
    for (ZMSystemMessage *systemMessage in self.showingUserAdded) {
        [systemMessage updateNeedsUpdatingUsersIfNeeded];
    }
    
    for (ZMSystemMessage *systemMessage in self.showingUserRemoved) {
        [systemMessage updateNeedsUpdatingUsersIfNeeded];
    }
}

+ (NSPredicate *)predicateForObjectsThatNeedToBeUpdatedUpstream;
{
    NSPredicate *basePredicate = [super predicateForObjectsThatNeedToBeUpdatedUpstream];
    NSPredicate *needsToBeUpdated = [NSPredicate predicateWithFormat:@"needsToBeUpdatedFromBackend == 0"];
    NSPredicate *nilRemoteIdentifiers = [NSPredicate predicateWithFormat:@"%K == nil && %K == nil", ZMUser.previewProfileAssetIdentifierKey, ZMUser.completeProfileAssetIdentifierKey];
    NSPredicate *notNilRemoteIdentifiers = [NSPredicate predicateWithFormat:@"%K != nil && %K != nil", ZMUser.previewProfileAssetIdentifierKey, ZMUser.completeProfileAssetIdentifierKey];
    
    // We don't want update the user when when we are in processing of updating profile images (only have one of the identifiers)
    NSPredicate *remoteIdentifiers = [NSCompoundPredicate orPredicateWithSubpredicates:@[nilRemoteIdentifiers, notNilRemoteIdentifiers]];
    
    return [NSCompoundPredicate andPredicateWithSubpredicates:@[basePredicate, needsToBeUpdated, remoteIdentifiers]];
}

- (void)updateWithSearchResultName:(NSString *)name handle:(NSString *)handle;
{
    // We never refetch unconnected users, but when performing a search we
    // might receive updated result and can update existing local users.
    if (name != nil && name != self.name) {
        self.name = name;
    }

    if (handle != nil && handle != self.handle) {
        self.handle = handle;
    }
}

@end


@implementation ZMUser (SelfUser)

+ (NSManagedObjectID *)storedObjectIdForUserInfoKey:(NSString *)objectIdKey persistedMetadataKey:(NSString *)metadataKey inContext:(NSManagedObjectContext *)moc
{
    NSManagedObjectID *moid = moc.userInfo[objectIdKey];
    if (moid == nil) {
        NSString *moidString = [moc persistentStoreMetadataForKey:metadataKey];
        if (moidString != nil) {
            NSURL *moidURL = [NSURL URLWithString:moidString];
            if (moidURL != nil) {
                moid = [moc.persistentStoreCoordinator managedObjectIDForURIRepresentation:moidURL];
                if (moid != nil) {
                    moc.userInfo[objectIdKey] = moid;
                }
            }
        }
    }
    return moid;
}

+ (ZMUser *)obtainCachedSessionById:(NSManagedObjectID *)moid inContext:(NSManagedObjectContext *)moc
{
    ZMUser *selfUser;
    if (moid != nil) {
        // It's ok for this to fail -- it will if the object is not around.
        ZMSession *session = (ZMSession *)[moc existingObjectWithID:moid error:NULL];
        Require((session == nil) || [session isKindOfClass: [ZMSession class]]);
        selfUser = session.selfUser;
    }
    return selfUser;
}

+ (ZMUser *)obtainCachedSelfUserById:(NSManagedObjectID *)moid inContext:(NSManagedObjectContext *)moc
{
    ZMUser *selfUser;
    if (moid != nil) {
        // It's ok for this to fail -- it will if the object is not around.
        NSManagedObject *result = [moc existingObjectWithID:moid error:NULL];
        Require((result == nil) || [result isKindOfClass: [ZMUser class]]);
        selfUser = (ZMUser *)result;
    }
    return selfUser;
}

+ (ZMUser *)createSessionIfNeededInContext:(NSManagedObjectContext *)moc withSelfUser:(ZMUser *)selfUser
{
    //clear old keys
    [moc.userInfo removeObjectForKey:SelfUserObjectIDKey];
    [moc setPersistentStoreMetadata:nil forKey:SelfUserObjectIDAsStringKey];

    NSError *error;

    //if there is no already session object than create one
    ZMSession *session = (ZMSession *)[moc executeFetchRequestOrAssert:[ZMSession sortedFetchRequest]].firstObject;
    if (session == nil) {
        session = [ZMSession insertNewObjectInManagedObjectContext:moc];
        RequireString([moc obtainPermanentIDsForObjects:@[session] error:&error],
                      "Failed to get ID for self user: %lu", (long) error.code);
    }
    
    //if there is already user in session, don't create new
    selfUser = selfUser ?: session.selfUser;
    
    if (selfUser == nil) {
        selfUser = [ZMUser insertNewObjectInManagedObjectContext:moc];
        RequireString([moc obtainPermanentIDsForObjects:@[selfUser] error:&error],
                      "Failed to get ID for self user: %lu", (long) error.code);
    }

    session.selfUser = selfUser;
    
    //store session object id in persistent metadata, so we can retrieve it from other context
    moc.userInfo[SessionObjectIDKey] = session.objectID;
    [moc setPersistentStoreMetadata:session.objectID.URIRepresentation.absoluteString forKey:SessionObjectIDAsStringKey];
    NOT_USED([moc makeMetadataPersistent]);
    // This needs to be a 'real' save, to make sure we push the metadata:
    RequireString([moc save:&error], "Failed to save self user: %lu", (long) error.code);

    return selfUser;
}

+ (ZMUser *)unboxSelfUserFromContextUserInfo:(NSManagedObjectContext *)moc
{
    ZMBoxedSelfUser *boxed = moc.userInfo[SelfUserKey];
    return boxed.selfUser;
}

+ (void)boxSelfUser:(ZMUser *)selfUser inContextUserInfo:(NSManagedObjectContext *)moc
{
    ZMBoxedSelfUser *boxed = [[ZMBoxedSelfUser alloc] init];
    boxed.selfUser = selfUser;
    moc.userInfo[SelfUserKey] = boxed;
}

+ (BOOL)hasSessionEntityInContext:(NSManagedObjectContext *)moc
{
    //In older client versions there is no Session entity (first model version )...
    return (moc.persistentStoreCoordinator.managedObjectModel.entitiesByName[[ZMSession entityName]] != nil);
}

+ (instancetype)selfUserInContext:(NSManagedObjectContext *)moc;
{
    // This method is a contention point.
    //
    // We're storing the object ID of the session (previously self user) (as a string) inside the store's metadata.
    // The metadata gets persisted, hence we're able to retrieve the session (self user) across launches.
    // Converting the string representation to an instance of NSManagedObjectID is not cheap.
    // We're hence caching the value inside the context's userInfo.
    
    //1. try to get boxed user from user info
    ZMUser *selfUser = [self unboxSelfUserFromContextUserInfo:moc];
    if (selfUser) {
        return selfUser;
    }
    
    // 2. try to get session object id by session key from user info or metadata
    NSManagedObjectID *moid = [self storedObjectIdForUserInfoKey:SessionObjectIDKey persistedMetadataKey:SessionObjectIDAsStringKey inContext:moc];
    if (moid == nil) {
        //3. try to get user object id by user id key from user info or metadata
        moid = [self storedObjectIdForUserInfoKey:SelfUserObjectIDKey persistedMetadataKey:SelfUserObjectIDAsStringKey inContext:moc];
        if (moid != nil) {
            //4. get user by it's object id
            selfUser = [self obtainCachedSelfUserById:moid inContext:moc];
            if (selfUser != nil) {
                //there can be no session object, create one and store self user in it
                (void)[self createSessionIfNeededInContext:moc withSelfUser:selfUser];
            }
        }
    }
    else {
        //4. get user from session by it's object id
        selfUser = [self obtainCachedSessionById:moid inContext:moc];
    }
    
    if (selfUser == nil) {
        //create user and store it's id in metadata by session key
        selfUser = [self createSessionIfNeededInContext:moc withSelfUser:nil];
    }
    //5. box user and store box in user info by user key
    [self boxSelfUser:selfUser inContextUserInfo:moc];
    
    return selfUser;
}

@end


@implementation  ZMUser (Utilities)

+ (ZMUser<ZMEditableUser> *)selfUserInUserSession:(id<ContextProvider>)session
{
    VerifyReturnNil(session != nil);
    return [self selfUserInContext:session.viewContext];
}

@end




@implementation ZMUser (Editable)

@dynamic readReceiptsEnabled;
@dynamic needsPropertiesUpdate;
@dynamic readReceiptsEnabledChangedRemotely;
@dynamic needsRichProfileUpdate;

- (void)setHandle:(NSString *)aHandle {
    [self willChangeValueForKey:HandleKey];
    [self setPrimitiveValue:[aHandle copy] forKey:HandleKey];
    [self didChangeValueForKey:HandleKey];
}

- (void)setName:(NSString *)aName {
    
    [self willChangeValueForKey:NameKey];
    [self setPrimitiveValue:[[aName copy] stringByRemovingExtremeCombiningCharacters] forKey:NameKey];
    [self didChangeValueForKey:NameKey];
    
    self.normalizedName = [self.name normalizedString];
}

- (void)setEmailAddress:(NSString *)anEmailAddress {
    
    [self willChangeValueForKey:EmailAddressKey];
    [self setPrimitiveValue:[anEmailAddress copy] forKey:EmailAddressKey];
    [self didChangeValueForKey:EmailAddressKey];
    
    self.normalizedEmailAddress = [self.emailAddress normalizedEmailaddress];
}

@end





@implementation ZMUser (Connections)


- (BOOL)isBlocked
{
    return self.blockState != ZMBlockStateNone;
}

+ (NSSet *)keyPathsForValuesAffectingIsBlocked
{
    return [NSSet setWithObjects:ConnectionKey, @"connection.status", nil];
}

- (ZMBlockState)blockState
{
    if (self.connection == nil) {
        return ZMBlockStateNone;
    }
    switch (self.connection.status) {
        case ZMConnectionStatusBlocked:
            return ZMBlockStateBlocked;
        case ZMConnectionStatusBlockedMissingLegalholdConsent:
            return ZMBlockStateBlockedMissingLegalholdConsent;
        default:
            return ZMBlockStateNone;
    }
}

+ (NSSet *)keyPathsForValuesAffectingBlockStateReason
{
    return [NSSet setWithObjects:ConnectionKey, @"connection.status", nil];
}

- (BOOL)isIgnored
{
    return self.connection != nil && self.connection.status == ZMConnectionStatusIgnored;
}

+ (NSSet *)keyPathsForValuesAffectingIsIgnored
{
    return [NSSet setWithObjects:ConnectionKey, @"connection.status", nil];
}

- (BOOL)isPendingApprovalBySelfUser
{
    return self.connection != nil && self.connection.status == ZMConnectionStatusPending;
}

+ (NSSet *)keyPathsForValuesAffectingIsPendingApprovalBySelfUser
{
    return [NSSet setWithObjects:ConnectionKey, @"connection.status", nil];
}

- (BOOL)isPendingApprovalByOtherUser
{
    return self.connection != nil && self.connection.status == ZMConnectionStatusSent;
}

+ (NSSet *)keyPathsForValuesAffectingIsPendingApprovalByOtherUser
{
    return [NSSet setWithObjects:ConnectionKey, @"connection.status", nil];
}

@end



@implementation ZMUser (ImageData)

+ (NSPredicate *)predicateForUsersOtherThanSelf
{
    return [NSPredicate predicateWithFormat:@"isSelfUser != YES"];
}

+ (NSPredicate *)predicateForSelfUser
{
    return [NSPredicate predicateWithFormat:@"isSelfUser == YES"];
}

@end



@implementation ZMUser (KeyValueValidation)

+ (BOOL)validateName:(NSString **)ioName error:(NSError **)outError
{
    [ExtremeCombiningCharactersValidator validateValue:ioName error:outError];
    if (outError != nil && *outError != nil) {
        return NO;
    }
    
    // The backend limits to 128. We'll fly just a bit below the radar.
    return *ioName == nil || [StringLengthValidator validateValue:ioName
                                              minimumStringLength:2
                                              maximumStringLength:100
                                                maximumByteLength:INT_MAX
                                                            error:outError];
}

+ (BOOL)isValidName:(NSString *)name
{
    NSString *value = [name copy];
    return [self validateName:&value error:nil];
}

+ (BOOL)validateAccentColorValue:(NSNumber **)ioAccent error:(NSError **)outError
{
    return [ZMAccentColorValidator validateValue:ioAccent error:outError];
}

+ (BOOL)validateEmailAddress:(NSString **)ioEmailAddress error:(NSError **)outError
{
    return [ZMEmailAddressValidator validateValue:ioEmailAddress error:outError];
}

+ (BOOL)isValidEmailAddress:(NSString *)emailAddress
{
    NSString *value = [emailAddress copy];
    return [self validateEmailAddress:&value error:nil];
}

+ (BOOL)validatePassword:(NSString **)ioPassword error:(NSError **)outError
{
    return [StringLengthValidator validateValue:ioPassword
                            minimumStringLength:8
                            maximumStringLength:120
                              maximumByteLength:INT_MAX
                                          error:outError];
}

+ (BOOL)isValidPassword:(NSString *)password
{
    NSString *value = [password copy];
    return [self validatePassword:&value error:nil];
}

+ (BOOL)validatePhoneNumber:(NSString **)ioPhoneNumber error:(NSError **)outError
{
    if (ioPhoneNumber == NULL || [*ioPhoneNumber length] < 1) {
        return NO;
    }
    else {
        return [ZMPhoneNumberValidator validateValue:ioPhoneNumber error:outError];
    }
}

+ (BOOL)isValidPhoneNumber:(NSString *)phoneNumber
{
    NSString *value = [phoneNumber copy];
    return [self validatePhoneNumber:&value error:nil];
}

+ (BOOL)validatePhoneVerificationCode:(NSString **)ioVerificationCode error:(NSError **)outError
{
    return [StringLengthValidator validateValue:ioVerificationCode
                            minimumStringLength:6
                            maximumStringLength:6
                              maximumByteLength:INT_MAX
                                          error:outError];
}

+ (BOOL)isValidPhoneVerificationCode:(NSString *)phoneVerificationCode
{
    NSString *value = [phoneVerificationCode copy];
    return [self validatePhoneVerificationCode:&value error:nil];
}

- (BOOL)validateValue:(id *)value forKey:(NSString *)key error:(NSError **)error
{
    if (self.isInserted) {
        // Self user gets inserted, no other users will. Ignore this case.
        //We does not need to validate selfUser for now, 'cuase it's not setup yet, i.e. it has empty name at this point
        return YES;
    }
    return [super validateValue:value forKey:key error:error];
}

- (BOOL)validateEmailAddress:(NSString **)ioEmailAddress error:(NSError **)outError
{
    return [ZMUser validateEmailAddress:ioEmailAddress error:outError];
}

- (BOOL)validateName:(NSString **)ioName error:(NSError **)outError
{
    return [ZMUser validateName:ioName error:outError];
}

- (BOOL)validateAccentColorValue:(NSNumber **)ioAccent error:(NSError **)outError
{
    return [ZMUser validateAccentColorValue:ioAccent error:outError];
}

@end




@implementation NSUUID (SelfUser)

- (BOOL)isSelfUserRemoteIdentifierInContext:(NSManagedObjectContext *)moc;
{
    return [[ZMUser selfUserInContext:moc].remoteIdentifier isEqual:self];
}

@end


