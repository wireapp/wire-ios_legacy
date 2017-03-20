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


#import "ZMSnapshotTestCase.h"
#import "Wire_iOS_Tests-Swift.h"
#import "Wire-Swift.h"
#import "Wire_iOS_Tests-Swift.h"
#import "MockMessage+Creation.h"
#import "WAZUIMagicIOS.h"
@import zmessaging;

@interface IconSystemCellTests : ZMSnapshotTestCase

@end

@implementation IconSystemCellTests

+ (NSDictionary *)systemMessageTypeToClass
{
    return @{
             @(ZMSystemMessageTypeNewClient):            [ConversationNewDeviceCell class],
             @(ZMSystemMessageTypeIgnoredClient):        [ConversationIgnoredDeviceCell class],
             @(ZMSystemMessageTypeConversationIsSecure): [ConversationVerifiedCell class],
             @(ZMSystemMessageTypePotentialGap):         [MissingMessagesCell class],
             @(ZMSystemMessageTypeDecryptionFailed):     [CannotDecryptCell class],
             @(ZMSystemMessageTypeReactivatedDevice):    [MissingMessagesCell class]
             };
}

+ (UITableView *)wrappedCellForMessageType:(ZMSystemMessageType)type users:(NSUInteger)usersCount clients:(NSUInteger)clientsCount config:(void(^)(MockMessage *))config {
    
    MockMessage *systemMessage = [MockMessageFactory systemMessageWithType:type users:usersCount clients:clientsCount];

    if (config != nil) {
        config(systemMessage);
    }

    IconSystemCell *cell = [[self.systemMessageTypeToClass[@(type)] alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"test"];
    
    ConversationCellLayoutProperties* layoutProperties = [[ConversationCellLayoutProperties alloc] init];
    layoutProperties.showSender = NO;
    layoutProperties.showBurstTimestamp = NO;
    layoutProperties.showUnreadMarker = NO;
    
    [cell prepareForReuse];
    cell.bounds = CGRectMake(0.0, 0.0, 320.0, 9999);
    cell.contentView.bounds = CGRectMake(0.0, 0.0, 320, 9999);
    cell.layoutMargins = UIEdgeInsetsMake(0, [WAZUIMagic floatForIdentifier:@"content.left_margin"],
                                          0, [WAZUIMagic floatForIdentifier:@"content.right_margin"]);
    
    [cell configureForMessage:systemMessage layoutProperties:layoutProperties];
    [cell layoutIfNeeded];
    CGSize size = [cell systemLayoutSizeFittingSize:CGSizeMake(320.0, 0.0) withHorizontalFittingPriority: UILayoutPriorityRequired verticalFittingPriority: UILayoutPriorityFittingSizeLevel];
    cell.bounds = CGRectMake(0.0, 0.0, size.width, size.height);
    return [cell wrapInTableView];
}

- (void)setUp
{
    [super setUp];
    self.snapshotBackgroundColor = UIColor.whiteColor;
}

- (void)testCannotDecryptMessage {
    UITableView *wrappedCell = [self.class wrappedCellForMessageType:ZMSystemMessageTypeDecryptionFailed users:0 clients:0 config:nil];
    ZMVerifyView(wrappedCell);
}
 
- (void)testNewClient_oneUser_oneClient {
    UITableView *wrappedCell = [self.class wrappedCellForMessageType:ZMSystemMessageTypeNewClient users:1 clients:1 config:nil];
    ZMVerifyView(wrappedCell);
}
 
- (void)testNewClient_selfUser_oneClient {
    UITableView *wrappedCell = [self.class wrappedCellForMessageType:ZMSystemMessageTypeNewClient users:1 clients:1 config:^(MockMessage *message) {
        MockSystemMessageData *mockMessageData = (MockSystemMessageData *)message.systemMessageData;
        mockMessageData.users = [NSSet setWithObject:[MockUser mockSelfUser]];
    }];
    ZMVerifyView(wrappedCell);
}
 
- (void)testNewClient_selfUser_manyClients {
    UITableView *wrappedCell = [self.class wrappedCellForMessageType:ZMSystemMessageTypeNewClient users:1 clients:2 config:^(MockMessage *message) {
        MockSystemMessageData *mockMessageData = (MockSystemMessageData *)message.systemMessageData;
        mockMessageData.users = [NSSet setWithObject:[MockUser mockSelfUser]];
    }];
    ZMVerifyView(wrappedCell);
}
 
- (void)testNewClient_oneUser_manyClient {
    UITableView *wrappedCell = [self.class wrappedCellForMessageType:ZMSystemMessageTypeNewClient users:1 clients:3 config:nil];
    ZMVerifyView(wrappedCell);
}
 
- (void)testNewClient_manyUsers_manyClient {
    UITableView *wrappedCell = [self.class wrappedCellForMessageType:ZMSystemMessageTypeNewClient users:3 clients:4 config:nil];
    ZMVerifyView(wrappedCell);
}

- (void)testIgnoredClient_oneUser_oneClient {
    UITableView *wrappedCell = [self.class wrappedCellForMessageType:ZMSystemMessageTypeIgnoredClient users:1 clients:1 config:nil];
    ZMVerifyView(wrappedCell);
}

- (void)testIgnoredClient_selfUser_oneClient {
    UITableView *wrappedCell = [self.class wrappedCellForMessageType:ZMSystemMessageTypeIgnoredClient users:1 clients:1 config:^(MockMessage *message) {
        MockSystemMessageData *mockMessageData = (MockSystemMessageData *)message.systemMessageData;
        mockMessageData.users = [NSSet setWithObject:[MockUser mockSelfUser]];
    }];
    ZMVerifyView(wrappedCell);
}

- (void)testIgnoredClient_selfUser_manyClients {
    UITableView *wrappedCell = [self.class wrappedCellForMessageType:ZMSystemMessageTypeIgnoredClient users:1 clients:2 config:^(MockMessage *message) {
        MockSystemMessageData *mockMessageData = (MockSystemMessageData *)message.systemMessageData;
        mockMessageData.users = [NSSet setWithObject:[MockUser mockSelfUser]];
    }];
    ZMVerifyView(wrappedCell);
}

- (void)testIgnoredClient_oneUser_manyClient {
    UITableView *wrappedCell = [self.class wrappedCellForMessageType:ZMSystemMessageTypeIgnoredClient users:1 clients:3 config:nil];
    ZMVerifyView(wrappedCell);
}

- (void)testConversationIsSecure {
    UITableView *wrappedCell = [self.class wrappedCellForMessageType:ZMSystemMessageTypeConversationIsSecure users:0 clients:0 config:nil];
    ZMVerifyView(wrappedCell);
}

- (void)testPotentialGap {
    UITableView *wrappedCell = [self.class wrappedCellForMessageType:ZMSystemMessageTypePotentialGap users:0 clients:0 config:nil];
    ZMVerifyView(wrappedCell);
}

- (void)testDecryptionFailed {
    UITableView *wrappedCell = [self.class wrappedCellForMessageType:ZMSystemMessageTypeDecryptionFailed users:0 clients:0 config:nil];
    ZMVerifyView(wrappedCell);
}

- (void)testStartedusingANewDevice {
    UITableView *wrappedCell = [self.class wrappedCellForMessageType:ZMSystemMessageTypeReactivatedDevice users:0 clients:0 config:nil];
    ZMVerifyView(wrappedCell);
}

@end
