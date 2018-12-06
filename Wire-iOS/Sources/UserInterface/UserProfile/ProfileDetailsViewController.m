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


@import WireExtensionComponents;
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
#import "ProfileFooterView.h"
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
@property (nonatomic) id<UserType, AccentColorProvider> bareUser;

@property (nonatomic) UserImageView *userImageView;
@property (nonatomic) UIView *stackViewContainer;
@property (nonatomic) GuestLabelIndicator *teamsGuestIndicator;
@property (nonatomic) BOOL showGuestLabel;
@property (nonatomic) AvailabilityTitleView *availabilityView;
@property (nonatomic) CustomSpacingStackView *stackView;
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

- (void)setupViews
{
    [self createUserImageView];
    [self createFooter];
    [self createGuestIndicator];
    
    self.view.backgroundColor = [UIColor wr_colorFromColorScheme:ColorSchemeColorContentBackground];
    self.stackViewContainer = [[UIView alloc] initForAutoLayout];
    [self.view addSubview:self.stackViewContainer];
    
    self.teamsGuestIndicator.hidden = !self.showGuestLabel;
    self.availabilityView.hidden = !ZMUser.selfUser.isTeamMember || self.fullUser.availability == AvailabilityNone;
    
    NSString *remainingTimeString = self.fullUser.expirationDisplayString;
    self.remainingTimeLabel = [[UILabel alloc] initForAutoLayout];
    [self.remainingTimeLabel setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
    self.remainingTimeLabel.text = remainingTimeString;
    self.remainingTimeLabel.textColor = [ColorScheme.defaultColorScheme colorWithName:ColorSchemeColorTextForeground];
    self.remainingTimeLabel.font = [UIFont mediumSemiboldFont];
    self.remainingTimeLabel.hidden = nil == remainingTimeString;

    [self createReadReceiptsEnabledLabel];
    
    UIView *userImageViewWrapper = [[UIView alloc] initWithFrame:CGRectZero];
    userImageViewWrapper.translatesAutoresizingMaskIntoConstraints = NO;
    [userImageViewWrapper addSubview:self.userImageView];
    
    [NSLayoutConstraint activateConstraints:
    @[[self.userImageView.leadingAnchor constraintEqualToAnchor:userImageViewWrapper.leadingAnchor constant:40],
      [self.userImageView.trailingAnchor constraintEqualToAnchor:userImageViewWrapper.trailingAnchor constant:-40],
      [self.userImageView.topAnchor constraintEqualToAnchor:userImageViewWrapper.topAnchor],
      [self.userImageView.bottomAnchor constraintEqualToAnchor:userImageViewWrapper.bottomAnchor]
      ]];
    
    self.stackView = [[CustomSpacingStackView alloc] initWithCustomSpacedArrangedSubviews:@[userImageViewWrapper, self.teamsGuestIndicator, self.remainingTimeLabel, self.availabilityView, self.readReceiptsEnabledLabel]];
    self.stackView.axis = UILayoutConstraintAxisVertical;
    self.stackView.spacing = 0;
    self.stackView.alignment = UIStackViewAlignmentCenter;
    [self.stackViewContainer addSubview:self.stackView];
    
    CGFloat verticalSpacing = 32;
    if (UIScreen.mainScreen.isSmall) {
        verticalSpacing = 16;
    }
    
    [self.stackView wr_addCustomSpacing:verticalSpacing after:userImageViewWrapper];

    if (self.remainingTimeLabel.isHidden) {
        [self.stackView wr_addCustomSpacing:(self.availabilityView.isHidden ? (verticalSpacing + 8) : verticalSpacing) after:self.teamsGuestIndicator];
    } else {
        [self.stackView wr_addCustomSpacing:8 after:self.teamsGuestIndicator];
        [self.stackView wr_addCustomSpacing:(self.availabilityView.isHidden ? (verticalSpacing + 8) : verticalSpacing) after:self.remainingTimeLabel];
    }
    
    [self.stackView wr_addCustomSpacing:verticalSpacing after:self.availabilityView];
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
    
    [self.stackViewContainer autoPinEdgeToSuperviewEdge:ALEdgeTop];
    [self.stackViewContainer autoPinEdgeToSuperviewEdge:ALEdgeLeading];
    [self.stackViewContainer autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
    [self.stackViewContainer autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:self.footerView];
    
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
    else {
        ProfileFooterView *userActionsFooterView = [[ProfileFooterView alloc] init];
        userActionsFooterView.translatesAutoresizingMaskIntoConstraints = NO;
        
        [userActionsFooterView setIconTypeForLeftButton:[self iconTypeForUserAction:[self leftButtonAction]]];
        [userActionsFooterView setIconTypeForRightButton:[self iconTypeForUserAction:[self rightButtonAction]]];
        [userActionsFooterView.leftButton setTitle:[[self buttonTextForUserAction:[self leftButtonAction]] uppercasedWithCurrentLocale] forState:UIControlStateNormal];
        
        [userActionsFooterView.leftButton addTarget:self action:@selector(performLeftButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        [userActionsFooterView.rightButton addTarget:self action:@selector(performRightButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        
        footerView = userActionsFooterView;
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
            return ZetaIconTypeCreateConversation;
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
    else if (user.canBeConnected) {
        return ProfileUserActionSendConnectionRequest;
    }
    else if (user.isWirelessUser) {
        return ProfileUserActionNone;
    }
    else {
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
        return ProfileUserActionPresentMenu;
    }
    else if (nil != user.team) {
        return ProfileUserActionPresentMenu;
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
            [self presentRemoveDialogueForParticipant:[self fullUser]
                                     fromConversation:self.conversation
                                            dismisser:self.viewControllerDismisser];
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

- (void)presentAddParticipantsViewController
{
    NSSet *selectedUsers = nil;
    if (nil != self.conversation.connectedUser) {
        selectedUsers = [NSSet setWithObject:self.conversation.connectedUser];
    } else {
        selectedUsers = [NSSet set];
    }
    
    ConversationCreationController *conversationCreationController = [[ConversationCreationController alloc] initWithPreSelectedParticipants:selectedUsers];
    
    if ([[[UIScreen mainScreen] traitCollection] horizontalSizeClass] == UIUserInterfaceSizeClassRegular) {
        [self dismissViewControllerAnimated:YES completion:^{
            UINavigationController *presentedViewController = [conversationCreationController wrapInNavigationController];
            
            presentedViewController.modalPresentationStyle = UIModalPresentationFormSheet;
            
            [[ZClientViewController sharedZClientViewController] presentViewController:presentedViewController
                                                                              animated:YES
                                                                            completion:nil];
        }];
    }
    else {
        KeyboardAvoidingViewController *avoiding = [[KeyboardAvoidingViewController alloc] initWithViewController:conversationCreationController];
        UINavigationController *presentedViewController = [avoiding wrapInNavigationController];
        
        presentedViewController.modalPresentationStyle = UIModalPresentationOverCurrentContext;
        presentedViewController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
        
        [self presentViewController:presentedViewController
                           animated:YES
                         completion:^{
            [UIApplication.sharedApplication wr_updateStatusBarForCurrentControllerAnimated:YES];
        }];
    }
    [self.delegate profileDetailsViewController:self didPresentConversationCreationController:conversationCreationController];
}

- (void)bringUpConnectionRequestSheet
{
    UIAlertController *controller = [UIAlertController controllerForAcceptingConnectionRequestForUser:self.fullUser completion:^(BOOL accept){
        if (accept) {
            [self acceptConnectionRequest];
        } else {
            [self cancelConnectionRequest];
        }
    }];
    
    controller.popoverPresentationController.sourceView = self.view;
    controller.popoverPresentationController.sourceRect = [self.view convertRect:self.footerView.frame fromView:self.footerView.superview];
    [self presentViewController:controller animated:YES completion:nil];
}

- (void)bringUpCancelConnectionRequestSheet
{
    UIAlertController *controller = [UIAlertController cancelConnectionRequestControllerForUser:self.fullUser completion:^(BOOL canceled) {
        if (!canceled) {
            [self cancelConnectionRequest];
        }
    }];

    [self presentViewController:controller animated:YES completion:nil];
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
            [self.bareUser connectWithMessage:message];
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
