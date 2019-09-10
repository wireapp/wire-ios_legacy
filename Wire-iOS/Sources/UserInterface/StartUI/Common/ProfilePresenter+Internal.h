//
// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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

// ui
#import "ProfileViewController.h"

@protocol ViewControllerDismisser;

@interface ProfilePresenter () <ViewControllerDismisser>
@end

@interface TransitionDelegate : NSObject <UIViewControllerTransitioningDelegate>

@end


@interface ProfilePresenter ()

@property (nonatomic, assign) CGRect presentedFrame;
@property (nonatomic, weak, nullable)   UIView *viewToPresentOn;
@property (nonatomic, weak, nullable)   UIViewController *controllerToPresentOn;
@property (nonatomic, copy, nullable)   dispatch_block_t onDismiss;
@property (nonatomic, nonnull) TransitionDelegate *transitionDelegate;

- (void)dismissViewController:(UIViewController *)profileViewController completion:(dispatch_block_t)completion;

@end
