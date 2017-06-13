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
#import "ConversationCell.h"
#import "TextMessageCell.h"
#import "ImageMessageCell.h"
#import "PingCell.h"
#import "Wire_iOS_Tests-Swift.h"
#import "Wire-Swift.h"
#import "MockMessage+Creation.h"

@import PureLayout;

// Allow us to programatically set gesture recognizer state
#import <UIKit/UIGestureRecognizerSubclass.h>

typedef NS_ENUM(NSUInteger, ConversationCellType) {
    ConversationCellTypeText,
    ConversationCellTypeTextWithRichMedia,
    ConversationCellTypeImage,
    ConversationCellTypeFileTransfer,
    ConversationCellTypePing,
    ConversationCellTypeSystemMessage,
    
    ConversationCellTypeCOUNT
};


@interface DeleteMessageTests : XCTestCase
@property (nonatomic) ConversationCell *sut;
@end

@implementation DeleteMessageTests

#pragma mark - Helpers

- (id<ZMConversationMessage>)messageForConversationCellType:(ConversationCellType)conversationType;
{
    MockMessage *message = nil;
    
    switch (conversationType) {
        case ConversationCellTypeText:
        {
            message = [MockMessageFactory textMessageIncludingRichMedia:NO];
        }
            break;
        case ConversationCellTypeTextWithRichMedia:
        {
            message = [MockMessageFactory textMessageIncludingRichMedia:YES];
        }
            break;
        case ConversationCellTypeImage:
        {
            message = [MockMessageFactory imageMessage];
        }
            break;
        case ConversationCellTypePing:
        {
            message = [MockMessageFactory pingMessage];
        }
            break;
        case ConversationCellTypeFileTransfer:
        {
            message = [MockMessageFactory fileTransferMessage];
            message.fileMessageData.transferState = ZMFileTransferStateDownloaded;
        }
            break;
        case ConversationCellTypeSystemMessage:
        {
            message = [MockMessageFactory systemMessageWithType:ZMSystemMessageTypeMissedCall users:1 clients:1];
        }
            break;
        case ConversationCellTypeCOUNT:
            XCTFail(@"You can't just give the ConversationCellTypeCOUNT and expect a message!");
            break;
    }
    
    return (id<ZMConversationMessage>)message;
}

- (ConversationCell *)conversationCellForType:(ConversationCellType)conversationType;
{
    ConversationCell *cell = nil;
    
    switch (conversationType){
        case ConversationCellTypeText:
        case ConversationCellTypeTextWithRichMedia:
        {
            cell = [[TextMessageCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"test"];
        }
            break;

        case ConversationCellTypeImage:
        {
            cell = [[ImageMessageCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"test"];
        }
            break;
        case ConversationCellTypePing:
        {
            cell = [[PingCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"test"];
        }
            break;
        case ConversationCellTypeFileTransfer:
        {
            cell = [[FileTransferCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"test"];
        }
            break;
        case ConversationCellTypeSystemMessage:
        {
            cell = [[CannotDecryptCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"test"];
        }
            break;
        case ConversationCellTypeCOUNT:
            XCTFail(@"You can't just give the ConversationCellTypeCOUNT and expect a cell!");
            break;
            
    }
    
    [cell configureForMessage:[self messageForConversationCellType:conversationType] layoutProperties:nil];
    [cell autoSetDimension:ALDimensionHeight toSize:60];
    
    return cell;
}

#pragma mark - Test cases

- (void)testThatTheExpectedCellsCanBeDeleted;
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"

    // can perform action decides if the action will be present in menu, therefor be deletable
    ConversationCell *textMessageCell = [self conversationCellForType:ConversationCellTypeText];
    XCTAssertTrue([textMessageCell canPerformAction:@selector(deleteMessage:) withSender:nil]);
    XCTAssertFalse([textMessageCell canPerformAction:@selector(delete:) withSender:nil]);

    ConversationCell *richMediaMessageCell = [self conversationCellForType:ConversationCellTypeTextWithRichMedia];
    XCTAssertTrue([richMediaMessageCell canPerformAction:@selector(deleteMessage:) withSender:nil]);
    XCTAssertFalse([richMediaMessageCell canPerformAction:@selector(delete:) withSender:nil]);
    
    ConversationCell *fileMessageCell = [self conversationCellForType:ConversationCellTypeFileTransfer];
    XCTAssertTrue([fileMessageCell canPerformAction:@selector(deleteMessage:) withSender:nil]);
    XCTAssertFalse([fileMessageCell canPerformAction:@selector(delete:) withSender:nil]);
    
    ConversationCell *pingMessageCell = [self conversationCellForType:ConversationCellTypePing];
    XCTAssertTrue([pingMessageCell canPerformAction:@selector(deleteMessage:) withSender:nil]);
    XCTAssertFalse([pingMessageCell canPerformAction:@selector(delete:) withSender:nil]);
    
    ConversationCell *imageMessageCell = [self conversationCellForType:ConversationCellTypeImage];
    XCTAssertTrue([imageMessageCell canPerformAction:@selector(deleteMessage:) withSender:nil]);
    XCTAssertFalse([imageMessageCell canPerformAction:@selector(delete:) withSender:nil]);

#pragma clang diagnostic pop
}

@end
