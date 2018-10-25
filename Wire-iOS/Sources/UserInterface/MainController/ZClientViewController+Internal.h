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


#import <Foundation/Foundation.h>
#import "ZClientViewController.h"

NS_ASSUME_NONNULL_BEGIN

@class ZMConversation;

/**
 * Protected methods for zclientviewcontroller.
 */

@interface ZClientViewController (Internal)

/**
 * Load and optionally show a conversation, but don't change the list selection.  This is the place to put 
 * stuff if you definitely need it to happen when a conversation is selected and/or presented
 *
 * This method should only be called when the list selection changes, or internally by other zclientviewcontroller
 * methods.
 *
 * @return YES if it actually switched views, NO if nothing changed (ie: we were already looking at the conversation)
 */
- (BOOL)loadConversation:(ZMConversation *)conversation scrollToMessage:(nullable id<ZMConversationMessage>)message focusOnView:(BOOL)focus animated:(BOOL)animated;
- (BOOL)loadConversation:(ZMConversation *)conversation scrollToMessage:(nullable id<ZMConversationMessage>)message focusOnView:(BOOL)focus animated:(BOOL)animated completion:(nullable dispatch_block_t)completion;

- (void)loadPlaceholderConversationControllerAnimated:(BOOL)animated;
- (void)loadPlaceholderConversationControllerAnimated:(BOOL)animated completion:(nullable dispatch_block_t)completion;

- (void)loadIncomingContactRequestsAndFocusOnView:(BOOL)focus animated:(BOOL)animated;
- (void)dismissClientListController:(id)sender;
@end

@interface ZClientViewController ()

@property (nonatomic, nonnull) UIView *topOverlayContainer;
@property (nonatomic, nullable) UIViewController *topOverlayViewController;
@property (nonatomic) NSLayoutConstraint *contentTopRegularConstraint;
@property (nonatomic) NSLayoutConstraint *contentTopCompactConstraint;


@end

NS_ASSUME_NONNULL_END
