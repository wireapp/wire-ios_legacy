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


#import "ParticipantsListCell.h"

#import <PureLayout/PureLayout.h>

#import "BadgeUserImageView.h"
#import "WAZUIMagicIOS.h"

#import "zmessaging+iOS.h"
#import <libkern/OSAtomic.h>

#import "UserImageView+Magic.h"



@interface ParticipantsListCell ()
{
    UIColor *_borderColor, *_selectedBorderColor;
}

@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (nonatomic, strong) UIColor *selectedBorderColor;
@property (nonatomic, strong) UIColor *badgeColor;

@property (nonatomic) CGFloat tileDiameter;
@property (nonatomic) CGFloat nameHeight;
@property (nonatomic) CGFloat nameTopMargin;

@property (weak, nonatomic) IBOutlet BadgeUserImageView *userImageView;

@property (readonly, nonatomic, copy) NSString *magicPrefix;

@end



@implementation ParticipantsListCell

- (id)init
{
    if (self = [super init]) {
        [self setup];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self addSubviews];
        [self setup];
    }
    return self;
}

- (void)addSubviews
{
    UILabel *nameLabel = [[UILabel alloc] init];
    nameLabel.textAlignment = NSTextAlignmentCenter;
    [self.contentView addSubview:nameLabel];
    self.nameLabel = nameLabel;

    BadgeUserImageView *userImageView = [[BadgeUserImageView alloc] initWithMagicPrefix:self.magicPrefix];
    self.userImageView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:userImageView];
    self.userImageView = userImageView;


    CGFloat imageViewSize = [WAZUIMagic cgFloatForIdentifier:@"participants.tile_image_diameter"];
    [self.userImageView autoSetDimensionsToSize:CGSizeMake(imageViewSize, imageViewSize)];
    [self.nameLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.userImageView withOffset:[WAZUIMagic cgFloatForIdentifier:@"participants.tile_name_vertical_spacing"]];
    [self.nameLabel autoPinEdge:ALEdgeLeft toEdge:ALEdgeLeft ofView:self.userImageView];
    [self.nameLabel autoPinEdge:ALEdgeRight toEdge:ALEdgeRight ofView:self.userImageView];
}

- (void)setup
{
    self.tileDiameter = [WAZUIMagic cgFloatForIdentifier:[self magicPathForKey:@"tile_image_diameter"]];
    self.nameHeight = [WAZUIMagic cgFloatForIdentifier:[self magicPathForKey:@"name_label_height"]];
    self.nameTopMargin = [WAZUIMagic cgFloatForIdentifier:[self magicPathForKey:@"tile_name_spacing"]];
    self.badgeColor = [UIColor colorWithMagicIdentifier:[self magicPathForKey:@"badge_icon_color"]];
    
    self.selectedBorderColor = [UIColor colorWithMagicIdentifier:[self magicPathForKey:@"selected_stroke_color"]];
    self.backgroundColor = [UIColor clearColor];

    self.userImageView.badgeColor = self.badgeColor;
}

- (void)awakeFromNib;
{
    [super awakeFromNib];
    [self setup];
}

- (NSString *)magicPathForKey:(NSString *)key;
{
    return [NSString stringWithFormat:@"%@.%@", self.magicPrefix, key];
}

- (NSString *)magicPrefix;
{
    return @"participants";
}

- (void)applyLayoutAttributes:(UICollectionViewLayoutAttributes *)layoutAttributes
{
    [super applyLayoutAttributes:layoutAttributes];

    // THe goal of this is that items need to fade through alpha=0 on iPad.
    // the layout attribtues are applied initially when the cell becomes visible.
    // so when cell is added to the view hierarchy, this gets run, and we set the initial alpha to 0
    // later alpha is managed by the scrollview delegate in participants.
    // without this, the initial alpha was always 1, and this looked like the most reasonable place to manage it.
    UICollectionView *sv = (UICollectionView *) self.superview;
    if ((layoutAttributes.frame.origin.x - sv.contentOffset.x) < 0) {
        self.alpha = 0;
    }
}

#pragma mark - Getters / setters

- (void)setRepresentedObject:(id)representedObject
{
    _representedObject = representedObject;
    
    if ([representedObject isKindOfClass:ZMUser.class]) {
        ZMUser *user = (ZMUser *)representedObject;
        self.userImageView.user = representedObject;
        self.nameLabel.text = [user.displayName uppercaseString];
    }
}

- (NSString *)name
{
    return self.nameLabel.text;
}

- (void)setName:(NSString *)name
{
    NSString *old = self.nameLabel.text;
    if ((old == name) || [old isEqualToString:name]) {
        return;
    }
    self.nameLabel.text = name;
}

@end
