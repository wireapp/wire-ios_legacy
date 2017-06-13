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


@import PureLayout;

#import "InviteBannerViewController.h"
#import "Button.h"
#import "UIColor+WR_ColorScheme.h"
#import "UIFont+MagicAccess.h"
#import "InviteContactsViewController.h"
#import "UIViewController+WR_Invite.h"
#import "Analytics+iOS.h"
#import "AnalyticsTracker+Invitations.h"

@interface InviteBannerViewController () <ContactsViewControllerDelegate>

@property (nonatomic) UIVisualEffectView *blurEffectView;
@property (nonatomic) UIView *separator;
@property (nonatomic) UILabel *messageLabel;
@property (nonatomic) Button *inviteButton;
@property (nonatomic) UIEdgeInsets edgeInsets;

@end

@implementation InviteBannerViewController

- (void)loadView
{
    self.blurEffectView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleDark]];
    self.view = self.blurEffectView;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.edgeInsets = UIEdgeInsetsMake(24, 24, 24, 24);
    
    self.separator = [[UIView alloc] initForAutoLayout];
    self.separator.backgroundColor = [UIColor wr_colorFromColorScheme:ColorSchemeColorSeparator variant:ColorSchemeVariantDark];
    [self.blurEffectView.contentView addSubview:self.separator];
    
    self.messageLabel = [[UILabel alloc] initForAutoLayout];
    self.messageLabel.textColor = [UIColor wr_colorFromColorScheme:ColorSchemeColorTextForeground variant:ColorSchemeVariantDark];
    self.messageLabel.attributedText = [self attributedTitleText];
    self.messageLabel.numberOfLines = 0;
    [self.blurEffectView.contentView addSubview:self.messageLabel];
    
    self.inviteButton = [Button buttonWithStyle:ButtonStyleFull];
    self.inviteButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.inviteButton addTarget:self action:@selector(presentInviteContactsViewController) forControlEvents:UIControlEventTouchUpInside];
    
    [self.inviteButton setTitle:NSLocalizedString(@"invite_banner.invite_button_title", nil) forState:UIControlStateNormal];
    [self.blurEffectView.contentView addSubview:self.inviteButton];
    
    [self createInitialConstraints];
}

- (void)createInitialConstraints
{
    [self.separator autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero excludingEdge:ALEdgeBottom];
    [self.separator autoSetDimension:ALDimensionHeight toSize:0.5];
    [self.messageLabel autoPinEdgesToSuperviewEdgesWithInsets:self.edgeInsets excludingEdge:ALEdgeBottom];
    [self.inviteButton autoPinEdgesToSuperviewEdgesWithInsets:self.edgeInsets  excludingEdge:ALEdgeTop];
    [self.inviteButton autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.messageLabel withOffset:24];
    [self.inviteButton autoSetDimension:ALDimensionHeight toSize:40];
}

- (NSAttributedString *)attributedTitleText
{
    NSString *title = NSLocalizedString(@"invite_banner.title", nil);
    NSString *paragraph = NSLocalizedString(@"invite_banner.message", nil);
    NSString *text = [@[title, paragraph] componentsJoinedByString:@"\u2029"];
    
    NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    paragraphStyle.paragraphSpacing = 10;
    
    NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithString:text attributes:@{ NSParagraphStyleAttributeName : paragraphStyle }];
    [attributedText addAttributes:@{ NSFontAttributeName: [UIFont fontWithMagicIdentifier:@"style.text.normal.font_spec_medium"] } range:[text rangeOfString:title]];
    [attributedText addAttributes:@{ NSFontAttributeName: [UIFont fontWithMagicIdentifier:@"style.text.normal.font_spec"] } range:[text rangeOfString:paragraph]];
    
    return [[NSAttributedString alloc] initWithAttributedString:attributedText];
}

#pragma mark - Actions

- (void)presentInviteContactsViewController
{
    InviteContactsViewController *inviteContactsViewController = [[InviteContactsViewController alloc] init];
    inviteContactsViewController.delegate = self;
    inviteContactsViewController.analyticsTracker = [AnalyticsTracker analyticsTrackerWithContext:NSStringFromInviteContext(InviteContextConversationList)];
    inviteContactsViewController.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    [self presentViewController:inviteContactsViewController animated:YES completion:^() {
        [[Analytics shared] tagScreenInviteContactList];
        [inviteContactsViewController.analyticsTracker tagEvent:AnalyticsEventInviteContactListOpened];
    }];
}

#pragma mark - ContactsViewControllerDelegate

- (void)contactsViewControllerDidCancel:(ContactsViewController *)controller
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)contactsViewControllerDidNotShareContacts:(ContactsViewController *)controller
{
    [self dismissViewControllerAnimated:YES completion:^{
        [self wr_presentInviteActivityViewControllerWithSourceView:self.inviteButton logicalContext:GenericInviteContextConversationList];
    }];
}

@end
