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


#import "ZMClientRegistrationStatus.h"
#import "ZMOperationLoop.h"
#import "ZMAuthenticationStatus_Internal.h"
#import "ZMClientRegistrationStatus+Internal.h"
#import "ZMCredentials.h"
#import <WireSyncEngine/WireSyncEngine-Swift.h>

@import UIKit;

NSString *const ZMPersistedClientIdKey = @"PersistedClientId";

static NSString *ZMLogTag ZM_UNUSED = @"Authentication";

@interface ZMClientRegistrationStatus ()

@property (nonatomic) BOOL isWaitingForClientsToBeDeleted;
@property (nonatomic) BOOL isWaitingForCredentials;
@property (nonatomic) BOOL needsToVerifySelfClient;

@property (nonatomic) ZMPersistentCookieStorage *cookieStorage;

@property (nonatomic) id clientUpdateToken;
@property (nonatomic) BOOL tornDown;

@end



@implementation ZMClientRegistrationStatus

- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext *)moc
                                      cookieStorage:(ZMPersistentCookieStorage *)cookieStorage
                  registrationStatusDelegate:(id<ZMClientRegistrationStatusDelegate>) registrationStatusDelegate;
{
    self = [super init];
    if (self != nil) {
        self.managedObjectContext = moc;
        self.registrationStatusDelegate = registrationStatusDelegate;
        self.needsToVerifySelfClient = !self.needsToRegisterClient;
        self.cookieStorage = cookieStorage;
        
        [self observeClientUpdates];
    }
    return self;
}

- (void)observeClientUpdates
{
    ZM_WEAK(self);
    self.clientUpdateToken = [ZMClientUpdateNotification addObserverWithContext:self.managedObjectContext block:^(enum ZMClientUpdateNotificationType type, NSArray<NSManagedObjectID *> *clientObjectIDs, NSError *error) {
        ZM_STRONG(self);
        [self.managedObjectContext performGroupedBlock:^{
            if (type == ZMClientUpdateNotificationTypeFetchCompleted) {
                [self didFetchClients:clientObjectIDs];
            }
            if (type == ZMClientUpdateNotificationTypeDeletionCompleted) {
                [self didDeleteClient];
            }
            if (type == ZMClientUpdateNotificationTypeDeletionFailed) {
                [self failedDeletingClient:error];
            }
            if (type == ZMClientUpdateNotificationTypeFetchFailed) {
                [self failedFetchingClients:error];
            }
        }];
    }];
}

- (void)tearDown
{
    self.clientUpdateToken = nil;
    self.tornDown = YES;
}

- (void)dealloc
{
    NSAssert(self.tornDown, @"needs to call teardown before deallocating");
}

- (ZMClientRegistrationPhase)currentPhase
{
    /*
     The flow is as follows
     ZMClientRegistrationPhaseWaitingForLogin
     [We try to login / register with the given credentials]
                |
     ZMClientRegistrationPhaseWaitingForSelfUser
     [We fetch the selfUser]
                |
     [User has email address,
      and it's not the SSO user]    --> NO  --> ZMClientRegistrationPhaseWaitingForEmailVerfication
                                                [user adds email and password, we fetch user from BE]
                                            --> ZMClientRegistrationPhaseUnregistered
                                                [Client is registered]
                                            --> ZMClientRegistrationPhaseRegistered
                                    --> YES --> Proceed
     ZMClientRegistrationPhaseUnregistered
     [We try to register the client without the password]
                |
     [Request succeeds ?]           --> YES --> ZMClientRegistrationPhaseRegistered // this is the case for the first device registered
                |
                NO
                |
     [User has email address?]      --> YES --> ZMClientRegistrationPhaseWaitingForLogin 
                                                [User enters password]
                                            --> ZMClientRegistrationPhaseUnregistered
                                                [User entered correct password ?] -->  YES --> Continue at [User has too many devices]
                                                                                  -->  NO  --> ZMClientRegistrationPhaseWaitingForLogin

     [User has too many deviced?]    --> YES --> ZMClientRegistrationPhaseFetchingClients
                                                [User selects device to delete]
                                            --> ZMClientRegistrationPhaseWaitingForDeletion
                                                [BE deletes device]
                                            --> See [NO]
                                     --> NO --> ZMClientRegistrationPhaseUnregistered
                                                [Client is registered]
                                            --> ZMClientRegistrationPhaseRegistered
     
    */
    
    // we only enter this state when the authentication has succeeded
    if (self.isWaitingForLogin) {
        return ZMClientRegistrationPhaseWaitingForLogin;
    }
    
    // before registering client we need to fetch self user to know whether or not the user has registered an email address
    if (self.isWaitingForSelfUser) {
        return ZMClientRegistrationPhaseWaitingForSelfUser;
    }
    
    // when the registration fails because the password is missing or wrong, we need to stop making requests until we have a new password
    if (self.needsToCheckCredentials && self.emailCredentials == nil) {
        return ZMClientRegistrationPhaseWaitingForLogin;
    }
    
    // when the client registration fails because there are too many clients already registered we need to fetch clients from the backend
    if (self.isWaitingForUserClients) {
        return ZMClientRegistrationPhaseFetchingClients;
    }
    
    // when the user
    if (!self.needsToRegisterClient) {
        return ZMClientRegistrationPhaseRegistered;
    }
    
    // when the user has previously only registered by phone and now wants to register a second device, he needs to register his email address and password first
    if (self.isAddingEmailNecessary) {
        return ZMClientRegistrationPhaseWaitingForEmailVerfication;
    }
    
    // when the user has too many clients registered already and selected one device to delete
    if (self.isWaitingForClientsToBeDeleted) {
        return ZMClientRegistrationPhaseWaitingForDeletion;
    }
    return ZMClientRegistrationPhaseUnregistered;
}

- (BOOL)isWaitingForLogin
{
    return self.cookieStorage.authenticationCookieData == nil;
}

- (BOOL)needsToRegisterClient
{
    return [[self class] needsToRegisterClientInContext:self.managedObjectContext];
}

+ (BOOL)needsToRegisterClientInContext:(NSManagedObjectContext *)moc;
{
    //replace with selfUser.client.remoteIdentifier == nil
    NSString *clientId = [moc persistentStoreMetadataForKey:ZMPersistedClientIdKey];
    return ![clientId isKindOfClass:[NSString class]] || clientId.length == 0;
}

- (BOOL)isWaitingForSelfUser
{
    ZMUser *selfUser = [ZMUser selfUserInContext:self.managedObjectContext];
    return (selfUser.remoteIdentifier == nil);
}

- (BOOL)isWaitingForSelfUserEmail
{
    ZMUser *selfUser = [ZMUser selfUserInContext:self.managedObjectContext];
    return (selfUser.emailAddress == nil);
}

- (BOOL)isAddingEmailNecessary
{
    ZMUser *selfUser = [ZMUser selfUserInContext:self.managedObjectContext];
    return ![self.managedObjectContext registeredOnThisDevice] &&
            self.isWaitingForSelfUserEmail &&
           !selfUser.usesCompanyLogin;
}

- (void)prepareForClientRegistration
{
    if (!self.needsToRegisterClient) {
        return;
    }
    
    ZMUser *selfUser = [ZMUser selfUserInContext:self.managedObjectContext];
    if (selfUser.remoteIdentifier == nil) {
        return;
    }
    
    if ([self needsToCreateNewClientForSelfUser:selfUser]) {
        ZMLogDebug(@"%@", NSStringFromSelector(_cmd));
        [self insertNewClientForSelfUser:selfUser];
    }
    else {
        // there is already an unregistered client in the store
        // since there is no change in the managedObject, it will not trigger [ZMRequestAvailableNotification notifyNewRequestsAvailable:] automatically
        // therefore we need to call it here
        [ZMRequestAvailableNotification notifyNewRequestsAvailable:self];
    }
}

- (BOOL)needsToCreateNewClientForSelfUser:(ZMUser *)selfUser
{
    if (selfUser.selfClient != nil && !selfUser.selfClient.isZombieObject) {
        return NO;
    }
    UserClient *notYetRegisteredClient = [selfUser.clients.allObjects firstObjectMatchingWithBlock:^BOOL(UserClient *client) {
        return client.remoteIdentifier == nil;
    }];
    return (notYetRegisteredClient == nil);
}

- (void)insertNewClientForSelfUser:(ZMUser *)selfUser
{
    [UserClient insertNewSelfClientInManagedObjectContext:self.managedObjectContext
                                                 selfUser:selfUser
                                                    model:[[UIDevice currentDevice] zm_model]
                                                    label:[[UIDevice currentDevice] name]];
    
    [self.managedObjectContext saveOrRollback];
}


- (void)didFetchSelfUser;
{
    ZMLogDebug(@"%@", NSStringFromSelector(_cmd));
    if (self.needsToRegisterClient) {
        
        if (self.isAddingEmailNecessary) {
            [self notifyEmailIsNecessary];
        }
        
        [self prepareForClientRegistration];
    }
    else {
        if (!self.needsToVerifySelfClient) {
            self.emailCredentials = nil;
        }
    }
    ZMLogDebug(@"current phase: %lu", (unsigned long)self.currentPhase);
}


- (void)didRegisterClient:(UserClient *)client
{
    ZMLogDebug(@"%@", NSStringFromSelector(_cmd));
    [self.managedObjectContext setPersistentStoreMetadata:client.remoteIdentifier forKey:ZMPersistedClientIdKey];
    [self.managedObjectContext saveOrRollback];
    
    [self fetchExistingSelfClientsAfterClientRegistered:client];
    [self.registrationStatusDelegate didRegisterSelfUserClient:client];
    self.emailCredentials = nil;
    self.needsToCheckCredentials = NO;
    
    ZMLogDebug(@"current phase: %lu", (unsigned long)self.currentPhase);
}

- (void)fetchExistingSelfClientsAfterClientRegistered:(UserClient *)currentSelfClient
{
    ZMUser *selfUser = [ZMUser selfUserInContext:self.managedObjectContext];

    NSSet *allClientsExceptCurrent = [selfUser.clients filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"remoteIdentifier != %@", currentSelfClient.remoteIdentifier]];
    if (allClientsExceptCurrent.count > 0) {
        [currentSelfClient missesClients:allClientsExceptCurrent];
        [currentSelfClient setLocallyModifiedKeys:[NSSet setWithObject:@"missingClients"]];
    }
}

- (void)notifyEmailIsNecessary
{
    NSError *emailMissingError = [[NSError alloc] initWithDomain:NSError.ZMUserSessionErrorDomain
                                                            code:ZMUserSessionNeedsToRegisterEmailToRegisterClient
                                                        userInfo:nil];
    [self.registrationStatusDelegate didFailToRegisterSelfUserClient:emailMissingError];
}

- (void)didFetchClients:(NSArray<NSManagedObjectID *> *)clientIDs;
{
    ZMLogDebug(@"%@", NSStringFromSelector(_cmd));
 
    if (self.needsToVerifySelfClient) {
        self.emailCredentials = nil;
        self.needsToVerifySelfClient = NO;
    }
    
    if (self.isWaitingForUserClients) {
        NSMutableDictionary *errorUserInfo = [NSMutableDictionary dictionary];
        errorUserInfo[ZMClientsKey] = clientIDs;
        NSError *outError = [NSError userSessionErrorWithErrorCode:ZMUserSessionCanNotRegisterMoreClients userInfo:errorUserInfo];
        [self.registrationStatusDelegate didFailToRegisterSelfUserClient:outError];
        self.isWaitingForUserClients = NO;
        self.isWaitingForClientsToBeDeleted = YES;
    }
}

- (void)failedFetchingClients:(NSError *)error
{
    if (error.code == ClientUpdateErrorSelfClientIsInvalid) {

        ZMUser *selfUser = [ZMUser selfUserInContext:self.managedObjectContext];
        UserClient *selfClient = selfUser.selfClient;

        if (selfClient != nil) {
            // the selfClient was removed by an other user
            [self didDetectCurrentClientDeletion];
        }
        self.needsToVerifySelfClient = NO;
    }
    if (error.code == ClientUpdateErrorDeviceIsOffline) {
        // we do nothing
    }
}

- (void)didDetectCurrentClientDeletion
{
    [self invalidateSelfClient];
    
    NSFetchRequest *clientFetchRequest = [UserClient sortedFetchRequest];
    NSArray <UserClient *>*clients = [self.managedObjectContext executeFetchRequestOrAssert:clientFetchRequest];
    
    for (UserClient *client in clients) {
        [client deleteClientAndEndSession];
    }
    
    [self.managedObjectContext deleteAndCreateNewEncryptionContext];
    [self invalidateCookieAndNotify];
}

- (BOOL)clientIsReadyForRequests
{
    return self.currentPhase == ZMClientRegistrationPhaseRegistered;
}

- (void)invalidateSelfClient
{
    ZMUser *selfUser = [ZMUser selfUserInContext:self.managedObjectContext];
    UserClient *selfClient = selfUser.selfClient;

    selfClient.remoteIdentifier = nil;
    [selfClient resetLocallyModifiedKeys:selfClient.keysThatHaveLocalModifications];
    [self.managedObjectContext setPersistentStoreMetadata:nil forKey:ZMPersistedClientIdKey];
    [self.managedObjectContext saveOrRollback];
}

- (void)didDeleteClient
{
    if (self.isWaitingForClientsToBeDeleted) {
        self.isWaitingForClientsToBeDeleted = NO;
        [self prepareForClientRegistration];
    }
}

- (void)failedDeletingClient:(NSError *)error
{
    NOT_USED(error);
    // this should not happen since we just added a password or registered -> hmm
}

@end
