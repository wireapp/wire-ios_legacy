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


#import "SwizzleTransition.h"
#import "UIView+WR_ExtendedBlockAnimations.h"

@implementation SwizzleTransition

- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext
{
    return 0.50f;
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext
{
    UIView *fromView = [transitionContext viewForKey:UITransitionContextFromViewKey];
    UIView *toView = [transitionContext viewForKey:UITransitionContextToViewKey];
    UIView *containerView = [transitionContext containerView];
    
    toView.frame = [transitionContext finalFrameForViewController:[transitionContext viewControllerForKey:UITransitionContextToViewControllerKey]];
    [containerView addSubview:toView];
    
    if (! [transitionContext isAnimated]) {
        [transitionContext completeTransition:YES];
        return;
    }
    [containerView setNeedsLayout];
    [containerView layoutIfNeeded];
    
    NSTimeInterval durationPhase1 = 0.0f;
    NSTimeInterval durationPhase2 = 0.0f;
    if (self.direction == SwizzleTransitionDirectionHorizontal) {
        toView.layer.transform = CATransform3DMakeTranslation(24.0f, 0.0f, 0.0f);
        durationPhase1 = 0.15f;
        durationPhase2 = 0.55f;
    }
    else {
        toView.layer.transform = CATransform3DMakeTranslation(0.0f, 48.0f, 0.0f);
        durationPhase1 = 0.10f;
        durationPhase2 = 0.30f;
    }
    toView.alpha = 0;
    
    [UIView wr_animateWithEasing:WREasingFunctionEaseInQuad duration:durationPhase1 delay:0 animations:^{
        fromView.alpha = 0;
        if (self.direction == SwizzleTransitionDirectionHorizontal) {
            fromView.layer.transform = CATransform3DMakeTranslation(48.0f, 0.0f, 0.0f);
        }
        else {
            fromView.layer.transform = CATransform3DMakeTranslation(0.0f, 48.0f, 0.0f);
        }
    } completion:^(BOOL finished) {
        [UIView wr_animateWithEasing:WREasingFunctionEaseOutQuad duration:durationPhase2 delay:0 animations:^{
            toView.layer.transform = CATransform3DIdentity;
            toView.alpha = 1;
        } completion:^(BOOL finished) {
            fromView.layer.transform = CATransform3DIdentity;
            [transitionContext completeTransition:YES];
        }];
    }];
}

@end
