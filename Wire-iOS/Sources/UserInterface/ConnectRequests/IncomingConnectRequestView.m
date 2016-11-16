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


#import "IncomingConnectRequestView.h"

#import <PureLayout/PureLayout.h>


#import "UIFont+MagicAccess.h"
#import "WAZUIMagicIOS.h"
#import "UserImageView.h"

#import "UIColor+WR_ColorScheme.h"
#import "TextView.h"
#import "UIColor+WAZExtensions.h"
#import "CommonConnectionsViewController.h"
#import "Constants.h"

#import "UIView+Borders.h"

#import "zmessaging+iOS.h"
#import "NSLayoutConstraint+Helpers.h"


@interface IncomingConnectRequestView ()

@property (nonatomic, strong) NSLayoutConstraint *messageTextViewHeightConstraint;

@end


@interface IncomingConnectRequestView ()

@property (nonatomic) UILabel *titleLabel;
@property (nonatomic) UILabel *subtitleLabel;

@property (nonatomic) Button *acceptButton;
@property (nonatomic) Button *ignoreButton;

@property (nonatomic, copy) NSString *senderName;
@property (nonatomic, copy) NSString *senderEmail;

@end


@implementation IncomingConnectRequestView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _showConnectionButtons = YES;
        [self setupViews];
        [self setupConstraints];
    }
    return self;
}

- (void)setupViews
{
    self.titleLabel = [[UILabel alloc] init];
    [self addSubview:self.titleLabel];
    
    self.subtitleLabel = [[UILabel alloc] init];
    self.subtitleLabel.numberOfLines = 2;
    [self addSubview:self.subtitleLabel];
    
    self.acceptButton = [Button buttonWithStyleClass:@"dialogue-button-full"];
    [self.acceptButton setTitle:[NSLocalizedString(@"inbox.connection_request.connect_button_title", @"") transformStringWithMagicKey:@"connect.connect_button.text_transform"] forState:UIControlStateNormal];
    [self.acceptButton addTarget:self action:@selector(connect) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.acceptButton];
    
    self.ignoreButton = [Button buttonWithStyleClass:@"dialogue-button-empty"];;
    [self.ignoreButton setTitle:[NSLocalizedString(@"inbox.connection_request.ignore_button_title", @"") transformStringWithMagicKey:@"connect.ignore_button.text_transform"] forState:UIControlStateNormal];
    [self.ignoreButton addTarget:self action:@selector(ignore) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.ignoreButton];
    
    self.userImageView = [[UserImageView alloc] initWithMagicPrefix:@"connect.sender_tile"];
    self.userImageView.translatesAutoresizingMaskIntoConstraints = NO;
    self.userImageView.shouldDesaturate = NO;
    self.userImageView.suggestedImageSize = UserImageViewSizeBig;
    [self addSubview:self.userImageView];
    
}

- (void)setupConstraints
{
    [UIView withPriority:UILayoutPriorityDefaultHigh setConstraints:^{
        self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [self.titleLabel addConstraintForTopMargin:24 relativeToView:self];
        [self.titleLabel addConstraintForLeftMargin:0 relativeToView:self];
        [self.titleLabel addConstraintForRightMargin:0 relativeToView:self];
        
        self.subtitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [self.subtitleLabel addConstraintForAligningTopToBottomOfView:self.titleLabel distance:0];
        [self.subtitleLabel addConstraintForLeftMargin:0 relativeToView:self];
        [self.subtitleLabel addConstraintForRightMargin:0 relativeToView:self];

        [self.userImageView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.subtitleLabel withOffset:24];
        [self.userImageView autoSetDimension:ALDimensionWidth toSize:IS_IPHONE_4 ? 200 : 240];
        [self.userImageView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionHeight ofView:self.userImageView];
        [self.userImageView autoAlignAxisToSuperviewAxis:ALAxisVertical];

        self.acceptButton.translatesAutoresizingMaskIntoConstraints = NO;
        [self.acceptButton addConstraintForAligningTopToBottomOfView:self.commonConnectionsController.view distance:24];
        [self.acceptButton addConstraintForBottomMargin:24 relativeToView:self];
        [self.acceptButton addConstraintForRightMargin:0 relativeToView:self];
        [self.acceptButton addConstraintForHeight:[WAZUIMagic cgFloatForIdentifier:@"connect.connect_button.height"]];
        
        self.ignoreButton.translatesAutoresizingMaskIntoConstraints = NO;
        [self.ignoreButton addConstraintForAligningTopToBottomOfView:self.commonConnectionsController.view distance:24];
        [self.ignoreButton addConstraintForBottomMargin:24 relativeToView:self];
        [self.ignoreButton addConstraintForLeftMargin:0 relativeToView:self];
        [self.ignoreBlock addConstraintForHeight:[WAZUIMagic cgFloatForIdentifier:@"connect.ignore_button.height"]];
        
        [self.acceptButton addConstraintForAligningLeftToRightOfView:self.ignoreButton distance:16];
        [self.acceptButton addConstraintForEqualWidthToView:self.ignoreButton];
    }];

}

- (void)setUser:(ZMUser *)user
{
    _user = user;
    
    self.senderName = user.name;
    self.senderEmail = user.emailAddress;

    self.userImageView.user = self.user;
}

- (void)setSenderName:(NSString *)senderName
{
    _senderName = senderName;
    
    if (senderName) {
        NSString *titleString = [NSString stringWithFormat:NSLocalizedString(@"connection_request.title", @"Connect Title"), senderName];
        NSMutableAttributedString *attributedTitleString = [[NSMutableAttributedString alloc] initWithString:titleString
                                                                                                  attributes:@{ NSFontAttributeName: [UIFont fontWithMagicIdentifier:@"style.text.normal.font_spec"],
                                                                                                                NSForegroundColorAttributeName: [UIColor wr_colorFromColorScheme:ColorSchemeColorTextForeground] }];
        
        [attributedTitleString addAttribute:NSFontAttributeName value:[UIFont fontWithMagicIdentifier:@"style.text.normal.font_spec_bold"] range:[titleString rangeOfString:senderName]];
        
        self.titleLabel.attributedText = attributedTitleString;
    }
    else {
        self.titleLabel.text = @"";
    }
}

- (void)setSenderEmail:(NSString *)senderEmail
{
    _senderEmail = senderEmail;
    
    if (senderEmail) {
        
        self.subtitleLabel.attributedText = [[NSAttributedString alloc] initWithString:senderEmail
                                                                            attributes:@{ NSFontAttributeName:[UIFont fontWithMagicIdentifier:@"style.text.normal.font_spec"],
                                                                                          NSForegroundColorAttributeName:[UIColor accentColor] }];
    }
    else {
        self.subtitleLabel.text = @"";
    }
}

- (void)setShowConnectionButtons:(BOOL)showConnectionButtons
{
    _showConnectionButtons = showConnectionButtons;
}

#pragma mark - Actions

- (void)connect
{
    if (self.acceptBlock) {
        self.acceptBlock();
    }
}

- (void)ignore
{
    if (self.ignoreBlock) {
        self.ignoreBlock();
    }
}

@end
