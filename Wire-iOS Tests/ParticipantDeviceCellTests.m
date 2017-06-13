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


#import <WireSyncEngine/WireSyncEngine.h>
#import "ZMSnapshotTestCase.h"
@import PureLayout;
#import "ParticipantDeviceCell.h"
#import "Wire_iOS_Tests-Swift.h"


@interface ParticipantDeviceCellTests : ZMSnapshotTestCase
@property (nonatomic) ParticipantDeviceCell *sut;
@property (nonatomic) ZMUser *user;
@end


@implementation ParticipantDeviceCellTests

- (void)setUp
{
    [super setUp];
    self.sut = [[ParticipantDeviceCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"reuseIdentifier"];
    [self.sut autoSetDimension:ALDimensionHeight toSize:64]; // This is a fixed height cell
    self.user = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
}

- (void)testThatItRendersTheCellUnverifiedFullWidthIdentifierLongerThan_16_Characters
{
    UserClient *client = [UserClient insertNewObjectInManagedObjectContext:self.uiMOC];
    client.remoteIdentifier = @"102030405060708090";
    client.user = self.user;
    client.deviceClass = @"tablet";
    [self.sut configureForClient:client];
    ZMVerifyView([self.sut wrapInTableView]);
}

- (void)testThatItRendersTheCellUnverifiedTruncatedIdentifier
{
    UserClient *client = [UserClient insertNewObjectInManagedObjectContext:self.uiMOC];
    client.remoteIdentifier = @"807060504030201";
    client.user = self.user;
    client.deviceClass = @"desktop";
    [self.sut configureForClient:client];
    ZMVerifyView([self.sut wrapInTableView]);
}

- (void)testThatItRendersTheCellUnverifiedTruncatedIdentifierMultipleCharactersMissing
{
    UserClient *client = [UserClient insertNewObjectInManagedObjectContext:self.uiMOC];
    client.remoteIdentifier = @"7060504030201";
    client.user = self.user;
    client.deviceClass = @"desktop";
    [self.sut configureForClient:client];
    ZMVerifyView([self.sut wrapInTableView]);
}

- (void)testThatItRendersTheCellVerifiedWithLabel
{
    UserClient *client = [UserClient insertNewObjectInManagedObjectContext:self.uiMOC];
    client.remoteIdentifier = @"e7b2u9d4s85h1gv0";
    client.user = self.user;
    client.deviceClass = @"phone";
    [self trustClient:client];
    [self.sut configureForClient:client];
    ZMVerifyView([self.sut wrapInTableView]);
}

#pragma mark - Helper

- (void)trustClient:(UserClient *)client
{
    UserClient *selfClient = [UserClient insertNewObjectInManagedObjectContext:self.uiMOC];
    selfClient.remoteIdentifier = @"selfClientID";
    [self.uiMOC setPersistentStoreMetadata:@"selfClientID" forKey:ZMPersistedClientIdKey];
    selfClient.user = [ZMUser selfUserInContext:self.uiMOC];
    [selfClient trustClient:client];
    
    
}

@end
