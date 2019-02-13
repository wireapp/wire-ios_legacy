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


#import <UIKit/UIKit.h>


// Notification to close the open drawers in cells of @c SwipeMenuCollectionCell
FOUNDATION_EXTERN NSString * const SwipeMenuCollectionCellCloseDrawerNotification;
// SwipeMenuCollectionCellCloseDrawerNotification userInfo key to suggest which cells should not be closedSee @p mutuallyExclusiveSwipeIdentifier of @c SwipeMenuCollectionCell.
FOUNDATION_EXTERN NSString * const SwipeMenuCollectionCellIDToCloseKey;

@interface SwipeMenuCollectionCell : UICollectionViewCell

@property (nonatomic, assign) BOOL canOpenDrawer;
@property (nonatomic, assign) CGFloat overscrollFraction;
@property (nonatomic, assign) CGFloat visualDrawerOffset;
/// Controls how far (distance) the @c menuView is revealed per swipe gesture. Default CGFLOAT_MAX, means all the way
@property (nonatomic) CGFloat maxVisualDrawerOffset;
/// Disabled and enables the separator line on the left of the @c menuView
@property (nonatomic) BOOL separatorLineViewDisabled;

// If this is set to some value, all cells with the same value will close when another one
// with the same value opens
@property (nonatomic, copy) NSString *mutuallyExclusiveSwipeIdentifier;

/// Main view to add subviews to
@property (nonatomic, readonly) UIView *swipeView;

/// View to add menu items to
@property (nonatomic, readonly) UIView *menuView;

// @m called when cell's content is overscrolled by user to the side. General use case for dismissing the cell off the screen.
@property (nonatomic, copy) void (^overscrollAction)(SwipeMenuCollectionCell *cell);


- (CGFloat)drawerWidth;
- (void)setDrawerOpen:(BOOL)open animated:(BOOL)animated;
- (void)setVisualDrawerOffset:(CGFloat)visualDrawerOffset updateUI:(BOOL)doUpdate;

@end



@interface SwipeMenuCollectionCell (DrawerOverrides)

/// No need to call super, void implementation
- (void)drawerScrollingStarts;

/// No need to call super, void implementation
- (void)drawerScrollingEndedWithOffset:(CGFloat)offset;

@end
