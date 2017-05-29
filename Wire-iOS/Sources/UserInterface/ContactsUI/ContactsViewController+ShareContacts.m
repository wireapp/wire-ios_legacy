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


#import "ContactsViewController+ShareContacts.h"
#import "ShareContactsViewController.h"
#import "ContactsDataSource.h"



@implementation ContactsViewController (ShareContacts)

- (void)presentShareContactsViewController
{
    ShareContactsViewController *shareContactsViewController = [[ShareContactsViewController alloc] init];
    shareContactsViewController.formStepDelegate = self;
    shareContactsViewController.analyticsTracker = self.analyticsTracker;
    
    [self presentChildViewcontroller:shareContactsViewController];
}

- (void)presentChildViewcontroller:(UIViewController *)viewController
{
    [self addChildViewController:viewController];
    [self.view addSubview:viewController.view];
    [viewController didMoveToParentViewController:self];
}

- (void)dismissChildViewController:(UIViewController *)viewController
{
    [UIView transitionWithView:viewController.view duration:0.35 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
        viewController.view.alpha = 0;
    } completion:^(BOOL finished) {
        [viewController willMoveToParentViewController:nil];
        [viewController.view removeFromSuperview];
        [viewController removeFromParentViewController];
    }];
}

- (void)didCompleteFormStep:(UIViewController *)viewController
{
    // Reload data source
    [self.dataSource setSearchRequest:self.dataSource.searchRequest];
    
    [self dismissChildViewController:viewController];
}

- (void)didSkipFormStep:(UIViewController *)viewController
{
    if ([self.delegate respondsToSelector:@selector(contactsViewControllerDidNotShareContacts:)]) {
        [self.delegate contactsViewControllerDidNotShareContacts:self];
    }
}

@end
