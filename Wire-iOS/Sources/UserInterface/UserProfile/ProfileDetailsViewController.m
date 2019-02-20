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


#import "ProfileDetailsViewController.h"
#import "ProfileDetailsViewController+Internal.h"

#import "WireSyncEngine+iOS.h"
#import "avs+iOS.h"
#import "Settings.h"



@import PureLayout;
@import WireDataModel;

#import "IconButton.h"
#import "Constants.h"
#import "UIColor+WAZExtensions.h"
#import "UIViewController+WR_Additions.h"

#import "TextView.h"
#import "Button.h"
#import "ContactsDataSource.h"
#import "Analytics.h"
#import "Wire-Swift.h"

#import "ZClientViewController.h"
#import "ProfileSendConnectionRequestFooterView.h"
#import "ProfileIncomingConnectionRequestFooterView.h"
#import "ProfileUnblockFooterView.h"

static NSString* ZMLogTag ZM_UNUSED = @"UI";

typedef NS_ENUM(NSUInteger, ProfileViewContentMode) {
    ProfileViewContentModeUnknown,
    ProfileViewContentModeNone,
    ProfileViewContentModeSendConnection,
    ProfileViewContentModeConnectionSent
};


@interface ProfileDetailsViewController ()

@property (nonatomic) id<UserType, AccentColorProvider> bareUser;

@end

@implementation ProfileDetailsViewController

- (instancetype)initWithUser:(id<UserType, AccentColorProvider>)user conversation:(ZMConversation *)conversation context:(ProfileViewControllerContext)context
{
    self = [super initWithNibName:nil bundle:nil];

    if (self) {
        _context = context;
        _bareUser = user;
        _conversation = conversation;
        _showGuestLabel = [user isGuestIn:conversation];
        _availabilityView = [[AvailabilityTitleView alloc] initWithUser:[self fullUser] style:AvailabilityTitleViewStyleOtherProfile];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setupViews];
    [self setupConstraints];
}

- (void)setupConstraints
{
    [self.stackView autoCenterInSuperview];
    
    CGFloat offset = 40;
    if (UIScreen.mainScreen.isSmall) {
        offset = 20;
    }
    
    [NSLayoutConstraint autoSetPriority:UILayoutPriorityRequired forConstraints:^{
        [self.stackView autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self.stackViewContainer withOffset:0 relation:NSLayoutRelationGreaterThanOrEqual];
        [self.stackView autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self.stackViewContainer withOffset:offset relation:NSLayoutRelationGreaterThanOrEqual];
        [self.stackView autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self.stackViewContainer withOffset:0 relation:NSLayoutRelationLessThanOrEqual];
        [self.stackView autoPinEdge:ALEdgeBottom toEdge:ALEdgeBottom ofView:self.stackViewContainer withOffset:-offset relation:NSLayoutRelationLessThanOrEqual];
    }];
    
    /*
    [self.stackViewContainer autoPinEdgeToSuperviewEdge:ALEdgeTop];
    [self.stackViewContainer autoPinEdgeToSuperviewEdge:ALEdgeLeading];
    [self.stackViewContainer autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
    [self.stackViewContainer autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:self.footerView];*/
    [self.stackViewContainer autoPinEdgesToSuperviewEdges];
    
    UIEdgeInsets bottomInset = UIEdgeInsetsMake(0, 0, UIScreen.safeArea.bottom, 0);
    [self.footerView autoPinEdgesToSuperviewEdgesWithInsets:bottomInset excludingEdge:ALEdgeTop];
}

#pragma mark - User Image

- (void)createUserImageView
{
    self.userImageView = [[UserImageView alloc] init];
    self.userImageView.initialsFont = [UIFont systemFontOfSize:80 weight:UIFontWeightThin];
    self.userImageView.userSession = [ZMUserSession sharedSession];
    self.userImageView.translatesAutoresizingMaskIntoConstraints = NO;
    self.userImageView.size = UserImageViewSizeBig;
    self.userImageView.user = self.bareUser;
}

- (void)createGuestIndicator
{
    self.teamsGuestIndicator = [[GuestLabelIndicator alloc] init];
}

#pragma mark - Footer

- (void)createFooter
{
    UIView *footerView;
    
    ZMUser *user = [self fullUser];
    
    ProfileViewContentMode mode = self.profileViewContentMode;
    
    BOOL validContext = (self.context == ProfileViewControllerContextSearch);
    
    if (!user.isTeamMember && validContext && user.isPendingApprovalBySelfUser) {
        ProfileIncomingConnectionRequestFooterView *incomingConnectionRequestFooterView = [[ProfileIncomingConnectionRequestFooterView alloc] init];
        incomingConnectionRequestFooterView.translatesAutoresizingMaskIntoConstraints = NO;
        [incomingConnectionRequestFooterView.acceptButton addTarget:self action:@selector(acceptConnectionRequest) forControlEvents:UIControlEventTouchUpInside];
        [incomingConnectionRequestFooterView.ignoreButton addTarget:self action:@selector(ignoreConnectionRequest) forControlEvents:UIControlEventTouchUpInside];
        footerView = incomingConnectionRequestFooterView;
    }
    else if (!user.isTeamMember && user.isBlocked) {
        ProfileUnblockFooterView *unblockFooterView = [[ProfileUnblockFooterView alloc] init];
        unblockFooterView.translatesAutoresizingMaskIntoConstraints = NO;
        [unblockFooterView.unblockButton addTarget:self action:@selector(unblockUser) forControlEvents:UIControlEventTouchUpInside];
        footerView = unblockFooterView;
    }
    else if (mode == ProfileViewContentModeSendConnection && self.context != ProfileViewControllerContextGroupConversation) {
        ProfileSendConnectionRequestFooterView *sendConnectionRequestFooterView = [[ProfileSendConnectionRequestFooterView alloc] initForAutoLayout];
        [sendConnectionRequestFooterView.sendButton addTarget:self action:@selector(sendConnectionRequest) forControlEvents:UIControlEventTouchUpInside];
        footerView = sendConnectionRequestFooterView;
    }
    
    [self.view addSubview:footerView];
    footerView.opaque = NO;
    self.footerView = footerView;
}

- (void)unblockUser
{
    [[ZMUserSession sharedSession] enqueueChanges:^{
        [[self fullUser] accept];
    }];
    
    [self openOneToOneConversation];
}

- (void)acceptConnectionRequest
{
    ZMUser *user = [self fullUser];
    [self dismissViewControllerWithCompletion:^{
        [[ZMUserSession sharedSession] enqueueChanges:^{
            [user accept];
        }];
    }];
}

- (void)ignoreConnectionRequest
{
    ZMUser *user = [self fullUser];
    
    [self dismissViewControllerWithCompletion:^{
        [[ZMUserSession sharedSession] enqueueChanges:^{
            [user ignore];
        }];
    }];
}

- (void)openOneToOneConversation
{
    if (self.fullUser == nil) {
        ZMLogError(@"No user to open conversation with");
        return;
    }
    ZMConversation __block *conversation = nil;
    
    [[ZMUserSession sharedSession] enqueueChanges:^{
        conversation = self.fullUser.oneToOneConversation;
    } completionHandler:^{
        [self.delegate profileDetailsViewController:self didSelectConversation:conversation];
    }];
}

#pragma mark - Utilities

- (ZMUser *)fullUser
{
    if ([self.bareUser isKindOfClass:[ZMUser class]]) {
        return (ZMUser *)self.bareUser;
    }
    else if ([self.bareUser isKindOfClass:[ZMSearchUser class]]) {
        ZMSearchUser *searchUser = (ZMSearchUser *)self.bareUser;
        return [searchUser user];
    }
    return nil;
}

- (void)dismissViewControllerWithCompletion:(dispatch_block_t)completion
{
    [self.delegate profileDetailsViewController:self wantsToBeDismissedWithCompletion:completion];
}

#pragma mark - Content

- (ProfileViewContentMode)profileViewContentMode
{
    
    ZMUser *fullUser = [self fullUser];
    
    if (fullUser != nil) {
        if (fullUser.isTeamMember) {
            return ProfileViewContentModeNone;
        }
        if (fullUser.isPendingApproval) {
            return ProfileViewContentModeConnectionSent;
        }
        else if (! fullUser.isConnected && ! fullUser.isBlocked && !fullUser.isSelfUser) {
            return ProfileViewContentModeSendConnection;
        }
    }
    else {
        
        if ([self.bareUser isKindOfClass:[ZMSearchUser class]]){
            ZMSearchUser *searchUser = (ZMSearchUser *)self.bareUser;
            
            if (searchUser.isPendingApprovalByOtherUser) {
                return ProfileViewContentModeConnectionSent;
            }
            else {
                return ProfileViewContentModeSendConnection;
            }
        }
    }
    
    return ProfileViewContentModeNone;
}

@end
