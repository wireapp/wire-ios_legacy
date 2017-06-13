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


@import PureLayout;

#import "AudioHeaderView.h"
@import WireExtensionComponents;
#import "WAZUIMagicIOS.h"


@interface AudioHeaderView ()

@property (nonatomic) UIView *providerImageContainer;
@property (nonatomic) UILabel *artistLabel;
@property (nonatomic) UILabel *trackTitleLabel;
@property (nonatomic) ButtonWithLargerHitArea *providerButton;
@property (nonatomic) BOOL initialConstraintsCreated;

@property (nonatomic) NSLayoutConstraint *providerImageContainerWidthConstraint;
@end



@implementation AudioHeaderView

- (instancetype)init
{
    self = [super init];
    
    if (self) {
        self.artistLabel = [[UILabel alloc] initForAutoLayout];
        self.artistLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        [self addSubview:self.artistLabel];
        
        self.trackTitleLabel = [[UILabel alloc] initForAutoLayout];
        self.trackTitleLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
        [self addSubview:self.trackTitleLabel];
        
        self.providerImageContainer = [[UIView alloc] initForAutoLayout];
        [self addSubview:self.providerImageContainer];
        
        self.providerButton = [ButtonWithLargerHitArea buttonWithType:UIButtonTypeCustom];
        self.providerButton.translatesAutoresizingMaskIntoConstraints = NO;
        [self.providerImageContainer addSubview:self.providerButton];
    }
    
    return self;
}

- (void)updateConstraints
{
    if (! self.initialConstraintsCreated) {
        self.initialConstraintsCreated = YES;
        
        [self.providerButton autoCenterInSuperview];
        [self.providerButton autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self.artistLabel];
        [self.providerButton autoSetDimensionsToSize:CGSizeMake(28, 28)];
        
        [self.providerImageContainer autoPinEdgeToSuperviewEdge:ALEdgeBottom];
        [self.providerImageContainer autoPinEdgeToSuperviewEdge:ALEdgeLeft];
        [self.providerImageContainer autoPinEdgeToSuperviewMargin:ALEdgeTop];
        [self.providerImageContainer autoPinEdge:ALEdgeRight toEdge:ALEdgeLeft ofView:self.artistLabel];
        
        [self.artistLabel autoPinEdgeToSuperviewMargin:ALEdgeLeft];
        [self.artistLabel autoPinEdgeToSuperviewMargin:ALEdgeRight];
        
        [self.trackTitleLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.artistLabel];
        [self.trackTitleLabel autoPinEdgeToSuperviewMargin:ALEdgeLeft];
        [self.trackTitleLabel autoPinEdgeToSuperviewMargin:ALEdgeRight];
    }
    
    [super updateConstraints];
}

@end
