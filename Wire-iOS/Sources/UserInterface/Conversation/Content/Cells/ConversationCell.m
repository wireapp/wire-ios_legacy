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

#import <PureLayout/PureLayout.h>

#import "WAZUIMagicIOS.h"
#import "UIColor+WAZExtensions.h"
#import "Message.h"
#import "UIColor+WR_ColorScheme.h"
#import "UIView+Borders.h"
#import "MessageTimestampView.h"
#import "UserImageView.h"
#import "AccentColorChangeHandler.h"
#import "Analytics+iOS.h"

const CGFloat ConversationCellSelectedOpacity = 0.4;
const NSTimeInterval ConversationCellSelectionAnimationDuration = 0.33;

@implementation MenuConfigurationProperties

@end

@implementation ConversationCellLayoutProperties

@end



@interface ConversationCell ()

@property (nonatomic, readwrite, strong) id<ZMConversationMessage>message;
@property (nonatomic, readwrite, strong) UIView *messageContentView;

@property (nonatomic, readwrite, strong) UILabel *authorLabel;
@property (nonatomic, readwrite, strong) NSParagraphStyle *authorParagraphStyle;

@property (nonatomic, readwrite, strong) UILabel *burstTimestampLabel;
@property (nonatomic, readwrite, strong) NSParagraphStyle *burstTimestampParagraphStyle;
@property (nonatomic, strong) NSTimer *burstTimestampTimer;

@property (nonatomic, readwrite, strong) UIView *unreadDotView;
@property (nonatomic, readwrite, strong) UserImageView *authorImageView;
@property (nonatomic, readwrite, strong) UIView *authorImageContainer;

@property (nonatomic, strong) AccentColorChangeHandler *accentColorChangeHandler;

@property (nonatomic, readwrite, strong) ConversationCellLayoutProperties *layoutProperties;

#pragma mark - Constraints

@property (nonatomic, strong) NSLayoutConstraint *authorHeightConstraint;
@property (nonatomic, strong) NSLayoutConstraint *authorLeftMarginConstraint;

@property (nonatomic, strong) NSLayoutConstraint *authorImageTopMarginConstraint;
@property (nonatomic, strong) NSLayoutConstraint *authorImageHeightConstraint;

@property (nonatomic, strong) NSLayoutConstraint *burstTimestampHeightConstraint;
@property (nonatomic, strong) NSLayoutConstraint *topMarginConstraint;
@property (nonatomic, strong) NSLayoutConstraint *messageToolsHeightConstraint;

@property (nonatomic, strong) NSLayoutConstraint *unreadDotHeightConstraint;
@property (nonatomic, strong) NSLayoutConstraint *messageContentBottomMarginConstraint;

@end



@implementation ConversationCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = [UIColor clearColor];
        self.opaque = NO;
        self.clipsToBounds = YES;
        self.tintColor = [UIColor accentColor];
        self.layoutMargins = UIEdgeInsetsZero;
        self.burstTimestampSpacing = 16;
        
        [self createViews];
        [self createBaseConstraints];
        
        self.longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
        [self.contentView addGestureRecognizer:self.longPressGestureRecognizer];

        
        self.accentColorChangeHandler = [AccentColorChangeHandler addObserver:self handlerBlock:^(UIColor *newColor, ConversationCell *cell) {
            cell.tintColor = newColor;
            cell.unreadDotView.backgroundColor = newColor;
        }];
        
        UIEdgeInsets layoutMargins = UIEdgeInsetsMake(0, [WAZUIMagic floatForIdentifier:@"content.left_margin"],
                                                      0, [WAZUIMagic floatForIdentifier:@"content.right_margin"]);
        
        self.contentView.layoutMargins = layoutMargins;
        
        // NOTE Layout margins are not being preserved beyond the UITableViewCell.contentView so we must re-apply them
        // here until we re-factor the the ConversationCell
        self.messageContentView.layoutMargins = layoutMargins;
    }
    
    return self;
}

- (void)willMoveToWindow:(UIWindow *)newWindow
{
    [super willMoveToWindow:newWindow];
    
    if (newWindow != nil) {
        if (self.layoutProperties.showBurstTimestamp) {
            self.burstTimestampTimer = [NSTimer scheduledTimerWithTimeInterval:60 target:self selector:@selector(updateBurstTimestamp) userInfo:nil repeats:YES];
        }
    } else {
        [self.burstTimestampTimer invalidate];
        self.burstTimestampTimer = nil;
    }
}

- (void)createViews
{
    self.messageContentView = [[UIView alloc] init];
    self.messageContentView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:self.messageContentView];
    
    
    self.authorLabel = [[UILabel alloc] init];
    self.authorLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:self.authorLabel];
    
    self.authorImageContainer = [[UIView alloc] init];
    self.authorImageContainer.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:self.authorImageContainer];
    
    self.authorImageView = [[UserImageView alloc] initWithMagicPrefix:@"content.author_image"];
    self.authorImageView.translatesAutoresizingMaskIntoConstraints = NO;
    self.authorImageView.delegate = self;
    self.authorImageView.borderColorMatchesAccentColor = NO;
    self.authorImageView.borderWidth = 0.5f;
    self.authorImageView.borderColor = [UIColor wr_colorFromColorScheme:ColorSchemeColorAvatarBorder];
    self.authorImageView.layer.shouldRasterize = YES;
    self.authorImageView.layer.rasterizationScale = [[UIScreen mainScreen] scale];
    [self.authorImageContainer addSubview:self.authorImageView];
    
    NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    paragraphStyle.minimumLineHeight = [WAZUIMagic cgFloatForIdentifier:@"content.burst_timestamp.line_height"];
    paragraphStyle.maximumLineHeight = paragraphStyle.minimumLineHeight;
    paragraphStyle.alignment = NSTextAlignmentCenter;
    self.burstTimestampParagraphStyle = paragraphStyle;

    self.burstTimestampLabel = [[UILabel alloc] init];
    self.burstTimestampLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:self.burstTimestampLabel];
    
    self.unreadDotView = [[UIView alloc] init];
    self.unreadDotView.translatesAutoresizingMaskIntoConstraints = NO;
    self.unreadDotView.backgroundColor = [UIColor accentColor];
    self.unreadDotView.layer.cornerRadius = 4;
    [self.contentView addSubview:self.unreadDotView];
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    
    self.topMarginConstraint.constant = 0;
    self.authorImageTopMarginConstraint.constant = 0;
    self.message = nil;
    self.beingEdited = NO;
}

- (void)willDisplayInTableView
{
    if (self.layoutProperties.showBurstTimestamp) {
        self.burstTimestampTimer = [NSTimer scheduledTimerWithTimeInterval:60 target:self selector:@selector(updateBurstTimestamp) userInfo:nil repeats:YES];
    }
}

- (void)didEndDisplayingInTableView
{
    [self.burstTimestampTimer invalidate];
    self.burstTimestampTimer = nil;
}

- (void)createBaseConstraints
{
    CGFloat authorImageDiameter = [WAZUIMagic floatForIdentifier:@"content.sender_image_tile_diameter"];
    
    self.topMarginConstraint = [self.burstTimestampLabel autoPinEdgeToSuperviewEdge:ALEdgeTop];
    
    [self.burstTimestampLabel autoAlignAxisToSuperviewAxis:ALAxisVertical];
    self.burstTimestampHeightConstraint = [self.burstTimestampLabel autoSetDimension:ALDimensionHeight toSize:0];
    
    self.unreadDotHeightConstraint = [self.unreadDotView autoSetDimension:ALDimensionHeight toSize:0];
    self.unreadDotHeightConstraint.active = NO;
    [self.unreadDotView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionHeight ofView:self.unreadDotView];
    [self.unreadDotView autoAlignAxis:ALAxisHorizontal toSameAxisOfView:self.burstTimestampLabel];
    [self.unreadDotView autoPinEdge:ALEdgeRight toEdge:ALEdgeLeft ofView:self.burstTimestampLabel withOffset:-8];
    
    [self.authorLabel autoPinEdgeToSuperviewMargin:ALEdgeLeft];
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
    
    self.authorImageTopMarginConstraint = [self.authorImageContainer autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.burstTimestampLabel];
    [self.authorImageContainer autoPinEdgeToSuperviewEdge:ALEdgeLeft];
    [self.authorImageContainer autoPinEdge:ALEdgeRight toEdge:ALEdgeLeft ofView:self.authorLabel];
    
    [self.messageContentView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.authorImageView];
    [self.messageContentView autoPinEdgeToSuperviewEdge:ALEdgeLeft];
    [self.messageContentView autoPinEdgeToSuperviewEdge:ALEdgeRight];
    self.messageContentBottomMarginConstraint = [self.messageContentView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
    
    [NSLayoutConstraint autoSetPriority:UILayoutPriorityDefaultHigh + 1 forConstraints:^{
        [self.unreadDotView autoSetDimension:ALDimensionHeight toSize:8];
        [self.authorImageView autoSetDimension:ALDimensionHeight toSize:authorImageDiameter];
    }];
}

- (void)updateConstraintConstants
{
    self.unreadDotHeightConstraint.active = ! self.layoutProperties.showUnreadMarker;
    self.authorImageHeightConstraint.active = ! self.layoutProperties.showSender;
    self.authorImageTopMarginConstraint.constant = self.layoutProperties.showBurstTimestamp ? self.burstTimestampSpacing : 0;
    self.topMarginConstraint.constant = self.layoutProperties.topPadding;
    self.authorHeightConstraint.active = ! self.layoutProperties.showSender;
    self.authorLabel.hidden = ! self.layoutProperties.showSender;
    self.authorImageContainer.hidden = ! self.layoutProperties.showSender;
    self.burstTimestampHeightConstraint.active = ! self.layoutProperties.showBurstTimestamp;
}

- (void)configureForMessage:(id<ZMConversationMessage>)message layoutProperties:(ConversationCellLayoutProperties *)layoutProperties;
{
    _message = message;

    _layoutProperties = layoutProperties;

    if (layoutProperties.showSender) {
        [self updateSenderAndSenderImage:message];
    }
    
    if (layoutProperties.showBurstTimestamp) {
        [self updateBurstTimestamp];
    }
    
    [self updateConstraintConstants];
}

- (void)updateSenderAndSenderImage:(id<ZMConversationMessage>)message
{
    self.authorLabel.text = message.sender.displayName.uppercaseString;
    self.authorImageView.user = message.sender;
}

- (void)updateBurstTimestamp
{
    NSAttributedString *burstTimestampText =
    [[NSAttributedString alloc] initWithString:[[Message formattedReceivedDateForMessage:self.message] uppercaseString]
                                    attributes:@{ NSParagraphStyleAttributeName: self.burstTimestampParagraphStyle }];
    
    self.burstTimestampLabel.attributedText = burstTimestampText;
}

#pragma mark - Long press management

- (UIView *)selectionView
{
    return self;
}

- (CGRect)selectionRect
{
    return self.frame;
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

- (void)menuWillShow:(NSNotification *)notification
{
    self.showsMenu = YES;
    if (self.menuConfigurationProperties.selectedMenuBlock != nil ) {
        self.menuConfigurationProperties.selectedMenuBlock(YES, YES);
    }
}

- (void)menuDidHide:(NSNotification *)notification
{
    self.showsMenu = NO;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if (self.menuConfigurationProperties.selectedMenuBlock != nil && !self.beingEdited) {
        self.menuConfigurationProperties.selectedMenuBlock(NO, YES);
    }
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

- (void)showMenu;
{
    if ([self.delegate respondsToSelector:@selector(conversationCell:willOpenMenuForCellType:)]) {
        [self.delegate conversationCell:self willOpenMenuForCellType:[self messageType]];
    }
    
    MenuConfigurationProperties *menuConfigurationProperties = [self menuConfigurationProperties];
    if (!menuConfigurationProperties) {
        return;
    }
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(menuWillShow:)
                                                 name:UIMenuControllerWillShowMenuNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(menuDidHide:)
                                                 name:UIMenuControllerDidHideMenuNotification object:nil];
    
    /**
     *  The reason why we are touching the window here is to workaround a bug where,
     *  After dismissing the webplayer, the window would fail to become the first responder, 
     *  preventing us to show the menu at all. 
     *  We now force the window to be the key window and to be the first responder to ensure that we can 
     *  show the menu controller.
     */
    [self.window makeKeyWindow];
    [self.window becomeFirstResponder];
    
    [self becomeFirstResponder];
    
    UIMenuController *menuController = [UIMenuController sharedMenuController];
    menuController.menuItems = menuConfigurationProperties.additionalItems;
    [menuController setTargetRect:menuConfigurationProperties.targetRect inView:menuConfigurationProperties.targetView];
    [menuController setMenuVisible:YES animated:YES];
    
    if ([self.delegate respondsToSelector:@selector(conversationCell:didOpenMenuForCellType:)]) {
        [self.delegate conversationCell:self didOpenMenuForCellType:[self messageType]];
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
    if (action == @selector(delete:) && self.message.canBeDeleted) {
        return YES;
    }
    
    return [super canPerformAction:action withSender:sender];
}

- (void)delete:(id)sender;
{
    if([self.delegate respondsToSelector:@selector(conversationCell:didSelectAction:)]) {
        [self.delegate conversationCell:self didSelectAction:ConversationCellActionDelete];
        [[Analytics shared] tagOpenedMessageAction:MessageActionTypeDelete];
    }
}

#pragma mark - UserImageView delegate

- (void)userImageViewTouchUpInside:(UserImageView *)userImageView
{
    if (! userImageView) {
        return;
    }
    
    if ([self.delegate respondsToSelector:@selector(conversationCell:userTapped:inView:)]) {
        [self.delegate conversationCell:self userTapped:BareUserToUser(userImageView.user) inView:userImageView];
    }
}

#pragma mark - Message observation

- (BOOL)updateForMessage:(MessageChangeInfo *)change
{
    if (change.userChangeInfo.nameChanged || change.senderChanged) {
        [self updateSenderAndSenderImage:change.message];
    }
    
    return NO;
}

#pragma mark - UIKeyInput

// We need to conform the cell to UIKeyInput to avoid the keyboard being dismissed
// when showing the UIMenuController, we might want to forward the calls to the text input field
// or post a notification to make it first responder again.

- (void)insertText:(NSString *)text
{
 // no-op
}

- (void)deleteBackward
{
    // no-op
}

- (BOOL)hasText
{
    return NO;
}


@end
