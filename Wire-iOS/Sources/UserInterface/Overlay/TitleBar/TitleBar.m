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
#import <Classy/Classy.h>

#import "TitleBar.h"
#import "WAZUIMagicIOS.h"



@interface TitleBar ()

@property (nonatomic) UILabel *titleLabel;
@property (nonatomic) UIView *bottomSeparatorLine;
@property (nonatomic) BOOL initialConstraintsCreated;

@end



@implementation TitleBar

- (instancetype)init
{
    self = [super init];

    if (self) {
        [self createTitleLabel];
        [self createBottomSeparatorLine];
    }

    return self;
}

- (void)createTitleLabel
{
    self.titleLabel = [[UILabel alloc] initForAutoLayout];
    self.titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    
    [self addSubview:self.titleLabel];
}

- (void)createBottomSeparatorLine
{
    self.bottomSeparatorLine = [[UIView alloc] init];
    self.bottomSeparatorLine.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self addSubview:self.bottomSeparatorLine];
}

- (void)updateConstraints
{
    if (! self.initialConstraintsCreated) {
        self.initialConstraintsCreated = YES;
        
        [self.titleLabel autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:30];
        [self.titleLabel autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:30];
        [self.titleLabel autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
        
        [self.bottomSeparatorLine autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero excludingEdge:ALEdgeTop];
        [self.bottomSeparatorLine autoSetDimension:ALDimensionHeight toSize:0.5f];
    }
    
    [super updateConstraints];
}

- (CGSize)intrinsicContentSize
{
    CGFloat statusBarHeight = [UIApplication sharedApplication].statusBarFrame.size.height;
    CGFloat titleBarHeight = [WAZUIMagic floatForIdentifier:@"title_bar.height"] + statusBarHeight;
    return CGSizeMake(UIViewNoIntrinsicMetric, titleBarHeight);
}

@end
