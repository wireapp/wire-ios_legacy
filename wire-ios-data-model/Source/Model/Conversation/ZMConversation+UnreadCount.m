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


@import WireUtilities;
@import WireTransport;

#import "ZMConversation+Internal.h"
#import "ZMConversation+UnreadCount.h"

#import "ZMMessage+Internal.h"
#import "ZMUser+Internal.h"
#import "NSManagedObjectContext+zmessaging.h"

#import <WireDataModel/WireDataModel-Swift.h>

NSString *const ZMConversationInternalEstimatedUnreadSelfMentionCountKey = @"internalEstimatedUnreadSelfMentionCount";
NSString *const ZMConversationInternalEstimatedUnreadSelfReplyCountKey = @"internalEstimatedUnreadSelfReplyCount";
NSString *const ZMConversationInternalEstimatedUnreadCountKey = @"internalEstimatedUnreadCount";
NSString *const ZMConversationLastUnreadKnockDateKey = @"lastUnreadKnockDate";
NSString *const ZMConversationLastUnreadMissedCallDateKey = @"lastUnreadMissedCallDate";
NSString *const ZMConversationLastReadLocalTimestampKey = @"lastReadLocalTimestamp";



@implementation ZMConversation (Internal_UnreadCount)

@dynamic lastUnreadKnockDate;
@dynamic lastUnreadMissedCallDate;

- (void)setLastUnreadKnockDate:(NSDate *)lastUnreadKnockDate
{
    RequireString(self.managedObjectContext.zm_isSyncContext, "lastUnreadKnockDate should only be set from the sync context");
    
    [self willChangeValueForKey:ZMConversationLastUnreadKnockDateKey];
    [self setPrimitiveValue:lastUnreadKnockDate forKey:ZMConversationLastUnreadKnockDateKey];
    [self didChangeValueForKey:ZMConversationLastUnreadKnockDateKey];
}

- (void)setLastUnreadMissedCallDate:(NSDate *)lastUnreadMissedCallDate
{
    RequireString(self.managedObjectContext.zm_isSyncContext, "lastUnreadMissedCallDate should only be set from the sync context");
    
    [self willChangeValueForKey:ZMConversationLastUnreadMissedCallDateKey];
    [self setPrimitiveValue:lastUnreadMissedCallDate forKey:ZMConversationLastUnreadMissedCallDateKey];
    [self didChangeValueForKey:ZMConversationLastUnreadMissedCallDateKey];
}

- (BOOL)hasUnreadKnock
{
    return (self.lastUnreadKnockDate != nil);
}

+ (NSSet *)keyPathsForValuesAffectingHasUnreadKnock
{
    return [NSSet setWithObjects:ZMConversationLastUnreadKnockDateKey,  nil];
}

- (BOOL)hasUnreadMissedCall
{
    return (self.lastUnreadMissedCallDate != nil);
}

+ (NSSet *)keyPathsForValuesAffectingHasUnreadMissedCall
{
    return [NSSet setWithObjects:ZMConversationLastUnreadMissedCallDateKey,  nil];
}

@end



@implementation ZMConversation (UnreadCount)

@dynamic internalEstimatedUnreadCount;
@dynamic internalEstimatedUnreadSelfMentionCount;
@dynamic internalEstimatedUnreadSelfReplyCount;
@dynamic hasUnreadUnsentMessage;
@dynamic needsToCalculateUnreadMessages;

+ (NSUInteger)unreadConversationCountInContext:(NSManagedObjectContext *)moc;
{    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:[ZMConversation entityName]];
    request.predicate = [self predicateForConversationConsideredUnread];
    
    return [moc countForFetchRequest:request error:nil];
}

+ (NSUInteger)unreadConversationCountExcludingSilencedInContext:(NSManagedObjectContext *)moc excluding:(ZMConversation *)conversation
{
    NSPredicate *excludedConversationPredicate = [NSPredicate predicateWithFormat:@"SELF != %@", conversation];
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:[ZMConversation entityName]];
    request.predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[excludedConversationPredicate, [self predicateForConversationConsideredUnreadExcludingSilenced]]];
    
    return [moc countForFetchRequest:request error:nil];
}

+ (NSPredicate *)predicateForConversationConsideredUnread;
{
    NSPredicate *notSelfConversation = [NSPredicate predicateWithFormat:@"%K != %d", ZMConversationConversationTypeKey, ZMConversationTypeSelf];
    NSPredicate *notInvalidConversation = [NSPredicate predicateWithFormat:@"%K != %d", ZMConversationConversationTypeKey, ZMConversationTypeInvalid];
    
    NSPredicate *pendingConnection = [NSPredicate predicateWithFormat:@"%K != nil AND %K.status == %d", ZMConversationConnectionKey, ZMConversationConnectionKey, ZMConnectionStatusPending];
    NSPredicate *acceptablePredicate = [NSCompoundPredicate orPredicateWithSubpredicates:@[pendingConnection, [self predicateForUnreadConversation]]];
    
    NSPredicate *notBlockedConnection = [NSPredicate predicateWithFormat:@"(%K == nil) OR (%K != nil AND %K.status != %d)", ZMConversationConnectionKey, ZMConversationConnectionKey, ZMConversationConnectionKey, ZMConnectionStatusBlocked];
    
    return [NSCompoundPredicate andPredicateWithSubpredicates:@[notSelfConversation, notInvalidConversation, notBlockedConnection, acceptablePredicate]];
}

+ (NSPredicate *)predicateForUnreadConversation
{
    NSPredicate *notifyAllPredicate = [NSPredicate predicateWithFormat:@"%K == %lu", ZMConversationMutedStatusKey, MutedMessageOptionValueNone];
    NSPredicate *notifyMentionsAndRepliesPredicate = [NSPredicate predicateWithFormat:@"%K < %lu", ZMConversationMutedStatusKey, MutedMessageOptionValueMentionsAndReplies];
    NSPredicate *unreadMentionsOrReplies = [NSPredicate predicateWithFormat:@"%K > 0 OR %K > 0", ZMConversationInternalEstimatedUnreadSelfMentionCountKey, ZMConversationInternalEstimatedUnreadSelfReplyCountKey];
    NSPredicate *unreadMessages = [NSPredicate predicateWithFormat:@"%K > 0", ZMConversationInternalEstimatedUnreadCountKey];
    NSPredicate *notifyAllAndHasUnreadMessages = [NSCompoundPredicate andPredicateWithSubpredicates:@[notifyAllPredicate, unreadMessages]];
    NSPredicate *notifyMentionsAndRepliesAndHasUnreadMentionsOrReplies = [NSCompoundPredicate andPredicateWithSubpredicates:@[notifyMentionsAndRepliesPredicate, unreadMentionsOrReplies]];
    
    return [NSCompoundPredicate orPredicateWithSubpredicates:@[notifyAllAndHasUnreadMessages, notifyMentionsAndRepliesAndHasUnreadMentionsOrReplies]];
}

+ (NSPredicate *)predicateForConversationConsideredUnreadExcludingSilenced;
{
    NSPredicate *notSelfConversation = [NSPredicate predicateWithFormat:@"%K != %d", ZMConversationConversationTypeKey, ZMConversationTypeSelf];
    NSPredicate *notInvalidConversation = [NSPredicate predicateWithFormat:@"%K != %d", ZMConversationConversationTypeKey, ZMConversationTypeInvalid];

    NSPredicate *notBlockedConnection = [NSPredicate predicateWithFormat:@"(%K == nil) OR (%K != nil AND %K.status != %d)", ZMConversationConnectionKey, ZMConversationConnectionKey, ZMConversationConnectionKey, ZMConnectionStatusBlocked];

    return [NSCompoundPredicate andPredicateWithSubpredicates:@[notSelfConversation, notInvalidConversation, notBlockedConnection, [self predicateForUnreadConversation]]];
}

- (void)setInternalEstimatedUnreadCount:(int64_t)internalEstimatedUnreadCount
{
    RequireString(self.managedObjectContext.zm_isSyncContext, "internalEstimatedUnreadCount should only be set from the sync context");
    
    [self willChangeValueForKey:ZMConversationInternalEstimatedUnreadCountKey];
    [self setPrimitiveValue:@(internalEstimatedUnreadCount) forKey:ZMConversationInternalEstimatedUnreadCountKey];
    [self didChangeValueForKey:ZMConversationInternalEstimatedUnreadCountKey];
}

- (void)setInternalEstimatedUnreadSelfMentionCount:(int64_t)internalEstimatedUnreadSelfMentionCount
{
    RequireString(self.managedObjectContext.zm_isSyncContext, "internalEstimatedUnreadSelfMentionCount should only be set from the sync context");
    
    [self willChangeValueForKey:ZMConversationInternalEstimatedUnreadSelfMentionCountKey];
    [self setPrimitiveValue:@(internalEstimatedUnreadSelfMentionCount) forKey:ZMConversationInternalEstimatedUnreadSelfMentionCountKey];
    [self didChangeValueForKey:ZMConversationInternalEstimatedUnreadSelfMentionCountKey];
}

- (void)setInternalEstimatedUnreadSelfReplyCount:(int64_t)internalEstimatedUnreadSelfReplyCount
{
    RequireString(self.managedObjectContext.zm_isSyncContext, "internalEstimatedUnreadSelfReplyCount should only be set from the sync context");
    
    [self willChangeValueForKey:ZMConversationInternalEstimatedUnreadSelfReplyCountKey];
    [self setPrimitiveValue:@(internalEstimatedUnreadSelfReplyCount) forKey:ZMConversationInternalEstimatedUnreadSelfReplyCountKey];
    [self didChangeValueForKey:ZMConversationInternalEstimatedUnreadSelfReplyCountKey];
}

- (ZMConversationListIndicator)unreadListIndicator;
{
    if (self.hasUnreadUnsentMessage) {
        return ZMConversationListIndicatorExpiredMessage;
    } if (self.estimatedUnreadSelfMentionCount > 0) {
        return ZMConversationListIndicatorUnreadSelfMention;
    } else if (self.estimatedUnreadSelfReplyCount > 0) {
        return ZMConversationListIndicatorUnreadSelfReply;
    } else if (self.hasUnreadMissedCall) {
        return ZMConversationListIndicatorMissedCall;
    } else if (self.hasUnreadKnock) {
        return ZMConversationListIndicatorKnock;
    } else if (self.estimatedUnreadCount != 0) {
        return ZMConversationListIndicatorUnreadMessages;
    }
    return ZMConversationListIndicatorNone;
}

+ (NSSet *)keyPathsForValuesAffectingUnreadListIndicator
{
    return [NSSet setWithObjects:ZMConversationLastUnreadMissedCallDateKey, ZMConversationLastUnreadKnockDateKey, ZMConversationInternalEstimatedUnreadCountKey, ZMConversationLastReadServerTimeStampKey, ZMConversationHasUnreadUnsentMessageKey,  nil];
}

- (BOOL)hasUnreadMessagesInOtherConversations
{
    return [ZMConversation unreadConversationCountExcludingSilencedInContext:self.managedObjectContext excluding:self] > 0;
}

@end

