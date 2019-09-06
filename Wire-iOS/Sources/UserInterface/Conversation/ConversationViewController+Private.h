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

#import "WireSyncEngine+iOS.h"
#import "ProfileViewController.h"

NS_ASSUME_NONNULL_BEGIN

@class ConversationInputBarViewController;
@class CollectionsViewController;
@class OutgoingConnectionViewController;
@class BarController;
@class InvisibleInputAccessoryView;
@class GuestsBarController;

@interface ConversationViewController (Private)

@property (nonatomic, readonly) ConversationContentViewController *contentViewController;
@property (nonatomic, readonly) ConversationInputBarViewController *inputBarController;
@property (nonatomic, readonly) UIViewController *participantsController;
@property (nonatomic, nullable) CollectionsViewController *collectionController;
@property (nonatomic, nullable) OutgoingConnectionViewController *outgoingConnectionViewController;
@property (nonatomic, readonly) BarController *conversationBarController;
@property (nonatomic, readonly) GuestsBarController *guestsBarController;
@property (nonatomic, readonly) InvisibleInputAccessoryView *invisibleInputAccessoryView;

@property (nonatomic, nullable) NSLayoutConstraint *inputBarBottomMargin;
@property (nonatomic, nullable) NSLayoutConstraint *inputBarZeroHeight;;

- (void)onBackButtonPressed:(UIButton *)backButton;
- (void)createOutgoingConnectionViewController;

@end

@interface ConversationViewController ()
@property (nonatomic) BOOL isAppearing;
@end

@interface ConversationViewController (ProfileViewController) <ProfileViewControllerDelegate>
@end

NS_ASSUME_NONNULL_END
