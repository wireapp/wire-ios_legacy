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
#import "AnimatedListMenuView.h"
#import "Wire-Swift.h"


static const CGFloat MaxVisualDrawerOffsetRevealDistance = 48;
static const NSTimeInterval IgnoreOverscrollTimeInterval = 0.005;
static const NSTimeInterval OverscrollRatio = 2.5;


@interface ConversationListCell () <AVSMediaManagerClientObserver>

@property (nonatomic, strong) ConversationListItemView *itemView;
@property (nonatomic, assign) BOOL hasCreatedInitialConstraints;
@property (nonatomic, strong) NSLayoutConstraint *titleBottomMarginConstraint;

@property (nonatomic, strong) NSLayoutConstraint *archiveRightMarginConstraint;

@property (nonatomic) AnimatedListMenuView *animatedListView;
@property (nonatomic) NSDate *overscrollStartDate;

@end

@interface ConversationListCell (Typing) <ZMTypingChangeObserver>
@end

@implementation ConversationListCell

- (void)dealloc
{
    if (![[Settings sharedSettings] disableAVS]) {
        [AVSMediaManagerClientChangeNotification removeObserver:self];
    }
    [ZMConversation removeTypingObserver:self];
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
    
    [self.itemView.rightAccessory addTarget:self
                                     action:@selector(onRightAccessorySelected:)
                           forControlEvents:UIControlEventTouchUpInside];
    [self.swipeView addSubview:self.itemView];

    AnimatedListMenuView *animatedView = [[AnimatedListMenuView alloc] initForAutoLayout];
    
    [self.menuView addSubview:animatedView];
    self.animatedListView = animatedView;
    [self.animatedListView enable1PixelBlueBorder];
    
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
        [ZMConversation removeTypingObserver:self];
        _conversation = conversation;
        [_conversation addTypingObserver:self];
        
        [self updateAppearance];
    }
}
    
- (void)updateAppearance
{
    [self.itemView updateForConversation:self.conversation];
}

- (void)onRightAccessorySelected:(UIButton *)sender
{
    MediaPlaybackManager *mediaPlaybackManager = [AppDelegate sharedAppDelegate].mediaPlaybackManager;
    
    if (mediaPlaybackManager.activeMediaPlayer != nil) {
        [self toggleMediaPlayer];
    }
    else {
        if (self.conversation.voiceChannel.state == VoiceChannelV2StateIncomingCall) {
            [self.conversation.voiceChannel joinWithVideo:NO userSession:[ZMUserSession sharedSession]];
        }
    }
}
    
- (void)toggleMediaPlayer
{
    MediaPlaybackManager *mediaPlaybackManager = [AppDelegate sharedAppDelegate].mediaPlaybackManager;
    
    if (mediaPlaybackManager.activeMediaPlayer.state == MediaPlayerStatePlaying) {
        [mediaPlaybackManager pause];
    } else {
        [mediaPlaybackManager play];
    }
    
    [self updateAppearance];
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
            [self updateAppearance];
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


@implementation ConversationListCell (Typing)

- (void)typingDidChange:(ZMTypingChangeNotification *)note
{
    [self updateAppearance];
}

@end

