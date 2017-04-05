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


#import "SearchView.h"
#import <PureLayout/PureLayout.h>
#import <Classy/Classy.h>
#import "UIView+MTAnimation.h"

#import "UserImageView.h"
#import "IconButton.h"
#import "PeopleInputController.h"
#import "AccentColorChangeHandler.h"
#import "WAZUIMagicIOS.h"
#import "UIColor+WR_ColorScheme.h"

#import "WireSyncEngine+iOS.h"
#import "UIColor+WAZExtensions.h"
#import "UIFont+MagicAccess.h"

@interface SearchView () <ZMUserObserver>
@property (nonatomic, readwrite) PeopleInputController *peopleInputController;
@property (nonatomic, readwrite) UIView *lineView;

@property (nonatomic) BOOL initialConstraintsCreated;
@property (nonatomic) id userObserverToken;
@end

@implementation SearchView

- (instancetype)initWithPeopleInputController:(PeopleInputController *)peopleInputController
{
    self = [super initWithFrame:CGRectZero];
    if (self) {
        
        self.peopleInputController = peopleInputController;

        self.lineView = [[UIView alloc] initForAutoLayout];
        [self addSubview:self.lineView];
        
        self.userObserverToken = [UserChangeInfo addUserObserver:self forUser:[ZMUser selfUser]];
    }
    return self;
}

- (void)updateConstraints
{
    if (! self.initialConstraintsCreated) {
        CGFloat leftMarginConvList = [WAZUIMagic floatForIdentifier:@"people_picker.search_results_mode.person_tile_left_margin"];
        CGFloat rightMargin = [WAZUIMagic cgFloatForIdentifier:@"people_picker.search_results_mode.person_tile_right_margin"];
        CGFloat minHeight = 50;

        [self autoSetDimension:ALDimensionHeight toSize:minHeight relation:NSLayoutRelationGreaterThanOrEqual];

        [self.peopleInputController.view autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:31];
        [self.peopleInputController.view autoSetDimension:ALDimensionHeight toSize:40 relation:NSLayoutRelationGreaterThanOrEqual];
        [self.peopleInputController.view autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:leftMarginConvList];
        [self.peopleInputController.view autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:rightMargin];

        [self bringSubviewToFront:self.cancelButton];
        
        [self.lineView autoSetDimension:ALDimensionHeight toSize:0.5f];
        [self.lineView autoPinEdge:ALEdgeLeft toEdge:ALEdgeLeft ofView:self.peopleInputController.view];
        [self.lineView autoPinEdge:ALEdgeRight toEdge:ALEdgeRight ofView:self.peopleInputController.view];
        [self.lineView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.peopleInputController.view];
        [self.lineView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
        
        self.initialConstraintsCreated = YES;
    }

    [super updateConstraints];
}


#pragma mark - ZMUserObserver

- (void)userDidChange:(UserChangeInfo *)note
{
    if ([note.user isSelfUser] && note.accentColorValueChanged) {
        self.lineView.backgroundColor = [UIColor accentColor];
    }
}

@end
