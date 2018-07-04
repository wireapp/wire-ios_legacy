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


#import "CrossfadeTransition.h"
#import "UIView+WR_ExtendedBlockAnimations.h"

@interface CrossfadeTransition ()

@property (nonatomic) CGFloat duration;

@end

@implementation CrossfadeTransition

- (instancetype)init
{
    return [self initWithDuration:0.35];
}

- (instancetype)initWithDuration:(CGFloat)duration
{
    self = [super init];
    
    if (self) {
        _duration = duration;
    }
    
    return self;
}

- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext
{
    return self.duration;
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext
{
    UIView *fromView = [transitionContext viewForKey:UITransitionContextFromViewKey];
    UIView *toView = [transitionContext viewForKey:UITransitionContextToViewKey];
    UIView *containerView = [transitionContext containerView];
    
    toView.frame = [transitionContext finalFrameForViewController:[transitionContext viewControllerForKey:UITransitionContextToViewControllerKey]];
    [containerView addSubview:toView];
    
    if (! [transitionContext isAnimated] || self.duration == 0) {
        [transitionContext completeTransition:YES];
        return;
    }
    
    toView.alpha = 0;
    
    [UIView wr_animateWithEasing:WREasingFunctionEaseInOutQuad duration:self.duration delay:0 animations:^{
        fromView.alpha = 0;
        toView.alpha = 1;
    } completion:^(BOOL finished) {
        [transitionContext completeTransition:YES];
    }];
}

@end
