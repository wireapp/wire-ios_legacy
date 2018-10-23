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


#import "MentionsCollectionViewCell.h"
@import PureLayout;
#import "WireSyncEngine+iOS.h"
#import "Wire-Swift.h"

@interface MentionsLabel : UILabel

@end


@implementation MentionsLabel

- (void)drawTextInRect:(CGRect)rect {
    UIEdgeInsets insets = {0, 4, 0, 0};
    [super drawTextInRect:UIEdgeInsetsInsetRect(rect, insets)];
}

@end


@interface MentionsCollectionViewCell ()

@property (nonatomic) BOOL initialConstraintsCreated;

@end

@implementation MentionsCollectionViewCell

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self) {
        
        self.contentView.translatesAutoresizingMaskIntoConstraints = NO;
        [self createUserImageView];
        [self createNameLabel];
        
        [self setNeedsUpdateConstraints];
    }
    
    return self;
}

-(void)createUserImageView
{
    self.userImageView = [[UserImageView alloc] init];
    self.userImageView.initialsFont = [UIFont systemFontOfSize:11 weight:UIFontWeightLight];
    self.userImageView.userSession = [ZMUserSession sharedSession];
    self.userImageView.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.contentView addSubview:self.userImageView];
}

- (void)createNameLabel
{
    self.nameLabel = [[MentionsLabel alloc] initForAutoLayout];
    self.nameLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    self.nameLabel.textColor = [UIColor whiteColor];
    self.nameLabel.font = UIFont.smallMediumFont;
    self.nameLabel.textAlignment = NSTextAlignmentCenter;
    
    [self.contentView addSubview:self.nameLabel];
}

- (void)updateConstraints
{
    if (! self.initialConstraintsCreated) {
        
        [self.contentView autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero];
        [self.userImageView autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero excludingEdge:ALEdgeRight];
        [self.nameLabel autoPinEdge:ALEdgeLeft toEdge:ALEdgeRight ofView:self.userImageView withOffset:0];
        [self.userImageView autoSetDimension:ALDimensionWidth toSize:32];
        [self.nameLabel autoPinEdgeToSuperviewEdge:ALEdgeRight];
        [self.nameLabel autoAlignAxis:ALAxisHorizontal toSameAxisOfView:self.userImageView];
        
        
        self.initialConstraintsCreated = YES;
    }
    
    [super updateConstraints];
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    
    self.userImageView.user = nil;
    self.nameLabel.text = nil;
}

@end
