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
#import "MockConversation.h"

@interface ConversationTitleViewTests : ZMSnapshotTestCase
@property (nonatomic) ConversationTitleView *sut;
@property (nonatomic) MockConversation *conversation;
@end

@implementation ConversationTitleViewTests

- (void)setUp
{
    [super setUp];
    self.conversation = [MockConversation new];
    self.conversation.relatedConnectionState = ZMConnectionStatusAccepted;
    self.conversation.displayName = @"Alan Turing";
    self.sut = [[ConversationTitleView alloc] initWithConversation:(ZMConversation *)self.conversation interactive:YES];
    self.snapshotBackgroundColor = UIColor.whiteColor;
}

- (void)testThatItRendersTheConversationDisplayNameCorrectly
{
    ZMVerifyView(self.sut);
}

- (void)testThatItUpdatesTheTitleViewAndRendersTheVerifiedShieldCorrectly
{
    // when
    self.conversation.securityLevel = ZMConversationSecurityLevelSecure;
    self.sut = [[ConversationTitleView alloc] initWithConversation:(ZMConversation *)self.conversation interactive:YES];

    // then
    ZMVerifyView(self.sut);
}

- (void)testThatItDoesNotRenderTheDownArrowForOutgoingConnections
{
    // when
    self.conversation.relatedConnectionState = ZMConnectionStatusSent;
    self.sut = [[ConversationTitleView alloc] initWithConversation:(ZMConversation *)self.conversation interactive:YES];

    // then
    ZMVerifyView(self.sut);
}

- (void)testThatItExecutesTheTapHandlerOnTitleTap
{
    // given
    __block NSUInteger callCount;
    self.sut.tapHandler = ^(UIButton *button) {
        callCount++;
    };
    
    XCTAssertEqual(callCount, 0lu);
    
    // when
    [self.sut.titleButton sendActionsForControlEvents:UIControlEventTouchUpInside];
    
    // then
    XCTAssertEqual(callCount, 1lu);
}

@end
