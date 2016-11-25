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


#import "ZMVoiceChannel+Additions.h"



NSString *StringFromZMVoiceChannelState(ZMVoiceChannelState state)
{
    switch (state) {
        case ZMVoiceChannelStateInvalid:
            return @"Invalid";
        case ZMVoiceChannelStateNoActiveUsers:
            return @"NoActiveUsers";
        case ZMVoiceChannelStateOutgoingCall:
            return @"OutgoingCall";
        case ZMVoiceChannelStateOutgoingCallInactive:
            return @"OutgoingCallInactive:";
        case ZMVoiceChannelStateIncomingCall:
            return @"IncomingCall:";
        case ZMVoiceChannelStateIncomingCallInactive:
            return @"IncomingCallInactive:";
        case ZMVoiceChannelStateSelfIsJoiningActiveChannel:
            return @"JoiningActiveChannel";
        case ZMVoiceChannelStateSelfConnectedToActiveChannel:
            return @"ConnectedToActiveChannel";
        case ZMVoiceChannelStateDeviceTransferReady:
            return @"TransferReady";
    }
}

FOUNDATION_EXPORT NSString *StringFromZMVoiceChannelConnectionState(ZMVoiceChannelConnectionState state)
{
    switch (state) {
        case ZMVoiceChannelConnectionStateInvalid:
            return @"Invalid";
        case ZMVoiceChannelConnectionStateNotConnected:
            return @"NotConnected";
        case ZMVoiceChannelConnectionStateConnecting:
            return @"Connecting";
        case ZMVoiceChannelConnectionStateConnected:
            return @"Connected";
    }
}



@implementation ZMVoiceChannel (Additions)

+ (id<VoiceChannel>)firstActiveVoiceChannelInConversationList:(NSArray *)conversations
{
    id<VoiceChannel> activeVoiceChannel = nil;
    for (ZMConversation *conversation in conversations) {
        if (conversation.voiceChannel != nil && conversation.voiceChannel.state > ZMVoiceChannelStateNoActiveUsers) {
            activeVoiceChannel = conversation.voiceChannel;
            break;
        }
    }
    
    return activeVoiceChannel;
}

@end
