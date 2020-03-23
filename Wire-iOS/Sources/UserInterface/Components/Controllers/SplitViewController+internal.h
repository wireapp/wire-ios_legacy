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

@property (nonatomic) NSLayoutConstraint *leftViewLeadingConstraint;
@property (nonatomic) NSLayoutConstraint *rightViewLeadingConstraint;

@property (nonatomic) NSLayoutConstraint *leftViewWidthConstraint;
@property (nonatomic) NSLayoutConstraint *rightViewWidthConstraint;

@property (nonatomic) NSLayoutConstraint *sideBySideConstraint;
@property (nonatomic) NSLayoutConstraint *pinLeftViewOffsetConstraint;

@property (nonatomic) SplitViewControllerLayoutSize layoutSize;

- (void)setInternalLeftViewController:(nullable UIViewController *)leftViewController;
- (void)updateConstraintsForSize:(CGSize)size;
- (NSArray *)constraintsInactiveForCurrentLayout;
- (NSArray *)constraintsActiveForCurrentLayout;
- (void)updateLeftViewVisibility;
- (void)updateForSize:(CGSize)size;
- (void)updateLayoutSizeAndLeftViewVisibility;

@end

@interface SplitViewController ()

@property (nonatomic) UIPanGestureRecognizer *horizontalPanner;

@property (nonatomic) UITraitCollection *futureTraitCollection;

@end


@interface SplitViewControllerTransitionContext : NSObject <UIViewControllerContextTransitioning>

@property (nonatomic, copy) void (^completionBlock)(BOOL didComplete);
@property (nonatomic, getter=isAnimated) BOOL animated;
@property (nonatomic, getter=isInteractive) BOOL interactive;

- (instancetype)initWithFromViewController:(UIViewController *)fromViewController toViewController:(UIViewController *)toViewController containerView:(UIView *)containerView;

@end



@interface SplitViewControllerTransitionContext ()

@property (nonatomic) NSDictionary *viewControllers;
@property (nonatomic) UIView *containerView;
@property (nonatomic) UIModalPresentationStyle presentationStyle;

@end
