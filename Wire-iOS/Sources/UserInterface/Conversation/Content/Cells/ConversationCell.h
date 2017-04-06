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


#import <UIKit/UIKit.h>

#import "UserImageView.h"
#import "WireSyncEngine+iOS.h"

#import "Analytics+iOS.h"
#import "MessageAction.h"

@class ConversationCell;
@class MessageToolboxView;
@class AnalyticsTracker;
@class LikeButton;
@class LinkAttachment;

extern const CGFloat ConversationCellSelectedOpacity;
extern const NSTimeInterval ConversationCellSelectionAnimationDuration;


typedef void (^SelectedMenuBlock)(BOOL selected, BOOL animated);
@interface MenuConfigurationProperties : NSObject

@property (nonatomic) CGRect targetRect;
@property (nonatomic) UIView *targetView;
@property (nonatomic) SelectedMenuBlock selectedMenuBlock;
@property (nonatomic) NSArray <UIMenuItem *> *additionalItems;
@property (nonatomic) NSUInteger likeItemIndex;

@end

@interface ConversationCellLayoutProperties : NSObject

@property (nonatomic, assign) BOOL showSender;
@property (nonatomic, assign) BOOL showBurstTimestamp;
@property (nonatomic, assign) BOOL showDayBurstTimestamp;
@property (nonatomic, assign) BOOL alwaysShowDeliveryState;
@property (nonatomic, assign) BOOL showUnreadMarker;
@property (nonatomic, assign) CGFloat topPadding;
@property (nonatomic, strong) NSArray<LinkAttachment *> *linkAttachments;

@end


@protocol ConversationCellDelegate <NSObject>

@optional
/// Called on touch up inside event on the user image (@c fromImage)
- (void)conversationCell:(ConversationCell *)cell userTapped:(ZMUser *)user inView:(UIView *)view;
- (void)conversationCellDidTapResendMessage:(ConversationCell *)cell;
- (void)conversationCell:(ConversationCell *)cell didSelectAction:(MessageAction)actionId;
- (void)conversationCell:(ConversationCell *)cell didSelectURL:(NSURL *)url;
- (BOOL)conversationCell:(ConversationCell *)cell shouldBecomeFirstResponderWhenShowMenuWithCellType:(MessageType)messageType;
- (void)conversationCell:(ConversationCell *)cell didOpenMenuForCellType:(MessageType)messageType;
- (void)conversationCellDidTapOpenLikers:(ConversationCell *)cell;
- (BOOL)conversationCellShouldStartDestructionTimer:(ConversationCell *)cell;
@end


@interface ConversationCell : UITableViewCell <UserImageViewDelegate>

@property (nonatomic, readonly) ConversationCellLayoutProperties *layoutProperties;

@property (nonatomic, readonly) id<ZMConversationMessage>message;
@property (nonatomic)           NSArray<NSString *> *searchQueries;
@property (nonatomic, readonly) UILabel *authorLabel;
@property (nonatomic, readonly) UserImageView *authorImageView;
@property (nonatomic, readonly) UIView *messageContentView;
@property (nonatomic)           LikeButton *likeButton;
@property (nonatomic, readonly) MessageToolboxView *toolboxView;
@property (nonatomic, readonly) UIView *countdownContainerView;
@property (nonatomic, strong, readonly) UIView *selectionView;
@property (nonatomic, readonly) CGRect selectionRect;
@property (nonatomic, strong, readonly) UIView *previewView;
@property (nonatomic) UIEdgeInsets contentLayoutMargins;

@property (nonatomic) CGFloat burstTimestampSpacing;
@property (nonatomic) BOOL showsMenu;
@property (nonatomic) BOOL beingEdited;

@property (nonatomic, weak) id<ConversationCellDelegate> delegate;

@property (nonatomic) AnalyticsTracker *analyticsTracker;
@property (nonatomic) UILongPressGestureRecognizer *longPressGestureRecognizer;
@property (nonatomic, readonly) UITapGestureRecognizer *doubleTapGestureRecognizer;

- (void)configureForMessage:(id<ZMConversationMessage>)message layoutProperties:(ConversationCellLayoutProperties *)layoutProperties;
/// Update cell due since the message content has changed. Return True if the change requires the cell to be re-sized.
- (BOOL)updateForMessage:(MessageChangeInfo *)changeInfo;
- (void)willDisplayInTableView;
- (void)didEndDisplayingInTableView;

- (void)forward:(id)sender;

#pragma mark - For deleted menu, meant to be implmented by subclass

- (MenuConfigurationProperties *)menuConfigurationProperties;
- (void)showMenu;

// This is used for tracking. Every subclass give which type of cell it is, to figure what kind of message it is.
- (MessageType)messageType;
@end

