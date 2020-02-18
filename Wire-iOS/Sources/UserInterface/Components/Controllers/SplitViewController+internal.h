////
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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

typedef NS_ENUM(NSInteger, SplitViewControllerTransition) {
    SplitViewControllerTransitionDefault,
    SplitViewControllerTransitionPresent,
    SplitViewControllerTransitionDismiss
};

@interface SplitViewController ()

@property (nonatomic) UIView *leftView;
@property (nonatomic) UIView *rightView;

@property (nonatomic) CGFloat openPercentage;

@property (nonatomic) NSLayoutConstraint *leftViewOffsetConstraint;
@property (nonatomic) NSLayoutConstraint *rightViewOffsetConstraint;

@property (nonatomic) NSLayoutConstraint *leftViewWidthConstraint;
@property (nonatomic) NSLayoutConstraint *rightViewWidthConstraint;

@property (nonatomic) NSLayoutConstraint *sideBySideConstraint;
@property (nonatomic) NSLayoutConstraint *pinLeftViewOffsetConstraint;

@property (nonatomic) SplitViewControllerLayoutSize layoutSize;

- (void)resetOpenPercentage;

- (NSArray *)constraintsInactiveForCurrentLayout;
- (NSArray *)constraintsActiveForCurrentLayout;

- (BOOL)transitionFromViewController:(UIViewController *)fromViewController
                    toViewController:(UIViewController *)toViewController
                       containerView:(UIView *)containerView
                            animator:(id<UIViewControllerAnimatedTransitioning>)animator
                            animated:(BOOL)animated
                          completion:(nullable dispatch_block_t)completion;

@end
