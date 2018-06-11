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


#import "UpsideDownTableView.h"

@implementation UpsideDownTableView

- (instancetype)initWithFrame:(CGRect)frame style:(UITableViewStyle)style
{
    self = [super initWithFrame:frame style:style];
    
    if (self) {
        [UIView performWithoutAnimation:^{
            self.transform = CGAffineTransformMakeScale(1, -1);
        }];
    }
    
    return self;
}

- (void)setCorrectedContentInset:(UIEdgeInsets)contentInset
{
    [super setContentInset:UIEdgeInsetsMake(contentInset.bottom, contentInset.left, contentInset.top, contentInset.right)];
}

- (UIEdgeInsets)correctedContentInset
{
    UIEdgeInsets insets = [super contentInset];
    return UIEdgeInsetsMake(insets.bottom, insets.left, insets.top, insets.right);
}
    
- (UIEdgeInsets)correctedScrollIndicatorInsets
{
    UIEdgeInsets insets = super.scrollIndicatorInsets;
    return UIEdgeInsetsMake(insets.bottom, insets.left, insets.top, insets.right);
}
    
- (void)setCorrectedScrollIndicatorInsets:(UIEdgeInsets)correctedScrollIndicatorInsets
{
    [super setScrollIndicatorInsets:UIEdgeInsetsMake(correctedScrollIndicatorInsets.bottom, correctedScrollIndicatorInsets.left, correctedScrollIndicatorInsets.top, correctedScrollIndicatorInsets.right)];
}

- (void)setTableHeaderView:(UIView *)tableHeaderView
{
    tableHeaderView.transform = CGAffineTransformMakeScale(1, -1);
    
    [super setTableFooterView:tableHeaderView];
}

- (UIView *)tableHeaderView
{
    return super.tableFooterView;
}

- (void)setTableFooterView:(UIView *)tableFooterView
{
    tableFooterView.transform = CGAffineTransformMakeScale(1, -1);
    
    [super setTableHeaderView:tableFooterView];
}

- (UIView *)tableFooterView
{
    return super.tableHeaderView;
}

- (id)dequeueReusableCellWithIdentifier:(NSString *)identifier
{
    UITableViewCell *cell = [super dequeueReusableCellWithIdentifier:identifier];
    
    cell.transform = CGAffineTransformMakeScale(1, -1);
    
    return cell;
}

- (void)scrollToNearestSelectedRowAtScrollPosition:(UITableViewScrollPosition)scrollPosition animated:(BOOL)animated
{
    [super scrollToNearestSelectedRowAtScrollPosition:[self inverseScrollPosition:scrollPosition] animated:animated];
}

- (void)scrollToRowAtIndexPath:(NSIndexPath *)indexPath atScrollPosition:(UITableViewScrollPosition)scrollPosition animated:(BOOL)animated
{
    [super scrollToRowAtIndexPath:indexPath atScrollPosition:[self inverseScrollPosition:scrollPosition] animated:animated];
}

- (id)dequeueReusableCellWithIdentifier:(NSString *)identifier forIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [super dequeueReusableCellWithIdentifier:identifier forIndexPath:indexPath];
    
    cell.transform = CGAffineTransformMakeScale(1, -1);
    
    return cell;
}

- (UITableViewScrollPosition)inverseScrollPosition:(UITableViewScrollPosition)scrollPosition
{
    if (scrollPosition == UITableViewScrollPositionTop) {
        return UITableViewScrollPositionBottom;
    }
    else if (scrollPosition == UITableViewScrollPositionBottom) {
        return UITableViewScrollPositionTop;
    }
    else {
        return scrollPosition;
    }
}

@end
