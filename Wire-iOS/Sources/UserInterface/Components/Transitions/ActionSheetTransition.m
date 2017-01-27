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


#import "ActionSheetTransition.h"
#import "ActionSheetContainerView.h"
#import "UIView+WR_ExtendedBlockAnimations.h"

@interface ActionSheetTransition ()

@property (nonatomic, weak) ActionSheetContainerView *actionSheetContainerView;
@property (nonatomic) BOOL reverse;

@end

@implementation ActionSheetTransition

- (instancetype)initWithActionSheetContainerView:(ActionSheetContainerView *)actionSheetContainerView reverse:(BOOL)reverse
{
    self = [super init];
    
    if (self) {
        self.actionSheetContainerView = actionSheetContainerView;
        self.reverse = reverse;
    }
    
    return self;
}

- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext
{
    return 0.90f;
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext
{
    UIView *toView = [transitionContext viewForKey:UITransitionContextToViewKey];
    UIView *containerView = [transitionContext containerView];
    
    toView.frame = [transitionContext finalFrameForViewController:[transitionContext viewControllerForKey:UITransitionContextToViewControllerKey]];
    [containerView addSubview:toView];
    
    if (! [transitionContext isAnimated]) {
        [transitionContext completeTransition:YES];
        return;
    }
    
    [toView layoutIfNeeded];
    
    CGAffineTransform offscreenSheet = CGAffineTransformMakeTranslation(0, self.actionSheetContainerView.bounds.size.height - self.actionSheetContainerView.sheetView.frame.origin.y);
    
    if (self.reverse) {
        [UIView wr_animateWithEasing:RBBEasingFunctionEaseInExpo duration:0.35 delay:0 animations:^{
            self.actionSheetContainerView.sheetView.transform = offscreenSheet;
            self.actionSheetContainerView.topContainerView.alpha = 0;
        } completion:^(BOOL finished) {
            
            [UIView animateWithDuration:0.35 animations:^{
                self.actionSheetContainerView.blurEffectView.effect = nil;
                self.actionSheetContainerView.sheetView.alpha = 0;
            } completion:^(BOOL finished) {
                [transitionContext completeTransition:YES];
            }];
        }];
    } else {
        self.actionSheetContainerView.blurEffectView.effect = nil;
        self.actionSheetContainerView.sheetView.alpha = 0;
        self.actionSheetContainerView.topContainerView.alpha = 0;
        self.actionSheetContainerView.sheetView.transform = offscreenSheet;
        
        [UIView animateWithDuration:0.35 animations:^{
            self.actionSheetContainerView.sheetView.alpha = 1;
            self.actionSheetContainerView.blurEffectView.effect = self.actionSheetContainerView.blurEffect;
        } completion:^(BOOL finished) {
            [UIView wr_animateWithEasing:RBBEasingFunctionEaseOutExpo duration:0.55 delay:0 animations:^{
                self.actionSheetContainerView.sheetView.transform = CGAffineTransformIdentity;
                self.actionSheetContainerView.topContainerView.alpha = 1;
            } completion:^(BOOL finished) {
                [transitionContext completeTransition:YES];
            }];
        }];
    }
}

@end
