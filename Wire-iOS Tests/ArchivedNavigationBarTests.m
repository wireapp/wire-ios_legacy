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
#import <PureLayout/PureLayout.h>
#import <Classy/Classy.h>

@interface ArchivedNavigationBarTests : ZMSnapshotTestCase
@property (nonatomic) ArchivedNavigationBar *sut;
@end

@implementation ArchivedNavigationBarTests

- (void)setUp {
    [super setUp];
    self.accentColor = ZMAccentColorViolet;
    self.snapshotBackgroundColor = [UIColor colorWithWhite:0.2 alpha:1];
    self.sut = [[ArchivedNavigationBar alloc] initWithTitle:@"ARCHIVE"];
    [CASStyler.defaultStyler styleItem:self.sut];
    // Wait until fonts are loaded in Classy
    [[NSRunLoop currentRunLoop] runUntilDate:[[NSDate date] dateByAddingTimeInterval:0.5]];
}

- (void)testThatItRendersTheNavigationBarCorrectInitially {
    ZMVerifyViewInAllIPhoneWidths(self.sut);
}

- (void)testThatItShowsTheSeparatorWhen_ShowSeparator_IsSetToYes {
    [UIView setAnimationsEnabled:NO];
    self.sut.showSeparator = YES;
    ZMVerifyViewInAllIPhoneWidths(self.sut);
    [UIView setAnimationsEnabled:YES];
}

@end
