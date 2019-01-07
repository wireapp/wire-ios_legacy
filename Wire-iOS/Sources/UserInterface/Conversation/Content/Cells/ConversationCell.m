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


#import "ConversationCell.h"
#import "ConversationCell+Private.h"

@import PureLayout;

#import "UIColor+WAZExtensions.h"
#import "Message+UI.h"
#import "Wire-Swift.h"
#import "AccentColorChangeHandler.h"
#import "Analytics.h"
#import "UIResponder+FirstResponder.h"

const CGFloat ConversationCellSelectedOpacity = 0.4;
const NSTimeInterval ConversationCellSelectionAnimationDuration = 0.33;
static const CGFloat BurstContainerExpandedHeight = 40;

@implementation ConversationCellLayoutProperties

@end



@interface ConversationCell ()

@property (nonatomic, readwrite) id<ZMConversationMessage>message;
@property (nonatomic, readwrite) UIView *messageContentView;

@property (nonatomic, readwrite) UILabel *authorLabel;
@property (nonatomic, readwrite) UIView *marginContainer;
@property (nonatomic, readwrite) NSParagraphStyle *authorParagraphStyle;

@property (nonatomic, readwrite) UserImageView *authorImageView;
@property (nonatomic, readwrite) UIView *authorImageContainer;

@property (nonatomic) MessageToolboxView *toolboxView;

@property (nonatomic) AccentColorChangeHandler *accentColorChangeHandler;
@property (nonatomic, readwrite) UITapGestureRecognizer *doubleTapGestureRecognizer;
@property (nonatomic, readwrite) ConversationCellLayoutProperties *layoutProperties;

#pragma mark - Constraints

@property (nonatomic) NSLayoutConstraint *authorHeightConstraint;
@property (nonatomic) NSLayoutConstraint *authorLeftMarginConstraint;

@property (nonatomic) NSLayoutConstraint *authorImageTopMarginConstraint;
@property (nonatomic) NSLayoutConstraint *authorImageHeightConstraint;

@property (nonatomic) NSLayoutConstraint *burstTimestampHeightConstraint;
@property (nonatomic) NSLayoutConstraint *topMarginConstraint;
@property (nonatomic) NSLayoutConstraint *messageToolsHeightConstraint;

@property (nonatomic) UIView *countdownContainerView;

@end

@interface ConversationCell (MessageToolboxViewDelegate) <MessageToolboxViewDelegate>

@end

@implementation ConversationCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        [self setupFont];
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = [UIColor clearColor];
        self.opaque = NO;
        self.clipsToBounds = YES;
        self.tintColor = [UIColor accentColor];
        self.layoutMargins = UIEdgeInsetsZero;
        self.burstTimestampSpacing = 16;
        
        [self createViews];

        self.contentLayoutMargins = UIView.directionAwareConversationLayoutMargins;

        [NSLayoutConstraint autoCreateAndInstallConstraints:^{
            [self createBaseConstraints];
        }];
        
        self.longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
        [self.contentView addGestureRecognizer:self.longPressGestureRecognizer];

        self.accentColorChangeHandler = [AccentColorChangeHandler addObserver:self handlerBlock:^(UIColor *newColor, ConversationCell *cell) {
            cell.tintColor = newColor;
        }];
        
    }
    
    return self;
}

- (void)dealloc
{
    [self.burstTimestampTimer invalidate];
    self.burstTimestampTimer = nil;
}

- (void)willMoveToWindow:(UIWindow *)newWindow
{
    [super willMoveToWindow:newWindow];
    
    if (newWindow != nil) {
        [self scheduledTimerForUpdateBurstTimestamp];
    } else {
        [self tearDownCountdown];
        [self.burstTimestampTimer invalidate];
        self.burstTimestampTimer = nil;
    }
}

- (void)createViews
{
    self.clipsToBounds = NO;
    self.contentView.clipsToBounds = NO;
    
    self.marginContainer = [[UIView alloc] init];
    self.marginContainer.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:self.marginContainer];

    self.messageContentView = [[UIView alloc] init];
    self.messageContentView.translatesAutoresizingMaskIntoConstraints = NO;
    self.messageContentView.accessibilityElementsHidden = NO;
    [self.contentView addSubview:self.messageContentView];

    self.authorLabel = [[UILabel alloc] init];
    self.authorLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.marginContainer addSubview:self.authorLabel];

    self.authorImageContainer = [[UIView alloc] init];
    self.authorImageContainer.translatesAutoresizingMaskIntoConstraints = NO;
    [self.marginContainer addSubview:self.authorImageContainer];
    
    self.authorImageView = [[UserImageView alloc] init];
    self.authorImageView.initialsFont = [UIFont systemFontOfSize:11 weight:UIFontWeightLight];
    self.authorImageView.userSession = [ZMUserSession sharedSession];
    self.authorImageView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.authorImageView addTarget:self action:@selector(userTappedAvatarView:) forControlEvents:UIControlEventTouchUpInside];
    
    self.authorImageView.layer.shouldRasterize = YES;
    self.authorImageView.layer.rasterizationScale = [[UIScreen mainScreen] scale];
    [self.authorImageContainer addSubview:self.authorImageView];
    
    NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    paragraphStyle.minimumLineHeight = 12;
    paragraphStyle.maximumLineHeight = paragraphStyle.minimumLineHeight;

    self.burstTimestampView = [[ConversationCellBurstTimestampView alloc] initForAutoLayout];
    self.burstTimestampView.isSeparatorHidden = YES;
    [self.contentView addSubview:self.burstTimestampView];

    
    self.toolboxView = [[MessageToolboxView alloc] init];
    self.toolboxView.delegate = self;
    self.toolboxView.translatesAutoresizingMaskIntoConstraints = NO;
    self.toolboxView.accessibilityIdentifier = @"MessageToolbox";
    self.toolboxView.accessibilityLabel = @"MessageToolbox";
    [self.contentView addSubview:self.toolboxView];
    
    self.countdownContainerView = [[UIView alloc] initForAutoLayout];
    [self.contentView addSubview:self.countdownContainerView];
    
    self.countdownContainerViewHidden = YES;

    self.doubleTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didDoubleTapMessage:)];
    self.doubleTapGestureRecognizer.numberOfTapsRequired = 2;
    self.doubleTapGestureRecognizer.delaysTouchesBegan = YES;
    [self.contentView addGestureRecognizer:self.doubleTapGestureRecognizer];
    
    self.contentView.isAccessibilityElement = YES;
    
    NSMutableArray *accessibilityElements = [NSMutableArray arrayWithArray:self.accessibilityElements];
    [accessibilityElements addObjectsFromArray:@[self.messageContentView, self.authorLabel, self.authorImageView, self.burstTimestampView.unreadDot, self.toolboxView]];
    self.accessibilityElements = accessibilityElements;
}

- (void)prepareForReuse
{
    self.message = nil;
    [self.toolboxView prepareForReuse];
    
    [super prepareForReuse];
    
    self.topMarginConstraint.constant = 0;
    self.authorImageTopMarginConstraint.constant = 0;
    self.beingEdited = NO;
    [self updateCountdownView];
}

- (void)didEndDisplayingInTableView
{
    [self.burstTimestampTimer invalidate];
    self.burstTimestampTimer = nil;
    [self.toolboxView stopCountdownTimer];
    [self tearDownCountdown];
    [self cellDidEndBeingVisible];
}

- (void)createBaseConstraints
{
    CGFloat authorImageDiameter = 24;

    self.topMarginConstraint = [self.burstTimestampView autoPinEdgeToSuperviewEdge:ALEdgeTop];
    [self.burstTimestampView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
    [self.burstTimestampView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];

    [NSLayoutConstraint autoSetPriority:UILayoutPriorityRequired forConstraints:^{
        self.burstTimestampHeightConstraint = [self.burstTimestampView autoSetDimension:ALDimensionHeight toSize:0];
    }];

    [self.marginContainer autoPinEdgesToSuperviewEdges];
    [self.authorLabel autoPinEdgeToSuperviewMargin:ALEdgeLeading];

    self.authorHeightConstraint = [self.authorLabel autoSetDimension:ALDimensionHeight toSize:0];
    [self.authorLabel autoAlignAxis:ALAxisHorizontal toSameAxisOfView:self.authorImageContainer];
    [self.authorLabel setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
    
    self.authorImageHeightConstraint = [self.authorImageView autoSetDimension:ALDimensionHeight toSize:0];
    self.authorHeightConstraint.active = NO;
    self.authorImageView.layer.cornerRadius = authorImageDiameter / 2;
    [self.authorImageView autoPinEdgeToSuperviewEdge:ALEdgeTop];
    [self.authorImageView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
    [self.authorImageView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionHeight ofView:self.authorImageView];
    [self.authorImageView autoCenterInSuperview];
    
    self.authorImageTopMarginConstraint = [self.authorImageContainer autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.burstTimestampView];
    [self.authorImageContainer autoPinEdgeToSuperviewEdge:ALEdgeLeading];
    [self.authorImageContainer autoPinEdge:ALEdgeTrailing toEdge:ALEdgeLeading ofView:self.authorLabel];

    [self.messageContentView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.authorImageView];
    [self.messageContentView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
    [self.messageContentView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
    
    [NSLayoutConstraint autoSetPriority:UILayoutPriorityRequired forConstraints:^{
        [self.authorImageView autoSetDimension:ALDimensionHeight toSize:authorImageDiameter];
    }];
    
    [NSLayoutConstraint autoSetPriority:UILayoutPriorityDefaultHigh + 1 forConstraints:^{
        [self.toolboxView autoSetDimension:ALDimensionHeight toSize:0];
    }];
    
    [self.toolboxView autoSetDimension:ALDimensionHeight toSize:0 relation:NSLayoutRelationGreaterThanOrEqual];
    [self.toolboxView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.messageContentView];
    [self.toolboxView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
    [self.toolboxView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
    [self.toolboxView autoPinEdgeToSuperviewEdge:ALEdgeBottom];

    const CGFloat inset = UIFont.normalRegularFont.lineHeight / 2;
    
    NSArray *countdownContainerConstraints =
    @[
      [self.countdownContainerView.topAnchor constraintEqualToAnchor:self.authorImageView.bottomAnchor constant:inset],
      [self.countdownContainerView.centerXAnchor constraintEqualToAnchor:self.authorImageView.centerXAnchor],
      [self.countdownContainerView.widthAnchor constraintEqualToConstant:8],
      [self.countdownContainerView.heightAnchor constraintEqualToConstant:8]
      ];

    [NSLayoutConstraint activateConstraints:countdownContainerConstraints];

}

- (void)setContentLayoutMargins:(UIEdgeInsets)contentLayoutMargins
{
    _contentLayoutMargins = contentLayoutMargins;
    
    // NOTE Layout margins are not being preserved beyond the UITableViewCell.contentView so we must re-apply them
    // here until we re-factor the the ConversationCell

    self.marginContainer.layoutMargins = contentLayoutMargins;
    self.messageContentView.layoutMargins = contentLayoutMargins;
    self.toolboxView.layoutMargins = contentLayoutMargins;
    self.burstTimestampView.layoutMargins = contentLayoutMargins;
}

- (void)updateConstraintConstants
{
    ConversationCellLayoutProperties *properties = self.layoutProperties;
    BOOL showBurstLabelContainer                 =   properties.showBurstTimestamp || properties.showDayBurstTimestamp;

    self.burstTimestampView.isShowingUnreadDot   =   properties.showUnreadMarker;
    self.authorImageHeightConstraint.active      = ! properties.showSender;
    self.authorImageTopMarginConstraint.constant =   showBurstLabelContainer ? self.burstTimestampSpacing : 0;
    self.topMarginConstraint.constant            =   properties.topPadding;
    self.authorHeightConstraint.active           = ! properties.showSender;
    self.authorLabel.hidden                      = ! properties.showSender;
    self.authorImageContainer.hidden             = ! properties.showSender;
    self.burstTimestampHeightConstraint.constant =   showBurstLabelContainer ? BurstContainerExpandedHeight : 0;
    self.burstTimestampView.isSeparatorExpanded  =   properties.showDayBurstTimestamp;
}

- (void)configureForMessage:(id<ZMConversationMessage>)message layoutProperties:(ConversationCellLayoutProperties *)layoutProperties;
{
    _message = message;
    _layoutProperties = layoutProperties;

    if (layoutProperties.showSender) {
        [self updateSenderAndSenderImage:message];
    }
    
    if (layoutProperties.showBurstTimestamp || layoutProperties.showDayBurstTimestamp) {
        [self updateBurstTimestamp];
    }

    self.actionController = [[ConversationMessageActionController alloc] initWithResponder:self.delegate message:message context:ConversationMessageActionControllerContextContent];

    [self updateConstraintConstants];
    [self updateToolboxVisibilityAnimated:NO];
    [self startCountdownAnimationIfNeeded:message];
    [self updateCountdownView];
}

- (void)updateToolboxVisibilityAnimated:(BOOL)animated
{
    if (nil == self.message) {
        return;
    }
    
    ZMDeliveryState deliveryState = self.message.deliveryState;
    
    BOOL shouldShowPendingDeliveryState = self.message.conversation.conversationType == ZMConversationTypeOneOnOne;
    BOOL shouldShowDeliveryState = (deliveryState == ZMDeliveryStatePending && shouldShowPendingDeliveryState) || deliveryState == ZMDeliveryStateFailedToSend || self.layoutProperties.alwaysShowDeliveryState;
    BOOL shouldBeVisible = self.selected || self.message.usersReaction.count > 0 || shouldShowDeliveryState;
    
    if (! [Message shouldShowTimestamp:self.message]) {
        shouldBeVisible = NO;
    }

    self.toolboxView.isAccessibilityElement = shouldBeVisible;

    if (shouldBeVisible) {
        [self.toolboxView configureForMessage:self.message forceShowTimestamp:self.selected animated:animated];
    }
    
    
    [self.toolboxView setHidden:!shouldBeVisible animated:animated];
}


- (void)setCountdownContainerViewHidden:(BOOL)countdownContainerViewHidden
{
    if (countdownContainerViewHidden == _countdownContainerViewHidden) {
        return;
    }
    
    _countdownContainerViewHidden = countdownContainerViewHidden;
    
    if (nil == self.countdownView) {
        if (!countdownContainerViewHidden) {
            self.countdownView = [[DestructionCountdownView alloc] init];
            self.countdownView.accessibilityIdentifier = @"EphemeralMessageCountdownView";
            self.countdownView.isAccessibilityElement = false;
            [self.countdownContainerView addSubview:self.countdownView];
            [self.countdownView autoPinEdgesToSuperviewEdges];
        }
    }
    else {
        self.countdownContainerView.hidden = countdownContainerViewHidden;
    }
    
}

#pragma mark - Size class

/**
 When iPad switches form/to slide over/fullscreen/split mode, update contentLayoutMargins

 @param previousTraitCollection previousTraitCollection
 */
- (void)traitCollectionDidChange:(nullable UITraitCollection *)previousTraitCollection
{
    [super traitCollectionDidChange:previousTraitCollection];
    if (!self.showsPreview) {
        self.contentLayoutMargins = UIView.directionAwareConversationLayoutMargins;
    }
}

#pragma mark - Long press management

- (UIView *)selectionView
{
    return self;
}

- (CGRect)selectionRect
{
    return self.bounds;
}

- (UIView *)previewView
{
    return self.selectionView;
}

- (BOOL)canBecomeFirstResponder;
{
    return YES;
}

- (MenuConfigurationProperties *)menuConfigurationProperties;
{
    return nil;
}

- (MessageType)messageType;
{
    return MessageTypeSystem;
}

- (void)setBeingEdited:(BOOL)beingEdited
{
    if (_beingEdited == beingEdited) {
        return;
    }
    
    _beingEdited = beingEdited;
    
    if (self.menuConfigurationProperties.selectedMenuBlock != nil) {
        self.menuConfigurationProperties.selectedMenuBlock(beingEdited, YES);
    }
}

- (void)handleLongPress:(UILongPressGestureRecognizer *)gestureRecognizer;
{
    if (! CGRectContainsPoint(self.contentView.bounds, [gestureRecognizer locationInView:self.contentView]) ||
        ! CGRectContainsPoint(self.menuConfigurationProperties.targetRect, [gestureRecognizer locationInView:self.menuConfigurationProperties.targetView])) {
        gestureRecognizer.enabled = NO;
        gestureRecognizer.enabled = YES;
    }
    
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        [self showMenu];
    }
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender;
{
    return [self.actionController canPerformAction:action];
}

- (id)forwardingTargetForSelector:(SEL)aSelector
{
    return self.actionController;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    [self updateToolboxVisibilityAnimated:YES];
}

#pragma mark - UserImageView delegate

- (void)userTappedAvatarView:(UserImageView *)userImageView
{
    if (! userImageView) {
        return;
    }
    
    // Edge case prevention:
    // If the keyboard (input field has focus) is up and the user is tapping directly on an avatar, we ignore this tap. This
    // solves us the problem of the repositioning the popover after the keyboard destroys the layout and the we would re-position
    // the popover again
    
    if (! IS_IPAD || IS_IPAD_LANDSCAPE_LAYOUT) {
        return;
    }

    if ([self.delegate respondsToSelector:@selector(conversationCell:userTapped:inView:frame:)]) {
        [self.delegate conversationCell:self
                             userTapped:BareUserToUser(userImageView.user)
                                 inView:userImageView
                                  frame:userImageView.bounds];
    }
}

#pragma mark - Message observation

- (BOOL)updateForMessage:(MessageChangeInfo *)change
{
    if (change.reactionsChanged) {
        [self.toolboxView updateForMessage:change];
    }
    
    if (change.userChangeInfo.nameChanged || change.senderChanged) {
        [self updateSenderAndSenderImage:change.message];
    }

    if (change.isObfuscatedChanged) {
        [self configureForMessage:change.message layoutProperties:self.layoutProperties];
        [self updateCountdownView];
    }

    if ([self.delegate respondsToSelector:@selector(conversationCellShouldStartDestructionTimer:)] &&
        [self.delegate conversationCellShouldStartDestructionTimer:self]) {
        if ([self.message startSelfDestructionIfNeeded]) {
            [self startCountdownAnimationIfNeeded:self.message];
        }
    }

    [self updateToolboxVisibilityAnimated:change.reactionsChanged];
    
    return change.reactionsChanged || change.deliveryStateChanged || change.isObfuscatedChanged;
}

#pragma mark - Countdown Timer

- (void)tearDownCountdown
{
    [self.destructionLink invalidate];
    self.destructionLink = nil;
    self.countdownView.hidden = YES;
    self.messageContentView.alpha = 1;
    [self.countdownView stopAnimating];
}

- (void)startCountdownAnimationIfNeeded:(id<ZMConversationMessage>)message
{
    if ([Message shouldShowDestructionCountdown:message] && nil == self.destructionLink) {
        self.destructionLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateCountdownView)];
        [self.destructionLink addToRunLoop:NSRunLoop.mainRunLoop forMode:NSRunLoopCommonModes];
    }
}

@end

@implementation ConversationCell (MessageToolboxViewDelegate)

- (void)messageToolboxViewDidRequestLike:(MessageToolboxView *)messageToolboxView
{
    [self.delegate conversationCell:messageToolboxView didSelectAction:MessageActionLike forMessage:self.message];
}

- (void)messageToolboxDidRequestOpeningDetails:(MessageToolboxView *)messageToolboxView preferredDisplayMode:(enum MessageDetailsDisplayMode)preferredDisplayMode
{
    MessageDetailsViewController *detailsViewController = [[MessageDetailsViewController alloc] initWithMessage:self.message preferredDisplayMode:preferredDisplayMode];
    [self.delegate conversationCellDidRequestOpeningMessageDetails:self messageDetails:detailsViewController];
}

- (void)messageToolboxViewDidSelectResend:(MessageToolboxView *)messageToolboxView
{
    [self.delegate conversationCellDidTapResendMessage:self];
}

- (void)messageToolboxViewDidSelectDelete:(MessageToolboxView *)messageToolboxView
{
    [self.delegate conversationCell:self didSelectAction:MessageActionDelete forMessage:self.message];
}

@end
