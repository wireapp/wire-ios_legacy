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


#import "Analytics+ConversationEvents.h"



NSString *NSStringFromSelectionType(SelectionType selectionType);
NSString *NSStringFromSelectionType(SelectionType selectionType)
{
    switch (selectionType) {
        case SelectionTypeSingle:
            return @"single";
        case SelectionTypeMulti:
            return @"multi";
    }
}

NSString *NSStringFromMessageActionType(MessageActionType actionType);
NSString *NSStringFromMessageActionType(MessageActionType actionType)
{
    switch (actionType) {
        case MessageActionTypeCopy:
            return @"copy";
        case MessageActionTypeDelete:
            return @"delete";
    }
}

NSString *NSStringFromMessageType(MessageType messageType);
NSString *NSStringFromMessageType(MessageType messageType)
{
    switch (messageType) {
        case MessageTypeText:
            return @"text";
        case MessageTypeImage :
            return @"image";
        case MessageTypeRichMedia:
            return @"rich_media";
        case MessageTypePing:
            return @"ping";
        case MessageTypeFile:
            return @"file";
        case MessageTypeSystem:
            return @"system";
        case MessageTypeLocation:
            return @"location";
    }
}

NSString *NSStringFromConversationType(ConversationType conversationType);
NSString *NSStringFromConversationType(ConversationType conversationType)
{
    switch (conversationType) {
        case ConversationTypeOneToOne:
            return @"one_to_one";
        case ConversationTypeGroup:
            return @"group";
    }
}

@implementation Analytics (ConversationEvents)

- (void)tagArchivedConversation
{
    [self tagEvent:@"conversation.archived_conversation"];
}

- (void)tagUnarchivedConversation
{
    [self tagEvent:@"conversation.unarchived_conversation"];
}

- (void)tagOpenedPeoplePickerGroupAction
{
    [self tagEvent:@"conversation.opened_group_action"];
}

- (void)tagSelectedMessage:(SelectionType)type conversationType:(ConversationType)conversationType messageType:(MessageType)messageType;
{
    [self tagEvent:@"conversation.selected_message" attributes:@{@"context" : NSStringFromSelectionType(type), @"type": NSStringFromMessageType(messageType), @"conversation_type" : NSStringFromConversationType(conversationType)}];
}

- (void)tagOpenedMessageAction:(MessageActionType)actionType;
{
    [self tagEvent:@"conversation.opened_message_action" attributes:@{@"action" : NSStringFromMessageActionType(actionType)}];
}

- (void)tagDeletedMessage;
{
    [self tagEvent:@"conversation.deleted_message"];
}

- (void)tagMessageCopy;
{
    [self tagEvent:@"conversation.copied_message"];
}

@end
