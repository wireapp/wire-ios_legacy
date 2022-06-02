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


@import WireSystem;

#import "ZMManagedObject.h"
#import "ZMMessage.h"

@class ZMUser;
@class ZMMessage;
@class ZMTextMessage;
@class ZMImageMessage;
@class ZMKnockMessage;
@class ZMConversationList;
@class ZMFileMetadata;
@class ZMLocationData;
@class LinkMetadata;
@class Team;
@class Label;
@class ParticipantRole;
@class Role;

@protocol ZMConversationMessage;

typedef NS_CLOSED_ENUM(int16_t, ZMConversationType) {
    ZMConversationTypeInvalid = 0,

    ZMConversationTypeSelf,
    ZMConversationTypeOneOnOne,
    ZMConversationTypeGroup,
    ZMConversationTypeConnection, // Incoming & outgoing connection request
};

/// The current indicator to be shown for a conversation in the conversation list.
typedef NS_ENUM(int16_t, ZMConversationListIndicator) {
    ZMConversationListIndicatorInvalid = 0,
    ZMConversationListIndicatorNone,
    ZMConversationListIndicatorUnreadSelfMention,
    ZMConversationListIndicatorUnreadSelfReply,
    ZMConversationListIndicatorUnreadMessages,
    ZMConversationListIndicatorKnock,
    ZMConversationListIndicatorMissedCall,
    ZMConversationListIndicatorExpiredMessage,
    ZMConversationListIndicatorActiveCall, ///< Ringing or talking in call.
    ZMConversationListIndicatorInactiveCall, ///< Other people are having a call but you are not in it.
    ZMConversationListIndicatorPending
};


extern NSString * _Null_unspecified const ZMIsDimmedKey; ///< Specifies that a range in an attributed string should be displayed dimmed.

@interface ZMConversation : ZMManagedObject

@property (nonatomic, copy, nullable) NSString *userDefinedName;

@property (readonly, nonatomic) ZMConversationType conversationType;
@property (readonly, nonatomic, nullable) NSDate *lastModifiedDate;
@property (readonly, nonatomic, nonnull) NSSet<ZMMessage *> *allMessages;
@property (readonly, nonatomic, nonnull) NSArray<ZMUser *> *sortedActiveParticipants;
@property (readonly, nonatomic, nonnull) ZMUser *creator;
@property (nonatomic, readonly) BOOL isPendingConnectionConversation;
@property (nonatomic, readonly) NSUInteger estimatedUnreadCount;
@property (nonatomic, readonly) NSUInteger estimatedUnreadSelfMentionCount;
@property (nonatomic, readonly) NSUInteger estimatedUnreadSelfReplyCount;
@property (nonatomic, readonly) ZMConversationListIndicator conversationListIndicator;
@property (nonatomic, readonly) BOOL hasDraftMessage;
@property (nonatomic, nullable) Team *team;
@property (nonatomic, nonnull) NSSet<Label *> *labels;
@property (nonatomic, nonnull) NSSet<ParticipantRole *> *participantRoles;
@property (nonatomic, nonnull) NSSet<Role *> *nonTeamRoles;
@property (nonatomic, nullable) NSString *domain;

/// This will return @c nil if the last added by self user message has not yet been sync'd to this device, or if the conversation has no self editable message.
@property (nonatomic, readonly, nullable) ZMMessage *lastEditableMessage;

@property (nonatomic) BOOL isArchived;

/// returns whether the user is allowed to write to this conversation
@property (nonatomic, readonly) BOOL isReadOnly;

/// For group conversation this will be nil, for one to one or connection conversation this will be the other user
@property (nonatomic, readonly, nullable) ZMUser *connectedUser;

- (BOOL)canMarkAsUnread;
- (void)markAsUnread;

/// If that conversation exists, it is returned, @c nil otherwise.
+ (nullable instancetype)existingOneOnOneConversationWithUser:(nonnull ZMUser *)otherUser inUserSession:(nonnull id<ContextProvider> )session;

@end

@interface ZMConversation (History)

/// This will reset the message history to the last message in the conversation.
- (void)clearMessageHistory;

/// UI should call this method on opening cleared conversation.
- (void)revealClearedConversation;

@end

@interface ZMConversation (Connections)

/// The message that was sent as part of the connection request.
@property (nonatomic, copy, readonly, nonnull) NSString *connectionMessage;

@end


