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
#import "zmessaging+iOS.h"
#import "NetworkConditionHelper.h"
#import "Wire-Swift.h"



@implementation Analytics (CallEvents)

- (void)tagInitiatedCallInConversation:(ZMConversation *)conversation video:(BOOL)video callingProtocol:(enum CallingProtocol)callingProtocol
{
    NSMutableDictionary *attributes = [[NSMutableDictionary alloc] init];
    [attributes addEntriesFromDictionary:[self attributesForConversation:conversation]];
    [attributes addEntriesFromDictionary:[self attributesForCallingProtocol:callingProtocol]];
    
    [self tagEvent:video ? @"calling.initiated_video_call" : @"calling.initiated_call" attributes:attributes];
}

- (void)tagReceivedCallInConversation:(ZMConversation *)conversation video:(BOOL)video callingProtocol:(enum CallingProtocol)callingProtocol
{
    NSMutableDictionary *attributes = [[NSMutableDictionary alloc] init];
    
    [attributes addEntriesFromDictionary:[self attributesForConversation:conversation]];
    [attributes addEntriesFromDictionary:[self attributesForCallingProtocol:callingProtocol]];
    [attributes addEntriesFromDictionary:[self attributesForAppIsActive]];
    
    [self tagEvent:video ? @"calling.received_video_call" : @"calling.received_call" attributes:attributes];
}

- (void)tagJoinedCallInConversation:(ZMConversation *)conversation video:(BOOL)video initiatedCall:(BOOL)initiatedCall callingProtocol:(enum CallingProtocol)callingProtocol
{
    NSMutableDictionary *attributes = [[NSMutableDictionary alloc] init];
    
    [attributes addEntriesFromDictionary:[self attributesForConversation:conversation]];
    [attributes addEntriesFromDictionary:[self attributesForCallingProtocol:callingProtocol]];
    [attributes addEntriesFromDictionary:[self attributesParticipantsInConversation:conversation]];
    [attributes addEntriesFromDictionary:[self attributesForAppIsActive]];
    [attributes addEntriesFromDictionary:[self attributesForInitiatedCall:initiatedCall]];
    
    [self tagEvent:video ? @"calling.joined_video_call" : @"calling.joined_call" attributes:attributes];
}

- (void)tagEstablishedCallInConversation:(ZMConversation *)conversation video:(BOOL)video initiatedCall:(BOOL)initiatedCall setupDuration:(NSTimeInterval)setupDuration callingProtocol:(enum CallingProtocol)callingProtocol
{
    NSMutableDictionary *attributes = [[NSMutableDictionary alloc] init];
    
    [attributes addEntriesFromDictionary:[self attributesForConversation:conversation]];
    [attributes addEntriesFromDictionary:[self attributesForCallingProtocol:callingProtocol]];
    [attributes addEntriesFromDictionary:[self attributesParticipantsInConversation:conversation]];
    [attributes addEntriesFromDictionary:[self attributesForAppIsActive]];
    [attributes addEntriesFromDictionary:[self attributesForInitiatedCall:initiatedCall]];
    [attributes addEntriesFromDictionary:[self attributesForCallSetupDuration:setupDuration]];
    
    [self tagEvent:video ? @"calling.established_successful_video_call" : @"calling.established_successful_call" attributes:attributes];
}

- (void)tagEndedCallInConversation:(ZMConversation *)conversation video:(BOOL)video initiatedCall:(BOOL)initiatedCall duration:(NSTimeInterval)duration reason:(VoiceChannelV2CallEndReason)reason callingProtocol:(enum CallingProtocol)callingProtocol
{
    NSMutableDictionary *attributes = [[NSMutableDictionary alloc] init];
    
    [attributes addEntriesFromDictionary:[self attributesForConversation:conversation]];
    [attributes addEntriesFromDictionary:[self attributesForCallingProtocol:callingProtocol]];
    [attributes addEntriesFromDictionary:[self attributesParticipantsInConversation:conversation]];
    [attributes addEntriesFromDictionary:[self attributesForInitiatedCall:initiatedCall]];
    [attributes addEntriesFromDictionary:[self attributesForCallEndReason:reason]];
    [attributes addEntriesFromDictionary:[self attributesForCallDuration:duration]];
    
    [self tagEvent:video ? @"calling.ended_video_call" : @"calling.ended_call" attributes:attributes];
}

#pragma mark - Attributes

- (NSDictionary *)attributesForCallingProtocol:(enum CallingProtocol)callingProtocol
{
    switch (callingProtocol) {
        case CallingProtocolVersion2:
            return @{ @"version" : @"C2" };
        case CallingProtocolVersion3:
            return @{ @"version" : @"C3" };
    }
}

- (NSDictionary *)attributesParticipantsInConversation:(ZMConversation *)conversation
{
    return @{ @"conversation_participants" : @(conversation.activeParticipants.count) };
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

- (NSDictionary *)attributesForCallEndReason:(VoiceChannelV2CallEndReason)reason
{
    return @{ @"reason" : [self stringForCallEndReason:reason] };
}

- (NSDictionary *)attributesForCallSetupDuration:(NSTimeInterval)duration
{
    TimeIntervalClusterizer *clusterizer = [TimeIntervalClusterizer callSetupDurationClusterizer];
    
    return @{ @"setup_time" : [clusterizer clusterizeTimeInterval:duration],
              @"setup_time_actual" : @(ceil(duration)) };
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

- (NSString *)stringForCallEndReason:(VoiceChannelV2CallEndReason)reason
{
    NSString *result = nil;
    switch (reason) {
        case VoiceChannelV2CallEndReasonRequestedSelf:
            result = @"self";
            break;
            
        case VoiceChannelV2CallEndReasonRequested:
            result = @"other";
            break;
            
        case VoiceChannelV2CallEndReasonInterrupted:
            result = @"gsm_call";
            break;
            
        case VoiceChannelV2CallEndReasonOtherLostMedia:
        case VoiceChannelV2CallEndReasonDisconnected:
        case VoiceChannelV2CallEndReasonRequestedAVS:
            result = [self stringForDroppedCall];
            break;
    }
    
    return result;
}

- (NSString *)stringForDroppedCall
{
    NetworkQualityType networkQuality = [NetworkConditionHelper sharedInstance].qualityType;
    
    NSString *result = nil;
    switch (networkQuality) {
        case NetworkQualityTypeWifi:
            result = @"drop_wifi";
            break;
            
        case NetworkQualityType2G:
            result = @"drop_2G";
            break;
            
        case NetworkQualityType3G:
            result = @"drop_3G";
            break;
            
        case NetworkQualityType4G:
            result = @"drop_4G";
            break;
            
        case NetworkQualityTypeUnkown:
            result = @"drop_unknown";
            break;
    }
    
    return result;
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
