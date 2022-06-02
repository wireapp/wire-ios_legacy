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


@import CoreData;
@import WireTransport;
@import WireUtilities;

#import "MockConnection.h"
#import "MockConversation.h"
#import "MockPicture.h"
#import "MockEvent.h"
#import "MockAsset.h"

@class MockPushEvent;
@class MockTeam;
@class MockMember;
@class MockService;
@class MockAsset;

@protocol MockTransportSessionObjectCreation;
@protocol UnauthenticatedTransportSessionDelegate;

NS_ASSUME_NONNULL_BEGIN

typedef ZMTransportResponse * _Nullable (^ZMCustomResponseGeneratorBlock)(ZMTransportRequest * _Nonnull request);

@interface MockTransportSession : NSObject <ZMRequestCancellation, ZMBackgroundable>

- (instancetype)initWithDispatchGroup:(nullable ZMSDispatchGroup *)group NS_DESIGNATED_INITIALIZER;

/// This will simply return @c self, but typecast to the expected type. For convenience.
- (ZMTransportSession *)mockedTransportSession;

@property (nonatomic, readonly) id<ZMPushChannel> pushChannel;
@property (nonatomic, nullable) id _userInfoAvailableClosure;

@property (nonatomic) NSURL *baseURL;
@property (nonatomic) NSURL *websocketURL;

@property (nonatomic) NSString *clientID;
@property (nonatomic) ZMPersistentCookieStorage *cookieStorage;
@property (readonly, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, readonly, copy) ZMCompletionHandlerBlock accessTokenFailureHandler;
@property (nonatomic, readonly, copy) ZMAccessTokenHandlerBlock accessTokenSuccessHandler;

@property (nonatomic, readonly) MockUser* selfUser;
@property (nonatomic, readonly) BOOL isPushChannelActive;
@property (nonatomic, copy, nullable) ZMCustomResponseGeneratorBlock responseGeneratorBlock;
@property (nonatomic, readonly) NSDictionary <NSString *, NSDictionary *> *pushTokens;
@property (nonatomic) BOOL disableEnqueueRequests;
@property (nonatomic) BOOL doNotRespondToRequests; //to simulate offline

/// List of domains which the backend is federated with
@property (nonatomic) NSArray<NSString *> *federatedDomains;

// What gets returned on GET /api-version
@property (nonatomic) NSArray<NSNumber *> *supportedAPIVersions;
@property (nonatomic) NSString *domain;
@property (nonatomic) BOOL federation;
@property (nonatomic) BOOL isAPIVersionEndpointAvailable;

@property (nonatomic, readonly) NSArray *updateEvents;

@property (nonatomic, readwrite) id<ReachabilityProvider, TearDownCapable> reachability;

@property (nonatomic) BOOL useLegaclyPushNotifications;

@property (nonatomic,  readonly, nullable) NSString *generatedEmailVerificationCode;

+ (NSString *)binaryDataTypeAsMIME:(NSString *)type;

- (void)addPushToken:(NSString *)token payload:(NSDictionary *)payload;
- (void)removePushToken:(NSString *)token;

- (void)configurePushChannelWithConsumer:(id<ZMPushChannelConsumer>)consumer groupQueue:(id<ZMSGroupQueue>)groupQueue NS_SWIFT_NAME(configurePushChannel(consumer:groupQueue:));

- (void)setAccessTokenRenewalFailureHandler:(ZMCompletionHandlerBlock)handler NS_SWIFT_NAME(setAccessTokenRenewalFailureHandler(handler:));
- (void)setAccessTokenRenewalSuccessHandler:(ZMAccessTokenHandlerBlock)handler;

- (void)setNetworkStateDelegate:(nullable id<ZMNetworkStateDelegate>)delegate;

- (BOOL)waitForAllRequestsToCompleteWithTimeout:(NSTimeInterval)timeout;

/// A list on transport requests received by client
- (NSArray<ZMTransportRequest *> *)receivedRequests;
/// Resets the list of received requests
- (void)resetReceivedRequests;

- (void)expireAllBlockedRequests;
- (void)tearDown;
- (void)completeAllBlockedRequests;

- (void)completePreviouslySuspendendRequest:(ZMTransportRequest *)request;

- (void)registerPushEvent:(MockPushEvent *)mockPushEvent;
- (void)logoutSelfUser;

/// Called after test case is finished to release all resources
- (void)cleanUp;

@end



@interface MockTransportSession (Mock)

- (void)completeRequest:(ZMTransportRequest *)originalRequest completionHandler:(ZMCompletionHandlerBlock)completionHandler;
- (ZMTransportEnqueueResult *)attemptToEnqueueSyncRequestWithGenerator:(NS_NOESCAPE ZMTransportRequestGenerator)requestGenerator;
- (void)enqueueOneTimeRequest:(ZMTransportRequest *)request NS_SWIFT_NAME(enqueueOneTime(_:));

@end



@interface MockTransportSession (CreatingObjects)

/// Runs the given @c block on the context's queue and saves the context.
- (void)performRemoteChanges:(void(^)(id<MockTransportSessionObjectCreation>))block;

- (void)saveAndCreatePushChannelEvents;
- (void)saveAndCreatePushChannelEventForSelfUser;

@end



@protocol MockTransportSessionObjectCreation <NSObject, ZMRequestCancellation>

- (MockUser *)insertSelfUserWithName:(NSString *)name;
- (MockUser *)insertUserWithName:(NSString *)name;
- (MockUser *)insertUserWithName:(NSString *)name includeClient:(BOOL)shouldIncludeClient;
- (NSDictionary<NSString *, MockPicture *> *)addProfilePictureToUser:(MockUser *)user;
- (NSDictionary<NSString *, MockAsset *> *)addV3ProfilePictureToUser:(MockUser *)user;
- (MockConnection *)insertConnectionWithSelfUser:(MockUser *)selfUser toUser:(MockUser *)toUser;

- (MockConversation *)insertSelfConversationWithSelfUser:(MockUser *)selfUser;
- (MockConversation *)insertOneOnOneConversationWithSelfUser:(MockUser *)selfUser otherUser:(MockUser *)otherUser;
- (MockConversation *)insertGroupConversationWithSelfUser:(MockUser *)selfUser otherUsers:(NSArray *)otherUsers;
- (MockConversation *)insertConversationWithSelfUser:(MockUser *)selfUser creator:(MockUser *)creator otherUsers:(nullable NSArray *)otherUsers type:(ZMTConversationType)conversationType;
- (MockConversation *)insertConversationWithSelfUserAndGroupRoles:(MockUser *)selfUser otherUsers:(nullable NSArray *)otherUsers;
- (MockConversation *)insertConversationWithCreator:(MockUser *)creator otherUsers:(NSArray *)otherUsers type:(ZMTConversationType)conversationType;

- (MockAsset *)insertAssetWithID:(NSUUID *)assetID assetToken:(NSUUID *)assetToken assetData:(NSData *)assetData contentType:(NSString *)contentType;

- (MockAsset *)insertAssetWithID:(NSUUID *)assetID domain:(nullable NSString *)domain assetToken:(NSUUID *)assetToken assetData:(NSData *)assetData contentType:(NSString *)contentType;

- (void)simulatePushChannelClosed;
- (void)simulatePushChannelOpened;

/// Whitelist an email so that registration is automatically verified
- (void)whiteListEmail:(NSString *)email;
/// Whitelist a phone so that we can login directly without asking for the code first (used in tests)
- (void)whiteListPhone:(NSString *)phone;

/// simulate the other party accepting a connection request
- (void)remotelyAcceptConnectionToUser:(MockUser*)user;

/// remove all stored /notification
- (void)clearNotifications;

- (MockConnection *)createConnectionRequestFromUser:(MockUser*)fromUser toUser:(MockUser*)toUser message:(nullable NSString *)message;

- (MockUserClient *)registerClientForUser:(MockUser *)user;
- (MockUserClient *)registerClientForUser:(MockUser *)user label:(NSString *)label type:(NSString *)type deviceClass:(NSString *)deviceClass;

/// deletes a remote user client for a user
- (void)deleteUserClientWithIdentifier:(NSString *)identifier forUser:(MockUser *)user;

- (void)createAssetWithData:(NSData *)data identifier:(NSString *)identifier contentType:(NSString *)contentType forConversation:(NSString *)conversation;

/// Returns the user (if any) with the given remote identifier
- (nullable MockUser *)userWithRemoteIdentifier:(NSString *)remoteIdentifier;

/// Returns the client (if any) for the given remote identifier
- (nullable MockUserClient *)clientForUser:(MockUser *)user remoteIdentifier:(NSString *)remoteIdentifier;

/// isBound means the team was created with version2 of teams and is bound to this user account
- (MockTeam *)insertTeamWithName:(nullable NSString *)name isBound:(BOOL)isBound;
- (MockTeam *)insertTeamWithName:(nullable NSString *)name isBound:(BOOL)isBound users:(NSSet<MockUser*> *)users;
- (MockMember *)insertMemberWithUser:(MockUser *)user inTeam:(MockTeam *)team;
- (void)removeMemberWithUser:(MockUser *)user fromTeam:(MockTeam *)team;
- (void)deleteTeam:(nonnull MockTeam *)team;
- (MockConversation *)insertTeamConversationToTeam:(MockTeam *)team withUsers:(NSArray<MockUser *> *)users creator:(MockUser *)creator;
- (void)deleteConversation:(nonnull MockConversation *)conversation;
- (void)deleteAccountForUser:(nonnull MockUser *)user;

/// Support for services
- (MockService *)insertServiceWithName:(NSString *)name
                            identifier:(NSString *)identifier
                              provider:(NSString *)provider;
@end

@interface MockTransportSession (IsTyping)

- (void)sendIsTypingEventForConversation:(MockConversation *)conversation user:(MockUser *)user started:(BOOL)started;

@end

@interface MockTransportSession (PhoneVerification)

@property (nonatomic, readonly) NSString *phoneVerificationCodeForRegistration;
@property (nonatomic, readonly) NSString *phoneVerificationCodeForLogin;
@property (nonatomic, readonly) NSString *phoneVerificationCodeForUpdatingProfile;
@property (nonatomic, readonly) NSString *invalidPhoneVerificationCode;

@end


NS_ASSUME_NONNULL_END

