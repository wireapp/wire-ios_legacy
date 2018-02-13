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


#import "SearchResultCell.h"
#import "WAZUIMagiciOS.h"
@import PureLayout;
#import "BadgeUserImageView.h"
#import "UIImage+ZetaIconsNeue.h"
#import "WireSyncEngine+iOS.h"
#import "UIView+WR_ExtendedBlockAnimations.h"
@import WireDataModel;
#import "Wire-Swift.h"

@interface SearchResultCell ()
@property (nonatomic, strong) UIView *gesturesView;
@property (nonatomic, strong) BadgeUserImageView *badgeUserImageView;
@property (nonatomic, strong) ConversationAvatarView *conversationImageView;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UIView *avatarContainer;
@property (nonatomic, strong) IconButton *instantConnectButton;

@property (nonatomic, strong) UIView *avatarOverlay;
@property (nonatomic, strong) UIImageView *successCheckmark;
@property (nonatomic, strong) UIImageView *trailingCheckmarkView;

@property (nonatomic, strong) UIStackView *nameLabelStackView;

@property (nonatomic, assign) BOOL initialConstraintsCreated;
@property (nonatomic, strong) NSLayoutConstraint *avatarViewSizeConstraint;
@property (nonatomic, strong) NSLayoutConstraint *conversationImageViewSize;
@property (nonatomic, strong) NSLayoutConstraint *nameRightMarginConstraint;
@property (nonatomic, strong) NSLayoutConstraint *guestLabelTrailingConstraint;
@property (nonatomic, strong) NSLayoutConstraint *guestLabelCheckmarkViewHorizontalConstraint;

@property (nonatomic, strong) UILabel *subtitleLabel;

@property (nonatomic, strong) GuestLabel *guestLabel;
@property (nonatomic, strong) UIView *separatorLineView;

@end

@implementation SearchResultCell

- (UIColor *)subtitleColor
{
    return [UIColor wr_colorFromColorScheme:ColorSchemeColorSectionText variant:self.colorSchemeVariant];
}

+ (UIFont *)lightFont
{
    return [UIFont fontWithMagicIdentifier:@"style.text.small.font_spec_light"];
}

+ (UIFont *)boldFont
{
    return [UIFont fontWithMagicIdentifier:@"style.text.small.font_spec_bold"];
}

+ (AddressBookCorrelationFormatter *)correlationFormatter
{
    static dispatch_once_t onceToken;
    static AddressBookCorrelationFormatter *formatter = nil;
    dispatch_once(&onceToken, ^{
        formatter = [[AddressBookCorrelationFormatter alloc] initWithLightFont:self.lightFont boldFont:self.boldFont color:UIColor.whiteColor];
    });

    return formatter;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.isAccessibilityElement = YES;
        self.shouldGroupAccessibilityChildren = YES;
        
        self.colorSchemeVariant = ColorSchemeVariantDark;
        self.contentView.translatesAutoresizingMaskIntoConstraints = NO;

        self.gesturesView = [[UIView alloc] initForAutoLayout];
        self.gesturesView.backgroundColor = [UIColor clearColor];
        [self.swipeView addSubview:self.gesturesView];

        self.avatarContainer = [[UIView alloc] initForAutoLayout];
        self.avatarContainer.userInteractionEnabled = NO;
        self.avatarContainer.opaque = NO;
        [self.swipeView addSubview:self.avatarContainer];

        self.conversationImageView = [[ConversationAvatarView alloc] initForAutoLayout];
        self.conversationImageView.opaque = NO;
        [self.avatarContainer addSubview:self.conversationImageView];
        
        self.nameLabelStackView = [[UIStackView alloc] initForAutoLayout];
        self.nameLabelStackView.axis = UILayoutConstraintAxisVertical;
        self.nameLabelStackView.spacing = 2;
        [self.swipeView addSubview:self.nameLabelStackView];

        self.nameLabel = [[UILabel alloc] initForAutoLayout];
        self.nameLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        self.nameLabel.textAlignment = NSTextAlignmentNatural;
        [self.nameLabelStackView addArrangedSubview:self.nameLabel];

        self.subtitleLabel = [[UILabel alloc] initForAutoLayout];
        self.subtitleLabel.accessibilityIdentifier = @"additionalUserInfo";
        [self.nameLabelStackView addArrangedSubview:self.subtitleLabel];

        self.separatorLineView = [[UIView alloc] initForAutoLayout];
        [self.swipeView addSubview:self.separatorLineView];
        
        self.trailingCheckmarkView = [[UIImageView alloc] initForAutoLayout];
        [self.swipeView addSubview:self.trailingCheckmarkView];
        self.trailingCheckmarkView.layer.borderColor = [ColorScheme.defaultColorScheme colorWithName:ColorSchemeColorIconNormal].CGColor;
        self.trailingCheckmarkView.layer.borderWidth = 2;
        self.trailingCheckmarkView.contentMode = UIViewContentModeCenter;
        self.trailingCheckmarkView.layer.cornerRadius = 12;

        UITapGestureRecognizer *doubleTapper = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTap:)];
        doubleTapper.numberOfTapsRequired = 2;
        doubleTapper.numberOfTouchesRequired = 1;
        doubleTapper.delaysTouchesBegan = YES;
        [self.gesturesView addGestureRecognizer:doubleTapper];
        
        self.instantConnectButton = [[IconButton alloc] initForAutoLayout];
        self.instantConnectButton.borderWidth = 0;
        self.instantConnectButton.adjustsImageWhenDisabled = NO;
        [self.instantConnectButton setIconColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [self.instantConnectButton setIcon:ZetaIconTypePlusCircled withSize:ZetaIconSizeTiny forState:UIControlStateNormal];
        
        [self.instantConnectButton addTarget:self action:@selector(instantConnect:) forControlEvents:UIControlEventTouchUpInside];
        self.instantConnectButton.accessibilityIdentifier = @"instantPlusConnectButton";
        [self.swipeView addSubview:self.instantConnectButton];

        [self createUserImageView];
        [self setNeedsUpdateConstraints];
        [self updateForContext];
        
        self.accessoryType = SearchResultCellAccessoryTypeNone;
    }
    return self;
}

- (void)createUserImageView
{
    [self.badgeUserImageView removeFromSuperview];

    self.badgeUserImageView = [[BadgeUserImageView alloc] initWithMagicPrefix:@"people_picker.search_results_mode"];
    self.badgeUserImageView.userSession = [ZMUserSession sharedSession];
    self.badgeUserImageView.size = UserImageViewSizeTiny;
    self.badgeUserImageView.translatesAutoresizingMaskIntoConstraints = NO;
    self.badgeUserImageView.badgeIconSize = ZetaIconSizeTiny;

    [self.avatarContainer addSubview:self.badgeUserImageView];
}

- (void)updateConstraints
{
    CGFloat rightMargin = [WAZUIMagic cgFloatForIdentifier:@"people_picker.search_results_mode.person_tile_right_margin"];
    CGFloat leftMargin = [WAZUIMagic cgFloatForIdentifier:@"people_picker.search_results_mode.person_tile_left_margin"];
    CGFloat nameAvatarMargin = [WAZUIMagic cgFloatForIdentifier:@"people_picker.search_results_mode.tile_name_horizontal_spacing"];
    if (! self.initialConstraintsCreated) {

        [self.badgeUserImageView autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero];
        [self.contentView autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero];

        [self.gesturesView autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero];

        [self.nameLabelStackView autoAlignAxis:ALAxisHorizontal toSameAxisOfView:self.avatarContainer];
        
        [self.nameLabelStackView autoPinEdge:ALEdgeLeading toEdge:ALEdgeTrailing ofView:self.avatarContainer withOffset:nameAvatarMargin];
        self.nameRightMarginConstraint = [self.nameLabelStackView autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self.swipeView withOffset:- rightMargin];

        self.avatarViewSizeConstraint = [self.avatarContainer autoSetDimension:ALDimensionWidth toSize:80];
        [self.avatarContainer autoMatchDimension:ALDimensionWidth toDimension:ALDimensionHeight ofView:self.avatarContainer];
        [self.avatarContainer autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self.swipeView withOffset:leftMargin];
        [self.avatarContainer autoAlignAxisToSuperviewMarginAxis:ALAxisHorizontal];

        self.conversationImageViewSize = [self.conversationImageView autoSetDimension:ALDimensionWidth toSize:80];
        [self.conversationImageView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionHeight ofView:self.conversationImageView];
        [self.conversationImageView autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self.swipeView withOffset:[WAZUIMagic cgFloatForIdentifier:@"people_picker.search_results_mode.person_tile_left_margin"]];
        [self.conversationImageView autoPinEdgeToSuperviewEdge:ALEdgeTop];

        [self.instantConnectButton autoAlignAxis:ALAxisHorizontal toSameAxisOfView:self.avatarContainer];
        [self.instantConnectButton autoPinEdgeToSuperviewEdge:ALEdgeTrailing withInset:16];
        
        [self.trailingCheckmarkView autoAlignAxis:ALAxisHorizontal toSameAxisOfView:self.avatarContainer];
        [self.trailingCheckmarkView autoPinEdgeToSuperviewEdge:ALEdgeTrailing withInset:16];
        [self.trailingCheckmarkView autoSetDimensionsToSize:CGSizeMake(24, 24)];

        [self.separatorLineView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
        [self.separatorLineView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
        [self.separatorLineView autoSetDimension:ALDimensionHeight toSize:UIScreen.hairline];
        [self.separatorLineView autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self.nameLabel];
        
        self.initialConstraintsCreated = YES;
        [self updateForContext];

        [UIView performWithoutAnimation:^{
            [self layoutIfNeeded];
        }];
    }

    CGFloat rightMarginForName = rightMargin;
    if (!self.instantConnectButton.hidden) {
        rightMarginForName = self.instantConnectButton.bounds.size.width;
    }
    else if (!self.guestLabel.hidden) {
        rightMarginForName = self.guestLabel.bounds.size.width + rightMargin;
    }

    self.nameRightMarginConstraint.constant = -rightMarginForName;
    [super updateConstraints];
}

- (void)updateForContext
{
    self.nameLabel.font = [UIFont fontWithMagicIdentifier:@"people_picker.search_results_mode.name_label_font"];
    self.nameLabel.textColor = [UIColor wr_colorFromColorScheme:ColorSchemeColorTextForeground variant:self.colorSchemeVariant];
    self.separatorLineView.backgroundColor = [ColorScheme.defaultColorScheme colorWithName:ColorSchemeColorCellSeparator variant:self.colorSchemeVariant];

    CGFloat squareImageWidth = [WAZUIMagic cgFloatForIdentifier:@"people_picker.search_results_mode.tile_image_diameter"];
    self.avatarViewSizeConstraint.constant = squareImageWidth;
    self.conversationImageViewSize.constant = squareImageWidth;
    self.badgeUserImageView.badgeColor = [UIColor whiteColor];
    
    [self updateSubtitle];
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    [UIView performWithoutAnimation:^{
        self.conversationImageView.conversation = nil;
        self.conversationImageView.hidden = NO;
        self.badgeUserImageView.hidden = NO;
        self.subtitleLabel.text = @"";
        self.nameLabel.text = @"";
        [self setDrawerOpen:NO animated:NO];
        // cleanup animation
        [self.instantConnectButton setIcon:ZetaIconTypePlusCircled withSize:ZetaIconSizeTiny forState:UIControlStateNormal];
        [self.avatarOverlay removeFromSuperview];
        self.avatarOverlay = nil;
        [self.successCheckmark removeFromSuperview];
        self.successCheckmark = nil;
        self.contentView.alpha = 1.0f;
        self.accessoryType = SearchResultCellAccessoryTypeNone;
        self.backgroundColor = UIColor.clearColor;
    }];
}

- (void)updateForUser
{
    ZMUser *fullUser = BareUserToUser(self.user);
    
    if (fullUser != nil && ZMUser.selfUser.isTeamMember) {
        UIColor *textColor = [[ColorScheme defaultColorScheme] colorWithName:ColorSchemeColorTextForeground variant:self.colorSchemeVariant];
        self.nameLabel.attributedText = [AvailabilityStringBuilder stringFor:fullUser with:AvailabilityLabelStyleList color:textColor];
    } else {
        self.nameLabel.text = self.user.name;
    }
    
    [self updateSubtitle];
    [self updateGuestLabel];
    
    BOOL canBeConnected = YES;

    if (self.user == nil) {
        canBeConnected = NO;
    }
    else if (fullUser != nil) {
        canBeConnected = fullUser.canBeConnected && ! fullUser.isBlocked && ! fullUser.isPendingApproval && !fullUser.isTeamMember && !fullUser.isServiceUser;
    }
    else {
        canBeConnected = self.user.canBeConnected;
    }

    self.instantConnectButton.hidden = ! canBeConnected;
    [self setNeedsUpdateConstraints];
    self.badgeUserImageView.user = (id)self.user;
    
    [self updateAccessibilityLabel];
}

- (void)updateForConversation
{
    if (self.conversation.conversationType == ZMConversationTypeOneOnOne) {
        ZMUser *otherUser = self.conversation.connectedUser;
        self.user = otherUser;
        self.badgeUserImageView.hidden = NO;
        self.conversationImageView.conversation = nil;
    }
    else {
        self.conversationImageView.conversation = self.conversation;
        self.badgeUserImageView.hidden = YES;
        self.user = nil;
        self.nameLabel.text = self.conversation.displayName;
    }
    
    [self updateAccessibilityLabel];
}

- (void)updateAccessibilityLabel
{
    if (self.nameLabel.text.length != 0 && self.subtitleLabel.text.length != 0) {
        self.accessibilityLabel = [NSString stringWithFormat:@"%@ - %@", self.nameLabel.text, self.subtitleLabel.text];
    }
    else if (self.nameLabel.text.length != 0) {
        self.accessibilityLabel = self.nameLabel.text;
    }
    else {
        self.accessibilityLabel = @"";
    }
}

#pragma mark - Public API

- (void)playAddUserAnimation
{
    [self.instantConnectButton setIcon:ZetaIconTypeCheckmarkCircled withSize:ZetaIconSizeTiny forState:UIControlStateNormal];

    self.avatarOverlay = [[UIView alloc] initForAutoLayout];
    self.avatarOverlay.backgroundColor = [UIColor blackColor];
    self.avatarOverlay.alpha = 0.0f;
    self.avatarOverlay.layer.cornerRadius = self.badgeUserImageView.bounds.size.width / 2.0f;
    [self.swipeView addSubview:self.avatarOverlay];

    [self.avatarOverlay autoAlignAxis:ALAxisHorizontal toSameAxisOfView:self.badgeUserImageView];
    [self.avatarOverlay autoAlignAxis:ALAxisVertical toSameAxisOfView:self.badgeUserImageView];
    [self.avatarOverlay autoSetDimensionsToSize:self.badgeUserImageView.bounds.size];
    [self layoutIfNeeded];

    [UIView wr_animateWithEasing:RBBEasingFunctionEaseOutQuart duration:0.15f animations:^{
        self.avatarOverlay.alpha = 0.5f;
    }];
    
    self.successCheckmark = [[UIImageView alloc] initForAutoLayout];
    self.successCheckmark.image = [UIImage imageForIcon:ZetaIconTypeClock iconSize:ZetaIconSizeSmall color:[UIColor whiteColor]];
    [self.swipeView addSubview:self.successCheckmark];
    self.successCheckmark.transform = CGAffineTransformMakeScale(1.8f, 1.8f);
    self.successCheckmark.alpha = 0.0f;

    [self.successCheckmark autoAlignAxis:ALAxisHorizontal toSameAxisOfView:self.badgeUserImageView];
    [self.successCheckmark autoAlignAxis:ALAxisVertical toSameAxisOfView:self.badgeUserImageView];
    [self.successCheckmark autoSetDimensionsToSize:self.successCheckmark.image.size];
    [self layoutIfNeeded];
    
    [UIView wr_animateWithEasing:RBBEasingFunctionEaseOutBounce duration:0.35f delay:0.1f animations:^{
        self.successCheckmark.transform = CGAffineTransformIdentity;
        self.successCheckmark.alpha = 1.0f;
    } completion:nil];
    
    [UIView wr_animateWithEasing:RBBEasingFunctionEaseOutQuart duration:0.55f delay:0.45f animations:^{
        self.contentView.alpha = 0.0f;
    } completion:nil];
}

#pragma mark - Callbacks

- (void)doubleTap:(UITapGestureRecognizer *)doubleTapper
{
    if (self.doubleTapAction != nil) {
        self.doubleTapAction(self);
    }
}

- (void)instantConnect:(UIButton *)button
{
    if (self.instantConnectAction != nil) {
        self.instantConnectAction(self);
    }
}

#pragma mark - Get, set

- (void)setUser:(id<ZMBareUser, ZMSearchableUser, AccentColorProvider>)user
{
    _user = user;

    [self updateForUser];
}

- (void)setConversation:(ZMConversation *)conversation
{
    _conversation = conversation;
    
    [self updateForConversation];
}

- (void)setSelected:(BOOL)selected
{
    [super setSelected:selected];
    [self updateTrailingImageViewSelected:selected];
}

- (void)setHighlighted:(BOOL)highlighted
{
    [super setHighlighted:highlighted];
    self.backgroundColor = highlighted ? [UIColor colorWithWhite:0 alpha:0.08] : UIColor.clearColor;
}

#pragma mark - Override

- (NSString *)mutuallyExclusiveSwipeIdentifier
{
    return NSStringFromClass(self.class);
}

- (BOOL)canOpenDrawer
{
    return NO;
}

- (void)updateSubtitle
{
    NSAttributedString *subtitle = [self attributedSubtitleForUser:(id)self.user];
    self.subtitleLabel.attributedText = subtitle;
    self.subtitleLabel.hidden = nil == subtitle || [subtitle.string isEqualToString:@""];
}

- (void)updateGuestLabel
{
    CGFloat rightMargin = [WAZUIMagic cgFloatForIdentifier:@"people_picker.search_results_mode.person_tile_right_margin"];

    if (nil != self.team && !self.user.isTeamMember) {
        if (nil == self.guestLabel) {
            self.guestLabel = [[GuestLabel alloc] init];
            [self.swipeView addSubview:self.guestLabel];
            [self.guestLabel autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
            self.guestLabelTrailingConstraint = [self.guestLabel autoPinEdgeToSuperviewEdge:ALEdgeTrailing withInset:rightMargin];
            self.guestLabelCheckmarkViewHorizontalConstraint = [self.guestLabel autoPinEdge:ALEdgeTrailing toEdge:ALEdgeLeading ofView:self.trailingCheckmarkView withOffset:-16];
            [self updateGuestLabelConstraints];
        }
        self.guestLabel.hidden = NO;
    }
    else {
        self.guestLabel.hidden = YES;
    }
}

- (void)updateGuestLabelConstraints
{
    self.guestLabelCheckmarkViewHorizontalConstraint.active = self.accessoryType == SearchResultCellAccessoryTypeTrailingCheckmark;
    self.guestLabelTrailingConstraint.active = self.accessoryType != SearchResultCellAccessoryTypeTrailingCheckmark;
}

- (void)setAccessoryType:(SearchResultCellAccessoryType)accessoryType
{
    _accessoryType = accessoryType;
    [self updateGuestLabelConstraints];
    [self setSelected:self.selected];
}

- (void)updateTrailingImageViewSelected:(BOOL)selected
{
    self.trailingCheckmarkView.hidden = self.accessoryType == SearchResultCellAccessoryTypeNone;
    
    switch (self.accessoryType) {
        case SearchResultCellAccessoryTypeNone:
            break;
        case SearchResultCellAccessoryTypeDisclosureIndicator: {
            self.trailingCheckmarkView.backgroundColor = nil;
            self.trailingCheckmarkView.layer.borderColor = UIColor.clearColor.CGColor;
            UIColor *color = [ColorScheme.defaultColorScheme colorWithName:ColorSchemeColorSeparator];
            self.trailingCheckmarkView.image = [UIImage imageForIcon:ZetaIconTypeDisclosureIndicator iconSize:ZetaIconSizeLike color:color];
            break;
        }
        case SearchResultCellAccessoryTypeTrailingCheckmark: {
            UIColor *foregroundColor = [ColorScheme.defaultColorScheme colorWithName:ColorSchemeColorBackground];
            UIColor *backgroundColor = [ColorScheme.defaultColorScheme colorWithName:ColorSchemeColorIconNormal];
            self.trailingCheckmarkView.image = selected ? [UIImage imageForIcon:ZetaIconTypeCheckmark iconSize:ZetaIconSizeLike color:foregroundColor] : nil;
            self.trailingCheckmarkView.backgroundColor = selected ? backgroundColor : UIColor.clearColor;
            UIColor *borderColor = selected ? backgroundColor : [backgroundColor colorWithAlphaComponent:0.64];
            self.trailingCheckmarkView.layer.borderColor = borderColor.CGColor;
            break;
        }
    }
}

- (NSAttributedString *)attributedSubtitleForRegularUser:(id <ZMBareUser, ZMSearchableUser>)user
{
    NSMutableAttributedString *subtitle = [[NSMutableAttributedString alloc] init];
    
    NSAttributedString *attributedHandle;
    NSString *handle = user.handle ?: BareUserToUser(user).handle;
    
    if (nil != handle && handle.length > 0) {
        NSDictionary *attributes = @{ NSFontAttributeName: self.class.boldFont, NSForegroundColorAttributeName: self.subtitleColor };
        NSString *displayHandle = [NSString stringWithFormat:@"@%@", handle];
        attributedHandle = [[NSAttributedString alloc] initWithString:displayHandle attributes:attributes];
        [subtitle appendAttributedString:attributedHandle];
    }
    
    NSString *addresBookName = BareUserToUser(user).addressBookEntry.cachedName;
    NSAttributedString *correlation = [self.class.correlationFormatter correlationTextFor:self.user addressBookName:addresBookName];
    if (nil != correlation) {
        if (nil != attributedHandle) {
            NSDictionary *delimiterAttributes = @{ NSFontAttributeName: self.class.lightFont, NSForegroundColorAttributeName: self.subtitleColor };
            [subtitle appendAttributedString:[[NSAttributedString alloc] initWithString:NSLocalizedString(@" · ", nil) attributes:delimiterAttributes]];
        }
        [subtitle appendAttributedString:correlation];
    }
    
    return subtitle.length != 0 ? [[NSAttributedString alloc] initWithAttributedString:subtitle] : nil;
}

- (NSAttributedString *)attributedSubtitleForServiceUser:(id <SearchServiceUser>)user
{
    if (user.summary.length != 0) {
        NSDictionary *attributes = @{ NSFontAttributeName: self.class.boldFont, NSForegroundColorAttributeName: self.subtitleColor };
        return [[NSAttributedString alloc] initWithString:user.summary
                                               attributes:attributes];
    }
    else {
        return nil;
    }
}

- (NSAttributedString *)attributedSubtitleForUser:(id <ZMBareUser, ZMSearchableUser>)user
{
    if ([user conformsToProtocol:@protocol(SearchServiceUser)]) {
        return [self attributedSubtitleForServiceUser:(id<SearchServiceUser>)user];
    }
    else {
        return [self attributedSubtitleForRegularUser:user];
    }
}

@end
