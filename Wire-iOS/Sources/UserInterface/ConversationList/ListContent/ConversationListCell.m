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
#import "ConversationListCell+Internal.h"

#import "ConversationListItemView.h"



#import "Settings.h"

#import "MediaPlayer.h"
#import "AppDelegate.h"


#import "AnimatedListMenuView.h"
#import "Wire-Swift.h"


@interface ConversationListCell () <AVSMediaManagerClientObserver>

@property (nonatomic) ConversationListItemView *itemView;

@property (nonatomic) NSLayoutConstraint *titleBottomMarginConstraint;

@property (nonatomic) id typingObserverToken;
@end

@interface ConversationListCell (Typing) <ZMTypingChangeObserver>
@end

@implementation ConversationListCell

- (void)dealloc
{
    [AVSMediaManagerClientChangeNotification removeObserver:self];
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

    self.itemView = [[ConversationListItemView alloc] init];
    
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                           action:@selector(onRightAccessorySelected:)];
    [self.itemView.rightAccessory addGestureRecognizer:tapGestureRecognizer];
    [self.swipeView addSubview:self.itemView];

    self.menuDotsView = [[AnimatedListMenuView alloc] init];
    [self.menuView addSubview:self.menuDotsView];
    
    [self setNeedsUpdateConstraints];
     
    [AVSMediaManagerClientChangeNotification addObserver:self];
}

- (void)setVisualDrawerOffset:(CGFloat)visualDrawerOffset updateUI:(BOOL)doUpdate
{
    [super setVisualDrawerOffset:visualDrawerOffset updateUI:doUpdate];
    
    // After X % of reveal we consider animation should be finished
    const CGFloat progress = (visualDrawerOffset / MaxVisualDrawerOffsetRevealDistance);
    [self.menuDotsView setProgress:progress animated:YES];
    if (progress >= 1 && ! self.overscrollStartDate) {
        self.overscrollStartDate = [NSDate date];
    }
    
    self.itemView.visualDrawerOffset = visualDrawerOffset;
}

- (void)setConversation:(ZMConversation *)conversation
{
    if (_conversation != conversation) {
        self.typingObserverToken = nil;
        _conversation = conversation;
        self.typingObserverToken = [_conversation addTypingObserver:self];
        
        [self updateAppearance];

        [self setupConversationObserverWithConversation: conversation];
    }
}
    
- (void)updateAppearance
{
    [self.itemView updateForConversation:self.conversation];
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

static CGSize cachedSize = {0, 0};

- (CGSize)sizeInCollectionViewSize:(CGSize)collectionViewSize
{
    if (!CGSizeEqualToSize(cachedSize, CGSizeZero) && cachedSize.width == collectionViewSize.width) {
        return cachedSize;
    }
        
    NSString *fullHeightString = @"Ü";
    [self.itemView configureWith:[[NSAttributedString alloc] initWithString:fullHeightString]
                        subtitle:[[NSAttributedString alloc] initWithString:fullHeightString attributes:[ZMConversation statusRegularStyle]]];
    
    CGSize fittingSize = CGSizeMake(collectionViewSize.width, 0);
    
    self.itemView.frame = CGRectMake(0, 0, fittingSize.width, 0);

    CGSize cellSize = [self.itemView systemLayoutSizeFittingSize:fittingSize];
    cellSize.width = collectionViewSize.width;
    cachedSize = cellSize;
    return cellSize;
}

+ (void)invalidateCachedCellSize
{
    cachedSize = CGSizeZero;
}

#pragma mark - AVSMediaManagerClientChangeNotification

- (void)mediaManagerDidChange:(AVSMediaManagerClientChangeNotification *)notification
{
    // AUDIO-548 AVMediaManager notifications arrive on a background thread.
    dispatch_async(dispatch_get_main_queue(), ^{
        if (notification.microphoneMuteChanged) {
            [self updateAppearance];
        }
    });
}

#pragma mark - DrawerOverrides

- (void)drawerScrollingStarts
{
    self.overscrollStartDate = nil;
}

@end


@implementation ConversationListCell (Typing)

- (void)typingDidChangeWithConversation:(ZMConversation *)conversation typingUsers:(NSSet<ZMUser *> *)typingUsers
{
    [self updateAppearance];
}

@end

