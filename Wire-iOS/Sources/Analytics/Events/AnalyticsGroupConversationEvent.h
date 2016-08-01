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
#import "AnalyticsEvent.h"



typedef NS_ENUM (NSUInteger, LeaveGroupAction)
{
    LeaveGroupActionLeave,
    LeaveGroupActionCancel,
};

typedef NS_ENUM (NSUInteger, CreatedGroupContext)
{
    CreatedGroupContextConversation,
    CreatedGroupContextStartUI,
};



@interface AnalyticsGroupConversationEvent : AnalyticsEvent

@property (assign, nonatomic, readonly) CreatedGroupContext createdGroupContext;
@property (assign, nonatomic, readonly) LeaveGroupAction leave;
@property (assign, nonatomic, readonly) NSUInteger numberOfParticipants;
@property (assign, nonatomic, readonly) NSUInteger newMembers;
@property (nonatomic, copy, readonly) NSString *action;

+ (instancetype)eventForCreatedGroupWithContext:(CreatedGroupContext)context participantCount:(NSUInteger)participantCount;

+ (instancetype)eventForAddParticipantsWithCount:(NSUInteger)newMembersCount;

+ (instancetype)eventForLeaveAction:(LeaveGroupAction)leaveAction participantCount:(NSUInteger)participantCount;

+ (instancetype)eventForDeleteAction:(NSString *)action withNumberOfParticipants:(NSUInteger)participantCount;

- (instancetype)initForConversationCreatedGroupWithContext:(CreatedGroupContext)context participantCount:(NSUInteger)participantCount;
- (instancetype)initForConversationAddedParticipantsWithCount:(NSUInteger)newMembersCount;

- (instancetype)initForConversationLeaveAction:(LeaveGroupAction)leaveAction participantCount:(NSUInteger)participantCount;

@end
