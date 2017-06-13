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


#import "RegistrationFormController.h"

@import PureLayout;

#import "Constants.h"



@interface RegistrationFormController ()

@property (nonatomic, readwrite) UIViewController *viewController;

@end


@implementation RegistrationFormController

+ (instancetype)registrationFormControllerWithViewController:(UIViewController *)viewController
{
    return [[self alloc] initWithViewController:viewController];
}

- (instancetype)initWithViewController:(UIViewController *)viewController
{
    self = [super initWithNibName:nil bundle:nil];
    
    if (self) {
        self.viewController = viewController;
    }
    
    return self;
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
    if (IS_IPAD) {
        
        [NSLayoutConstraint autoSetPriority:UILayoutPriorityDefaultHigh + 1 forConstraints:^{
            [self.viewController.view autoSetDimension:ALDimensionWidth toSize:self.viewController.maximumFormSize.width];
            [self.viewController.view autoSetDimension:ALDimensionHeight toSize:self.viewController.maximumFormSize.height];
        }];
        
        [NSLayoutConstraint autoSetPriority:UILayoutPriorityDefaultHigh - 1 forConstraints:^{
            [self.viewController.view autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero];
        }];
        
        [self.viewController.view autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:0 relation:NSLayoutRelationGreaterThanOrEqual];
        [self.viewController.view autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:0 relation:NSLayoutRelationGreaterThanOrEqual];
        
        [self.viewController.view autoCenterInSuperview];
    } else {
        [self.viewController.view autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero];
    }
}

- (NSString *)title
{
    return self.viewController.title;
}

@end



@implementation UIViewController (RegistrationFormController)

- (CGSize)maximumFormSize
{
    return CGSizeMake(414, 736);
}

- (RegistrationFormController *)registrationFormViewController
{
    return [[RegistrationFormController alloc] initWithViewController:self];
}

- (UIViewController *)registrationFormUnwrappedController
{
    if ([self isKindOfClass:[RegistrationFormController class]]) {
        
        RegistrationFormController *registrationFormViewController = (RegistrationFormController *)self;
        return registrationFormViewController.viewController;
    }
    else {
        return self;
    }
}

@end
