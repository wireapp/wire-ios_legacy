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


#import <Foundation/Foundation.h>
#include "ZMUserSessionTestsBase.h"
#import "Tests-Swift.h"
@import WireSyncEngine;

@implementation ThirdPartyServices

- (void)userSessionIsReadyToUploadServicesData:(ZMUserSession *)userSession;
{
    NOT_USED(userSession);
    ++self.uploadCount;
}

@end

@implementation ZMUserSessionTestsBase

- (void)setUp
{
    [super setUp];
    
    WireCallCenterV3Factory.wireCallCenterClass = WireCallCenterV3Mock.self;
    
    self.thirdPartyServices = [[ThirdPartyServices alloc] init];
    self.dataChangeNotificationsCount = 0;
    self.baseURL = [NSURL URLWithString:@"http://bar.example.com"];
    self.cookieStorage = [ZMPersistentCookieStorage storageForServerName:@"usersessiontest.example.com" userIdentifier:NSUUID.createUUID];
    self.mockPushChannel = [[MockPushChannel alloc] init];
    self.transportSession = [[RecordingMockTransportSession alloc] initWithCookieStorage:self.cookieStorage pushChannel:self.mockPushChannel];
    self.mockSessionManager = [[MockSessionManager alloc] init];
    self.mediaManager = [[MockMediaManager alloc] init];
    self.flowManagerMock = [[FlowManagerMock alloc] init];

    NSUUID *userId = [NSUUID createUUID];
    [ZMUser selfUserInContext:self.syncMOC].remoteIdentifier = userId;
    
    [self createSutWithUserId:userId];

    self.sut.thirdPartyServicesDelegate = self.thirdPartyServices;
    self.sut.sessionManager = (id<SessionManagerType>)self.mockSessionManager;
    
    WaitForAllGroupsToBeEmpty(0.5);
    
    self.validCookie = [@"valid-cookie" dataUsingEncoding:NSUTF8StringEncoding];
}

- (void)tearDown
{
    NSURL *cachesURL = [[NSFileManager defaultManager] cachesURLForAccountWith:self.userIdentifier in:self.sut.sharedContainerURL];
    NSArray *items = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:cachesURL includingPropertiesForKeys:nil options:0 error:nil];
    for (NSURL *item in items) {
        [[NSFileManager defaultManager] removeItemAtURL:item error:nil];
    }
    
    self.baseURL = nil;
    self.cookieStorage = nil;
    self.validCookie = nil;
    self.thirdPartyServices = nil;
    self.sut.thirdPartyServicesDelegate = nil;
    self.mockSessionManager = nil;
    self.transportSession = nil;
    self.mediaManager = nil;
    self.flowManagerMock = nil;
    id tempSut = self.sut;
    self.sut = nil;
    [tempSut tearDown];
    
    [super tearDown];
}

- (void)didChangeAuthenticationData
{
    ++self.dataChangeNotificationsCount;
}

- (void)simulateLoggedInUser
{
    [self.syncMOC setPersistentStoreMetadata:@"foooooo" forKey:ZMPersistedClientIdKey];
    [ZMUser selfUserInContext:self.syncMOC].remoteIdentifier = [NSUUID createUUID];
    [self.cookieStorage setAuthenticationCookieData:self.validCookie];
}

@end
