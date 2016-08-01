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



#import "AnalyticsGroupConversationEvent.h"



typedef NS_ENUM(NSUInteger, GroupAction)
{
    GroupActionAddedParticipant,
    GroupActionCreated,
    GroupActionLeave,
    GroupActionDelete
};



@interface AnalyticsGroupConversationEvent ()

@property (assign, nonatomic) GroupAction actionType;
@property (assign, nonatomic, readwrite) CreatedGroupContext createdGroupContext;
@property (assign, nonatomic, readwrite) LeaveGroupAction leave;
@property (assign, nonatomic, readwrite) NSUInteger numberOfParticipants;
@property (assign, nonatomic, readwrite) NSUInteger newMembers;
@property (nonatomic, copy, readwrite) NSString *action;

@end



@implementation AnalyticsGroupConversationEvent

+ (instancetype)eventForLeaveAction:(LeaveGroupAction)leaveAction participantCount:(NSUInteger)participantCount
{
    return [[AnalyticsGroupConversationEvent alloc] initForConversationLeaveAction:leaveAction participantCount:participantCount];
}

+ (instancetype)eventForAddParticipantsWithCount:(NSUInteger)newMembersCount
{
    return [[AnalyticsGroupConversationEvent alloc] initForConversationAddedParticipantsWithCount:newMembersCount];
}

+ (instancetype)eventForDeleteAction:(NSString *)action withNumberOfParticipants:(NSUInteger)participantCount
{
    AnalyticsGroupConversationEvent *ev = [AnalyticsGroupConversationEvent new];
    ev.action = action;
    ev.numberOfParticipants = participantCount;
    ev.actionType = GroupActionDelete;
    return ev;
}

+ (instancetype)eventForCreatedGroupWithContext:(CreatedGroupContext)context participantCount:(NSUInteger)participantCount
{
    return [[AnalyticsGroupConversationEvent alloc] initForConversationCreatedGroupWithContext:context participantCount:participantCount];
}

- (NSString *)eventTag
{
    NSString *result = nil;
    
    switch (self.actionType) {
        case GroupActionAddedParticipant:
            result = @"conversation.added_member_to_group";
            break;
            
        case GroupActionCreated:
            result = @"conversation.created_new_group";
            break;
            
        case GroupActionDelete:
            result = @"deleteGroupConversation";
            break;
            
        case GroupActionLeave:
            result = @"leaveGroupConversation";
            break;
    }
    
    return result;
}

- (instancetype)initForConversationLeaveAction:(LeaveGroupAction)leaveAction participantCount:(NSUInteger)participantCount
{
    self = [super init];
    if (self) {
        self.actionType = GroupActionLeave;
        self.leave = leaveAction;
        self.numberOfParticipants = participantCount;
    }
    return self;
}

- (instancetype)initForConversationAddedParticipantsWithCount:(NSUInteger)newMembersCount
{
    self = [super init];
    if (self) {
        self.actionType = GroupActionAddedParticipant;
        self.newMembers = newMembersCount;
    }
    return self;
}

- (instancetype)initForConversationCreatedGroupWithContext:(CreatedGroupContext)context participantCount:(NSUInteger)participantCount
{
    self = [super init];
    if (self) {
        self.actionType = GroupActionCreated;
        self.createdGroupContext = context;
        self.numberOfParticipants = participantCount;
    }
    return self;
}

- (NSDictionary *)attributesDump
{
    switch (self.actionType) {
        case GroupActionAddedParticipant:
            return [self attributesDumpForAddParticipant];
            break;
            
        case GroupActionLeave:
            return [self attributesDumpForLeaveFromConv];
            break;
        
        case GroupActionDelete:
            return [self attributesDumpForDeleteConv];
            break;
            
        case GroupActionCreated:
            return [self attributesDumpForCreatedGroup];
        default:
            break;
    }
    
    return nil;
}

- (NSDictionary *)attributesDumpForAddParticipant
{
    // No clusterization for the add participant event
    return @{ @"new_members": @(self.newMembers) };
}

- (NSDictionary *)attributesDumpForCreatedGroup
{
    NSMutableDictionary *result = [NSMutableDictionary dictionaryWithCapacity:6];
    [self dumpIntegerClusterizedValueForKey:NSStringFromSelector(@selector(numberOfParticipants))
                               toDictionary:result
                             forClusterizer:DefaultIntegerClusterizer.participantClusterizer];
    
    NSString *contextString = [[self class] createdGroupContextToString:self.createdGroupContext];
    if (contextString) {
        [result setObject:contextString forKey:@"context"];
    }
    
    return result;
}

- (NSDictionary *)attributesDumpForLeaveFromConv
{
    NSMutableDictionary *result = [NSMutableDictionary dictionaryWithCapacity:6];
    [self dumpIntegerClusterizedValueForKey:NSStringFromSelector(@selector(numberOfParticipants)) toDictionary:result];
    NSString *leaveActionString = [[self class] leaveGroupActionToString:self.leave];
    [result setObject:leaveActionString forKey:NSStringFromSelector(@selector(leave))];
    return result;
}

- (NSDictionary *)attributesDumpForDeleteConv
{
    NSMutableDictionary *result = [NSMutableDictionary dictionaryWithCapacity:6];
    [self dumpIntegerClusterizedValueForKey:NSStringFromSelector(@selector(numberOfParticipants)) toDictionary:result];
    NSString *deleteActionString = self.action;
    if (deleteActionString) {
        [result setObject:deleteActionString forKey:NSStringFromSelector(@selector(leave))];
    }
    return result;
}

+ (NSString *)leaveGroupActionToString:(LeaveGroupAction) action
{
    switch (action) {
        case LeaveGroupActionLeave:
            return @"leave";
            
        case LeaveGroupActionCancel:
            return @"cancel";
    }
}

+ (NSString *)createdGroupContextToString:(CreatedGroupContext)context
{
    switch (context) {
        case CreatedGroupContextConversation:
            return @"conversation";
            
        case CreatedGroupContextStartUI:
            return @"contacts_quick_menu";
            
        default:
            return @"unknown";
    }
}

@end
