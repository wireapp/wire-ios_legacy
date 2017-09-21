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


#import "ContactsCell.h"
#import "BadgeUserImageView.h"
@import PureLayout;
#import "WireSyncEngine+iOS.h"
#import "UserImageView+Magic.h"
@import WireExtensionComponents;



NS_ASSUME_NONNULL_BEGIN
@interface ContactsCell ()
@property (nonatomic) BadgeUserImageView *userImageView;
@property (nonatomic) UILabel *userNameLabel;
@property (nonatomic) UILabel *userSubtitleLabel;
@property (nonatomic) UIView *userNameContainerView;
@property (nonatomic, readwrite) Button *actionButton;
@property (nonatomic) CGFloat actionButtonWidth;
@property (nonatomic) NSLayoutConstraint *actionButtonRightConstraint;
@property (nonatomic) NSLayoutConstraint *actionButtonWidthConstraint;
@end
NS_ASSUME_NONNULL_END



@implementation ContactsCell

#pragma mark - Init

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self setup];
    }
    return self;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setup];
    }
    return self;
}

#pragma mark - Setup UI

- (void)setup
{
    _actionButtonWidth = 50;    // default value
    [self setupSubviews];
    [self setupConstraints];
}

- (void)setupSubviews
{
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    self.userImageView = [[BadgeUserImageView alloc] initWithMagicPrefix:@"address_book"];
    self.userImageView.userSession = [ZMUserSession sharedSession];
    self.userImageView.size = UserImageViewSizeTiny;
    self.userImageView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:self.userImageView];
    
    self.userNameContainerView = [[UIView alloc] initForAutoLayout];
    [self.contentView addSubview:self.userNameContainerView];
    
    self.userNameLabel = [[UILabel alloc] initForAutoLayout];
    [self.userNameContainerView addSubview:self.userNameLabel];
    
    self.userSubtitleLabel = [[UILabel alloc] initForAutoLayout];
    [self.userNameContainerView addSubview:self.userSubtitleLabel];
    
    self.actionButton = [Button buttonWithStyleClass:@"dialogue-button-full"];
    [self.actionButton setTitle:@"INVITE" forState:UIControlStateNormal];
    [self.actionButton addTarget:self action:@selector(actionButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:self.actionButton];
}

- (void)setupConstraints
{
    [self.userImageView autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsMake(8, 24, 8, 0) excludingEdge:ALEdgeTrailing];
    [self.userImageView autoPinEdge:ALEdgeRight toEdge:ALEdgeLeft ofView:self.userNameContainerView withOffset:-10];
    [self.userImageView autoSetDimensionsToSize:self.userImageView.intrinsicContentSize];
    [NSLayoutConstraint autoSetPriority:UILayoutPriorityRequired forConstraints:^{
        [self.userImageView autoSetContentHuggingPriorityForAxis:ALAxisHorizontal];
        [self.userImageView autoSetContentHuggingPriorityForAxis:ALAxisVertical];
    }];
    
    [self.userNameContainerView autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
    [self.userNameContainerView autoPinEdge:ALEdgeTrailing toEdge:ALEdgeLeading ofView:self.actionButton
                                 withOffset:-8 relation:NSLayoutRelationLessThanOrEqual];
    
    [self.userNameLabel autoPinEdgeToSuperviewEdge:ALEdgeLeading];
    [self.userNameLabel autoPinEdgeToSuperviewEdge:ALEdgeTop];
    [self.userNameLabel autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
    [self.userSubtitleLabel autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self.userNameLabel];
    [self.userSubtitleLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.userNameLabel withOffset:0];
    [self.userSubtitleLabel autoPinEdgeToSuperviewEdge:ALEdgeBottom];
    [self.userSubtitleLabel autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
    
    self.actionButtonRightConstraint = [self.actionButton autoPinEdgeToSuperviewEdge:ALEdgeTrailing withInset:9];
    [NSLayoutConstraint autoSetPriority:UILayoutPriorityDefaultHigh + 1 forConstraints:^{
        self.actionButtonWidthConstraint = [self.actionButton autoSetDimension:ALDimensionWidth toSize:self.actionButtonWidth];
    }];
    [self.actionButton autoSetDimension:ALDimensionWidth toSize:48 relation:NSLayoutRelationGreaterThanOrEqual];    // MIN Width
    [self.actionButton autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self withMultiplier:0.4f relation:NSLayoutRelationLessThanOrEqual];  // MAX width
    [self.actionButton autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
}

#pragma mark - Properties

- (void)setSearchUser:(ZMSearchUser *)searchUser
{
    _searchUser = searchUser;
    
    self.userImageView.user = _searchUser;
    if (_searchUser.name.length > 0) {
        self.userNameLabel.text = _searchUser.name;
    } else if (_searchUser.contact.emailAddresses.count > 0) {
        self.userNameLabel.text = _searchUser.contact.emailAddresses[0];
    } else if (_searchUser.contact.phoneNumbers.count > 0) {
        self.userNameLabel.text = _searchUser.contact.phoneNumbers[0];
    }
    
    // For users who has sent us connected request, we show that
    // Otherwise, we display name in contacts for users who are:
    // 1) Wire contacts of current user => searchUser.user != nil
    // 2) Are also present in current users address book => nameInContacts != nil
    // 3) Name in address book is different from name in Wire
    NSString *subtitle = @"";
    if (searchUser.user != nil) {
        if ([searchUser.user isPendingApprovalBySelfUser]) {
            subtitle = [NSString stringWithFormat:NSLocalizedString(@"contacts_ui.connection_request", @""), subtitle, nil];
        } else if (subtitle.length > 0 && ([subtitle caseInsensitiveCompare:_searchUser.name] != NSOrderedSame)) {
            subtitle = [NSString stringWithFormat:NSLocalizedString(@"contacts_ui.name_in_contacts", @""), subtitle, nil];
        }
    } else {
        subtitle = @"";
    }
    self.userSubtitleLabel.text = subtitle;
    
    if ([searchUser.user isPendingApprovalBySelfUser]) {
        [self.userImageView setBadgeIcon:ZetaIconTypeClock];
    } else {
        self.userImageView.badgeIcon = ZetaIconTypeNone;
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    if (self.userImageView.badgeIcon != ZetaIconTypeNone && self.userImageView.badgeIcon != ZetaIconTypeCheckmark) {
        return;
    }
    self.userImageView.badgeIcon = selected ? ZetaIconTypeCheckmark : ZetaIconTypeNone;
}

- (void)setSectionIndexShown:(BOOL)sectionIndexShown
{
    _sectionIndexShown = sectionIndexShown;
    
    self.actionButtonRightConstraint.constant = _sectionIndexShown ? -9 : -24;
    [self layoutIfNeeded];
}

- (void)setActionButtonWidth:(CGFloat)actionButtonWidth
{
    _actionButtonWidth = actionButtonWidth;
    
    self.actionButtonWidthConstraint.constant = _actionButtonWidth;
    [self layoutIfNeeded];
}

- (void)setAllActionButtonTitles:(NSArray *)allActionButtonTitles
{
    _allActionButtonTitles = allActionButtonTitles;
    self.actionButtonWidth = [self actionButtonWidthForTitles:_allActionButtonTitles
                                                textTransform:self.actionButton.textTransform
                                                contentInsets:self.actionButton.contentEdgeInsets
                                               textAttributes:@{NSFontAttributeName : self.actionButton.titleLabel.font}];
}

- (CGFloat)actionButtonWidthForTitles:(NSArray *)actionButtonTitles
                        textTransform:(TextTransform)textTransform
                        contentInsets:(UIEdgeInsets)contentInsets
                       textAttributes:(NSDictionary *)textAttributes
{
    CGFloat width = 0.0f;
    for (NSString *title in actionButtonTitles) {
        NSString *transformedTitle = [title transformStringWithTransform:textTransform];
        CGFloat titleWidth = [transformedTitle sizeWithAttributes:textAttributes].width;
        if (titleWidth > width) {
            width = titleWidth;
        }
    }
    return ceilf(contentInsets.left + width + contentInsets.right);
}

#pragma mark - Actions

- (void)actionButtonPressed:(id)sender
{
    if (self.actionButtonHandler) {
        self.actionButtonHandler(self.searchUser);
    }
}

#pragma mark - Status update

- (void)invitationStatusChanged
{
    if (self.searchUser.user.connection.status == ZMInvitationStatusPending ||
        self.searchUser.user.connection.status == ZMInvitationStatusSent) {
        [self.userImageView setBadgeIcon:ZetaIconTypeClock animated:YES];
    } else if (self.searchUser.user.connection.status == ZMInvitationStatusFailed) {
        [self.userImageView setBadgeIcon:ZetaIconTypeNone animated:YES];
    }
}

@end

