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


#import "SplitViewController.h"
#import "SplitViewController+internal.h"
#import "Wire-Swift.h"

NSString *SplitLayoutObservableDidChangeToLayoutSizeNotification = @"SplitLayoutObservableDidChangeToLayoutSizeNotificationName";


@implementation SplitViewController


- (void)updateConstraintsForSize:(CGSize)size {
    [self updateConstraintsForSize:size willMoveToEmptyView:NO];
}

- (CGFloat)leftViewControllerWidth
{
    return self.leftViewWidthConstraint.constant;
}

- (void)setLayoutSize:(SplitViewControllerLayoutSize)layoutSize
{
    if (_layoutSize != layoutSize) {
        _layoutSize = layoutSize;
        [[NSNotificationCenter defaultCenter] postNotificationName:SplitLayoutObservableDidChangeToLayoutSizeNotification object:self];
    }
}

- (void)setInternalLeftViewController:(nullable UIViewController *)leftViewController {
    _leftViewController = leftViewController;
}

- (void)setLeftViewController:(nullable UIViewController *)leftViewController
{
    [self setLeftViewController:leftViewController animated:NO completion:nil];
}

- (void)setLeftViewController:(nullable UIViewController *)leftViewController animated:(BOOL)animated completion:(nullable dispatch_block_t)completion
{
    [self setLeftViewController:leftViewController animated:animated transition:SplitViewControllerTransitionDefault completion:completion];
}

- (void)setRightViewController:(nullable UIViewController *)rightViewController
{
    [self setRightViewController:rightViewController animated:NO completion:nil];
}

- (void)setRightViewController:(nullable UIViewController *)rightViewController animated:(BOOL)animated completion:(nullable dispatch_block_t)completion
{
    if (self.rightViewController == rightViewController) {
        return;
    }
    
    // To determine if self.rightViewController.presentedViewController is actually presented over it, or is it
    // presented over one of it's parents.
    if (self.rightViewController.presentedViewController.presentingViewController == self.rightViewController) {
        [self.rightViewController dismissViewControllerAnimated:NO completion:nil];
    }
    
    UIViewController *removedViewController = self.rightViewController;
    
    BOOL transitionDidStart =
    [self transitionFromViewController:removedViewController
                      toViewController:rightViewController
                         containerView:self.rightView
                              animator:[self animatorForRightView]
                              animated:animated
                            completion:completion];
    
    if (transitionDidStart) {
        _rightViewController = rightViewController;
    }
}


- (void)setInternalLeftViewControllerRevealed:(BOOL)leftViewControllerIsRevealed
{
    _leftViewControllerRevealed = leftViewControllerIsRevealed;
}

- (void)setLeftViewControllerRevealed:(BOOL)leftViewControllerIsRevealed
{
    _leftViewControllerRevealed = leftViewControllerIsRevealed;
    [self updateLeftViewControllerVisibilityAnimated:YES completion:nil];
}

- (void)setLeftViewControllerRevealed:(BOOL)leftViewControllerRevealed animated:(BOOL)animated completion:(nullable dispatch_block_t)completion
{
    _leftViewControllerRevealed = leftViewControllerRevealed;
    [self updateLeftViewControllerVisibilityAnimated:animated completion:completion];
}

- (void)setOpenPercentage:(CGFloat)percentage
{
    _openPercentage = percentage;
    [self updateRightAndLeftEdgeConstraints: percentage];
    
    [self setNeedsStatusBarAppearanceUpdate];
}


@end
