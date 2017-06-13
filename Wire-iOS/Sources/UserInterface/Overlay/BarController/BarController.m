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


@import PureLayout;

#import "BarController.h"



@interface BarController ()

@property (nonatomic, readonly) NSMutableArray *mutableBars;
@property (nonatomic) NSLayoutConstraint *topEdgeConstraint;
@property (nonatomic, copy) void (^barInCompletionBlock)(BOOL finished);
@property (nonatomic, copy) void (^barOutCompletionBlock)(BOOL finished);

@end



@implementation BarController

- (instancetype)init
{
    self = [super init];
    
    if (self) {
        _mutableBars = [[NSMutableArray alloc] init];
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.clipsToBounds = YES;
}

- (UIViewController *)topBar
{
    return self.mutableBars.firstObject;
}

- (NSArray *)bars
{
    return [self.mutableBars copy];
}

- (void)presentBar:(UIViewController *)viewController
{
    if (self.mutableBars.lastObject == viewController) {
        return; // Don't present already presented bar
    }
    
    // Add / move viewController to the top of the stack.
    [self.mutableBars removeObject:viewController];
    [self.mutableBars addObject:viewController];
    
    [self transitionToBarViewController:self.mutableBars.lastObject];
}

- (void)dismissBar:(UIViewController *)viewController
{
    [self.mutableBars removeObject:viewController];
    
    [self transitionToBarViewController:self.mutableBars.lastObject];
}

- (void)animateBarIn:(UIView *)bar withCompletion:(void(^)(BOOL finished))completion
{
    self.barInCompletionBlock = completion;
    self.topEdgeConstraint.constant = -bar.intrinsicContentSize.height;
    [self.view layoutIfNeeded];
    self.topEdgeConstraint.constant = 0;
    
    [UIView animateWithDuration:0.35 delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        [self.view layoutIfNeeded];
    } completion:^(BOOL finished) {
        if (self.barInCompletionBlock != nil) {
            self.barInCompletionBlock(YES);
            self.barInCompletionBlock = nil;
        }
    }];
}

- (void)animateBarOut:(UIView *)bar withCompletion:(void(^)(BOOL finished))completion
{
    self.barOutCompletionBlock = completion;
    self.topEdgeConstraint.constant = -bar.intrinsicContentSize.height;
    
    [UIView animateWithDuration:0.35 delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        [self.view layoutIfNeeded];
    } completion:^(BOOL finished) {
        if (self.barOutCompletionBlock != nil) {
            self.barOutCompletionBlock(YES);
            self.barOutCompletionBlock = nil;
        }
    }];
}

- (void)transitionToBarViewController:(UIViewController *)viewController
{
    [self transitionFromBarViewController:self.childViewControllers.firstObject toBarViewController:viewController];
}

- (void)transitionFromBarViewController:(UIViewController *)fromController toBarViewController:(UIViewController *)toController
{
    if (fromController == nil && toController == nil) {
        return;
    }
    
    if (fromController == nil) {
        [self addChildViewController:toController];
        [self.view addSubview:toController.view];
        [toController didMoveToParentViewController:self];
        
        [self installConstraintsForBar:toController.view];
        [self animateBarIn:toController.view withCompletion:nil];
    }
    else if (toController == nil) {
        [self animateBarOut:fromController.view withCompletion:^(BOOL finished) {
            [fromController willMoveToParentViewController:nil];
            [fromController.view removeFromSuperview];
            [fromController removeFromParentViewController];
        }];
    }
    else {
        @weakify(self);
        [self animateBarOut:fromController.view withCompletion:^(BOOL finished) {
            @strongify(self);
            [fromController willMoveToParentViewController:nil];
            [fromController.view removeFromSuperview];
            [fromController removeFromParentViewController];
            
            [self addChildViewController:toController];
            [self.view addSubview:toController.view];
            [toController didMoveToParentViewController:self];
            
            [self installConstraintsForBar:toController.view];
            [self animateBarIn:toController.view withCompletion:nil];
        }];
    }
}

- (void)installConstraintsForBar:(UIView *)bar
{
    [bar autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero excludingEdge:ALEdgeTop];
    self.topEdgeConstraint = [bar autoPinEdgeToSuperviewEdge:ALEdgeTop];
}

@end
