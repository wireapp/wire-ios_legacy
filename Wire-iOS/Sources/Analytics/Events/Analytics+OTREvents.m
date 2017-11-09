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


#import "Analytics+OTREvents.h"

NSString *DeviceVerificationFromTypeToString(DeviceVerificationType type);
NSString *DeviceOwnerFromTypeToString(DeviceOwnerType type);

static NSString *const OTRTrackingPrefix = @"e2ee.";

@implementation Analytics (OTREvents)

- (void)tagOTREvent:(NSString *)event;
{
    [self tagEvent:[OTRTrackingPrefix stringByAppendingString:event]];
}

- (void)tagOTREvent:(NSString *)event attributes:(NSDictionary *)attributes;
{
    [self tagEvent:[OTRTrackingPrefix stringByAppendingString:event] attributes:attributes];
}

- (void)tagDeleteDevice;
{
    [self tagOTREvent:@"removed_own_device"];
}

- (void)tagChangeDeviceVerification:(DeviceVerificationType)verificationType deviceOwner:(DeviceOwnerType)ownerType;
{
    NSString *eventString = [NSString stringWithFormat:@"%@_%@_device", DeviceVerificationFromTypeToString(verificationType), DeviceOwnerFromTypeToString(ownerType)];
    [self tagOTREvent:eventString];
}

- (void)tagConversationIsVerified;
{
    [self tagOTREvent:@"verified_conversation"];
}

- (void)tagSelfDeviceList;
{
    [self tagOTREvent:@"viewed_own_devices"];
}

- (void)tagOtherDeviceList;
{
    [self tagOTREvent:@"viewed_foreign_devices"];
}

- (void)tagCannotDecryptMessageWithAttributes:(NSDictionary *)userInfo;
{
    [self tagOTREvent:@"e2ee.failed_message_decyption" attributes:userInfo];
}

@end

NSString *DeviceVerificationFromTypeToString(DeviceVerificationType type)
{
    switch (type) {
        case DeviceVerificationTypeVerified:
            return @"verified";
            break;
        case DeviceVerificationTypeUnverified:
            return @"unverified";
            break;
    }
}

NSString *DeviceOwnerFromTypeToString(DeviceOwnerType type)
{
    switch (type) {
        case DeviceOwnerTypeSelf:
            return @"own";
            break;
        case DeviceOwnerTypeOther:
            return @"foreign";
            break;
    }
}
