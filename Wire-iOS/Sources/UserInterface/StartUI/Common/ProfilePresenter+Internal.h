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

@protocol ViewControllerDismisser;

#pragma clang diagnostic push
// To get rid of 'No protocol definition found' warnings which are not accurate
#pragma clang diagnostic ignored "-Weverything"

@interface ProfilePresenter () <ViewControllerDismisser>
@end

#pragma clang diagnostic pop


@interface TransitionDelegate : NSObject <UIViewControllerTransitioningDelegate>

@end


@interface ProfilePresenter ()

@property (nonatomic, assign) CGRect presentedFrame;
@property (nonatomic, weak, nullable)   UIView *viewToPresentOn;
@property (nonatomic, weak, nullable)   UIViewController *controllerToPresentOn;
@property (nonatomic, copy, nullable)   dispatch_block_t onDismiss;
@property (nonatomic, nonnull) TransitionDelegate *transitionDelegate;

- (void)dismissViewController:(UIViewController * _Nonnull)profileViewController completion:(dispatch_block_t _Nullable)completion;

@end
