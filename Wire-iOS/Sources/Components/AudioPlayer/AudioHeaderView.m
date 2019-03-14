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


#import "AudioHeaderView.h"
#import "AudioHeaderView+Internal.h"
#import "Wire-Swift.h"



@implementation AudioHeaderView

- (instancetype)init
{
    self = [super init];
    
    if (self) {
        self.artistLabel = [[UILabel alloc] init];
        self.artistLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        self.artistLabel.textColor = [UIColor wr_colorFromColorScheme:ColorSchemeColorTextForeground variant:ColorSchemeVariantDark];
        self.artistLabel.font = UIFont.smallLightFont;

        self.trackTitleLabel = [[UILabel alloc] init];
        self.trackTitleLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
        self.trackTitleLabel.textColor = [UIColor wr_colorFromColorScheme:ColorSchemeColorTextForeground variant:ColorSchemeVariantDark];
        self.trackTitleLabel.font = UIFont.smallSemiboldFont;

        self.providerImageContainer = [[UIView alloc] init];
        [self addSubview:self.providerImageContainer];
        
        self.providerButton = [ButtonWithLargerHitArea buttonWithType:UIButtonTypeCustom];
        self.providerButton.translatesAutoresizingMaskIntoConstraints = NO;
        [self.providerImageContainer addSubview:self.providerButton];

        self.textStackView = [[UIStackView alloc] initWithArrangedSubviews:@[self.artistLabel, self.trackTitleLabel]];
        self.textStackView.axis = UILayoutConstraintAxisVertical;
        [self addSubview:self.textStackView];

        [self configureConstraints];
    }
    
    return self;
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    [super traitCollectionDidChange:previousTraitCollection];
    self.providerImageContainerWidthConstraint.constant = UIView.conversationLayoutMargins.left;
    self.textTrailingConstraint.constant = -UIView.conversationLayoutMargins.right;
}

@end
