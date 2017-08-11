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


#import "ZMConversation+Actions.h"
#import "ZMUser+Additions.h"

NSString * const ConversationActionDelete = @"ConversationActionDelete";
NSString * const ConversationActionLeave = @"ConversationActionLeave";
NSString * const ConversationActionSilence = @"ConversationActionSilence";
NSString * const ConversationActionUnsilence = @"ConversationActionUnsilence";
NSString * const ConversationActionArchive = @"ConversationActionArchive";
NSString * const ConversationActionUnarchive = @"ConversationActionUnarchive";
NSString * const ConversationActionCancelConnectionRequest = @"ConversationActionCancelConnectionRequest";
NSString * const ConversationActionBlockUser = @"ConversationActionBlockUser";
NSString * const ConversationActionUnblockUser = @"ConversationActionUnblockUser";



@implementation ZMConversation (Actions)

- (NSOrderedSet *)availableActions
{
    if (self.conversationType == ZMConversationTypeConnection) {
        return [self availableActionsForPendingConversation];
    } else if (self.conversationType == ZMConversationTypeOneOnOne) {
        return [self availableActionsForOneToOneConversation];
    } else {
        return [self availableActionsForGroupConversation];
    }
}

- (NSOrderedSet *)availableActionsForOneToOneConversation
{
    NSMutableOrderedSet *actions = [NSMutableOrderedSet orderedSet];

    if (nil == self.team) {
        if (self.connectedUser.isBlocked) {
            [actions addObject:ConversationActionUnblockUser];
        } else {
            [actions addObject:ConversationActionBlockUser];
        }
    }

    [actions addObjectsFromArray:[self availableActionsForConversation].array];
    [actions addObject:ConversationActionDelete];

    return actions;
}

- (NSOrderedSet *)availableActionsForGroupConversation
{
    NSMutableOrderedSet *actions = [NSMutableOrderedSet orderedSet];

    BOOL selfIsActiveParticipant = [self.activeParticipants containsObject:[ZMUser selfUser]];

    if (selfIsActiveParticipant) {
        [actions addObject:ConversationActionLeave];
    }

    [actions addObjectsFromArray:[self availableActionsForConversation].array];
    [actions addObject:ConversationActionDelete];

    return actions;
}

- (NSOrderedSet *)availableActionsForPendingConversation
{
    NSMutableOrderedSet *actions = [NSMutableOrderedSet orderedSet];
    [actions addObject:self.archiveActionForConversation];
    [actions addObject:ConversationActionCancelConnectionRequest];
    return actions;
}

- (NSOrderedSet *)availableActionsForConversation
{
    NSMutableOrderedSet *actions = [NSMutableOrderedSet orderedSet];

    if (! self.isReadOnly) {
        if (self.isSilenced) {
            [actions addObject:ConversationActionUnsilence];
        }
        else {
            [actions addObject:ConversationActionSilence];
        }
    }

    [actions addObject:self.archiveActionForConversation];
    return actions;
}

- (ConversationAction *)archiveActionForConversation
{
    return self.isArchived ? ConversationActionUnarchive : ConversationActionArchive;
}

@end
