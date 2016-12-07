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


#import "ProfileHeaderView.h"

#import "WAZUIMagicIOS.h"
#import "UIImage+ZetaIconsNeue.h"
#import <PureLayout/PureLayout.h>

@import WireExtensionComponents;
#import <PureLayout/PureLayout.h>
#import "WireStyleKit.h"
#import "Wire-Swift.h"


@interface ProfileHeaderView ()

@property (nonatomic, assign) ProfileHeaderStyle headerStyle;
@property (nonatomic, strong, readwrite) UILabel *titleLabel;
@property (nonatomic, strong, readwrite) UILabel *akaLabel;
@property (nonatomic, strong) UIImageView *akaImageView;
@property (nonatomic, strong) UIImageView *verifiedImageView;
@property (nonatomic, strong, readwrite) UITextView *subtitleLabel;
@property (nonatomic, strong, readwrite) IconButton *dismissButton;
@property (nonatomic) NSLayoutConstraint *subtitleLabelTopOffset;
@end



@implementation ProfileHeaderView

- (instancetype)initWithHeaderStyle:(ProfileHeaderStyle)headerStyle {
    // Use non-zero rect to avoid broken autolayout
	if (self = [super initWithFrame:CGRectMake(0, 0, 320, 80)]) {
		_headerStyle = headerStyle;
		[self createViews];
		[self setupConstraints];
	}
	return self;
}

- (void)createViews
{
    self.titleLabel = [[UILabel alloc] initForAutoLayout];
    [self addSubview:self.titleLabel];
    
    self.akaLabel = [[UILabel alloc] initForAutoLayout];
    self.akaLabel.backgroundColor = [UIColor clearColor];
    [self addSubview:self.akaLabel];
    
    self.akaImageView = [[UIImageView alloc] initWithImage:[UIImage imageForIcon:ZetaIconTypeAddressBook
                                                                        iconSize:ZetaIconSizeSearchBar
                                                                           color:[UIColor colorWithMagicIdentifier:@"style.color.foreground.faded"]]];
    [self addSubview:self.akaImageView];
    
    self.verifiedImageView = [[UIImageView alloc] initWithImage:[WireStyleKit imageOfShieldverified]];
    self.verifiedImageView.accessibilityIdentifier = @"VerifiedShield";
    [self addSubview:self.verifiedImageView];
    self.verifiedImageView.hidden = YES;

    self.subtitleLabel = [[LinkInteractionTextView alloc] initForAutoLayout];
	self.subtitleLabel.editable = NO;
    self.subtitleLabel.scrollEnabled = NO;
	self.subtitleLabel.textContainerInset = UIEdgeInsetsZero;
	self.subtitleLabel.textContainer.lineFragmentPadding = 0;
	self.subtitleLabel.textContainer.maximumNumberOfLines = 1;
	self.subtitleLabel.textContainer.lineBreakMode = NSLineBreakByTruncatingTail;
	self.subtitleLabel.dataDetectorTypes = UIDataDetectorTypeLink;
    self.subtitleLabel.backgroundColor = [UIColor clearColor];
    [self addSubview:self.subtitleLabel];
    
    self.dismissButton = [IconButton iconButtonCircular];
    self.dismissButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.dismissButton.accessibilityIdentifier = @"OtherUserProfileCloseButton";
    

	switch (self.headerStyle) {
		case ProfileHeaderStyleBackButton: {
            [self.dismissButton setIcon:ZetaIconTypeChevronLeft withSize:ZetaIconSizeTiny forState:UIControlStateNormal];
			break;
		}

		case ProfileHeaderStyleCancelButton: {
            [self.dismissButton setIcon:ZetaIconTypeX withSize:ZetaIconSizeTiny forState:UIControlStateNormal];
			break;
		}

		case ProfileHeaderStyleNoButton:
			self.dismissButton.hidden = YES;
			break;
	}

    [self addSubview:self.dismissButton];
}

- (void)setupConstraints
{

	CGFloat contentTopMargin = [WAZUIMagic cgFloatForIdentifier:@"profile_temp.content_top_margin"];

    [self.titleLabel autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:contentTopMargin];
	[self.titleLabel autoSetDimension:ALDimensionHeight toSize:32];
    [self.titleLabel autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:[WAZUIMagic cgFloatForIdentifier:@"profile_temp.content_left_margin"] + 32];
    [self.titleLabel autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:[WAZUIMagic cgFloatForIdentifier:@"profile_temp.content_left_margin"] + 32];

    [self.akaLabel addConstraintForAligningTopToBottomOfView:self.titleLabel distance:4];
    [self.akaLabel autoAlignAxisToSuperviewAxis:ALAxisVertical];
    
    [self.akaImageView autoAlignAxis:ALAxisHorizontal toSameAxisOfView:self.akaLabel];
    [self.akaImageView autoPinEdge:ALEdgeLeft toEdge:ALEdgeRight ofView:self.akaLabel withOffset:8];
    [self.akaLabel autoPinEdge:ALEdgeRight toEdge:ALEdgeLeft ofView:self.akaImageView withOffset:-8];
    
    self.subtitleLabelTopOffset = [self.subtitleLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.akaLabel withOffset:10];
    [self.subtitleLabel autoAlignAxisToSuperviewAxis:ALAxisVertical];
    [self.subtitleLabel autoPinEdgeToSuperviewEdge:ALEdgeBottom];
	[self.subtitleLabel autoSetDimension:ALDimensionHeight toSize:32];

	CGFloat dismissButtonTopMargin = 24;

    [self.dismissButton autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:dismissButtonTopMargin];
    [self.dismissButton autoMatchDimension:ALDimensionWidth toDimension:ALDimensionHeight ofView:self.dismissButton];
    [self.dismissButton autoSetDimension:ALDimensionWidth toSize:32];
    
    [self.verifiedImageView autoAlignAxis:ALAxisHorizontal toSameAxisOfView:self.titleLabel];
    [self.verifiedImageView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionHeight ofView:self.verifiedImageView];
    [self.verifiedImageView autoSetDimension:ALDimensionWidth toSize:16];
    [self.verifiedImageView autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:[WAZUIMagic cgFloatForIdentifier:@"profile_temp.content_left_margin"]];
    
    
	switch (self.headerStyle) {
		case ProfileHeaderStyleBackButton:
			[self.dismissButton autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:[WAZUIMagic cgFloatForIdentifier:@"profile_temp.content_left_margin"]];

			break;
		case ProfileHeaderStyleCancelButton:
            [self.dismissButton autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:[WAZUIMagic cgFloatForIdentifier:@"profile_temp.content_right_margin"]];
			break;

		case ProfileHeaderStyleNoButton:

			break;
	}
}

 - (void)setShowVerifiedShield:(BOOL)showVerifiedShield
{
    _showVerifiedShield = showVerifiedShield;
    BOOL shouldHide = YES;
    if (self.headerStyle != ProfileHeaderStyleBackButton) {
        shouldHide = !showVerifiedShield;
    }
    
    [UIView transitionWithView:self.verifiedImageView
                      duration:0.2
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{
        self.verifiedImageView.hidden = shouldHide;
    } completion:nil];
}

- (CGSize)intrinsicContentSize
{

    if (self.subtitleLabel.text.length != 0) {
        return CGSizeMake(UIViewNoIntrinsicMetric, self.subtitleLabel.bounds.size.height);
    }
    else if (!self.dismissButton.hidden) {
        return CGSizeMake(UIViewNoIntrinsicMetric, self.dismissButton.bounds.size.height);
    }
    else if (self.titleLabel.text.length != 0) {
        return CGSizeMake(UIViewNoIntrinsicMetric, self.titleLabel.bounds.size.height);
    }
    else {
        return CGSizeMake(UIViewNoIntrinsicMetric, 30.0f);
    }
}

- (void)updateConstraints
{
    [self invalidateIntrinsicContentSize];
    self.akaImageView.hidden = (self.akaLabel.attributedText.length == 0);
    self.subtitleLabelTopOffset.constant = (self.akaLabel.attributedText.length == 0) ? 0 : 10;
    [super updateConstraints];
}

@end
