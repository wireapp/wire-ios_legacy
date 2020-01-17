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


NS_ASSUME_NONNULL_BEGIN

@class ConversationInputBarViewController;
@class CollectionsViewController;
@class OutgoingConnectionViewController;
@class BarController;
@class InvisibleInputAccessoryView;
@class GuestsBarController;
@class ConversationTitleView;
@class MediaBarViewController;
@class ConversationContentViewController;

@protocol ConversationInputBarViewControllerDelegate;
@protocol ZMConversationObserver;
@protocol ZMConversationListObserver;

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
- (void)openConversationList;

@end

@interface ConversationViewController ()
@property (nonatomic) BOOL isAppearing;

@property (nonatomic) BarController *conversationBarController;
@property (nonatomic, readwrite) MediaBarViewController *mediaBarViewController;

@property (nonatomic) ConversationContentViewController *contentViewController;
@property (nonatomic) UIViewController *participantsController;

@property (nonatomic) ConversationInputBarViewController *inputBarController;
@property (nonatomic) OutgoingConnectionViewController *outgoingConnectionViewController;

@property (nonatomic) NSLayoutConstraint *inputBarBottomMargin;
@property (nonatomic) NSLayoutConstraint *inputBarZeroHeight;
@property (nonatomic, readwrite) InvisibleInputAccessoryView *invisibleInputAccessoryView;
@property (nonatomic, readwrite) GuestsBarController *guestsBarController;

@property (nonatomic) id voiceChannelStateObserverToken;
@property (nonatomic) id conversationObserverToken;

@property (nonatomic) ConversationTitleView *titleView;
@property (nonatomic) CollectionsViewController *collectionController;
@property (nonatomic) id conversationListObserverToken;
@property (nonatomic, readwrite) ConversationCallController *startCallController;

@end

@interface ConversationViewController (InputBar) <ConversationInputBarViewControllerDelegate>
@end


@interface ConversationViewController (ConversationListObserver) <ZMConversationListObserver>
@end


NS_ASSUME_NONNULL_END
