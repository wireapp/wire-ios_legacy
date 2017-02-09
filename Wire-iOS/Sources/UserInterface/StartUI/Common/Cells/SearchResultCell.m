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
#import <PureLayout.h>
#import "UIView+MTAnimation.h"
#import "BadgeUserImageView.h"
#import "UIImage+ZetaIconsNeue.h"
#import "zmessaging+iOS.h"
#import <ZMCDataModel/ZMBareUser.h>
#import "Wire-Swift.h"

@interface SearchResultCell ()
@property (nonatomic, strong) UIView *gesturesView;
@property (nonatomic, strong) BadgeUserImageView *badgeUserImageView;
@property (nonatomic, strong) UIImageView *conversationImageView;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UIView *avatarContainer;
@property (nonatomic, strong) IconButton *instantConnectButton;

@property (nonatomic, strong) UIView *avatarOverlay;
@property (nonatomic, strong) UIImageView *successCheckmark;

@property (nonatomic, assign) BOOL initialConstraintsCreated;
@property (nonatomic, strong) NSLayoutConstraint *avatarViewSizeConstraint;
@property (nonatomic, strong) NSLayoutConstraint *conversationImageViewSize;
@property (nonatomic, strong) NSLayoutConstraint *nameLabelTopConstraint;
@property (nonatomic, strong) NSLayoutConstraint *nameLabelVerticalConstraint;
@property (nonatomic, strong) NSLayoutConstraint *nameRightMarginConstraint;
@property (nonatomic, strong) NSLayoutConstraint *subtitleRightMarginConstraint;

@property (nonatomic, strong) UILabel *subtitleLabel;

@end

@implementation SearchResultCell

+ (UIColor *)subtitleColor
{
    return [UIColor colorWithWhite:1.0f alpha:0.4f];
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
        formatter = [[AddressBookCorrelationFormatter alloc] initWithLightFont:self.lightFont boldFont:self.boldFont color:self.subtitleColor];
    });

    return formatter;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.contentView.translatesAutoresizingMaskIntoConstraints = NO;

        self.gesturesView = [[UIView alloc] initForAutoLayout];
        self.gesturesView.backgroundColor = [UIColor clearColor];
        [self.swipeView addSubview:self.gesturesView];

        self.avatarContainer = [[UIView alloc] initForAutoLayout];
        self.avatarContainer.userInteractionEnabled = NO;
        self.avatarContainer.opaque = NO;
        [self.swipeView addSubview:self.avatarContainer];

        self.conversationImageView = [[UIImageView alloc] initForAutoLayout];
        self.conversationImageView.opaque = NO;
        [self.avatarContainer addSubview:self.conversationImageView];

        self.nameLabel = [[UILabel alloc] initForAutoLayout];
        self.nameLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        self.nameLabel.textAlignment = NSTextAlignmentNatural;
        [self.swipeView addSubview:self.nameLabel];

        self.subtitleLabel = [[UILabel alloc] initForAutoLayout];
        self.subtitleLabel.accessibilityIdentifier = @"additionalUserInfo";
        [self.swipeView addSubview:self.subtitleLabel];

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
    }
    return self;
}

- (void)createUserImageView
{
    [self.badgeUserImageView removeFromSuperview];

    self.badgeUserImageView = [[BadgeUserImageView alloc] initWithMagicPrefix:@"people_picker.search_results_mode"];
    self.badgeUserImageView.suggestedImageSize = UserImageViewSizeTiny;
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

        [self.subtitleLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.nameLabel];
        [self.subtitleLabel autoPinEdge:ALEdgeLeading toEdge:ALEdgeTrailing ofView:self.avatarContainer withOffset:[WAZUIMagic cgFloatForIdentifier:@"people_picker.search_results_mode.tile_name_horizontal_spacing"]];
        self.subtitleRightMarginConstraint = [self.subtitleLabel autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self.swipeView withOffset:- rightMargin];

        self.nameLabelTopConstraint = [self.nameLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self.swipeView withOffset:9.0f];
        self.nameLabelVerticalConstraint = [self.nameLabel autoAlignAxis:ALAxisHorizontal toSameAxisOfView:self.avatarContainer];
        
        if (self.subtitleLabel.text.length == 0) {
            self.nameLabelTopConstraint.active = NO;
            self.nameLabelVerticalConstraint.active = YES;
        }
        else {
            self.nameLabelVerticalConstraint.active = NO;
            self.nameLabelTopConstraint.active = YES;
        }
        
        [self.nameLabel autoPinEdge:ALEdgeLeading toEdge:ALEdgeTrailing ofView:self.avatarContainer withOffset:nameAvatarMargin];
        self.nameRightMarginConstraint = [self.nameLabel autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self.swipeView withOffset:- rightMargin];

        self.avatarViewSizeConstraint = [self.avatarContainer autoSetDimension:ALDimensionWidth toSize:80];
        [self.avatarContainer autoMatchDimension:ALDimensionWidth toDimension:ALDimensionHeight ofView:self.avatarContainer];
        [self.avatarContainer autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self.swipeView withOffset:leftMargin];
        [self.avatarContainer autoAlignAxisToSuperviewMarginAxis:ALAxisHorizontal];

        self.conversationImageViewSize = [self.conversationImageView autoSetDimension:ALDimensionWidth toSize:80];
        [self.conversationImageView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionHeight ofView:self.conversationImageView];
        [self.conversationImageView autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self.swipeView withOffset:[WAZUIMagic cgFloatForIdentifier:@"people_picker.search_results_mode.person_tile_left_margin"]];
        [self.conversationImageView autoPinEdgeToSuperviewEdge:ALEdgeTop];

        [self.instantConnectButton autoAlignAxis:ALAxisHorizontal toSameAxisOfView:self.avatarContainer];
        [self.instantConnectButton autoPinEdgeToSuperviewEdge:ALEdgeTrailing withInset:0];
        [self.instantConnectButton autoSetDimensionsToSize:CGSizeMake(64, 64)];

        self.initialConstraintsCreated = YES;
        [self updateForContext];

        [UIView performWithoutAnimation:^{
            [self layoutIfNeeded];
        }];
    }

    self.subtitleRightMarginConstraint.constant = self.instantConnectButton.hidden ? -rightMargin : - self.instantConnectButton.bounds.size.width;
    self.nameRightMarginConstraint.constant = self.instantConnectButton.hidden ? -rightMargin : - self.instantConnectButton.bounds.size.width;

    [super updateConstraints];
}

- (void)updateForContext
{
    self.nameLabel.font = [UIFont fontWithMagicIdentifier:@"people_picker.search_results_mode.name_label_font"];
    self.nameLabel.textColor = [UIColor colorWithMagicIdentifier:@"people_picker.search_results_mode.context_create_conversation.name_label_font_color"];

    CGFloat squareImageWidth = [WAZUIMagic cgFloatForIdentifier:@"people_picker.search_results_mode.tile_image_diameter"];
    self.avatarViewSizeConstraint.constant = squareImageWidth;
    self.conversationImageViewSize.constant = squareImageWidth;
    self.badgeUserImageView.badgeColor = [UIColor colorWithMagicIdentifier:@"people_picker.search_results_mode.context_create_conversation.badge_icon_color"];
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    [UIView performWithoutAnimation:^{
        self.conversationImageView.image = nil;
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
    }];
}

- (void)updateForUser
{
    self.displayName = self.user.name;
    
    [self updateSubtitleForCommonConnections:self.user.totalCommonConnections];
    
    BOOL canBeConnected = YES;

    if (self.user == nil) {
        canBeConnected = NO;
    }
    else if (BareUserToUser(self.user) != nil) {
        ZMUser *fullUser = BareUserToUser(self.user);

        canBeConnected = fullUser.canBeConnected && ! fullUser.isBlocked && ! fullUser.isPendingApproval;
    }
    else {
        canBeConnected = self.user.canBeConnected;
    }

    self.instantConnectButton.hidden = ! canBeConnected;
    [self setNeedsUpdateConstraints];
    self.badgeUserImageView.user = self.user;
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

    [UIView mt_animateWithViews:@[self.avatarOverlay]
                       duration:0.15f
                 timingFunction:MTTimingFunctionEaseOutQuart
                     animations:^{
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

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (self.successCheckmark != nil) {            
            self.successCheckmark.mt_animationExaggeration = 4;
            [UIView mt_animateWithViews:@[self.successCheckmark]
                               duration:0.35f
                         timingFunction:MTTimingFunctionEaseOutBack
                             animations:^{
                                 self.successCheckmark.transform = CGAffineTransformIdentity;
                                 self.successCheckmark.alpha = 1.0f;
                             }];
        }
    });

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.45f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [UIView mt_animateWithViews:@[self.contentView]
                           duration:0.55f
                     timingFunction:MTTimingFunctionEaseOutQuart
                         animations:^{
                             self.contentView.alpha = 0.0f;
                         }];
    });

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

- (void)setUser:(id<ZMBareUser, ZMSearchableUser>)user
{
    _user = user;

    [self updateForUser];
}

- (void)setConversation:(ZMConversation *)conversation
{
    _conversation = conversation;
    
    if (conversation.conversationType == ZMConversationTypeOneOnOne) {
        ZMUser *otherUser = conversation.connectedUser;
        self.user = otherUser;
        self.badgeUserImageView.hidden = NO;
        self.conversationImageView.image = nil;
    }
    else {
        self.conversationImageView.image = [UIImage imageNamed:@"group-icon.png"];
        self.badgeUserImageView.hidden = YES;
        self.user = nil;
        self.displayName = conversation.displayName;
    }
}

- (void)setDisplayName:(NSString *)displayName
{
    _displayName = [displayName copy];

    self.nameLabel.text = [_displayName transformStringWithMagicKey:@"people_picker.search_results_mode.name_label_text_transform"];
}

- (void)setSelected:(BOOL)selected
{
    [super setSelected:selected];

    if (selected) {
        [self.badgeUserImageView setBadgeIcon:ZetaIconTypeCheckmark];
    } else {
        self.badgeUserImageView.badge = nil;
    }
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

- (void)updateSubtitleForCommonConnections:(NSUInteger)connections
{
    NSAttributedString *subtitle = [self attributedSubtitleWithConnectionCount:connections];

    if (nil == subtitle) {
        self.subtitleLabel.text = @"";
        self.nameLabelTopConstraint.active = NO;
        self.nameLabelVerticalConstraint.active = YES;
    } else {
        self.nameLabelVerticalConstraint.active = NO;
        self.nameLabelTopConstraint.active = YES;
        self.subtitleLabel.attributedText = subtitle;
    }
}

- (NSAttributedString *)attributedSubtitleWithConnectionCount:(NSUInteger)connections
{
    NSMutableAttributedString *subtitle = [[NSMutableAttributedString alloc] init];
    [subtitle beginEditing];

    NSAttributedString *handle;
    if (nil != self.user.handle && self.user.handle.length > 0) {
        NSDictionary *attributes = @{ NSFontAttributeName: self.class.boldFont, NSForegroundColorAttributeName: self.class.subtitleColor };
        NSString *displayHandle = [NSString stringWithFormat:@"@%@", self.user.handle];
        handle = [[NSAttributedString alloc] initWithString:displayHandle attributes:attributes];
        [subtitle appendAttributedString:handle];
    }

    NSString *addresBookName = BareUserToUser(self.user).addressBookEntry.cachedName;
    NSAttributedString *correlation = [self.class.correlationFormatter correlationTextFor:self.user with:connections addressBookName:addresBookName];
    if (nil != correlation) {
        if (nil != handle) {
            NSDictionary *delimiterAttributes = @{ NSFontAttributeName: self.class.lightFont, NSForegroundColorAttributeName: self.class.subtitleColor };
            [subtitle appendAttributedString:[[NSAttributedString alloc] initWithString:@" · " attributes:delimiterAttributes]];
        }
        [subtitle appendAttributedString:correlation];
    }

    [subtitle endEditing];
    return subtitle.length != 0 ? [[NSAttributedString alloc] initWithAttributedString:subtitle] : nil;
}

@end
