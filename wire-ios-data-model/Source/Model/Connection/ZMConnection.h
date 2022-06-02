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


#import "ZMManagedObject.h"

@class ZMUser;
@class ZMConversation;

typedef NS_ENUM(int16_t, ZMConnectionStatus) {
    ZMConnectionStatusInvalid = 0,
    ZMConnectionStatusAccepted, ///< Both users have accepted
    ZMConnectionStatusPending, ///< The other user has sent us a request
    ZMConnectionStatusIgnored, ///< We have ignored this user
    ZMConnectionStatusBlocked, ///< We have blocked this user
    ZMConnectionStatusSent, ///< We have sent a request to connect
    ZMConnectionStatusCancelled, ///< We cancel sent reqeust to connect
    ZMConnectionStatusBlockedMissingLegalholdConsent, ///< The user is blocked due to legal hold missing consent
};

@interface ZMConnection : ZMManagedObject

@property (nonatomic) NSDate *lastUpdateDate;
@property (nonatomic, copy) NSString *message;
@property (nonatomic) ZMConnectionStatus status;
@property (readonly, nonatomic) ZMUser *to;
@property (nonatomic,readonly) BOOL hasValidConversation;

@end
