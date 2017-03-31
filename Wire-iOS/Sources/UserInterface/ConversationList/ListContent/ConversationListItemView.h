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

@class ConversationAvatarView;
@class ConversationListAccessoryView;

FOUNDATION_EXPORT NSString * const ConversationListItemDidScrollNotification;

@interface ConversationListItemView : UIView

@property (nonatomic, copy) NSString *titleText;
@property (nonatomic, copy) NSAttributedString *subtitleAttributedText;

@property (nonatomic, strong, readonly) UILabel *titleField;
@property (nonatomic, strong, readonly) ConversationAvatarView *avatarView;
@property (nonatomic, strong, readonly) ConversationListAccessoryView *rightAccessory;

@property (nonatomic, assign) BOOL selected;
@property (nonatomic, assign) CGFloat visualDrawerOffset;

- (void)setVisualDrawerOffset:(CGFloat)visualDrawerOffset notify:(BOOL)notify;

@end
