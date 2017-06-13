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


#import "ParticipantsHeaderView.h"
@import WireExtensionComponents;

#import "IconButton.h"
#import "WAZUIMagicIOS.h"
#import "UIColor+WR_ColorScheme.h"
#import <Classy/Classy.h>
@import PureLayout;
#import "Constants.h"
#import "UIImage+ZetaIconsNeue.h"
#import "ColorScheme.h"
#import "Wire-Swift.h"


static NSTimeInterval const ParticipantsHeaderViewEditHintDismissTimeout = 10.0f;


@interface ParticipantsHeaderView () <UITextViewDelegate>

@property (nonatomic, strong, readwrite) UIView *topSeparatorLine;
@property (nonatomic, strong, readwrite) UIView *separatorLine;

@property (nonatomic, strong) IconButton *cancelButton;
@property (nonatomic, assign) CGSize cancelButtonSize;
@property (nonatomic, strong) NSLayoutConstraint *cancelButtonWidthConstraint;
@property (nonatomic, strong, readwrite) UITextView *titleView;
@property (nonatomic, strong) UIView *titleViewBackground;
@property (nonatomic, strong) UILabel *subtitleLabel;

@property (nonatomic, strong) UIImageView *editHintView;
@property (nonatomic, strong) NSLayoutConstraint *editHintViewLeftOffsetConstraint;

@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) NSLayoutConstraint *containerViewRightConstraint;

@end



@implementation ParticipantsHeaderView

- (instancetype)init
{
    self = [super initWithFrame:CGRectZero];
    if (self) {
        [self addCancelButton];
		[self addNameEditHint];
        [self addContainerView];
        [self addTitleBackground];
        [self addTitle];
        [self addSubtitle];
        [self addSeparatorLine];
        [self addTopSeparatorLine];
        [self setupConstraints];
    }
    return self;
}

- (void)setTopButtonsHidden:(BOOL)topButtonsHidden
{
    [self setTopButtonsHidden:topButtonsHidden animated:NO];
}

- (void)setTopButtonsHidden:(BOOL)topButtonsHidden animated:(BOOL)animated
{
    dispatch_block_t animation = ^() {
        self.cancelButton.alpha = topButtonsHidden ? 0.0f : 1.0f;
        self.cancelButtonWidthConstraint.constant = topButtonsHidden ? 0 : 32;
        self.containerViewRightConstraint.constant = topButtonsHidden ? 0 : -20;
        self.editHintView.alpha = topButtonsHidden ? 0.0f : 1.0f;
        [self setNeedsUpdateConstraints];
        [self setNeedsLayout];
        
    };
    
    if (animated) {
        [UIView animateWithDuration:0.35f animations:animation];
    }
    else {
        animation();
    }
	
	if (! topButtonsHidden) {
		__weak ParticipantsHeaderView *weakSelf = self;
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(ParticipantsHeaderViewEditHintDismissTimeout * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
			weakSelf.editHintView.alpha = 0;
		});
	}
}

- (void)setSubtitleHidden:(BOOL)subtitleHidden
{
    _subtitleHidden = subtitleHidden;

    self.subtitleLabel.hidden = _subtitleHidden;
}

- (BOOL)areTopButtonsHidden
{
    return self.cancelButton.alpha == 0;
}

- (void)buttonTapped:(id)sender
{
    UIImage *image = [self.cancelButton imageForState:UIControlStateNormal];
    if (! image) {
        return;
    }
    if ([self.delegate respondsToSelector:@selector(participantsHeaderView:didTapButton:)]) {
        [self.delegate participantsHeaderView:self didTapButton:self.cancelButton];
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    [self updateEditHintViewLeftOffset];
}

#pragma mark - UI creation

- (void)addContainerView
{
	self.containerView = [[UIView alloc] init];
	self.containerView.translatesAutoresizingMaskIntoConstraints = NO;
	
	[self addSubview:self.containerView];

	self.containerView.backgroundColor = [UIColor clearColor];
}

- (void)addCancelButton
{
	self.cancelButton = [IconButton iconButtonCircular];
	self.cancelButton.translatesAutoresizingMaskIntoConstraints = NO;
	
	[self addSubview:self.cancelButton];
    
    [self.cancelButton setIcon:ZetaIconTypeX withSize:ZetaIconSizeTiny forState:UIControlStateNormal];

	[self.cancelButton addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
	
	if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
		// Don’t show the button in iPad popovers.
		self.cancelButton.hidden = YES;
	}
}

- (void)addTitle
{
	self.titleView = [UITextView new];
	self.titleView.translatesAutoresizingMaskIntoConstraints = NO;
	self.titleView.keyboardAppearance = [ColorScheme defaultColorScheme].keyboardAppearance;
    self.titleView.accessibilityIdentifier = @"ParticipantsView_GroupName";
    self.titleView.scrollEnabled = NO;
    self.titleView.backgroundColor = [UIColor clearColor];
    self.titleView.contentInset = UIEdgeInsetsZero;
    self.titleView.textContainerInset = UIEdgeInsetsZero;
    self.titleView.textContainer.lineFragmentPadding = 0;
    self.titleView.textContainer.maximumNumberOfLines = 5;
    self.titleView.textContainer.lineBreakMode = NSLineBreakByTruncatingTail;

	[self.containerView addSubview:self.titleView];

	self.titleView.delegate = self;
}

- (void)addTitleBackground
{
    self.titleViewBackground = [UIView new];
    self.titleViewBackground.translatesAutoresizingMaskIntoConstraints = NO;
    self.titleViewBackground.layer.masksToBounds = YES;

    [self.containerView addSubview:self.titleViewBackground];
}

- (void)addSubtitle
{
	self.subtitleLabel = [[UILabel alloc] init];
	self.subtitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
	[self.subtitleLabel setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
	[self.subtitleLabel setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
	
	[self.containerView addSubview:self.subtitleLabel];
}

- (void)addTopSeparatorLine
{
	self.topSeparatorLine = [[UIView alloc] init];
	self.topSeparatorLine.translatesAutoresizingMaskIntoConstraints = NO;
	
	[self addSubview:self.topSeparatorLine];
}

- (void)addSeparatorLine
{
	self.separatorLine = [[UIView alloc] init];
	self.separatorLine.translatesAutoresizingMaskIntoConstraints = NO;
	
	[self addSubview:self.separatorLine];
	
	self.separatorLine.hidden = YES;
}

- (void)addNameEditHint
{
    UIImage *hintImage = [UIImage imageForIcon:ZetaIconTypePencil iconSize:ZetaIconSizeTiny color:[UIColor wr_colorFromColorScheme:ColorSchemeColorTextForeground]];
	self.editHintView = [[UIImageView alloc] initWithImage:hintImage];
	self.editHintView.translatesAutoresizingMaskIntoConstraints = NO;

	[self addSubview:self.editHintView];
}

- (void)setupConstraints
{
    // Editing hint
    [self.editHintView addConstraintForAligningTopToTopOfView:self distance:-34];
    self.editHintViewLeftOffsetConstraint = [self.editHintView addConstraintForAligningLeftToLeftOfView:self.titleView distance:0];

    // Container view
    [self.containerView addConstraintForAligningTopToTopOfView:self.cancelButton distance:-6];
    [self.containerView addConstraintForLeftMargin:24 relativeToView:self];
    
    self.containerViewRightConstraint = [self.containerView autoPinEdge:ALEdgeRight toEdge:ALEdgeLeft ofView:self.cancelButton withOffset:-20 relation:NSLayoutRelationEqual];
    
    // Cancel button
    [self.cancelButton addConstraintForAligningTopToTopOfView:self distance:- 26];
    [self.cancelButton addConstraintForRightMargin:16 relativeToView:self];
    [self.cancelButton autoMatchDimension:ALDimensionHeight toDimension:ALDimensionWidth ofView:self.cancelButton];
    self.cancelButtonWidthConstraint = [self.cancelButton autoSetDimension:ALDimensionWidth toSize:32];
    
    // Title view
    [self.titleView addConstraintForTopMargin:0 relativeToView:self.containerView];
    [self.titleView addConstraintForLeftMargin:0 relativeToView:self.containerView];
    [self.titleView addConstraintForRightMargin:0 relativeToView:self.containerView];

    // Title view background
    NSDictionary *dict = [WAZUIMagic sharedMagic][@"participants.name_field"];
    [self.titleViewBackground addConstraintForAligningLeftToLeftOfView:self.titleView distance:-[dict[@"padding_left"] floatValue]];
    [self.titleViewBackground addConstraintForAligningTopToTopOfView:self.titleView  distance:[dict[@"padding_top"] floatValue]];
    [self.titleViewBackground addConstraintForAligningRightToRightOfView:self.titleView distance:[dict[@"padding_right"] floatValue]];
    [self.titleViewBackground addConstraintForAligningBottomToBottomOfView:self.titleView distance:-[dict[@"padding_bottom"] floatValue]];

    // Subtitle label
    [self.subtitleLabel addConstraintForAligningTopToBottomOfView:self.titleView distance:5];
    [self.subtitleLabel addConstraintForLeftMargin:0 relativeToView:self.containerView];
    [self.subtitleLabel addConstraintForRightMargin:0 relativeToView:self.containerView];

    // Top separator line
    [self.topSeparatorLine addConstraintsForRightMargin:0 leftMargin:0 relativeToView:self];
    [self.topSeparatorLine addConstraintForHeight:0.5];
    [self.topSeparatorLine addConstraintForAligningTopToTopOfView:self distance:0];

    // Separator line
    [self.separatorLine addConstraintsForRightMargin:0 leftMargin:0 relativeToView:self];
    [self.separatorLine addConstraintForHeight:0.5];
    [self.separatorLine addConstraintForAligningBottomToBottomOfView:self distance:0];

    // General
	[self.containerView addConstraintForAligningBottomToBottomOfView:self.subtitleLabel distance:-4];
	[self addConstraintForAligningBottomToBottomOfView:self.containerView distance:- 24];
}

- (void)updateEditHintViewLeftOffset
{
    CGSize labelSize = self.titleView.intrinsicContentSize;

    self.editHintViewLeftOffsetConstraint.constant = labelSize.width + 5.0f;
    [self setNeedsUpdateConstraints];
}


#pragma mark - UITextViewDelegate

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView
{
    [UIView animateWithAnimationIdentifier:@"participants.name_field.focused_background_show_animation" animations:^{
        self.cas_styleClass = @"editing";
    } options:0 completion:nil];

    self.editHintView.alpha = 0;

    if (self.delegate && [self.delegate respondsToSelector:@selector(participantsHeaderView:textViewShouldBeginEditing:)]) {
        return [self.delegate participantsHeaderView:self textViewShouldBeginEditing:textView];
    }

    return NO;
}

- (BOOL)textViewShouldEndEditing:(UITextView *)textView
{
    [UIView animateWithAnimationIdentifier:@"participants.name_field.focused_background_hide_animation" animations:^{
        self.cas_styleClass = nil;
    } options:0 completion:nil];

    [textView resignFirstResponder];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(participantsHeaderView:textViewDidEndEditing:)]) {
        [self.delegate participantsHeaderView:self textViewDidEndEditing:textView];
    }

    return YES;
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    if ([text rangeOfString:@"\n"].location != NSNotFound) {
        [textView resignFirstResponder];
        return NO;
    }
    BOOL result = NO;
    if (self.delegate && [self.delegate respondsToSelector:@selector(participantsHeaderView:textView:shouldChangeCharactersInRange:replacementString:)]) {
        result = [self.delegate participantsHeaderView:self textView:textView shouldChangeCharactersInRange:range replacementString:text];
    }
    
    return result;
}

#pragma mark - Public

- (void)setTitle:(NSString *)title
{
    self.titleView.text = title;
    [self updateEditHintViewLeftOffset];
}

- (void)setSubtitle:(NSString *)subtitle
{
    self.subtitleLabel.text = [subtitle uppercasedWithCurrentLocale];
}

- (void)setTitleAccessibilityIdentifier:(NSString *)identifier
{
    self.titleView.accessibilityIdentifier = identifier;
}

- (void)setSubtitleAccessibilityIdentifier:(NSString *)identifier
{
    self.subtitleLabel.accessibilityIdentifier = identifier;
}

- (void)setCancelButtonAccessibilityIdentifier:(NSString *)identifier
{
    self.cancelButton.accessibilityIdentifier = identifier;
}

@end
