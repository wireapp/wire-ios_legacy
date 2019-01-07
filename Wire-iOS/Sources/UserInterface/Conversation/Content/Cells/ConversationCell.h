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

#import "WireSyncEngine+iOS.h"
#import "MessageAction.h"
#import "MessageType.h"

@class ConversationCell;
@class MessageToolboxView;
@class LikeButton;
@class LinkAttachment;
@class ConversationCellBurstTimestampView;
@class AdditionalMenuItem;
@class MenuConfigurationProperties;
@class UserImageView;
@class ConversationMessageActionController;
@class MessageDetailsViewController;

extern const CGFloat ConversationCellSelectedOpacity;
extern const NSTimeInterval ConversationCellSelectionAnimationDuration;

typedef void (^SelectedMenuBlock)(BOOL selected, BOOL animated);

@interface ConversationCellLayoutProperties : NSObject

@property (nonatomic, assign) BOOL showSender;
@property (nonatomic, assign) BOOL showBurstTimestamp;
@property (nonatomic, assign) BOOL showDayBurstTimestamp;
@property (nonatomic, assign) BOOL alwaysShowDeliveryState;
@property (nonatomic, assign) BOOL showUnreadMarker;
@property (nonatomic, assign) CGFloat topPadding;

@end


@protocol ConversationCellDelegate <MessageActionResponder>

@optional
/// Called on touch up inside event on the user image (@c fromImage)
- (void)conversationCell:(UIView *)cell userTapped:(id<UserType>)user inView:(UIView *)view frame:(CGRect)frame;
- (void)conversationCellDidTapResendMessage:(ConversationCell *)cell;
- (void)conversationCell:(ConversationCell *)cell didSelectURL:(NSURL *)url;
- (BOOL)conversationCellShouldBecomeFirstResponderWhenShowingMenuForCell:(UIView *)cell;
- (void)conversationCellDidRequestOpeningMessageDetails:(UIView *)cell messageDetails:(MessageDetailsViewController *)messageDetails;
- (BOOL)conversationCellShouldStartDestructionTimer:(ConversationCell *)cell;
- (void)conversationCell:(UIView *)cell openGuestOptionsFromView:(UIView *)sourceView;
- (void)conversationCell:(UIView *)cell openParticipantsDetailsWithSelectedUsers:(NSArray <ZMUser *>*)selectedUsers fromView:(UIView *)sourceView;
- (void)conversationCell:(UIView *)cell didSelectAction:(MessageAction)actionId forMessage:(id<ZMConversationMessage>)message;
@end

@interface ConversationCell : UITableViewCell

@property (nonatomic, readonly) ConversationCellLayoutProperties *layoutProperties;

@property (nonatomic, readonly) id<ZMConversationMessage>message;
@property (nonatomic)           NSArray<NSString *> *searchQueries;
@property (nonatomic, readonly) UILabel *authorLabel;
@property (nonatomic, readonly) UserImageView *authorImageView;
@property (nonatomic, readonly) UIView *messageContentView;
@property (nonatomic, readonly) MessageToolboxView *toolboxView;
@property (nonatomic, readonly) UIView *countdownContainerView;
@property (nonatomic, strong, readonly) UIView *selectionView;
@property (nonatomic, readonly) CGRect selectionRect;
@property (nonatomic, readonly) UIView *previewView;
@property (nonatomic) UIEdgeInsets contentLayoutMargins;

@property (nonatomic) CGFloat burstTimestampSpacing;
@property (nonatomic) BOOL showsMenu;
@property (nonatomic) BOOL beingEdited;

@property (nonatomic, weak) id<ConversationCellDelegate> delegate;

@property (nonatomic) UILongPressGestureRecognizer *longPressGestureRecognizer;
@property (nonatomic, readonly) UITapGestureRecognizer *doubleTapGestureRecognizer;
@property (nonatomic, readwrite) ConversationCellBurstTimestampView *burstTimestampView;
@property (nonatomic) NSTimer *burstTimestampTimer;

@property (nonatomic) UIFont *burstNormalFont;
@property (nonatomic) UIFont *burstBoldFont;

@property (nonatomic) ConversationMessageActionController *actionController;

- (void)configureForMessage:(id<ZMConversationMessage>)message layoutProperties:(ConversationCellLayoutProperties *)layoutProperties;
/// Update cell due since the message content has changed. Return True if the change requires the cell to be re-sized.
- (BOOL)updateForMessage:(MessageChangeInfo *)changeInfo;
- (void)didEndDisplayingInTableView;

#pragma mark - For deleted menu, meant to be implmented by subclass

- (MenuConfigurationProperties *)menuConfigurationProperties;

// This is used for tracking. Every subclass give which type of cell it is, to figure what kind of message it is.
- (MessageType)messageType;
@end

