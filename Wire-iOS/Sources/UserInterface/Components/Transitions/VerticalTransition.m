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


#import "VerticalTransition.h"
#import "UIView+WR_ExtendedBlockAnimations.h"

@interface VerticalTransition ()

@property (nonatomic) CGFloat offset;

@end

@implementation VerticalTransition

- (id)initWithOffset:(CGFloat)offset
{
    self = [self init];
    
    if (self) {
        _offset = offset;
    }
    
    return self;
}

- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext
{
    return 0.55f;
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext
{
    UIView *fromView = [transitionContext viewForKey:UITransitionContextFromViewKey];
    UIView *toView = [transitionContext viewForKey:UITransitionContextToViewKey];
    UIView *containerView = [transitionContext containerView];
    
    toView.frame = [transitionContext finalFrameForViewController:[transitionContext viewControllerForKey:UITransitionContextToViewControllerKey]];
    fromView.frame = [transitionContext initialFrameForViewController:[transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey]];
    
    [containerView addSubview:toView];
    
    if (! [transitionContext isAnimated]) {
        [transitionContext completeTransition:YES];
        return;
    }
    
    CGRect finalRect = [transitionContext finalFrameForViewController:[transitionContext viewControllerForKey:UITransitionContextToViewControllerKey]];
    
    double sign = copysign(1.0f, self.offset);
    CGAffineTransform toTransfrom = CGAffineTransformMakeTranslation(0, -self.offset);
    CGAffineTransform fromTransform = CGAffineTransformMakeTranslation(0, sign * (finalRect.size.height - fabs(self.offset)));
    
    fromView.transform = fromTransform;
    toView.transform = toTransfrom;
    
    NSArray <UIView *> *viewsToHide = [self.dataSource viewsToHideDuringVerticalTransition:self];
    
    [viewsToHide enumerateObjectsUsingBlock:^(UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        obj.hidden = YES;
    }];
    
    [UIView wr_animateWithEasing:WREasingFunctionEaseOutExpo duration:[self transitionDuration:transitionContext] delay:0 animations:^{
        fromView.transform = CGAffineTransformMakeTranslation(0.0f, sign * finalRect.size.height);
        toView.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished) {
        fromView.transform = CGAffineTransformIdentity;
        [viewsToHide enumerateObjectsUsingBlock:^(UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            obj.hidden = NO;
        }];
        [transitionContext completeTransition:YES];
    }];
}

@end
