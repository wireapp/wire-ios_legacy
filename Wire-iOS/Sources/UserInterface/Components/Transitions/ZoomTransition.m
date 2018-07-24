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


#import "ZoomTransition.h"
#import "UIView+WR_ExtendedBlockAnimations.h"

@interface ZoomTransition ()

@property (nonatomic) CGPoint interactionPoint;
@property (nonatomic) BOOL reversed;

@end

@implementation ZoomTransition

- (instancetype)initWithInteractionPoint:(CGPoint)interactionPoint reversed:(BOOL)reversed
{
    self = [super init];
    
    if (self) {
        _interactionPoint = interactionPoint;
        _reversed = reversed;
    }
    
    return self;
}

- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext
{
    return 0.65f;
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
    
    [toView layoutIfNeeded];
    
    if (self.reversed) {
        fromView.alpha = 1.0f;
        fromView.layer.needsDisplayOnBoundsChange = NO;
        
        [UIView wr_animateWithEasing:WREasingFunctionEaseInExpo duration:0.35 animations:^{
            fromView.alpha = 0.0f;
            fromView.transform = CGAffineTransformMakeScale(0.5f, 0.5f);
        } completion:^(BOOL finished) {
            fromView.transform = CGAffineTransformIdentity;
        }];
        
        toView.alpha = 0;
        toView.transform = CGAffineTransformMakeScale(2.0f, 2.0f);
        
        
        [UIView wr_animateWithEasing:WREasingFunctionEaseOutExpo duration:0.35 delay:0.3 animations:^{
            toView.alpha = 1;
            toView.transform = CGAffineTransformIdentity;
        } completion:^(BOOL finished) {
            [transitionContext completeTransition:YES];
        }];
    } else {
        fromView.alpha = 1.0f;
        fromView.layer.needsDisplayOnBoundsChange = NO;
        
        CGRect frame = fromView.frame;
        fromView.layer.anchorPoint = self.interactionPoint;
        fromView.frame = frame;
        
        [UIView wr_animateWithEasing:WREasingFunctionEaseInExpo duration:0.35 animations:^{
            fromView.alpha = 0.0f;
            fromView.transform = CGAffineTransformMakeScale(2.0f, 2.0f);
        } completion:^(BOOL finished) {
            fromView.transform = CGAffineTransformIdentity;
        }];
        
        frame = toView.frame;
        toView.layer.anchorPoint = self.interactionPoint;
        toView.frame = frame;
        
        toView.alpha = 0;
        toView.transform = CGAffineTransformMakeScale(0.5, 0.5);
        
        
        [UIView wr_animateWithEasing:WREasingFunctionEaseOutExpo duration:0.35 delay:0.3 animations:^{
            toView.alpha = 1;
            toView.transform = CGAffineTransformIdentity;
        } completion:^(BOOL finished) {
            [transitionContext completeTransition:YES];
        }];
    }
}

@end
