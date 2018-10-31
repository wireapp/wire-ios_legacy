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


#import "MentionsCollectionViewController.h"
#import "WireSyncEngine+iOS.h"
#import "MentionsBubbleView.h"
#import "MentionsCollectionViewCell.h"
#import "MentionsCollectionView.h"
#import "Wire-Swift.h"

@import PureLayout;




MentionsCollectionViewCell *prototypeCell;

@interface MentionsCollectionViewController () <UICollectionViewDelegateFlowLayout>

@property (nonatomic, readwrite) MentionsBubbleView *mentionsBubbleView;
@property (nonatomic) MentionsCollectionView *mentionsCollectionView;

@end

@implementation MentionsCollectionViewController

static NSString * const reuseIdentifier = @"MentionsCell";

- (instancetype)init
{
    self = [super init];
    if (self) {
        
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            prototypeCell = [[MentionsCollectionViewCell alloc] initWithFrame:CGRectZero];
        });
    }
    return self;
}

#pragma mark - UICollectionViewDelegateFlowLayout

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section
{
    return 4;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    
    if (self.mentionedUsers.count == 1){
        
        ZMUser *user = (ZMUser *) self.mentionedUsers.allObjects.firstObject;
        
        prototypeCell.nameLabel.text = [user.displayName stringByReplacingOccurrencesOfString:@" " withString:@""];
    }
    
    CGFloat height =  32;
    
    CGFloat nameWidth = self.mentionedUsers.count == 1 ? [prototypeCell.nameLabel sizeThatFits:CGSizeMake(UIViewNoIntrinsicMetric, height)].width : 0;

    CGFloat width = self.mentionedUsers.count == 1 ? 32+ceil(nameWidth)+16 : 32;
    
    return  CGSizeMake(width, height);
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    NSInteger sections = self.mentionedUsers.count ? 1 : 0;
    return sections;
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.mentionedUsers.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    MentionsCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    
    ZMUser *user = [self.mentionedUsers allObjects][indexPath.row];
    cell.userImageView.user = user;
    
    cell.nameLabel.text = self.mentionedUsers.count == 1 ? [user.displayName uppercasedWithCurrentLocale] : nil;
    
    return cell;
}


- (MentionsBubbleView *)mentionsBubbleView
{
    
    if (_mentionsBubbleView == nil) {
    
        _mentionsBubbleView = [[MentionsBubbleView alloc] initForAutoLayout];
        _mentionsBubbleView.bubbleColor = [UIColor blackColor];
        _mentionsBubbleView.backgroundColor = [UIColor clearColor];
        
        [_mentionsBubbleView addSubview:self.mentionsCollectionView];
        [NSLayoutConstraint autoSetPriority:UILayoutPriorityDefaultHigh forConstraints:^{
            [self.mentionsCollectionView autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsMake(9, 8, 15, 8)];
        }];
    }
    
    return _mentionsBubbleView;
}

- (MentionsCollectionView *)mentionsCollectionView
{
    if (_mentionsCollectionView == nil) {
        
        UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
        flowLayout.minimumInteritemSpacing = 8;
        
        MentionsCollectionView * mentionsCollectionView = [[MentionsCollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:flowLayout];
        mentionsCollectionView.scrollEnabled = NO;
        mentionsCollectionView.backgroundColor = [UIColor clearColor];
        
        mentionsCollectionView.dataSource = self;
        mentionsCollectionView.delegate = self;
        
        [mentionsCollectionView registerClass:[MentionsCollectionViewCell class] forCellWithReuseIdentifier:reuseIdentifier];
        
        _mentionsCollectionView = mentionsCollectionView;
    }
    
    return _mentionsCollectionView;
}

- (void)setMentionedUsers:(NSSet *)mentionedUsers
{
    if ([mentionedUsers isEqualToSet:_mentionedUsers]){
        return;
    }
    
    _mentionedUsers = mentionedUsers;
    
    if (self.mentionedUsers.count == 0) {
        
        self.mentionsCollectionView.hidden = YES;
    }
    else {
        self.mentionsCollectionView.hidden = NO;
    }
    
    [self.mentionsCollectionView reloadData];
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    ZMUser *mentionedUser = [self.mentionedUsers allObjects][indexPath.row];
    
    [self.delegate didTapOnSuggestedUserForMention:mentionedUser];
}


- (void)presentFromRect:(CGRect)rect inView:(UIView *)view
{
    if (self.mentionedUsers.count == 1){
        
        prototypeCell.nameLabel.text = [((ZMUser *)self.mentionedUsers.allObjects[0]).displayName stringByReplacingOccurrencesOfString:@" " withString:@""];
    }
    
    NSInteger sections = self.mentionedUsers.count ? 1 : 0;

    CGPoint arrowOriginInBubbleSuperview = [self.mentionsBubbleView.superview convertPoint:rect.origin fromView:view];
    UIView *viewOfBottomConstraint = self.mentionsBubbleViewBottomConstraint.secondItem;
    CGPoint arrowOringInViewOfBottomConstraint = [viewOfBottomConstraint convertPoint:rect.origin fromView:view];
    CGFloat magicHeight = 32+16+8;
    CGFloat currentHeight = sections > 0 ? magicHeight : 0;
    CGFloat nameWidth = self.mentionedUsers.count == 1 ? [prototypeCell.nameLabel sizeThatFits:CGSizeMake(32, UIViewNoIntrinsicMetric)].width + 16 : 0;
    CGFloat widthWithName = self.mentionsCollectionView.intrinsicContentSize.width + nameWidth;
    
    CGFloat width = CGMin(ceil(widthWithName), 150);
    
    self.mentionsBubbleViewBottomConstraint.constant = arrowOringInViewOfBottomConstraint.y;
    self.mentionsBubbleViewLeftConstraint.constant = arrowOriginInBubbleSuperview.x-width/2;
    // width + insets from superview
    self.mentionsBubbleViewWidthConstraint.constant = width + 8 + 8;
    [self.mentionsBubbleView layoutIfNeeded];
    
    self.mentionsBubbleViewHeightConstraint.constant = currentHeight;

    [UIView wr_animateWithEasing:WREasingFunctionEaseOutQuart duration:0.2 animations:^{
        [self.mentionsBubbleView layoutIfNeeded];
        [self.mentionsCollectionView layoutIfNeeded];
    }];
}


@end
