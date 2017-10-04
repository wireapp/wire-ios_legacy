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


#import "VoiceChannelV2+Additions.h"



NSString *StringFromVoiceChannelV2State(VoiceChannelV2State state)
{
    switch (state) {
        case VoiceChannelV2StateInvalid:
            return @"Invalid";
        case VoiceChannelV2StateNoActiveUsers:
            return @"NoActiveUsers";
        case VoiceChannelV2StateOutgoingCall:
            return @"OutgoingCall";
        case VoiceChannelV2StateOutgoingCallDegraded:
            return @"OutgoingCallDegraded";
        case VoiceChannelV2StateOutgoingCallInactive:
            return @"OutgoingCallInactive:";
        case VoiceChannelV2StateIncomingCall:
            return @"IncomingCall:";
        case VoiceChannelV2StateIncomingCallDegraded:
            return @"IncomingCallDegraded";
        case VoiceChannelV2StateIncomingCallInactive:
            return @"IncomingCallInactive:";
        case VoiceChannelV2StateSelfIsJoiningActiveChannel:
            return @"JoiningActiveChannel";
        case VoiceChannelV2StateSelfIsJoiningActiveChannelDegraded:
            return @"JoiningActiveChannelDegraded";
        case VoiceChannelV2StateEstablishedDataChannel:
            return @"EstablishedDataChannel";
        case VoiceChannelV2StateSelfConnectedToActiveChannel:
            return @"ConnectedToActiveChannel";
        case VoiceChannelV2StateDeviceTransferReady:
            return @"TransferReady";
    }
}

FOUNDATION_EXPORT NSString *StringFromVoiceChannelV2ConnectionState(VoiceChannelV2ConnectionState state)
{
    switch (state) {
        case VoiceChannelV2ConnectionStateInvalid:
            return @"Invalid";
        case VoiceChannelV2ConnectionStateNotConnected:
            return @"NotConnected";
        case VoiceChannelV2ConnectionStateConnecting:
            return @"Connecting";
        case VoiceChannelV2ConnectionStateConnected:
            return @"Connected";
    }
}
