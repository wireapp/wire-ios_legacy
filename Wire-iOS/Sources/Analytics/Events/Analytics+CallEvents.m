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


#import "Analytics+CallEvents.h"
#import "WireSyncEngine+iOS.h"
#import "Wire-Swift.h"



@implementation Analytics (CallEvents)

- (void)tagInitiatedCallInConversation:(ZMConversation *)conversation video:(BOOL)video
{
    NSMutableDictionary *attributes = [[NSMutableDictionary alloc] init];
    [attributes addEntriesFromDictionary:[self attributesForConversation:conversation]];
    [attributes addEntriesFromDictionary:[self attributesForCallingProtocol]];
    
    [self tagEvent:video ? @"calling.initiated_video_call" : @"calling.initiated_call" attributes:attributes];
}

- (void)tagReceivedCallInConversation:(ZMConversation *)conversation video:(BOOL)video
{
    NSMutableDictionary *attributes = [[NSMutableDictionary alloc] init];
    
    [attributes addEntriesFromDictionary:[self attributesForConversation:conversation]];
    [attributes addEntriesFromDictionary:[self attributesForCallingProtocol]];
    [attributes addEntriesFromDictionary:[self attributesForAppIsActive]];
    
    [self tagEvent:video ? @"calling.received_video_call" : @"calling.received_call" attributes:attributes];
}

- (void)tagJoinedCallInConversation:(ZMConversation *)conversation video:(BOOL)video initiatedCall:(BOOL)initiatedCall
{
    NSMutableDictionary *attributes = [[NSMutableDictionary alloc] init];
    
    [attributes addEntriesFromDictionary:[self attributesForConversation:conversation]];
    [attributes addEntriesFromDictionary:[self attributesForCallingProtocol]];
    [attributes addEntriesFromDictionary:[self attributesParticipantsInConversation:conversation]];
    [attributes addEntriesFromDictionary:[self attributesForAppIsActive]];
    [attributes addEntriesFromDictionary:[self attributesForInitiatedCall:initiatedCall]];
    
    [self tagEvent:video ? @"calling.joined_video_call" : @"calling.joined_call" attributes:attributes];
}

- (void)tagEstablishedCallInConversation:(ZMConversation *)conversation video:(BOOL)video initiatedCall:(BOOL)initiatedCall setupDuration:(NSTimeInterval)setupDuration
{
    NSMutableDictionary *attributes = [[NSMutableDictionary alloc] init];
    
    [attributes addEntriesFromDictionary:[self attributesForConversation:conversation]];
    [attributes addEntriesFromDictionary:[self attributesForCallingProtocol]];
    [attributes addEntriesFromDictionary:[self attributesParticipantsInConversation:conversation]];
    [attributes addEntriesFromDictionary:[self attributesForAppIsActive]];
    [attributes addEntriesFromDictionary:[self attributesForInitiatedCall:initiatedCall]];
    [attributes addEntriesFromDictionary:[self attributesForCallSetupDuration:setupDuration]];
    
    [self tagEvent:video ? @"calling.established_video_call" : @"calling.established_call" attributes:attributes];
}

- (void)tagEndedCallInConversation:(ZMConversation *)conversation video:(BOOL)video initiatedCall:(BOOL)initiatedCall duration:(NSTimeInterval)duration callEndReason:(NSString *)callEndReason
{
    NSMutableDictionary *attributes = [[NSMutableDictionary alloc] init];
    
    [attributes addEntriesFromDictionary:[self attributesForConversation:conversation]];
    [attributes addEntriesFromDictionary:[self attributesForCallingProtocol]];
    [attributes addEntriesFromDictionary:[self attributesParticipantsInConversation:conversation]];
    [attributes addEntriesFromDictionary:[self attributesForInitiatedCall:initiatedCall]];
    [attributes addEntriesFromDictionary:[self attributesForCallEndReason:callEndReason]];
    [attributes addEntriesFromDictionary:[self attributesForCallDuration:duration]];
    
    [self tagEvent:video ? @"calling.ended_video_call" : @"calling.ended_call" attributes:attributes];
}

#pragma mark - Attributes

- (NSDictionary *)attributesForCallingProtocol
{
    return @{ @"version" : @"C3" };
}

- (NSDictionary *)attributesParticipantsInConversation:(ZMConversation *)conversation
{
    return @{ @"conversation_participants" : [NSString stringWithFormat:@"%lu", (unsigned long)conversation.activeParticipants.count] };
}

- (NSDictionary *)attributesForConversation:(ZMConversation *)conversation
{
    return @{ @"conversation_type" : [self stringForConversationType:conversation.conversationType],
              @"with_bot"          : conversation.isBotConversation ? @"true" : @"false" };
}

- (NSDictionary *)attributesForInitiatedCall:(BOOL)initiatedCall
{
    return @{ @"direction" : initiatedCall ? @"outgoing" : @"incoming" };
}

- (NSDictionary *)attributesForAppIsActive
{
    return @{ @"app_is_active" : [[UIApplication sharedApplication] applicationState] == UIApplicationStateActive ? @"true" : @"false" };
}

- (NSDictionary *)attributesForCallEndReason:(NSString *)callEndReason
{
    return @{ @"reason" : callEndReason };
}

- (NSDictionary *)attributesForCallSetupDuration:(NSTimeInterval)duration
{
    TimeIntervalClusterizer *clusterizer = [TimeIntervalClusterizer callSetupDurationClusterizer];
    
    return @{ @"setup_time" : [clusterizer clusterizeTimeInterval:duration],
              @"setup_time_actual" : [NSString stringWithFormat:@"%.02f", duration]};
}

- (NSDictionary *)attributesForCallDuration:(NSTimeInterval)duration
{
    NSString *durationSlot;
    
    if (duration <= 15) {
        durationSlot = @"[0s-15s]";
    }
    else if (duration <= 30) {
        durationSlot = @"[15s-30s]";
    }
    else if (duration <= 60) {
        durationSlot = @"[30s-60s]";
    }
    else if (duration <= 60 * 3) {
        durationSlot = @"[61s-3min]";
    }
    else if (duration <= 60 * 10) {
        durationSlot = @"[3min-10min]";
    }
    else if (duration <= 60 * 60) {
        durationSlot = @"[10min-1h]";
    } else {
        durationSlot = @"[1h-infinite]";
    }
    
    return @{ @"duration" : durationSlot,
              @"durationActual" : @(ceil(duration))};
}

- (NSString *)stringForConversationType:(ZMConversationType)conversationType
{
    NSString *result = nil;
    switch (conversationType) {
        case ZMConversationTypeOneOnOne:
            result = @"one_to_one";
            break;
        case ZMConversationTypeGroup:
            result = @"group";
            break;
        case ZMConversationTypeSelf:
            result = @"self";
            break;
        case ZMConversationTypeConnection:
            result = @"connection";
            break;
        case ZMConversationTypeInvalid:
        default:
            result = @"invalid";
            break;
    }
    return result;
}

@end
