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
#import "zmessaging+iOS.h"
#import "Wire-Swift.h"

@import Classy;

NSString * const ConversationListItemDidScrollNotification = @"ConversationListItemDidScrollNotification";



@interface ConversationListItemView ()

@property (nonatomic, strong, readwrite) ConversationListAvatarView *avatarView;
@property (nonatomic, strong, readwrite) ConversationListAccessoryView *rightAccessory;
@property (nonatomic, strong) UIView *avatarContainer;
@property (nonatomic, strong) UILabel *titleField;
@property (nonatomic, strong) UILabel *subtitleField;
@property (nonatomic, strong) UIView *lineView;

@property (nonatomic, strong) NSLayoutConstraint *titleTopMarginConstraint;
@property (nonatomic, strong) NSLayoutConstraint *titleCenterConstraint;

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
    }
    return self;
}

- (void)setupConversationListItemView
{
    self.titleField = [[UILabel alloc] initForAutoLayout];
    self.titleField.numberOfLines = 1;
    self.titleField.lineBreakMode = NSLineBreakByTruncatingTail;
    self.titleField.accessibilityLabel = @"Conversatsion name";
    [self addSubview:self.titleField];

    self.avatarContainer = [[UIView alloc] initForAutoLayout];
    [self addSubview:self.avatarContainer];

    self.avatarView = [[ConversationListAvatarView alloc] initForAutoLayout];
    [self.avatarContainer addSubview:self.avatarView];

    self.rightAccessory = [[ConversationListAccessoryView alloc] initWithMediaPlaybackManager:[AppDelegate sharedAppDelegate].mediaPlaybackManager];
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
    self.subtitleField.accessibilityLabel = @"Conversatsion status";
    self.subtitleField.numberOfLines = 1;
    [self addSubview:self.subtitleField];
}

- (void)createConstraints
{
    [NSLayoutConstraint autoCreateAndInstallConstraints:^{
        [self autoSetDimension:ALDimensionHeight toSize:56.0 relation:NSLayoutRelationGreaterThanOrEqual];
        CGFloat leftMargin = 64.0;
        [self.avatarContainer autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero excludingEdge:ALEdgeTrailing];
        [self.avatarContainer autoPinEdge:ALEdgeTrailing toEdge:ALEdgeLeading ofView:self.titleField];
        
        [self.avatarView autoCenterInSuperview];
        [self.avatarView autoSetDimensionsToSize:CGSizeMake(26, 26)];
        
        [self.titleField autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self withOffset:leftMargin];
        [self.titleField autoPinEdge:ALEdgeTrailing toEdge:ALEdgeLeading ofView:self.rightAccessory withOffset:-8.0 relation:NSLayoutRelationLessThanOrEqual];
        self.titleTopMarginConstraint = [self.titleField autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:10.0f];
        self.titleTopMarginConstraint.active = NO;
        self.titleCenterConstraint = [self.titleField autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
        
        [self.rightAccessory autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
        [self.rightAccessory autoPinEdgeToSuperviewEdge:ALEdgeTrailing withInset:16.0];
        
        [NSLayoutConstraint autoSetPriority:UILayoutPriorityDefaultHigh forConstraints:^{
            [self.subtitleField autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.titleField withOffset:8.0];
        }];
        [self.subtitleField autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self.titleField];
        [self.subtitleField autoPinEdge:ALEdgeTrailing toEdge:ALEdgeLeading ofView:self.rightAccessory withOffset:-8.0 relation:NSLayoutRelationLessThanOrEqual];
        [self.subtitleField autoPinEdge:ALEdgeBottom toEdge:ALEdgeBottom ofView:self withOffset:-12.0];
        
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
    
    if (subtitleAttributedText.string.length == 0) {
        self.titleTopMarginConstraint.active = NO;
        self.titleCenterConstraint.active = YES;
    }
    else {
        self.titleCenterConstraint.active = NO;
        self.titleTopMarginConstraint.active = YES;
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

