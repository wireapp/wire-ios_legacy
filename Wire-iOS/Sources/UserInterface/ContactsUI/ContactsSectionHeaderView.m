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


#import "ContactsSectionHeaderView.h"
@import PureLayout;



NS_ASSUME_NONNULL_BEGIN
@interface ContactsSectionHeaderView ()
@property (nonatomic) NSLayoutConstraint *sectionTitleLeftConstraint;
@end
NS_ASSUME_NONNULL_END



@implementation ContactsSectionHeaderView

- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithReuseIdentifier:reuseIdentifier];
    
    if (self) {
        [self setupSubviews];
        [self setupConstraints];
    }
    
    return self;
}

- (void)setupSubviews
{
    self.height = 20.0f;
    self.textLabel.hidden = YES;
    self.titleLabel = [[UILabel alloc] initForAutoLayout];
    [self.contentView addSubview:self.titleLabel];
}

- (void)setupConstraints
{
    [self.titleLabel autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
    self.sectionTitleLeftConstraint = [self.titleLabel autoPinEdgeToSuperviewEdge:ALEdgeLeading
                                                                        withInset:24];
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    
    self.backgroundColor = [UIColor clearColor];
}

- (CGSize)intrinsicContentSize
{
    return CGSizeMake(UIViewNoIntrinsicMetric, self.height);
}

@end
