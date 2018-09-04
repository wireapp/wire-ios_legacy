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


#import "KeyboardAvoidingViewController.h"
#import "KeyboardAvoidingViewController+Internal.h"

@import PureLayout;

#import "UIView+Zeta.h"
#import "Constants.h"
#import "KeyboardFrameObserver+iOS.h"
#import "Wire-Swift.h"



@interface KeyboardAvoidingViewController ()

@property (nonatomic, readwrite) UIViewController *viewController;
@property (nonatomic) NSLayoutConstraint *topEdgeConstraint;

@end



@implementation KeyboardAvoidingViewController

+ (void)load
{
    @autoreleasepool {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            [KeyboardFrameObserver sharedObserver];
        });
    }
}

- (instancetype)initWithViewController:(UIViewController *)viewController
{
    self = [super initWithNibName:nil bundle:nil];
    
    if (self) {
        self.viewController = viewController;

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(keyboardFrameWillChange:)
                                                     name:UIKeyboardWillChangeFrameNotification
                                                   object:nil];
    }
    
    return self;
}

- (BOOL)shouldAutorotate
{
    return [self.viewController shouldAutorotate];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return [self.viewController supportedInterfaceOrientations];
}

- (UINavigationItem *)navigationItem
{
    return [self.viewController navigationItem];
}

- (BOOL)prefersStatusBarHidden
{
    return self.viewController.prefersStatusBarHidden;
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return self.viewController.preferredStatusBarStyle;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.opaque = NO;
    [self addChildViewController:self.viewController];
    [self.view addSubview:self.viewController.view];
    self.viewController.view.translatesAutoresizingMaskIntoConstraints = NO;
    [self.viewController didMoveToParentViewController:self];
    
    [self createInitialConstraints];
}

- (void)createInitialConstraints
{
    [self.viewController.view autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:0];
    [self.viewController.view autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:0];
    self.topEdgeConstraint = [self.viewController.view autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:self.topInset];
    
    self.bottomEdgeConstraint = [self.viewController.bottomLayoutGuide.bottomAnchor constraintEqualToAnchor:self.bottomLayoutGuide.bottomAnchor constant:0];
    [self.bottomEdgeConstraint setActive:YES];
}

- (void)setTopInset:(CGFloat)topInset
{
    _topInset = topInset;
    self.topEdgeConstraint.constant = topInset;
    [self.view setNeedsLayout];
}

- (NSString *)title
{
    return self.viewController.title;
}

@end
