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
#import "Wire-Swift.h"

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
        UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, NSLocalizedString(@"general.loading", @""));
        self.spinnerView.hidden = NO;
        self.view.userInteractionEnabled = NO;
        [self.spinnerView.spinner startAnimation];
    }
    else {
        self.spinnerView.hidden = YES;
        self.view.userInteractionEnabled = YES;
        [self.spinnerView.spinner stopAnimation];
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
        [_loadingView addSubview:self.spinnerView];

        [self createConstraintsWithLoadingView:_loadingView spinnerView:self.spinnerView];

        self.loadingView = _loadingView;
    }

    return _loadingView;
}

- (void)setLoadingView:(UIView *)loadingView
{
    objc_setAssociatedObject(self, (__bridge void *) LoadingViewKey, loadingView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
