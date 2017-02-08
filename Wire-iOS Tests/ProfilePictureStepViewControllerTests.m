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
#import "ProfilePictureStepViewController.h"
#import "ProfilePictureStepViewController+Testing.h"
#import <PureLayout/PureLayout.h>
#import "MockEditableUser.h"


@interface ProfilePictureStepViewControllerTests : ZMSnapshotTestCase
@property (nonatomic) ProfilePictureStepViewController *sut;
@property (nonatomic, copy) void (^configurationBlock)(UIView *);

@end


@implementation ProfilePictureStepViewControllerTests

- (void)setUp {
    [super setUp];
    self.accentColor = ZMAccentColorStrongBlue;
    MockEditableUser *editableUser = [MockEditableUser mockUser];
    self.sut = [[ProfilePictureStepViewController alloc] initWithEditableUser:editableUser];

    __weak typeof(self)weakSelf = self;
    self.configurationBlock = ^(__unused UIView *view) {
        [weakSelf.sut loadViewIfNeeded];
        [weakSelf.sut viewWillAppear:NO];
        weakSelf.sut.showLoadingView = NO;
        weakSelf.sut.profilePictureImageView.image = [weakSelf imageInTestBundleNamed:@"unsplash_matterhorn.jpg"];
    };
}

- (void)testThatItRendersTheViewControllerCorrectlyInAllDeviceSizes {
    ZMVerifyViewInAllIPhoneSizesWithBlock(self.sut.view, self.configurationBlock);
}

@end
