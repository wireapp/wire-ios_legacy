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


#import "ConversationListItemView.h"

#import <PureLayout/PureLayout.h>

#import "WAZUIMagicIOS.h"
#import "Constants.h"
#import "UIColor+WAZExtensions.h"

#import "UIView+Borders.h"
#import "WireSyncEngine+iOS.h"
#import "Wire-Swift.h"

@import Classy;

NSString * const ConversationListItemDidScrollNotification = @"ConversationListItemDidScrollNotification";



@interface ConversationListItemView ()

@property (nonatomic, strong, readwrite) ConversationAvatarView *avatarView;
@property (nonatomic, strong, readwrite) ConversationListAccessoryView *rightAccessory;
@property (nonatomic, strong) UIView *avatarContainer;
@property (nonatomic, strong) UIView *labelsContainer;
@property (nonatomic, strong) UILabel *titleField;
@property (nonatomic, strong) UILabel *subtitleField;
@property (nonatomic, strong) UIView *lineView;

@property (nonatomic, strong) NSLayoutConstraint *titleTwoLineConstraint;
@property (nonatomic, strong) NSLayoutConstraint *titleOneLineConstraint;

@end



@implementation ConversationListItemView

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setupConversationListItemView];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(contentSizeCategoryDidChange:)
                                                     name:UIContentSizeCategoryDidChangeNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(mediaPlayerStateChanged:)
                                                     name:MediaPlaybackManagerPlayerStateChangedNotification
                                                   object:nil];
    }
    return self;
}

- (void)setupConversationListItemView
{
    self.labelsContainer = [[UIView alloc] initForAutoLayout];
    [self addSubview:self.labelsContainer];
    
    self.titleField = [[UILabel alloc] initForAutoLayout];
    self.titleField.numberOfLines = 1;
    self.titleField.lineBreakMode = NSLineBreakByTruncatingTail;
    [self.labelsContainer addSubview:self.titleField];
    
    [self configureFont];

    self.avatarContainer = [[UIView alloc] initForAutoLayout];
    [self addSubview:self.avatarContainer];

    self.avatarView = [[ConversationAvatarView alloc] initForAutoLayout];
    [self.avatarContainer addSubview:self.avatarView];

    self.rightAccessory = [[ConversationListAccessoryView alloc] initWithMediaPlaybackManager:[AppDelegate sharedAppDelegate].mediaPlaybackManager];
    self.rightAccessory.accessibilityLabel = @"status";
    [self addSubview:self.rightAccessory];

    [self createSubtitleField];
    
    self.lineView = [[UIView alloc] initForAutoLayout];
    self.lineView.backgroundColor = [UIColor colorWithWhite:1.0f alpha:0.08f];
    [self addSubview:self.lineView];
    
    [self.rightAccessory setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
    
    [self.titleField setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
    [self.titleField setContentCompressionResistancePriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
    [self.titleField setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
    [self.titleField setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];

    [self.subtitleField setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
    [self.subtitleField setContentCompressionResistancePriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
    [self.subtitleField setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
    [self.subtitleField setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
    [self createConstraints];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(otherConversationListItemDidScroll:)
                                                 name:ConversationListItemDidScrollNotification
                                               object:nil];
}

- (void)createSubtitleField
{
    self.subtitleField = [[UILabel alloc] initForAutoLayout];
    self.subtitleField.textColor = [UIColor colorWithWhite:1.0f alpha:0.64f];
    self.subtitleField.accessibilityLabel = @"Conversation status";
    self.subtitleField.numberOfLines = 1;
    [self.labelsContainer addSubview:self.subtitleField];
}

- (void)createConstraints
{
    [NSLayoutConstraint autoCreateAndInstallConstraints:^{
        
        [self autoSetDimension:ALDimensionHeight toSize:64.0 relation:NSLayoutRelationGreaterThanOrEqual];
        CGFloat leftMargin = 64.0;
        [self.avatarContainer autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero excludingEdge:ALEdgeTrailing];
        [self.avatarContainer autoPinEdge:ALEdgeTrailing toEdge:ALEdgeLeading ofView:self.titleField];
        
        [self.avatarView autoCenterInSuperview];
        
        [self.titleField autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero excludingEdge:ALEdgeBottom];
        [self.subtitleField autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.titleField withOffset:2.0];
        [self.subtitleField autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero excludingEdge:ALEdgeTop];
        
        [self.labelsContainer autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:8 relation:NSLayoutRelationGreaterThanOrEqual];
        [self.labelsContainer autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self withOffset:leftMargin];
        [self.labelsContainer autoPinEdge:ALEdgeTrailing toEdge:ALEdgeLeading ofView:self.rightAccessory withOffset:-8.0];
        [self.labelsContainer autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:8 relation:NSLayoutRelationGreaterThanOrEqual];
        
        self.titleTwoLineConstraint = [self.labelsContainer autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
        self.titleTwoLineConstraint.active = NO;
        self.titleOneLineConstraint = [self.titleField autoAlignAxis:ALAxisHorizontal toSameAxisOfView:self];
        
        [self.rightAccessory autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
        [self.rightAccessory autoPinEdgeToSuperviewEdge:ALEdgeTrailing withInset:16.0];
        
        [self.lineView autoSetDimension:ALDimensionHeight toSize:UIScreen.hairline];
        [self.lineView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
        [self.lineView autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self withOffset:0.0];
        [self.lineView autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self.titleField];
    }];
}

- (void)setTitleText:(NSString *)titleText
{
    _titleText = titleText;
    self.titleField.text = titleText;
}

- (void)setSubtitleAttributedText:(NSAttributedString *)subtitleAttributedText
{
    _subtitleAttributedText = subtitleAttributedText;
    self.subtitleField.attributedText = subtitleAttributedText;
    self.subtitleField.accessibilityValue = subtitleAttributedText.string;
    if (subtitleAttributedText.string.length == 0) {
        self.titleTwoLineConstraint.active = NO;
        self.titleOneLineConstraint.active = YES;
    }
    else {
        self.titleOneLineConstraint.active = NO;
        self.titleTwoLineConstraint.active = YES;
    }
}

- (void)setSelected:(BOOL)selected
{
    if (_selected != selected) {
        _selected = selected;
        
        self.backgroundColor = self.selected ? [UIColor colorWithWhite:0 alpha:0.08] : [UIColor clearColor];
    }
}

- (void)setVisualDrawerOffset:(CGFloat)visualDrawerOffset notify:(BOOL)notify
{
    _visualDrawerOffset = visualDrawerOffset;
    if (notify && _visualDrawerOffset != visualDrawerOffset) {
        [[NSNotificationCenter defaultCenter] postNotificationName:ConversationListItemDidScrollNotification object:self];
    }
}

- (void)setVisualDrawerOffset:(CGFloat)visualDrawerOffset
{
    [self setVisualDrawerOffset:visualDrawerOffset notify:YES];
}

- (void)updateAppearance
{
    self.titleField.text = self.titleText;
}

#pragma mark - Observer

- (void)contentSizeCategoryDidChange:(NSNotification *)notification
{
    [self configureFont];
}

- (void)mediaPlayerStateChanged:(NSNotification *)notification
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.conversation != nil &&
            [[[[[AppDelegate sharedAppDelegate] mediaPlaybackManager] activeMediaPlayer] sourceMessage] conversation] == self.conversation) {
            [self updateForConversation:self.conversation];
        }
    });
}

- (void)otherConversationListItemDidScroll:(NSNotification *)notification
{
    if ([notification.object isEqual:self]) {
        return;
    }
    else {
        ConversationListItemView *otherItem = notification.object;

        CGFloat fraction = 1.0f;
        if (self.bounds.size.width != 0) {
            fraction = (1.0f - otherItem.visualDrawerOffset / self.bounds.size.width);
        }

        if (fraction > 1.0f) {
            fraction = 1.0f;
        }
        else if (fraction < 0.0f) {
            fraction = 0.0f;
        }
        self.alpha = 0.35f + fraction * 0.65f;
    }
}

@end

