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

#import "WireSyncEngine+iOS.h"
#import <WireDataModel/ZMBareUser.h>
#import "avs+iOS.h"
#import "Settings.h"


@import WireExtensionComponents;
@import PureLayout;

#import "IconButton.h"
#import "WAZUIMagicIOS.h"
#import "Constants.h"
#import "UIColor+WAZExtensions.h"
#import "UserImageView.h"
#import "UIColor+WR_ColorScheme.h"
#import "UIViewController+WR_Additions.h"

#import "TextView.h"
#import "Button.h"
#import "ContactsDataSource.h"
#import "Analytics+iOS.h"
#import "AnalyticsTracker.h"
#import "AnalyticsTracker+Invitations.h"
#import "Wire-Swift.h"

#import "ZClientViewController.h"
#import "ProfileFooterView.h"
#import "ProfileSendConnectionRequestFooterView.h"
#import "ProfileIncomingConnectionRequestFooterView.h"
#import "ProfileUnblockFooterView.h"
#import "ActionSheetController+Conversation.h"
#import "ProfileNavigationControllerDelegate.h"


typedef NS_ENUM(NSUInteger, ProfileViewContentMode) {
    ProfileViewContentModeUnknown,
    ProfileViewContentModeNone,
    ProfileViewContentModeSendConnection,
    ProfileViewContentModeConnectionSent
};


typedef NS_ENUM(NSUInteger, ProfileUserAction) {
    ProfileUserActionNone,
    ProfileUserActionOpenConversation,
    ProfileUserActionAddPeople,
    ProfileUserActionRemovePeople,
    ProfileUserActionBlock,
    ProfileUserActionPresentMenu,
    ProfileUserActionUnblock,
    ProfileUserActionAcceptConnectionRequest,
    ProfileUserActionSendConnectionRequest,
    ProfileUserActionCancelConnectionRequest
};


@interface ProfileDetailsViewController ()

@property (nonatomic) ProfileViewControllerContext context;
@property (nonatomic) id<ZMBareUser, ZMSearchableUser, AccentColorProvider> bareUser;
@property (nonatomic) ZMConversation *conversation;

@property (nonatomic) UserImageView *userImageView;
@property (nonatomic) UIView *userImageViewContainer;
@property (nonatomic) UIView *footerView;
@property (nonatomic) UILabel *teamsGuestLabel;
@property (nonatomic) BOOL showGuestLabel;

@end

@implementation ProfileDetailsViewController

- (instancetype)initWithUser:(id<ZMBareUser, ZMSearchableUser, AccentColorProvider>)user conversation:(ZMConversation *)conversation context:(ProfileViewControllerContext)context
{
    self = [super initWithNibName:nil bundle:nil];
    
    if (self) {
        _context = context;
        _bareUser = user;
        _conversation = conversation;
        _showGuestLabel = [user isGuestInConversation:conversation];
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupViews];
    [self setupConstraints];
}

- (void)setupViews
{
    [self createUserImageView];
    [self createFooter];
    if (self.showGuestLabel) {
        [self createTeamsGuestLabel];
    }
}

- (void)setupConstraints
{
    [self.userImageViewContainer autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero excludingEdge:ALEdgeBottom];
    
    [self.userImageView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionWidth ofView:self.userImageView];
    [self.userImageView autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:48 relation:NSLayoutRelationGreaterThanOrEqual];
    [self.userImageView autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:48 relation:NSLayoutRelationGreaterThanOrEqual];
    [self.userImageView autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:0 relation:NSLayoutRelationGreaterThanOrEqual];

    if (self.showGuestLabel) {
        [self.teamsGuestLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.userImageView withOffset:15];
        [self.teamsGuestLabel autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:0 relation:NSLayoutRelationGreaterThanOrEqual];
        [self.teamsGuestLabel autoPinEdge:ALEdgeLeft toEdge:ALEdgeLeft ofView:self.userImageView];
        [self.teamsGuestLabel autoPinEdge:ALEdgeRight toEdge:ALEdgeRight ofView:self.userImageView];
    }
    
    [self.userImageView autoAlignAxisToSuperviewAxis:ALAxisVertical];
    [NSLayoutConstraint autoSetPriority:UILayoutPriorityDefaultLow forConstraints:^{
        [self.userImageView autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
    }];

    [self.footerView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.userImageViewContainer];
    [self.footerView autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero excludingEdge:ALEdgeTop];
}

#pragma mark - User Image

- (void)createUserImageView
{
    self.userImageViewContainer = [[UIView alloc] initForAutoLayout];
    [self.view addSubview:self.userImageViewContainer];
    
    self.userImageView = [[UserImageView alloc] initWithMagicPrefix:@"profile.user_image"];
    self.userImageView.userSession = [ZMUserSession sharedSession];
    self.userImageView.translatesAutoresizingMaskIntoConstraints = NO;
    self.userImageView.size = UserImageViewSizeBig;
    self.userImageView.user = self.bareUser;
    [self.userImageViewContainer addSubview:self.userImageView];
}

- (void)createTeamsGuestLabel
{
    self.teamsGuestLabel = [[UILabel alloc] initForAutoLayout];
    self.teamsGuestLabel.numberOfLines = 0;
    self.teamsGuestLabel.textAlignment = NSTextAlignmentCenter;
    [self.userImageViewContainer addSubview:self.teamsGuestLabel];
    self.teamsGuestLabel.text = NSLocalizedString(@"profile.details.guest", nil);
}

#pragma mark - Footer

- (void)createFooter
{
    UIView *footerView;
    
    ZMUser *user = [self fullUser];
    
    ProfileViewContentMode mode = self.profileViewContentMode;
    
    BOOL validContext = (self.context == ProfileViewControllerContextSearch ||
                         self.context == ProfileViewControllerContextCommonConnection);
    
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
        [[Analytics shared]tagScreen:@"BLOCKED_USER"];
    }
    else if (mode == ProfileViewContentModeSendConnection && self.context != ProfileViewControllerContextGroupConversation) {
        ProfileSendConnectionRequestFooterView *sendConnectionRequestFooterView = [[ProfileSendConnectionRequestFooterView alloc] initForAutoLayout];
        [sendConnectionRequestFooterView.sendButton addTarget:self action:@selector(sendConnectionRequest) forControlEvents:UIControlEventTouchUpInside];
        footerView = sendConnectionRequestFooterView;
    }
    else {
        ProfileFooterView *userActionsfooterView = [[ProfileFooterView alloc] init];
        userActionsfooterView.translatesAutoresizingMaskIntoConstraints = NO;
        [[Analytics shared]tagScreen:@"OTHER_USER_PROFILE"];
        
        [userActionsfooterView setIconTypeForLeftButton:[self iconTypeForUserAction:[self leftButtonAction]]];
        [userActionsfooterView setIconTypeForRightButton:[self iconTypeForUserAction:[self rightButtonAction]]];
        [userActionsfooterView.leftButton setTitle:[[self buttonTextForUserAction:[self leftButtonAction]] uppercasedWithCurrentLocale] forState:UIControlStateNormal];
        
        [userActionsfooterView.leftButton addTarget:self action:@selector(performLeftButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        [userActionsfooterView.rightButton addTarget:self action:@selector(performRightButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        
        footerView = userActionsfooterView;
    }
    
    [self.view addSubview:footerView];
    footerView.opaque = NO;
    self.footerView = footerView;
}

- (NSString *)buttonTextForUserAction:(ProfileUserAction)userAction
{
    NSString *buttonText = @"";
    
    switch (userAction) {
        case ProfileUserActionSendConnectionRequest:
        case ProfileUserActionAcceptConnectionRequest:
            buttonText = NSLocalizedString(@"profile.connection_request_dialog.button_connect", nil);
            break;
            
        case ProfileUserActionCancelConnectionRequest:
            buttonText = NSLocalizedString(@"profile.cancel_connection_button_title", nil);
            break;
            
        case ProfileUserActionUnblock:
            buttonText = NSLocalizedString(@"profile.connection_request_state.blocked", nil);
            break;
            
        case ProfileUserActionAddPeople:
            buttonText = NSLocalizedString(@"profile.create_conversation_button_title", nil);
            break;
            
        case ProfileUserActionOpenConversation:
            buttonText = NSLocalizedString(@"profile.open_conversation_button_title", nil);
            break;
            
        default:
            break;
    }
    
    return buttonText;
}

- (ZetaIconType)iconTypeForUserAction:(ProfileUserAction)userAction
{
    switch (userAction) {
        case ProfileUserActionAddPeople:
            return ZetaIconTypeConvMetaAddPerson;
            break;
            
        case ProfileUserActionPresentMenu:
            return ZetaIconTypeEllipsis;
            break;
            
        case ProfileUserActionUnblock:
            return ZetaIconTypeBlock;
            break;
            
        case ProfileUserActionBlock:
            return ZetaIconTypeBlock;
            break;
            
        case ProfileUserActionRemovePeople:
            return ZetaIconTypeMinus;
            break;
            
        case ProfileUserActionCancelConnectionRequest:
            return ZetaIconTypeUndo;
            break;
            
        case ProfileUserActionOpenConversation:
            return ZetaIconTypeConversation;
            break;
            
        case ProfileUserActionSendConnectionRequest:
        case ProfileUserActionAcceptConnectionRequest:
            return ZetaIconTypePlus;
            break;
            
        default:
            return ZetaIconTypeNone;
            break;
    }
}

- (ProfileUserAction)leftButtonAction
{
    ZMUser *user = [self fullUser];
    
    if (user.isSelfUser) {
        return ProfileUserActionNone;
    }
    else if ((user.isConnected || user.isTeamMember) && self.context == ProfileViewControllerContextOneToOneConversation) {
        return ProfileUserActionAddPeople;
    }
    else if (user.isTeamMember) {
        return ProfileUserActionOpenConversation;
    }
    else if (user.isBlocked) {
        return ProfileUserActionUnblock;
    }
    else if (user.isPendingApprovalBySelfUser) {
        return ProfileUserActionAcceptConnectionRequest;
    }
    else if (user.isPendingApprovalByOtherUser) {
        return ProfileUserActionCancelConnectionRequest;
    }
    else if (! user.isConnected && ! user.isPendingApprovalByOtherUser) {
        return ProfileUserActionSendConnectionRequest;
    } else {
        return ProfileUserActionOpenConversation;
    }
}

- (ProfileUserAction)rightButtonAction
{
    ZMUser *user = [self fullUser];
    
    if (user.isSelfUser) {
        return ProfileUserActionNone;
    }
    else if (self.context == ProfileViewControllerContextGroupConversation) {
        if ([[ZMUser selfUser] canRemoveUserFromConversation:self.conversation]) {
            return ProfileUserActionRemovePeople;
        }
        else {
            return ProfileUserActionNone;
        }
    }
    else if (user.isConnected) {
        if (self.context == ProfileViewControllerContextCommonConnection) {
            return ProfileUserActionBlock;
        }
        else {
            return ProfileUserActionPresentMenu;
        }
    }
    else {
        return ProfileUserActionNone;
    }
}

#pragma mark - Actions

- (void)performLeftButtonAction:(id)sender
{
    [self performUserAction:[self leftButtonAction]];
}

- (void)performRightButtonAction:(id)sender
{
    [self performUserAction:[self rightButtonAction]];
}

- (void)performUserAction:(ProfileUserAction)action
{
    switch (action) {
        case ProfileUserActionAddPeople:
            [self presentAddParticipantsViewController];
            break;
            
        case ProfileUserActionPresentMenu:
            [self presentMenuSheetController];
            break;
            
        case ProfileUserActionUnblock:
            [self unblockUser];
            break;
            
        case ProfileUserActionOpenConversation:
            [self openOneToOneConversation];
            break;
            
        case ProfileUserActionRemovePeople:
            [self presentRemoveFromConversationDialogue];
            break;
            
        case ProfileUserActionAcceptConnectionRequest:
            [self bringUpConnectionRequestSheet];
            break;
            
        case ProfileUserActionSendConnectionRequest:
            [self sendConnectionRequest];
            break;
            
        case ProfileUserActionCancelConnectionRequest:
            [self bringUpCancelConnectionRequestSheet];
            break;
        default:
            break;
    }
}

- (void)presentMenuSheetController
{
    ActionSheetController *actionSheetController = [ActionSheetController dialogForConversationDetails:self.conversation style:ActionSheetController.defaultStyle];
    [self presentViewController:actionSheetController animated:YES completion:nil];
}

- (void)presentAddParticipantsViewController
{
    AddParticipantsViewController *addParticipantsViewController = [[AddParticipantsViewController alloc] initWithConversation:self.conversation];
    
    addParticipantsViewController.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    addParticipantsViewController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    
    [self presentViewController:addParticipantsViewController animated:YES completion:^{
        [Analytics.shared tagScreenInviteContactList];
        [Analytics.shared tagOpenedPeoplePickerGroupAction];
    }];
    
    [self.delegate profileDetailsViewController:self didPresentAddParticipantsViewController:addParticipantsViewController];
}

- (void)presentRemoveFromConversationDialogue
{
    __block ActionSheetController *actionSheetController =
    [ActionSheetController dialogForRemovingUser:[self fullUser] fromConversation:self.conversation style:[ActionSheetController defaultStyle] completion:^(BOOL canceled) {
        [self dismissViewControllerAnimated:YES completion:^{
            if (canceled) {
                return;
            }
            
            [[ZMUserSession sharedSession] enqueueChanges:^{
                [self.conversation removeParticipant:[self fullUser]];
            } completionHandler:^{
                [self.delegate profileDetailsViewController:self wantsToBeDismissedWithCompletion:nil];
            }];
        }];
    }];
    
    [self presentViewController:actionSheetController animated:YES completion:nil];
    
    MediaManagerPlayAlert();
}

- (void)bringUpConnectionRequestSheet
{
    [self presentViewController:[ActionSheetController dialogForAcceptingConnectionRequestWithUser:[self fullUser] style:[ActionSheetController defaultStyle] completion:^(BOOL ignored) {
        [self dismissViewControllerAnimated:YES completion:^{
            if (ignored) {
                [self cancelConnectionRequest];
            } else {
                [self acceptConnectionRequest];
            }
        }];
    }] animated:YES completion:nil];
}

- (void)bringUpCancelConnectionRequestSheet
{
    [self presentViewController:[ActionSheetController dialogForCancelingConnectionRequestWithUser:[self fullUser] style:[ActionSheetController defaultStyle] completion:^(BOOL canceled) {
        [self dismissViewControllerAnimated:YES completion:^{
            if (! canceled) {
                [self cancelConnectionRequest];
            }
        }];
    }] animated:YES completion:nil];
}

- (void)unblockUser
{
    [[ZMUserSession sharedSession] enqueueChanges:^{
        [[self fullUser] accept];
    } completionHandler:^{
        [[Analytics shared] tagUnblocking];
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

- (void)cancelConnectionRequest
{
    [self dismissViewControllerWithCompletion:^{
        ZMUser *user = [self fullUser];
        [[ZMUserSession sharedSession] enqueueChanges:^{
            [user cancelConnectionRequest];
        }];
    }];
}

- (void)sendConnectionRequest
{
    NSString *message = [NSString stringWithFormat:NSLocalizedString(@"missive.connection_request.default_message",@"Default connect message to be shown"), self.bareUser.displayName, [ZMUser selfUser].name];
    
    @weakify(self);
    [self dismissViewControllerWithCompletion:^{
        @strongify(self);
        [[ZMUserSession sharedSession] enqueueChanges:^{
            [self.bareUser connectWithMessageText:message completionHandler:nil];
        } completionHandler:^{
            AnalyticsConnectionRequestMethod method = [self connectionRequestMethodForContext:self.context];
            [Analytics.shared tagEventObject:[AnalyticsConnectionRequestEvent eventForAddContactMethod:method connectRequestCount:self.bareUser.totalCommonConnections]];
        }];
    }];
}

- (AnalyticsConnectionRequestMethod)connectionRequestMethodForContext:(ProfileViewControllerContext)context
{
    switch (context) {
        case ProfileViewControllerContextGroupConversation:
            return AnalyticsConnectionRequestMethodParticipants;
        case ProfileViewControllerContextSearch:
            return AnalyticsConnectionRequestMethodUserSearch;
        default:
            return AnalyticsConnectionRequestMethodUnknown;
    }
}

- (void)openOneToOneConversation
{
    if (self.fullUser == nil) {
        DDLogError(@"No user to open conversation with");
        return;
    }
    ZMConversation __block *conversation = nil;
    
    [[ZMUserSession sharedSession] enqueueChanges:^{
        conversation = [self.fullUser oneToOneConversationInTeam:ZMUser.selfUser.team];
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
