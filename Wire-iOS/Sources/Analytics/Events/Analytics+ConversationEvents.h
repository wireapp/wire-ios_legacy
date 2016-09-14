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
#import "AnalyticsBase.h"

typedef NS_ENUM(NSUInteger, SelectionType) {
    SelectionTypeSingle,
    SelectionTypeMulti
};

typedef NS_ENUM(NSUInteger, MessageActionType) {
    MessageActionTypeCopy,
    MessageActionTypeDelete,
    MessageActionTypeEdit
};

typedef NS_ENUM(NSUInteger, MessageType) {
    MessageTypeUnknown,
    MessageTypeText,
    MessageTypeImage,
    MessageTypeFile,
    MessageTypeAudio,
    MessageTypeVideo,
    MessageTypeRichMedia,
    MessageTypePing,
    MessageTypeSystem,
    MessageTypeLocation
};

typedef NS_ENUM(NSUInteger, ConversationType) {
    ConversationTypeOneToOne,
    ConversationTypeGroup
};

typedef NS_ENUM(NSUInteger, MessageDeletionType) {
    MessageDeletionTypeLocal,
    MessageDeletionTypeEverywhere
};

typedef NS_ENUM(NSUInteger, ReactionType) {
    ReactionTypeUndefined,
    ReactionTypeLike,
    ReactionTypeUnlike
};

typedef NS_ENUM(NSUInteger, InteractionMethod) {
    InteractionMethodUndefined,
    InteractionMethodButton,
    InteractionMethodMenu,
    InteractionMethodDoubleTap
};


@interface Analytics (ConversationEvents)

- (void)tagArchivedConversation;
- (void)tagUnarchivedConversation;
- (void)tagOpenedPeoplePickerGroupAction;

- (void)tagSelectedMessage:(SelectionType)type conversationType:(ConversationType)conversationType messageType:(MessageType)messageType;
- (void)tagOpenedMessageAction:(MessageActionType)actionType;

- (void)tagDeletedMessage:(MessageType)messageType messageDeletionType:(MessageDeletionType)messageDeletionType conversationType:(ConversationType)conversationType timeElapsed:(NSTimeInterval)timeElapsed;
- (void)tagEditedMessageConversationType:(ConversationType)conversationType timeElapsed:(NSTimeInterval)timeElapsed;

- (void)tagMessageCopy;

@end
