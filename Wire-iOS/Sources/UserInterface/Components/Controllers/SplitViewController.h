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


@class SplitViewController;

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, SplitViewControllerLayoutSize) {
    SplitViewControllerLayoutSizeCompact,
    SplitViewControllerLayoutSizeRegularPortrait,
    SplitViewControllerLayoutSizeRegularLandscape
};

@protocol SplitLayoutObservable <NSObject>
@property (nonatomic, readonly) SplitViewControllerLayoutSize layoutSize;
@property (nonatomic, readonly) CGFloat leftViewControllerWidth;
@end

FOUNDATION_EXPORT NSString *SplitLayoutObservableDidChangeToLayoutSizeNotification;

@protocol SplitViewControllerDelegate <NSObject>
- (BOOL)splitViewControllerShouldMoveLeftViewController:(SplitViewController *)splitViewController;
@end


@interface UIViewController (SplitViewController)
@property (nonatomic, readonly, nullable) SplitViewController *wr_splitViewController;
@end



@interface SplitViewController : UIViewController <SplitLayoutObservable>
@property (nonatomic, nullable) UIViewController *leftViewController;
@property (nonatomic, nullable) UIViewController *rightViewController;

@property (nonatomic, getter=isLeftViewControllerRevealed) BOOL leftViewControllerRevealed;

@property (nonatomic, weak, nullable) id<SplitViewControllerDelegate> delegate;

- (void)setLeftViewController:(nullable UIViewController *)leftViewController animated:(BOOL)animated completion:(nullable dispatch_block_t)completion;
- (void)setRightViewController:(nullable UIViewController *)rightViewController animated:(BOOL)animated completion:(nullable dispatch_block_t)completion;
- (void)setLeftViewControllerRevealed:(BOOL)leftViewControllerIsRevealed animated:(BOOL)animated completion:(nullable dispatch_block_t)completion;
@end

NS_ASSUME_NONNULL_END
