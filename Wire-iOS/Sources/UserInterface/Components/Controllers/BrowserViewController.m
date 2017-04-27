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


@import WebKit;

#import <PureLayout/PureLayout.h>
#import <Classy/Classy.h>

#import "BrowserViewController.h"
#import "BrowserBarView.h"
@import WireExtensionComponents;
#import "Wire-Swift.h"



@interface BrowserViewController ()

@property (nonatomic) WKWebView *webView;
@property (nonatomic) BrowserBarView *browserBarView;
@property (nonatomic) NSObject *estimatedProgressObserver;
@property (nonatomic) NSObject *titleObserver;
@property (nonatomic) BOOL useWithStatusBar;

@end

@implementation BrowserViewController

- (instancetype)initWithURL:(NSURL *)URL
{
    return [self initWithURL:URL forUseWithStatusBar:NO];
}

- (instancetype)initWithURL:(NSURL *)URL forUseWithStatusBar:(BOOL)statusBar
{
    self = [super initWithNibName:nil bundle:nil];
    
    if (self) {
        _URL = URL;
        _useWithStatusBar = statusBar;
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    WKWebViewConfiguration * configuration = [[WKWebViewConfiguration alloc] init];
    configuration.allowsInlineMediaPlayback = YES;
    configuration.mediaPlaybackRequiresUserAction = NO;
    
    self.webView = [[WKWebView alloc] initWithFrame:self.view.frame configuration:configuration];
    self.webView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.webView loadRequest:[NSURLRequest requestWithURL:self.URL]];
    [self.view addSubview:self.webView];
    
    self.browserBarView = [[BrowserBarView alloc] initForUseWithStatusBar:self.useWithStatusBar];
    self.browserBarView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.browserBarView];
    
    [self.browserBarView.shareButton addTarget:self action:@selector(openShareDialog:) forControlEvents:UIControlEventTouchUpInside];
    [self.browserBarView.closeButton addTarget:self action:@selector(dismiss:) forControlEvents:UIControlEventTouchUpInside];
    
    [self createInitialConstraints];
    
    self.estimatedProgressObserver =
    [KeyValueObserver observeObject:self.webView
                            keyPath:@"estimatedProgress"
                             target:self
                           selector:@selector(estimatedProgressChanged:)];
    
    self.titleObserver =
    [KeyValueObserver observeObject:self.webView
                            keyPath:@"title"
                             target:self
                           selector:@selector(titleChanged:)];
}

- (void)createInitialConstraints
{
    [self.browserBarView autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero excludingEdge:ALEdgeBottom];
    [self.browserBarView autoSetDimension:ALDimensionHeight toSize:64];
    
    [self.webView autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero excludingEdge:ALEdgeTop];
    [self.webView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.browserBarView];
}

#pragma mark - Actions

- (IBAction)dismiss:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)openShareDialog:(id)sender
{
    UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:@[self.URL] applicationActivities:nil];
    activityVC.modalPresentationStyle = UIModalPresentationPopover;
    
    [self presentViewController:activityVC animated:YES completion:nil];
    
    activityVC.popoverPresentationController.sourceView = self.browserBarView.shareButton;
    CGRect sourceRect = CGRectInset(self.browserBarView.shareButton.bounds, 0, -10);
    sourceRect.origin.x = CGRectGetMidX(self.browserBarView.shareButton.bounds) - 10;
    activityVC.popoverPresentationController.sourceRect = sourceRect;
}

#pragma mark - Observers

- (void)estimatedProgressChanged:(NSDictionary *)change
{
    self.browserBarView.progress = self.webView.estimatedProgress;
}

- (void)titleChanged:(NSDictionary *)change
{
    self.browserBarView.titleLabel.text = [self.webView.title uppercasedWithCurrentLocale];
}

@end
