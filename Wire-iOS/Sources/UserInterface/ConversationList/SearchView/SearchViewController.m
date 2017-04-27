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

@interface SearchViewController ()
@property (nonatomic, readwrite) PeopleInputController *peopleInputController;
@property (nonatomic, readwrite) SearchView *searchView;
@property (nonatomic, readwrite) IconButton *cancelButton;
@end

@implementation SearchViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.peopleInputController = [[PeopleInputController alloc] init];
    [self addChildViewController:self.peopleInputController];
    self.peopleInputController.view.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.peopleInputController.view];
    [self.peopleInputController didMoveToParentViewController:self];

    self.cancelButton = [[IconButton alloc] initForAutoLayout];
    self.cancelButton.borderWidth = 0;
    self.cancelButton.accessibilityIdentifier = @"PeoplePickerClearButton";
    [self.cancelButton setIcon:ZetaIconTypeX withSize:ZetaIconSizeSearchBar forState:UIControlStateNormal];
    [self.cancelButton setIconColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.view addSubview:self.cancelButton];
    

    SearchView *searchView = [[SearchView alloc] initWithPeopleInputController:self.peopleInputController];
    searchView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.cancelButton addTarget:self action:@selector(onCloseButtonPressed:) forControlEvents:UIControlEventTouchUpInside];

    self.searchView = searchView;

    [self.view insertSubview:searchView belowSubview:self.peopleInputController.view];

    [self createViewConstraints];
}

- (void)createViewConstraints
{
    CGFloat rightMargin = [WAZUIMagic cgFloatForIdentifier:@"people_picker.search_results_mode.person_tile_right_margin"];
    [self.searchView autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero];
    
    [self.cancelButton autoPinEdgeToSuperviewEdge:ALEdgeTrailing withInset:rightMargin - 10];
    [self.cancelButton autoAlignAxis:ALAxisHorizontal toSameAxisOfView:self.peopleInputController.view];
    [self.cancelButton autoMatchDimension:ALDimensionWidth toDimension:ALDimensionHeight ofView:self.cancelButton];
    [self.cancelButton autoSetDimension:ALDimensionWidth toSize:30];
}

- (void)onCloseButtonPressed:(id)sender;
{
    if ([self.delegate respondsToSelector:@selector(searchViewControllerWantsToDismissController:)]) {
        [self.delegate searchViewControllerWantsToDismissController:self];
    }
}

@end
