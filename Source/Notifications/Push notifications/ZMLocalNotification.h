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
// along with this program. If not, see <http://www.gnu.org/licenses/>.


@import UIKit;
#import "ZMUpdateEvent.h"

@class ZMUpdateEvent;
@class ZMConversation;
@class ZMUser;
@class ZMMessage;

extern  NSString * _Null_unspecified const ZMLocalNotificationConversationObjectURLKey;
extern NSString * _Null_unspecified const ZMLocalNotificationUserInfoSenderKey;
extern NSString * _Null_unspecified const ZMLocalNotificationUserInfoNonceKey;

typedef NS_ENUM(int, ZMLocalNotificationType) {
    ZMLocalNotificationTypeInvalid = 0,
    ZMLocalNotificationTypeEvent,
    ZMLocalNotificationTypeExpiredMessage,
};


typedef NS_ENUM(int, ZMLocalNotificationForEventType) {
    ZMLocalNotificationForEventTypeInvalid = 0,
    ZMLocalNotificationForEventTypePostInConversation,
    ZMLocalNotificationForEventTypeKnock,
    ZMLocalNotificationForEventTypeCall,
    ZMLocalNotificationForEventTypeConversationCreate,
    ZMLocalNotificationForEventTypeMemberJoin,
    ZMLocalNotificationForEventTypeMemberLeave,
    ZMLocalNotificationForEventTypeConversationRename,
    ZMLocalNotificationForEventTypeConnectionRequest,
    ZMLocalNotificationForEventTypeConnectionAccepted,
    ZMLocalNotificationForEventTypeNewConnection
};


extern NSString * _Null_unspecified const ZMPushStringMessageAdd;
extern NSString * _Null_unspecified const ZMPushStringImageAdd;
extern NSString * _Null_unspecified const ZMPushStringMessageAddMany;

extern NSString * _Null_unspecified const ZMPushStringMemberJoin;
extern NSString * _Null_unspecified const ZMPushStringMemberLeave;
extern NSString * _Null_unspecified const ZMPushStringMemberLeaveSender;

extern NSString * _Null_unspecified const ZMPushStringMemberJoinMany;
extern NSString * _Null_unspecified const ZMPushStringMemberLeaveMany;

extern NSString * _Null_unspecified const ZMPushStringKnock;

extern NSString * _Null_unspecified const ZMPushStringCallStarts;
extern NSString * _Null_unspecified const ZMPushStringCallMissed;
extern NSString * _Null_unspecified const ZMPushStringVideoCallStarts;

extern NSString * _Null_unspecified const ZMPushStringConversationRename;
extern NSString * _Null_unspecified const ZMPushStringConnectionRequest;
extern NSString * _Null_unspecified const ZMPushStringConnectionAccepted;

extern NSString * _Null_unspecified const ZMPushStringConversationCreate;
extern NSString *_Null_unspecified const ZMPushStringNewConnection;


@interface ZMLocalNotification : NSObject

@property (nonatomic, readonly) ZMLocalNotificationType type;

+ (nullable ZMConversation *)conversationForLocalNotification:(nonnull UILocalNotification *)notification inManagedObjectContext:(nonnull NSManagedObjectContext *)MOC;
+ (nullable ZMMessage *)messageForLocalNotification:(nonnull UILocalNotification *)notification conversation:(nonnull ZMConversation *)conversation inManagedObjectContext:(nonnull NSManagedObjectContext *)MOC;
+ (nullable NSUUID *)senderRemoteIdentifierForLocalNotification:(nonnull UILocalNotification *)notification;

@end




@interface ZMLocalNotificationForExpiredMessage : ZMLocalNotification

@property (nonatomic, readonly, nonnull) ZMMessage *message;
@property (nonatomic, readonly, nonnull) ZMConversation *conversation;

@property (nonatomic, readonly, nonnull) UILocalNotification *uiNotification;

- (nonnull instancetype)initWithExpiredMessage:(nonnull ZMMessage *)message;
- (nonnull instancetype)initWithConversation:(nonnull ZMConversation *)conversation;

@end

