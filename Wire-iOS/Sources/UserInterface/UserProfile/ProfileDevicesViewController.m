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


#import "ProfileDevicesViewController.h"
#import "ProfileDevicesViewController+Internal.h"

#import "ParticipantDeviceHeaderView.h"
#import "ParticipantDeviceCell.h"

#import "Analytics.h"
@import PureLayout;
#import "Wire-Swift.h"

@import WireSyncEngine;
@import WireRequestStrategy;

@interface ProfileDevicesViewController () <ZMUserObserver, ParticipantDeviceHeaderViewDelegate>

@property (nonatomic) id userObserverToken;
@property (strong, nonatomic, readwrite) ZMUser *user;
@property (strong, nonatomic) NSArray <UserClient *> *sortedClients;

@end



@implementation ProfileDevicesViewController

- (instancetype)initWithUser:(ZMUser *)user
{
    if (!(self = [super init])) {
        return nil;
    }
    self.user = user;
    if ([ZMUserSession sharedSession] != nil) {
        self.userObserverToken = [UserChangeInfo addObserver:self forUser:self.user userSession:[ZMUserSession sharedSession]];
    }
    [self refreshSortedClientsWithSet:user.clients];
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.clearsSelectionOnViewWillAppear = YES;
    self.tableView.rowHeight = 64;
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    self.tableView.backgroundColor = UIColor.clearColor;
    [ParticipantDeviceCell registerIn:self.tableView];
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 32, 0);
    self.tableView.separatorInset = UIEdgeInsetsMake(0, 56, 0, 0);
    [self setupTableHeaderView];

    [self setupStyle];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self reloadData];
    [self.user fetchUserClients];
}

- (void)reloadData
{
    [self refreshSortedClientsWithSet:self.user.clients];
    [self updateTableHeaderView];
    [self.tableView reloadData];
}


#pragma mark - Setup

- (void)setupTableHeaderView
{
    ParticipantDeviceHeaderView *headerView = [[ParticipantDeviceHeaderView alloc] initWithUserName:self.user.displayName];
    headerView.delegate = self;
    [self setParticipantDeviceHeaderView:headerView];
}

- (void)updateTableHeaderView
{
    if (CGRectEqualToRect(self.tableView.bounds, CGRectZero)) {
        return;
    }
    
    ParticipantDeviceHeaderView *headerView = (ParticipantDeviceHeaderView *)self.tableView.tableHeaderView;
    headerView.showUnencryptedLabel = self.user.clients.count == 0;
    CGSize fittingSize = CGSizeMake(CGRectGetWidth(self.tableView.bounds), 44);
    CGSize requiredSize = [headerView systemLayoutSizeFittingSize:fittingSize
                                    withHorizontalFittingPriority:UILayoutPriorityRequired
                                          verticalFittingPriority:UILayoutPriorityDefaultLow];
    
    headerView.frame = CGRectMake(0, 0, requiredSize.width, requiredSize.height);
    self.tableView.tableHeaderView = headerView;
}

- (void)setParticipantDeviceHeaderView:(ParticipantDeviceHeaderView *)headerView
{
    self.tableView.tableHeaderView = headerView;
    [self updateTableHeaderView];
}

- (void)refreshSortedClientsWithSet:(NSSet <UserClient *>*)clients
{
    NSSortDescriptor *clientSortDescriptors = [NSSortDescriptor sortDescriptorWithKey:@"activationDate" ascending:NO];
    self.sortedClients = [clients sortedArrayUsingDescriptors:@[clientSortDescriptors]];
}

#pragma mark - ZMUserObserver

- (void)userDidChange:(UserChangeInfo *)note
{
    if (note.trustLevelChanged || note.clientsChanged) {
        [self reloadData];
    }
}

#pragma mark - ParticipantDeviceHeaderViewDelegate

- (void)participantsDeviceHeaderViewDidTapLearnMore:(ParticipantDeviceHeaderView *)headerView
{
    [NSURL.wr_fingerprintLearnMoreURL openInAppAboveViewController:self];
}

#pragma mark - UITableView

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.sortedClients.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ParticipantDeviceCell *cell = [tableView dequeueReusableCellWithIdentifier:ParticipantDeviceCell.zm_reuseIdentifier forIndexPath:indexPath];
    UserClient *client = self.sortedClients[indexPath.row];
    [cell configureForClient:client];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    UserClient *client = self.sortedClients[indexPath.row];
    [self.delegate profileDevicesViewController:self didTapDetailForClient:client];
}

@end

