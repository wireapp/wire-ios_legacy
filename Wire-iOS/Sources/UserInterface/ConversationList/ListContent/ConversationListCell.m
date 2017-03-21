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


#import "ConversationListCell.h"

#import <PureLayout/PureLayout.h>

#import "ConversationListItemView.h"
#import "ConversationListIndicator.h"
#import "ListItemRightAccessoryView.h"
@import WireExtensionComponents;

#import "Constants.h"
#import "WAZUIMagicIOS.h"
#import "zmessaging+iOS.h"
#import "avs+iOS.h"
#import "Settings.h"

#import "MediaPlaybackManager.h"
#import "MediaPlayer.h"
#import "AppDelegate.h"

#import "UIColor+WAZExtensions.h"
#import "UIView+Borders.h"

#import "ZClientViewController.h"
#import "AccentColorChangeHandler.h"
#import "AnimatedListMenuView.h"



static const CGFloat MaxVisualDrawerOffsetRevealDistance = 48;
static const NSTimeInterval IgnoreOverscrollTimeInterval = 0.005;
static const NSTimeInterval OverscrollRatio = 2.5;


@interface ConversationListCell (RightAccesory) <ListItemRightAccessoryViewDelegate>
@end


@interface ConversationListCell () <AVSMediaManagerClientObserver>

@property (nonatomic, strong) ConversationListItemView *itemView;
@property (nonatomic, assign) BOOL hasCreatedInitialConstraints;
@property (nonatomic, strong) NSLayoutConstraint *titleBottomMarginConstraint;

@property (nonatomic, strong) NSLayoutConstraint *archiveRightMarginConstraint;

@property (nonatomic, strong) AccentColorChangeHandler *accentColorHandler;
@property (nonatomic) AnimatedListMenuView *animatedListView;
@property (nonatomic) NSDate *overscrollStartDate;


@end



@implementation ConversationListCell

- (void)dealloc
{
    if (![[Settings sharedSettings] disableAVS]) {
        [AVSMediaManagerClientChangeNotification removeObserver:self];
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupConversationListCell];
    }
    return self;
}

- (void)setupConversationListCell
{
    self.separatorLineViewDisabled = YES;
    self.maxVisualDrawerOffset = MaxVisualDrawerOffsetRevealDistance;
    self.overscrollFraction = CGFLOAT_MAX; // Never overscroll
    self.canOpenDrawer = NO;
    self.clipsToBounds = YES;
    
    self.itemView = [[ConversationListItemView alloc] initForAutoLayout];
    [self.swipeView addSubview:self.itemView];

    AnimatedListMenuView *animatedView = [[AnimatedListMenuView alloc] initForAutoLayout];
    
    [self.menuView addSubview:animatedView];
    self.animatedListView = animatedView;
    [self.animatedListView enable1PixelBlueBorder];

    self.itemView.rightAccessory.delegate = self;
    
    self.accentColorHandler = [AccentColorChangeHandler addObserver:self handlerBlock:^(UIColor *newColor, ConversationListCell *cell) {
        cell.itemView.selectionColor = newColor;
    }];
    
    [self setNeedsUpdateConstraints];
    
    if (![[Settings sharedSettings] disableAVS]) {
        [AVSMediaManagerClientChangeNotification addObserver:self];
    }
}

- (void)setVisualDrawerOffset:(CGFloat)visualDrawerOffset updateUI:(BOOL)doUpdate
{
    [super setVisualDrawerOffset:visualDrawerOffset updateUI:doUpdate];
    
    // After X % of reveal we consider animation should be finished
    const CGFloat progress = (visualDrawerOffset / MaxVisualDrawerOffsetRevealDistance);
    [self.animatedListView setProgress:progress animated:YES];
    if (progress >= 1 && ! self.overscrollStartDate) {
        self.overscrollStartDate = [NSDate date];
    }
    
    self.itemView.visualDrawerOffset = visualDrawerOffset;
}

- (void)setSelected:(BOOL)selected
{
    [super setSelected:selected];
    if (IS_IPAD) {
        self.itemView.selected  = self.selected || self.highlighted;
        [self updateAccessoryViews];
    }
}

- (void)setHighlighted:(BOOL)highlighted
{
    [super setHighlighted:highlighted];
    if (IS_IPAD) {
        self.itemView.selected  = self.selected || self.highlighted;
    } else {
        self.itemView.selected = self.highlighted;
    }
}

- (void)updateConstraints
{
    CGFloat leftMarginConvList = [WAZUIMagic floatForIdentifier:@"list.left_margin"];
    
    if (! self.hasCreatedInitialConstraints) {
        self.hasCreatedInitialConstraints = YES;
        [self.itemView autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero];

        [self.animatedListView autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero];

        [NSLayoutConstraint autoSetPriority:UILayoutPriorityDefaultLow forConstraints:^{
            [self.animatedListView autoPinEdgeToSuperviewEdge:ALEdgeLeading withInset:leftMarginConvList];
            self.archiveRightMarginConstraint = [self.animatedListView autoPinEdgeToSuperviewEdge:ALEdgeTrailing withInset:leftMarginConvList / 2.0f];
        }];
    }

    if ([self.itemView.statusIndicator isDisplayingAnyIndicators]) {
        self.archiveRightMarginConstraint.constant = -leftMarginConvList / 2.0f;
    }
    else {
        self.archiveRightMarginConstraint.constant = -leftMarginConvList;
    }

    [super updateConstraints];
}

- (void)prepareForReuse
{
    [super prepareForReuse];

    [self.itemView setVisualDrawerOffset:0 notify:NO];
    self.itemView.alpha = 1.0f;
    self.overscrollStartDate = nil;

    self.conversation = nil;
}

- (void)setConversation:(ZMConversation *)conversation
{
    if (_conversation != conversation) {
        
        _conversation = conversation;
        
        [self updateAppearance];
    }
}

- (void)updateAppearance
{
    self.itemView.titleText = self.conversation.displayName;
    [self updateSubtitle];
    [self updateAccessoryViews];
}

- (void)updateAccessoryViews
{
    if (self.conversation != nil) {
        self.itemView.statusIndicator.indicatorType = self.conversation.conversationListIndicator;
        self.itemView.statusIndicator.unreadCount = self.conversation.estimatedUnreadCount;
    }
    else {
        self.itemView.statusIndicator.indicatorType = ZMConversationListIndicatorNone;
        self.itemView.statusIndicator.unreadCount = 0;
    }
    
    [self updateRightAccessory];
    [self setNeedsUpdateConstraints];
}

- (void)updateSubtitle
{
    id<ZMConversationMessage> lastMessage = [self.conversation lastTextMessage];
    
    if (lastMessage == nil || lastMessage.sender.isSelfUser) {
        self.itemView.subtitleAttributedText = nil;
        return;
    }
    
    NSString *content = [lastMessage.textMessageData.messageText stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
    NSString *subtitle = content;
    
    if (self.conversation.conversationType == ZMConversationTypeGroup) {
        subtitle = [NSString stringWithFormat:@"%@: %@", lastMessage.sender.displayName, content];
    }
    UIFont *textFont = [UIFont fontWithMagicIdentifier:@"style.text.small.font_spec"];
    UIColor *dimmedColor = [[ColorScheme defaultColorScheme] colorWithName:ColorSchemeColorTextDimmed variant:ColorSchemeVariantDark];
    
    NSDictionary *textAttributes = @{NSFontAttributeName: textFont,
                                     NSForegroundColorAttributeName: dimmedColor};
    
    NSMutableAttributedString *subtitleAttributed = [[NSMutableAttributedString alloc] initWithString:subtitle
                                                                                           attributes:textAttributes];
    
    UIFont *usernameFont = [UIFont fontWithMagicIdentifier:@"style.text.small.font_spec_bold"];
    
    NSDictionary *nameAttributes = @{NSFontAttributeName: usernameFont,
                                     NSForegroundColorAttributeName: dimmedColor};
    
    [subtitleAttributed setAttributes:nameAttributes
                          toSubstring:lastMessage.sender.displayName];
    
    self.itemView.subtitleAttributedText = subtitleAttributed;
}

- (BOOL)canOpenDrawer
{
    return YES;
}

#pragma mark - AVSMediaManagerClientChangeNotification

- (void)mediaManagerDidChange:(AVSMediaManagerClientChangeNotification *)notification
{
    // AUDIO-548 AVMediaManager notifications arrive on a background thread.
    dispatch_async(dispatch_get_main_queue(), ^{
        if (notification.microphoneMuteChanged && (self.conversation.voiceChannel.state > VoiceChannelV2StateNoActiveUsers)) {
            [self updateAccessoryViews];
        }
    });
}

#pragma mark - DrawerOverrides

- (void)drawerScrollingEndedWithOffset:(CGFloat)offset
{
    if (self.animatedListView.progress >= 1) {
        BOOL overscrolled = NO;
        if (offset > (CGRectGetWidth(self.frame) / OverscrollRatio)) {
            overscrolled = YES;
        } else if (self.overscrollStartDate) {
            NSTimeInterval diff = [[NSDate date] timeIntervalSinceDate:self.overscrollStartDate];
            overscrolled = (diff > IgnoreOverscrollTimeInterval);
        }

        if (overscrolled) {
            [self.delegate conversationListCellOverscrolled:self];
        }
    }
    self.overscrollStartDate = nil;
}

- (void)drawerScrollingStarts
{
    self.overscrollStartDate = nil;
}

@end



@implementation ConversationListCell (RightAccessory)


- (void)accessoryViewWantsToJoinCall:(ListItemRightAccessoryView *)accessoryView
{
    if (self.conversation.voiceChannel.state == VoiceChannelV2StateIncomingCallInactive) {
        [self.conversation startAudioCallWithCompletionHandler:nil];
    } else {
        DDLogError(@"Cannot join a call in a conversation without ongoing call");
    }
}

- (void)updateRightAccessory
{
    if ([self shouldShowMediaButton]) {
        self.itemView.rightAccessoryType = ConversationListRightAccessoryMediaButton;
    }
    else if (self.conversation.isSilenced) {
        self.itemView.rightAccessoryType = ConversationListRightAccessorySilencedIcon;
    }
    else if (self.conversation.conversationListIndicator == ZMConversationListIndicatorInactiveCall) {
        self.itemView.rightAccessoryType = ConversationListRightAccessoryJoinCall;
    }
    else {
        self.itemView.rightAccessoryType = ConversationListRightAccessoryNone;
    }

    [self.itemView updateRightAccessoryAppearance];
}

- (BOOL)shouldShowMediaButton
{
    if (self.selected && IS_IPAD_LANDSCAPE_LAYOUT) {
        return NO;
    }
    
    MediaPlaybackManager *mediaPlaybackManager = [AppDelegate sharedAppDelegate].mediaPlaybackManager;
    
    if ([mediaPlaybackManager.activeMediaPlayer.sourceMessage.conversation isEqual:self.conversation]) {
        return YES;
    }
    
    return NO;
}

@end

