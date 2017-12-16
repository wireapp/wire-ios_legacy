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

@class ZMConversation;
@class ConversationAvatarView;
@class ConversationListAccessoryView;

FOUNDATION_EXPORT NSString * const ConversationListItemDidScrollNotification;

@interface ConversationListItemView : UIView

// Please use `updateForConversation:` to set conversation.
@property (nonatomic) ZMConversation *conversation;

@property (nonatomic, copy) NSAttributedString *titleText;
@property (nonatomic, copy) NSAttributedString *subtitleAttributedText;

@property (nonatomic, readonly) UILabel *titleField;
@property (nonatomic, readonly) ConversationAvatarView *avatarView;
@property (nonatomic, readonly) ConversationListAccessoryView *rightAccessory;

@property (nonatomic) BOOL selected;
@property (nonatomic) CGFloat visualDrawerOffset;

- (void)setVisualDrawerOffset:(CGFloat)visualDrawerOffset notify:(BOOL)notify;
- (void)accessibilityContentsDidChange;

@end
