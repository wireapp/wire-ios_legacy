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


#import "FormFlowViewController.h"
#import "RegistrationFormController.h"

@interface FormFlowViewController ()

@end

@implementation FormFlowViewController


#pragma mark - NavigationControllerDelegate

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    
    UIViewController *controller = [viewController isKindOfClass:[RegistrationFormController class]] ? ((RegistrationFormController *)viewController).viewController : viewController;
    
    if ([self.formStepDelegate respondsToSelector:@selector(formStep:willMoveToStep:)]) {
        [self.formStepDelegate formStep:self willMoveToStep:controller];
    }
}

- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    UIViewController *controller = [viewController isKindOfClass:[RegistrationFormController class]] ? ((RegistrationFormController *)viewController).viewController : viewController;
    
    if ([self.formStepDelegate respondsToSelector:@selector(formStep:didMoveToStep:)]) {
        [self.formStepDelegate formStep:self didMoveToStep:controller];
    }
}

@end
