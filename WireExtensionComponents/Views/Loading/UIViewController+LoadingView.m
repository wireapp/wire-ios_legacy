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


#import "UIViewController+LoadingView.h"

#import <objc/runtime.h>
#import "ProgressSpinner.h"
#import "NSLayoutConstraint+Helpers.h"
#import <WireExtensionComponents/WireExtensionComponents-Swift.h>

const NSString *ActivityIndicatorKey = @"activityIndicator";
const NSString *LoadingViewKey = @"loadingView";



@implementation UIViewController (LoadingView)

- (UIActivityIndicatorView *)activityIndicator
{
    return objc_getAssociatedObject(self, (__bridge const void *) (ActivityIndicatorKey));
}

- (void)setActivityIndicator:(UIActivityIndicatorView *)activityIndicator
{
    objc_setAssociatedObject(self, (__bridge const void *) (ActivityIndicatorKey), activityIndicator, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)showLoadingView
{
    UIView *_loadingView = objc_getAssociatedObject(self, (__bridge void *) LoadingViewKey);
    return ! _loadingView.hidden;
}

- (void)setShowLoadingView:(BOOL)shouldShow
{
    self.loadingView.hidden = ! shouldShow;
    if (shouldShow) {
        self.activityIndicator.hidden = NO;
        [self.activityIndicator startAnimation:nil];
    }
    else {
        self.activityIndicator.hidden = YES;
        [self.activityIndicator stopAnimation:nil];
    }
}

- (UIView *)loadingView
{
    UIView *_loadingView = objc_getAssociatedObject(self, (__bridge void *) LoadingViewKey);

    if (nil == _loadingView) {
        _loadingView = [[UIView alloc] init];
        [self.view addSubview:_loadingView];

        _loadingView.hidden = YES;
        _loadingView.translatesAutoresizingMaskIntoConstraints = NO;
        _loadingView.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.5f];
        [_loadingView addConstraintsFittingToView:self.view];

        self.activityIndicator = [[ProgressSpinner alloc] init];
        self.activityIndicator.translatesAutoresizingMaskIntoConstraints = NO;
        self.activityIndicator.hidesWhenStopped = NO;
        [_loadingView addSubview:self.activityIndicator];
        [self.activityIndicator addConstraintsCenteringToView:_loadingView];

        self.loadingView = _loadingView;
    }

    return _loadingView;
}

- (void)setLoadingView:(UIView *)loadingView
{
    objc_setAssociatedObject(self, (__bridge void *) LoadingViewKey, loadingView, 
    OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)indicateLoadingSuccessWithCompletion:(dispatch_block_t)completion
{
    CheckAnimationView *checkView = [[CheckAnimationView alloc] init];
    checkView.alpha = 0;
    checkView.center = self.loadingView.center;
    [self.loadingView addSubview:checkView];
    
    [UIView animateWithDuration:1 animations:^{
        self.activityIndicator.alpha = 0;
        checkView.alpha = 1;
    } completion:^(BOOL completed){
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (completion != nil) {
                completion();
            }
            self.activityIndicator.alpha = 1;
            [self setShowLoadingView:NO];
            [checkView removeFromSuperview];
        });
    }];
}

@end
