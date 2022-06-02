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

@import avs;
@import UIKit;

#import "IntegrationTest.h"
#import "Tests-Swift.h"
#import <WireSyncEngine/WireSyncEngine.h>

@implementation IntegrationTest

- (void)setUp {
    [super setUp];
    BackgroundActivityFactory.sharedFactory.activityManager = UIApplication.sharedApplication;
    [BackgroundActivityFactory.sharedFactory resume];

    self.mockMediaManager = [[MockMediaManager alloc] init];
    self.mockEnvironment = [[MockEnvironment alloc] init];
    self.mockLoginDelegete = [[MockLoginDelegate alloc] init];
    self.appState = @"authenticated";
    
    self.currentUserIdentifier = [NSUUID createUUID];
    [self configureDefaultAPIVersion];
    [self _setUp];
}

- (void)tearDown {
    [self _tearDown];
    BackgroundActivityFactory.sharedFactory.activityManager = nil;
    
    self.mockMediaManager = nil;
    self.currentUserIdentifier = nil;
    self.mockEnvironment = nil;
    
    WaitForAllGroupsToBeEmpty(0.5);
    [NSFileManager.defaultManager removeItemAtURL:[MockUserClient mockEncryptionSessionDirectory] error:nil];
    
    [super tearDown];
}

- (BOOL)useInMemoryStore
{
    return YES;
}

- (BOOL)useRealKeychain
{
    return NO;
}

- (ZMTransportSession *)transportSession
{
    return (ZMTransportSession *)self.mockTransportSession;
}

@end
