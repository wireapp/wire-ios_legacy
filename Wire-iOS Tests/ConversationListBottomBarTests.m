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
@import PureLayout;
#import <Classy/Classy.h>


@interface MockConversationListBottomBarDelegate : NSObject <ConversationListBottomBarControllerDelegate>
@property (nonatomic) NSUInteger plusButtonCallCount;
@property (nonatomic) NSUInteger archiveButtonTapCount;
@property (nonatomic) NSUInteger cameraButtonTapCount;
@property (nonatomic) NSUInteger composeButtonCallCount;
@end


@implementation MockConversationListBottomBarDelegate

- (instancetype)init
{
    self = [super init];
    return self;
}

- (void)conversationListBottomBar:(ConversationListBottomBarController *)bar didTapButtonWithType:(enum ConversationListButtonType)buttonType
{
    switch (buttonType) {
        case ConversationListButtonTypeArchive:
            self.archiveButtonTapCount++;
            break;
        case ConversationListButtonTypeCompose:
            self.composeButtonCallCount++;
            break;
        case ConversationListButtonTypeCamera:
            self.cameraButtonTapCount++;
            break;
        case ConversationListButtonTypePlus:
            self.plusButtonCallCount++;
            break;
    }
}

@end


@interface ConversationListBottomBarTests : ZMSnapshotTestCase
@property (nonatomic) ConversationListBottomBarController *sut;
@property (nonatomic) MockConversationListBottomBarDelegate *mockDelegate;
@end


@implementation ConversationListBottomBarTests

- (void)setUp
{
    [super setUp];
    self.snapshotBackgroundColor = [UIColor colorWithWhite:0.2 alpha:1]; // In order to make the separator more visible
    self.accentColor = ZMAccentColorBrightYellow;
    self.mockDelegate = [MockConversationListBottomBarDelegate new];
    [UIView performWithoutAnimation:^{
        self.sut = [[ConversationListBottomBarController alloc] initWithDelegate:self.mockDelegate];
    }];
    [CASStyler.defaultStyler styleItem:self.sut];
 }

- (void)testThatItRendersTheBottomBarCorrectlyInInitialState
{
    // when
    XCTAssertFalse(self.sut.showSeparator);
    
    // then
    ZMVerifyViewInAllIPhoneWidths(self.sut.view);
}

- (void)testThatTheSeparatorIsNotHiddenWhen_ShowSeparator_IsSetToYes
{
    // when
    self.sut.showSeparator = YES;
    
    // then
    XCTAssertFalse(self.sut.separator.hidden);
    ZMVerifyViewInAllIPhoneWidths(self.sut.view);
}

- (void)testThatItHidesTheContactsTitleAndShowsArchivedButtonWhen_ShowArchived_IsSetToYes
{
    // when
    self.sut.showArchived = YES;
    
    // then
    ZMVerifyViewInAllIPhoneWidths(self.sut.view);
}

- (void)testThatItShowsTheContactsTitleAndHidesTheArchivedButtonWhen_ShowArchived_WasSetToYesAndIsSetToNo
{
    // given
    self.accentColor = ZMAccentColorStrongBlue; // To make the snapshot distinguishable from the inital state
    [CASStyler.defaultStyler styleItem:self.sut];
    self.sut.showArchived = YES;
    
    // when
    self.sut.showArchived = NO;
    
    // then
    ZMVerifyViewInAllIPhoneWidths(self.sut.view);
}

- (void)testThatItCallsTheDelegateWhenTheContactsButtonIsTapped
{
    // when
    [self.sut.plusButton sendActionsForControlEvents:UIControlEventTouchUpInside];
    
    // then
    XCTAssertEqual(self.mockDelegate.plusButtonCallCount, 1lu);
    XCTAssertEqual(self.mockDelegate.archiveButtonTapCount, 0lu);
    XCTAssertEqual(self.mockDelegate.cameraButtonTapCount, 0lu);
    XCTAssertEqual(self.mockDelegate.composeButtonCallCount, 0lu);
}

- (void)testThatItCallsTheDelegateWhenTheArchivedButtonIsTapped
{
    // when
    [self.sut.archivedButton sendActionsForControlEvents:UIControlEventTouchUpInside];
    
    // then
    XCTAssertEqual(self.mockDelegate.plusButtonCallCount, 0lu);
    XCTAssertEqual(self.mockDelegate.archiveButtonTapCount, 1lu);
    XCTAssertEqual(self.mockDelegate.cameraButtonTapCount, 0lu);
    XCTAssertEqual(self.mockDelegate.composeButtonCallCount, 0lu);
}

- (void)testThatItCallsTheDelegateWhenTheCameraButtonIsTapped
{
    // when
    [self.sut.cameraButton sendActionsForControlEvents:UIControlEventTouchUpInside];
    
    // then
    XCTAssertEqual(self.mockDelegate.plusButtonCallCount, 0lu);
    XCTAssertEqual(self.mockDelegate.archiveButtonTapCount, 0lu);
    XCTAssertEqual(self.mockDelegate.cameraButtonTapCount, 1lu);
    XCTAssertEqual(self.mockDelegate.composeButtonCallCount, 0lu);
}

- (void)testThatItCallsTheDelegateWhenTheComposeButtonIsTapped
{
    // when
    [self.sut.composeButton sendActionsForControlEvents:UIControlEventTouchUpInside];

    // then
    XCTAssertEqual(self.mockDelegate.plusButtonCallCount, 0lu);
    XCTAssertEqual(self.mockDelegate.archiveButtonTapCount, 0lu);
    XCTAssertEqual(self.mockDelegate.cameraButtonTapCount, 0lu);
    XCTAssertEqual(self.mockDelegate.composeButtonCallCount, 1lu);
}

@end
