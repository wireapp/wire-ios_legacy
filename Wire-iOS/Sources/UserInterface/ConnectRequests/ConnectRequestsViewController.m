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


#import "ConnectRequestsViewController.h"

// ui
#import "TextView.h"
#import "ConnectRequestCell.h"
#import "ProfileViewController.h"
#import "UIView+PopoverBorder.h"
#import "ProfilePresenter.h"
#import "Wire-Swift.h"

// model
#import "WireSyncEngine+iOS.h"

// helpers
@import PureLayout;


@class ZMConversation;

static NSString *ConnectionRequestCellIdentifier = @"ConnectionRequestCell";


@interface ConnectRequestsViewController () <ZMConversationListObserver, ZMUserObserver, UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) NSArray *connectionRequests;
@property (nonatomic) id userObserverToken;
@property (nonatomic) id pendingConnectionsListObserverToken;

@property (nonatomic) UITableView *tableView;
@property (nonatomic) CGRect lastLayoutBounds;
@end



@implementation ConnectRequestsViewController

- (void)loadView
{
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero];
    self.view = self.tableView;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.tableView registerClass:[ConnectRequestCell class] forCellReuseIdentifier:ConnectionRequestCellIdentifier];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    ZMConversationList *pendingConnectionsList = [ZMConversationList pendingConnectionConversationsInUserSession:[ZMUserSession sharedSession]];
    self.pendingConnectionsListObserverToken = [ConversationListChangeInfo addObserver:self
                                                                               forList:pendingConnectionsList
                                                                           userSession:[ZMUserSession sharedSession]];
    
    self.userObserverToken = [UserChangeInfo addObserver:self forUser:[ZMUser selfUser] userSession:[ZMUserSession sharedSession]];
    self.connectionRequests = pendingConnectionsList;
    
    [self reload];
    
    self.tableView.backgroundColor = [UIColor wr_colorFromColorScheme:ColorSchemeColorBackground];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    self.tableView.separatorColor = [UIColor wr_colorFromColorScheme:ColorSchemeColorSeparator];
    
    self.tableView.estimatedRowHeight = 0;
    self.tableView.estimatedSectionHeaderHeight = 0;
    self.tableView.estimatedSectionFooterHeight = 0;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [[UIApplication sharedApplication] wr_updateStatusBarForCurrentControllerAnimated:YES];
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (void)viewDidLayoutSubviews
{
    if (!CGSizeEqualToSize(self.lastLayoutBounds.size, self.view.bounds.size)) {
        self.lastLayoutBounds = self.view.bounds;
        [self.tableView reloadData];
        CGFloat yPos = self.tableView.contentSize.height - self.tableView.bounds.size.height + UIScreen.safeArea.bottom;
        [self.tableView setContentOffset:CGPointMake(0, yPos)];
    }
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [self.tableView reloadData];
    } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
    }];
    
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.connectionRequests.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ConnectRequestCell *cell = [tableView dequeueReusableCellWithIdentifier:ConnectionRequestCellIdentifier];
    [self configureCell:cell forIndexPath:indexPath];
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView.bounds.size.height <= 0) {
        return [[UIScreen mainScreen] bounds].size.height;
    }
    return tableView.bounds.size.height - 48;
}

#pragma mark - Helpers

- (void)configureCell:(ConnectRequestCell *)cell forIndexPath:(NSIndexPath *)indexPath
{
    ZMConversation *request = self.connectionRequests[(self.connectionRequests.count - 1) - indexPath.row];
    
    ZMUser *user = request.connectedUser;
    cell.user = user;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.separatorInset = UIEdgeInsetsZero;
    cell.preservesSuperviewLayoutMargins = NO;
    cell.layoutMargins = UIEdgeInsetsMake(0, 0, 8, 0);
    @weakify(self);
    
    cell.acceptBlock = ^{
        @strongify(self);
        
        if (self.connectionRequests.count == 0) {
            [[ZClientViewController sharedZClientViewController] hideIncomingContactRequestsWithCompletion:^{
                [[ZClientViewController sharedZClientViewController] selectConversation:user.oneToOneConversation
                                                                            focusOnView:YES
                                                                               animated:YES];
            }];
        }
    };
    
    cell.ignoreBlock = ^{
        if (self.connectionRequests.count == 0) {
            [[ZClientViewController sharedZClientViewController] hideIncomingContactRequestsWithCompletion:nil];
        }
    };
    
}

#pragma mark - ZMUserObserver

- (void)userDidChange:(UserChangeInfo *)change
{
    [self.tableView reloadData]; //may need a slightly different approach, like enumerating through table cells of type FirstTimeTableViewCell and setting their bgColor property
}


#pragma mark - ZMConversationsObserver

- (void)conversationListDidChange:(ConversationListChangeInfo *)change
{
    [self reload];
}

- (void)reload
{
    [self.tableView reloadData];
    
    if (self.connectionRequests.count != 0) {
        // Scroll to bottom of inbox
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:self.connectionRequests.count - 1 inSection:0]
                              atScrollPosition:UITableViewScrollPositionBottom
                                      animated:YES];
    }
    else {
        [[ZClientViewController sharedZClientViewController] hideIncomingContactRequestsWithCompletion:nil];
    }
}

@end
