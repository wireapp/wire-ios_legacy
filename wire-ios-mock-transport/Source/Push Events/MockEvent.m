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


@import WireTransport;
@import WireUtilities;
@import WireSystem;

#import "MockEvent.h"
#import "MockConversation.h"
#import <WireMockTransport/WireMockTransport-Swift.h>

static ZMLogLevel_t const ZMLogLevel ZM_UNUSED = ZMLogLevelWarn;

@implementation MockEvent

@dynamic from;
@dynamic identifier;
@dynamic time;
@dynamic type;
@dynamic data;
@dynamic conversation;
@dynamic decryptedOTRData;


+ (NSString *)stringFromType:(ZMUpdateEventType)type
{
    return [ZMUpdateEvent eventTypeStringForUpdateEventType:type];
}

+ (ZMUpdateEventType)typeFromString:(NSString *)string
{
    return [ZMUpdateEvent updateEventTypeForEventTypeString:string];
}

+ (NSArray *)persistentEvents;
{
    return @[@(ZMUpdateEventTypeConversationRename),
             @(ZMUpdateEventTypeConversationMemberJoin),
             @(ZMUpdateEventTypeConversationMemberLeave),
             @(ZMUpdateEventTypeConversationConnectRequest),
             @(ZMUpdateEventTypeConversationMessageAdd),
             @(ZMUpdateEventTypeConversationClientMessageAdd),
             @(ZMUpdateEventTypeConversationAssetAdd),
             @(ZMUpdateEventTypeConversationKnock),
             @(ZMUpdateEventTypeConversationOtrMessageAdd),
             @(ZMUpdateEventTypeConversationOtrAssetAdd),
             @(ZMUpdateEventTypeConversationReceiptModeUpdate)
            ];
}


- (id<ZMTransportData>)transportData;
{
    return @{@"conversation": self.conversation.identifier ?: [NSNull null],
             @"data": self.data ?: [NSNull null],
             @"from": self.from ? self.from.identifier : [NSNull null],
             @"id": self.identifier ?: [NSNull null],
             @"time": self.time.transportString ?: [NSNull null],
             @"type": self.type ?: [NSNull null],
            };
}

- (ZMUpdateEventType)eventType
{
    return (ZMUpdateEventType)[[self class] typeFromString:self.type];
}

@end
