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

#import "ConversationListIndicator.h"
#import "ListItemRightAccessoryView.h"
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
@property (nonatomic, strong, readwrite) ConversationListIndicator *statusIndicator;
@property (nonatomic, strong, readwrite) ListItemRightAccessoryView *rightAccessory;
@property (nonatomic, strong) UIView *avatarContainer;
@property (nonatomic, strong) UILabel *titleField;
@property (nonatomic, strong) UILabel *subtitleField;
@property (nonatomic, strong) UIView *lineView;

@property (nonatomic, strong) NSLayoutConstraint *titleTopMarginConstraint;
@property (nonatomic, strong) NSLayoutConstraint *titleCenterConstraint;
@property (nonatomic, strong) NSLayoutConstraint *rightAccessoryWidthConstraint;

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
    _selectionColor = [UIColor accentColor];
    
    self.titleField = [[UILabel alloc] initForAutoLayout];
    self.titleField.numberOfLines = 1;
    self.titleField.lineBreakMode = NSLineBreakByTruncatingTail;
    [self addSubview:self.titleField];

    self.avatarContainer = [[UIView alloc] initForAutoLayout];
    [self addSubview:self.avatarContainer];

    self.avatarView = [[ConversationListAvatarView alloc] initForAutoLayout];
    [self.avatarContainer addSubview:self.avatarView];

    self.statusIndicator = [[ConversationListIndicator alloc] initForAutoLayout];
    self.statusIndicator.hidden = YES;
    [self addSubview:self.statusIndicator];

    self.rightAccessory = [[ListItemRightAccessoryView alloc] initForAutoLayout];
    [self addSubview:self.rightAccessory];

    [self createSubtitleField];
    
    [self createConstraints];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(otherConversationListItemDidScroll:)
                                                 name:ConversationListItemDidScrollNotification
                                               object:nil];
}

- (void)createSubtitleField
{
    self.subtitleField = [[UILabel alloc] initForAutoLayout];

    self.subtitleField.textColor = [UIColor colorWithMagicIdentifier:@"list.subtitle.color"];
    self.subtitleField.numberOfLines = 1;
    [self addSubview:self.subtitleField];

    self.lineView = [[UIView alloc] initForAutoLayout];
    self.lineView.cas_styleClass = @"separator";
    [self addSubview:self.lineView];
}

- (void)createConstraints
{
    CGFloat leftMargin = [WAZUIMagic floatForIdentifier:@"list.left_margin"];
    [self.avatarContainer autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero excludingEdge:ALEdgeTrailing];
    [self.avatarContainer autoPinEdge:ALEdgeTrailing toEdge:ALEdgeLeading ofView:self.titleField];

    [self.avatarView autoCenterInSuperview];
    [self.avatarView autoSetDimensionsToSize:CGSizeMake(24, 24)];

    [self.titleField autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self withOffset:leftMargin];
    [self.titleField autoPinEdge:ALEdgeTrailing toEdge:ALEdgeLeading ofView:self.rightAccessory withOffset:0.0 relation:NSLayoutRelationLessThanOrEqual];
    self.titleTopMarginConstraint = [self.titleField autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:8.0f];
    self.titleTopMarginConstraint.active = NO;
    self.titleCenterConstraint = [self.titleField autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
    
    [self.rightAccessory autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
    [self.rightAccessory autoSetDimension:ALDimensionHeight toSize:28.0f];
    [self.rightAccessory autoPinEdgeToSuperviewEdge:ALEdgeTrailing withInset:18.0];
    self.rightAccessoryWidthConstraint = [self.rightAccessory autoSetDimension:ALDimensionWidth toSize:0.0f];

    [self.statusIndicator autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
    [self.statusIndicator autoSetDimension:ALDimensionHeight toSize:28.0f];
    [self.statusIndicator autoPinEdgeToSuperviewEdge:ALEdgeTrailing withInset:18.0];
    
    [self.rightAccessory setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
    [self.titleField setContentCompressionResistancePriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];

    [self updateRightAccessoryWidth];

    [self.subtitleField autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.titleField withOffset:4];
    [self.subtitleField autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self.titleField];
    [self.subtitleField autoPinEdge:ALEdgeTrailing toEdge:ALEdgeLeading ofView:self.rightAccessory withOffset:0.0 relation:NSLayoutRelationLessThanOrEqual];

    [self.lineView autoSetDimension:ALDimensionHeight toSize:UIScreen.hairline];
    [self.lineView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
    [self.lineView autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self withOffset:0];
    [self.lineView autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self.titleField];
}

- (void)setTitleText:(NSString *)titleText
{
    _titleText = titleText;
    self.titleField.attributedText = [self formattedTextForTitle:titleText withSelectionState:self.selected];
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

- (void)setSelectionColor:(UIColor *)selectionColor
{
    _selectionColor = selectionColor;
    [self updateAppearance];
}

- (void)setSelected:(BOOL)selected
{
    if (_selected != selected) {
        _selected = selected;
        [self updateAppearance];
    }
}

- (void)setRightAccessoryType:(ConversationListRightAccessoryType)rightAccessoryType
{
    if (_rightAccessoryType == rightAccessoryType) {
        return;
    }
    
    _rightAccessoryType = rightAccessoryType;
    
    self.rightAccessory.accessoryType = rightAccessoryType;
    [self updateRightAccessoryWidth];
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

- (void)updateRightAccessoryWidth
{
    BOOL muteVoiceAndLandscape = (self.rightAccessoryType == ConversationListRightAccessoryMuteVoiceButton && IS_IPAD_LANDSCAPE_LAYOUT);
    self.rightAccessoryWidthConstraint.active = YES;

    if (muteVoiceAndLandscape) {
        // If we are showing the mute button and in landscape, don't show the button
        self.rightAccessoryWidthConstraint.constant = 0;
        self.rightAccessory.hidden = YES;
    } else if (self.rightAccessoryType == ConversationListRightAccessoryJoinCall) {
        self.rightAccessoryWidthConstraint.active = NO;
        self.rightAccessory.hidden = NO;
    } else if (self.rightAccessoryType == ConversationListRightAccessoryNone) {
        self.rightAccessoryWidthConstraint.constant = 0;
        self.rightAccessory.hidden = YES;
    } else {
        self.rightAccessoryWidthConstraint.constant = 28.0f;
        self.rightAccessory.hidden = NO;
    }
    
    self.statusIndicator.hidden = !self.rightAccessory.hidden;
}

- (void)updateForCurrentOrientation
{
    [self updateRightAccessoryWidth];
}

- (void)updateRightAccessoryAppearance
{
    [self.rightAccessory updateButtonStates];
}

- (void)updateAppearance
{
    self.titleField.attributedText = [self formattedTextForTitle:self.titleText withSelectionState:self.selected];
    UIColor *textColor = [self colorForSelectionState:self.selected];
    self.subtitleField.textColor = [textColor colorWithAlphaComponent:0.7];
    self.statusIndicator.foregroundColor = self.selectionColor;
}

- (NSAttributedString *)formattedTextForTitle:(NSString *)title withSelectionState:(BOOL)selected
{
    if (title == nil) {
        title = @"";
    }
    
    return [[NSAttributedString alloc] initWithString:title attributes:[self textAttributesWithSelectionState:selected]];
}

- (NSDictionary *)textAttributesWithSelectionState:(BOOL)selected
{
    UIFont *textFont = [UIFont fontWithMagicIdentifier:@"style.text.normal.font_spec"];
    UIColor *textColor = [self colorForSelectionState:selected];
    
    NSDictionary *attributes = @{
                                 NSFontAttributeName: textFont,
                                 NSForegroundColorAttributeName: textColor,
                                 };
    return attributes;
}

- (UIColor *)colorForSelectionState:(BOOL)selected
{
    UIColor *textColor = nil;
    
    if (selected) {
        textColor = self.selectionColor;
    }
    else {
        textColor = [UIColor colorWithMagicIdentifier:@"style.color.static_foreground.normal"];
    }
    
    return textColor;
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

