//// 
//// Wire
//// Copyright (C) 2016 Wire Swiss GmbH
//// 
//// This program is free software: you can redistribute it and/or modify
//// it under the terms of the GNU General Public License as published by
//// the Free Software Foundation, either version 3 of the License, or
//// (at your option) any later version.
//// 
//// This program is distributed in the hope that it will be useful,
//// but WITHOUT ANY WARRANTY; without even the implied warranty of
//// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
//// GNU General Public License for more details.
//// 
//// You should have received a copy of the GNU General Public License
//// along with this program. If not, see http://www.gnu.org/licenses/.
//// 
//
//
//#import "ProfileHeaderView.h"
//
//#import "WAZUIMagicIOS.h"
//#import "UIImage+ZetaIconsNeue.h"
//#import <PureLayout/PureLayout.h>
//
//#import <WireExtensionComponents/WireExtensionComponents.h>
//#import <PureLayout/PureLayout.h>
//#import "WireStyleKit.h"
//#import "Wire-Swift.h"
//
//
//@interface ProfileHeaderView ()
//@property (nonatomic, assign) ProfileHeaderStyle headerStyle;
//@property (nonatomic, strong, readwrite) UILabel *titleLabel;
//@property (nonatomic, strong, readwrite) UITextView *subtitleLabel;
//@property (nonatomic, strong, readwrite) UILabel *correlationLabel;
//@property (nonatomic, strong) UIImageView *verifiedImageView;
//@property (nonatomic, strong, readwrite) IconButton *dismissButton;
//@end
//
//
//
//@implementation ProfileHeaderView
//
//- (instancetype)initWithViewModel:(ProfileHeaderViewModel *)viewModel
//{
//	if (self = [super initWithFrame:CGRectZero]) {
//        _headerStyle = viewModel.style;
//		[self createViews];
//        [self configureWithModel:viewModel];
//		[self setupConstraints];
//	}
//	return self;
//}
//
//- (void)createViews
//{
//    self.translatesAutoresizingMaskIntoConstraints = NO;
//    self.titleLabel = [[UILabel alloc] initForAutoLayout];
//    [self addSubview:self.titleLabel];
//    
//    self.correlationLabel = [[UILabel alloc] initForAutoLayout];
//    self.correlationLabel.backgroundColor = [UIColor clearColor];
//    [self addSubview:self.correlationLabel];
//    
//    self.verifiedImageView = [[UIImageView alloc] initWithImage:[WireStyleKit imageOfShieldverified]];
//    self.verifiedImageView.accessibilityIdentifier = @"VerifiedShield";
//    [self addSubview:self.verifiedImageView];
//    self.verifiedImageView.hidden = YES;
//
//    self.subtitleLabel = [[LinkInteractionTextView alloc] initForAutoLayout];
//	self.subtitleLabel.editable = NO;
//    self.subtitleLabel.scrollEnabled = NO;
//	self.subtitleLabel.textContainerInset = UIEdgeInsetsZero;
//	self.subtitleLabel.textContainer.lineFragmentPadding = 0;
//	self.subtitleLabel.textContainer.maximumNumberOfLines = 1;
//	self.subtitleLabel.textContainer.lineBreakMode = NSLineBreakByTruncatingTail;
//	self.subtitleLabel.dataDetectorTypes = UIDataDetectorTypeLink;
//    self.subtitleLabel.backgroundColor = [UIColor clearColor];
//    [self addSubview:self.subtitleLabel];
//    
//    self.dismissButton = [IconButton iconButtonCircular];
//    self.dismissButton.translatesAutoresizingMaskIntoConstraints = NO;
//    self.dismissButton.accessibilityIdentifier = @"OtherUserProfileCloseButton";
//    
//
//	switch (self.headerStyle) {
//		case ProfileHeaderStyleBackButton: {
//            [self.dismissButton setIcon:ZetaIconTypeChevronLeft withSize:ZetaIconSizeTiny forState:UIControlStateNormal];
//			break;
//		}
//
//		case ProfileHeaderStyleCancelButton: {
//            [self.dismissButton setIcon:ZetaIconTypeX withSize:ZetaIconSizeTiny forState:UIControlStateNormal];
//			break;
//		}
//
//		case ProfileHeaderStyleNoButton:
//			self.dismissButton.hidden = YES;
//			break;
//	}
//
//    [self addSubview:self.dismissButton];
//}
//
//- (void)setupConstraints
//{
//	CGFloat contentTopMargin = [WAZUIMagic cgFloatForIdentifier:@"profile_temp.content_top_margin"];
//
//    [self.titleLabel autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:contentTopMargin];
//	[self.titleLabel autoSetDimension:ALDimensionHeight toSize:32];
//    [self.titleLabel autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:[WAZUIMagic cgFloatForIdentifier:@"profile_temp.content_left_margin"] + 32];
//    [self.titleLabel autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:[WAZUIMagic cgFloatForIdentifier:@"profile_temp.content_left_margin"] + 32];
//
//    [self.subtitleLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.titleLabel withOffset:10];
//    [self.subtitleLabel autoAlignAxisToSuperviewAxis:ALAxisVertical];
//	[self.subtitleLabel autoSetDimension:ALDimensionHeight toSize:32];
//
//    [self.correlationLabel addConstraintForAligningTopToBottomOfView:self.subtitleLabel distance:4];
//    [self.correlationLabel autoAlignAxisToSuperviewAxis:ALAxisVertical];
//    [self.correlationLabel autoPinEdgeToSuperviewEdge:ALEdgeBottom];
//
//	CGFloat dismissButtonTopMargin = 24;
//
//    [self.dismissButton autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:dismissButtonTopMargin];
//    [self.dismissButton autoMatchDimension:ALDimensionWidth toDimension:ALDimensionHeight ofView:self.dismissButton];
//    [self.dismissButton autoSetDimension:ALDimensionWidth toSize:32];
//    
//    [self.verifiedImageView autoAlignAxis:ALAxisHorizontal toSameAxisOfView:self.titleLabel];
//    [self.verifiedImageView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionHeight ofView:self.verifiedImageView];
//    [self.verifiedImageView autoSetDimension:ALDimensionWidth toSize:16];
//    [self.verifiedImageView autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:[WAZUIMagic cgFloatForIdentifier:@"profile_temp.content_left_margin"]];
//    
//    
//	switch (self.headerStyle) {
//		case ProfileHeaderStyleBackButton:
//			[self.dismissButton autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:[WAZUIMagic cgFloatForIdentifier:@"profile_temp.content_left_margin"]];
//
//			break;
//		case ProfileHeaderStyleCancelButton:
//            [self.dismissButton autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:[WAZUIMagic cgFloatForIdentifier:@"profile_temp.content_right_margin"]];
//			break;
//
//		case ProfileHeaderStyleNoButton:
//			break;
//	}
//}
//
//- (void)configureWithModel:(ProfileHeaderViewModel *)model
//{
//    self.titleLabel.attributedText = model.title;
//    self.subtitleLabel.attributedText = model.subtitle;
//    self.correlationLabel.attributedText = model.correlationText;
//}
//
// - (void)setShowVerifiedShield:(BOOL)showVerifiedShield
//{
//    _showVerifiedShield = showVerifiedShield;
//    BOOL shouldHide = YES;
//    if (self.headerStyle != ProfileHeaderStyleBackButton) {
//        shouldHide = !showVerifiedShield;
//    }
//    
//    [UIView transitionWithView:self.verifiedImageView
//                      duration:0.2
//                       options:UIViewAnimationOptionTransitionCrossDissolve
//                    animations:^{
//        self.verifiedImageView.hidden = shouldHide;
//    } completion:nil];
//}
//
//- (CGSize)intrinsicContentSize
//{
//    return CGSizeMake(UIViewNoIntrinsicMetric, CGRectGetMaxY(self.correlationLabel.bounds));
//}
//
//- (void)updateConstraints
//{
//    [self invalidateIntrinsicContentSize];
//    [super updateConstraints];
//}
//
//@end
