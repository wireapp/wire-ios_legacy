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

@import WireRequestStrategy;
#import "ZMSyncStateDelegate.h"

@class ZMCredentials;
@class UserClient;
@class ZMEmailCredentials;
@class ZMPersistentCookieStorage;
@class ZMCookie;

typedef NS_ENUM(NSUInteger, ZMClientRegistrationPhase) {
    /// The client is not registered - we send out a request to register the client
    ZMClientRegistrationPhaseUnregistered = 0,
    
    /// the user is not logged in yet or has entered the wrong credentials - we don't send out any requests
    ZMClientRegistrationPhaseWaitingForLogin,
    
    /// the user is logged in but is waiting to fetch the selfUser - we send out a request to fetch the selfUser
    ZMClientRegistrationPhaseWaitingForSelfUser,
    
    /// the user has too many devices registered - we send a request to fetch all devices
    ZMClientRegistrationPhaseFetchingClients,
    
    /// the user has selected a device to delete - we send a request to delete the device
    ZMClientRegistrationPhaseWaitingForDeletion,
    
    /// the user has registered with phone but needs to register an email address and password to register a second device - we wait until we have emailCredentials
    ZMClientRegistrationPhaseWaitingForEmailVerfication,
    
    /// The client is registered
    ZMClientRegistrationPhaseRegistered
};


extern NSString *const ZMPersistedClientIdKey;


@interface ZMClientRegistrationStatus : NSObject <ClientRegistrationDelegate, TearDownCapable>

- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext *)moc
                                      cookieStorage:(ZMPersistentCookieStorage *)cookieStorage
                  registrationStatusDelegate:(id<ZMClientRegistrationStatusDelegate>) registrationStatusDelegate;

- (void)prepareForClientRegistration;
- (BOOL)needsToRegisterClient;
+ (BOOL)needsToRegisterClientInContext:(NSManagedObjectContext *)moc;

- (void)didFetchSelfUser;
- (void)didRegisterClient:(UserClient *)client;

- (void)didDetectCurrentClientDeletion;
- (BOOL)clientIsReadyForRequests;

- (void)tearDown;

@property (nonatomic, readonly) ZMPersistentCookieStorage *cookieStorage;
@property (nonatomic, readonly) ZMClientRegistrationPhase currentPhase;
@property (nonatomic) ZMEmailCredentials *emailCredentials;

@property (nonatomic) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, weak) id <ZMClientRegistrationStatusDelegate> registrationStatusDelegate;
@property (nonatomic) BOOL needsToCheckCredentials;
@property (nonatomic) BOOL isWaitingForUserClients;

@end
