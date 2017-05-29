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


#import "SearchViewController.h"
#import <PureLayout/PureLayout.h>
#import "PeopleInputController.h"
#import "IconButton.h"
#import "WireSyncEngine+iOS.h"
#import "WAZUIMagicIOS.h"
#import "UIColor+WAZExtensions.h"

@interface SearchViewController () <ZMUserObserver>
@property (nonatomic, readwrite) PeopleInputController *peopleInputController;
@property (nonatomic, readwrite) UILabel *searchTitleLabel;
@property (nonatomic, readwrite) IconButton *cancelButton;
@property (nonatomic, readwrite) UIView *lineView;
@property (nonatomic) id userObserverToken;

@end

@implementation SearchViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.lineView = [[UIView alloc] initForAutoLayout];
    self.lineView.backgroundColor = [UIColor accentColor];
    [self.view addSubview:self.lineView];
    
    self.peopleInputController = [[PeopleInputController alloc] init];
    [self addChildViewController:self.peopleInputController];
    self.peopleInputController.view.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.peopleInputController.view];
    [self.peopleInputController didMoveToParentViewController:self];

    self.searchTitleLabel = [[UILabel alloc] init];
    self.searchTitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.searchTitleLabel.text = self.title.localizedUppercaseString;
    self.searchTitleLabel.textAlignment = NSTextAlignmentCenter;
    [self.searchTitleLabel setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
    [self.view addSubview:self.searchTitleLabel];
    
    self.cancelButton = [[IconButton alloc] initForAutoLayout];
    self.cancelButton.borderWidth = 0;
    self.cancelButton.accessibilityIdentifier = @"PeoplePickerClearButton";
    [self.cancelButton setIcon:ZetaIconTypeX withSize:ZetaIconSizeSearchBar forState:UIControlStateNormal];
    [self.cancelButton setIconColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.cancelButton addTarget:self action:@selector(onCloseButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.cancelButton];

    [self createViewConstraints];
    
    self.userObserverToken = [UserChangeInfo addUserObserver:self forUser:[ZMUser selfUser]];
}

- (void)createViewConstraints
{
    [self.searchTitleLabel autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsMake(24, 24, 0, 24) excludingEdge:ALEdgeBottom];
    
    CGFloat leftMargin = [WAZUIMagic floatForIdentifier:@"people_picker.search_results_mode.person_tile_left_margin"];
    CGFloat rightMargin = [WAZUIMagic cgFloatForIdentifier:@"people_picker.search_results_mode.person_tile_right_margin"];
    
    [self.peopleInputController.view autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.searchTitleLabel];
    [self.peopleInputController.view autoSetDimension:ALDimensionHeight toSize:40 relation:NSLayoutRelationGreaterThanOrEqual];
    [self.peopleInputController.view autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:leftMargin];
    [self.peopleInputController.view autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:rightMargin];
    
    [self.cancelButton autoPinEdgeToSuperviewEdge:ALEdgeTrailing withInset:rightMargin - 10];
    [self.cancelButton autoAlignAxis:ALAxisHorizontal toSameAxisOfView:self.peopleInputController.view];
    [self.cancelButton autoMatchDimension:ALDimensionWidth toDimension:ALDimensionHeight ofView:self.cancelButton];
    [self.cancelButton autoSetDimension:ALDimensionWidth toSize:30];
    
    [self.lineView autoSetDimension:ALDimensionHeight toSize:0.5f];
    [self.lineView autoPinEdge:ALEdgeLeft toEdge:ALEdgeLeft ofView:self.peopleInputController.view];
    [self.lineView autoPinEdge:ALEdgeRight toEdge:ALEdgeRight ofView:self.peopleInputController.view];
    [self.lineView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.peopleInputController.view];
    [self.lineView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
}

- (void)onCloseButtonPressed:(id)sender;
{
    if ([self.delegate respondsToSelector:@selector(searchViewControllerWantsToDismissController:)]) {
        [self.delegate searchViewControllerWantsToDismissController:self];
    }
}

#pragma mark - ZMUserObserver

- (void)userDidChange:(UserChangeInfo *)note
{
    if ([note.user isSelfUser] && note.accentColorValueChanged) {
        self.lineView.backgroundColor = [UIColor accentColor];
    }
}

@end
