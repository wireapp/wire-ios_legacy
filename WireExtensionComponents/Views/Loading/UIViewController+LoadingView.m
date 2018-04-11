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

- (SpinnerSubtitleView *)spinnerView
{
   SpinnerSubtitleView *view = objc_getAssociatedObject(self, (__bridge const void *) (ActivityIndicatorKey));
    
    if (nil == view) {
        view = [[SpinnerSubtitleView alloc] init];
        view.translatesAutoresizingMaskIntoConstraints = NO;
        view.spinner.hidesWhenStopped = NO;
        [self setSpinnerView:view];
    }
    
    return view;
}

- (void)setSpinnerView:(SpinnerSubtitleView *)spinnerView
{
    objc_setAssociatedObject(self, (__bridge const void *) (ActivityIndicatorKey), spinnerView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
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
        self.spinnerView.hidden = NO;
        [self.spinnerView.spinner startAnimation:nil];
    }
    else {
        self.spinnerView.hidden = YES;
        [self.spinnerView.spinner stopAnimation:nil];
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
        [_loadingView addSubview:self.spinnerView];
        [self.spinnerView addConstraintsCenteringToView:_loadingView];

        self.loadingView = _loadingView;
    }

    return _loadingView;
}

- (void)setLoadingView:(UIView *)loadingView
{
    objc_setAssociatedObject(self, (__bridge void *) LoadingViewKey, loadingView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)indicateLoadingSuccessRemovingCheckmark:(BOOL)removingCheckmark completion:(dispatch_block_t)completion
{
    CheckAnimationView __block *checkView = nil;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        checkView = [[CheckAnimationView alloc] init];
        checkView.center = self.loadingView.center;
        [self.loadingView addSubview:checkView];
        checkView.alpha = 0;
        
        [UIView animateWithDuration:0.5f animations:^{
            checkView.alpha = 1;
        } completion:nil];
    });
    
    [UIView animateWithDuration:0.75f animations:^{
        self.spinnerView.spinner.alpha = 0;
        self.spinnerView.spinner.transform = CGAffineTransformMakeScale(0.01, 0.01);
    } completion:^(BOOL completed){
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (completion != nil) {
                completion();
            }
            if (removingCheckmark) {
                self.spinnerView.spinner.alpha = 1;
                self.spinnerView.spinner.transform = CGAffineTransformIdentity;
                [self setShowLoadingView:NO];
                [checkView removeFromSuperview];
            }
        });
    }];
}

@end
