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


#import "WebViewController.h"
@import WebKit;

@import WireExtensionComponents;
#import "WAZUIMagicIOS.h"
#import "UIColor+WAZExtensions.h"
#import "Constants.h"
#import "UIViewController+Orientation.h"
#import "UIImage+ZetaIconsNeue.h"
@import PureLayout;
#import "NSLayoutConstraint+Helpers.h"


@interface WebViewController () <WKNavigationDelegate>

@property (nonatomic, strong) ButtonWithLargerHitArea *closeButton;
@property (nonatomic, strong) UIView *closeButtonBg;
@property (nonatomic, readwrite) WKWebView *webView;

@end



@implementation WebViewController

+ (instancetype)webViewControllerWithURL:(NSURL *)URL
{
    WebViewController *webViewController = [self new];
    webViewController.URL = URL;
    return webViewController;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    self.webView = [[WKWebView alloc] initForAutoLayout];
    self.webView.navigationDelegate = self;
    self.webView.backgroundColor = [UIColor accentColor];
    self.webView.opaque = NO;
    [self.view addSubview:self.webView];

    [self.webView addConstraintsFittingToView:self.view];

    if (self.URL != nil) {
        [self.webView loadRequest:[NSURLRequest requestWithURL:self.URL]];
    }
    
    self.closeButton = [ButtonWithLargerHitArea buttonWithType:UIButtonTypeCustom];
    
    UIImage *cancelImage = [UIImage imageForIcon:ZetaIconTypeX iconSize:ZetaIconSizeSmall color:[UIColor colorWithMagicIdentifier:@"webcontroller.cancel_button_color"]];
    
    self.closeButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.closeButton.accessibilityIdentifier = @"WebViewCloseButton";
    [self.view insertSubview:self.closeButton aboveSubview:self.loadingView];
    
    [self.closeButton setImage:cancelImage forState:UIControlStateNormal];
    [self.closeButton addTarget:self action:@selector(closeButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    
    
    [self.closeButton addConstraintForTopMargin:21 relativeToView:self.view];
    [self.closeButton addConstraintForRightMargin:21 relativeToView:self.view];
    [self.closeButton addConstraintForWidth:cancelImage.size.width];
    [self.closeButton addConstraintForHeight:cancelImage.size.height];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return [self.class wr_supportedInterfaceOrientations];
}

#pragma mark - Accessors

- (void)setURL:(NSURL *)URL
{
    _URL = URL;
    [self.webView loadRequest:[NSURLRequest requestWithURL:self.URL]];
}

#pragma mark - Actions

- (void)closeButtonTapped:(UIButton *)button
{
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - WKNavigationDelegate

- (void)webView:(WKWebView *)webView didCommitNavigation:(WKNavigation *)navigation
{
    self.showLoadingView = YES;
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation
{
    self.showLoadingView = NO;
    
    self.closeButtonBg = [[UIView alloc] initWithFrame:CGRectZero];
    self.closeButtonBg.translatesAutoresizingMaskIntoConstraints = NO;
    self.closeButtonBg.layer.cornerRadius = [WAZUIMagic cgFloatForIdentifier:@"webcontroller.cancel_button_bgradius"]/2;
    self.closeButtonBg.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.88];
    [self.view insertSubview:self.closeButtonBg belowSubview:self.closeButton];
    
    [self.closeButtonBg addConstraintsForSize:CGSizeMake([WAZUIMagic cgFloatForIdentifier:@"webcontroller.cancel_button_bgradius"], [WAZUIMagic cgFloatForIdentifier:@"webcontroller.cancel_button_bgradius"])];
    [self.closeButtonBg addConstraintsCenteringToView:self.closeButton];
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
    if (!navigationAction.targetFrame.isMainFrame) {
        NSURL *targetURL = navigationAction.request.URL;
        UIApplication *application = UIApplication.sharedApplication;
        if ([application canOpenURL:targetURL]) {
            [application openURL:targetURL];
        }
    }

    decisionHandler(WKNavigationActionPolicyAllow);
}

@end
