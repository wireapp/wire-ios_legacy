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


@import Foundation;
@import WireSyncEngine;
#import "MockLoader.h"


@interface MockConversation : NSObject<Mockable>    

@property (nonatomic, copy) NSString *displayName;
@property (nonatomic) id<LabelType> folder;
@property (nonatomic) ZMUser *creator;
@property (nonatomic) id<UserType> connectedUser;
@property (nonatomic) ZMConversationType conversationType;
@property (nonatomic) NSArray *sortedActiveParticipants;
@property (nonatomic) ZMConversationSecurityLevel securityLevel;
@property (nonatomic) ZMConnectionStatus relatedConnectionState;
@property (nonatomic) BOOL canStartVideoCall;
@property (nonatomic) BOOL isConversationEligibleForVideoCalls;
@property (nonatomic) NSArray<id<ZMConversationMessage>> *unreadMessages;
@property (nonatomic) BOOL isReadOnly;
@property (nonatomic) BOOL isArchived;
@property (nonatomic) NSUUID *teamRemoteIdentifier;
@property (nonatomic) ZMConversationLegalHoldStatus legalHoldStatus;

- (ZMConversation *)convertToRegularConversation;
- (void)verifyLegalHoldSubjects;
@end
