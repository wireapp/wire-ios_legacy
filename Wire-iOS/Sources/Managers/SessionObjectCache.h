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


#import <Foundation/Foundation.h>

@class ZMUserSession;
@class ZMConversationList;



@interface SessionObjectCache : NSObject

@property (nonatomic, strong, readonly) ZMUserSession *userSession;

/// Cached, auto-updating model objects
@property (nonatomic, readonly) ZMConversationList *conversationList;
@property (nonatomic, readonly) ZMConversationList *archivedConversations;
@property (nonatomic, readonly) ZMConversationList *allConversations;
@property (nonatomic, readonly) ZMConversationList *clearedConversations;
@property (nonatomic, readonly) ZMConversationList *pendingConnectionRequests;

/// count of list + archived
@property (nonatomic, readonly) NSUInteger totalConversationsCount;

+ (instancetype)sharedCache;

- (instancetype)initWithUserSession:(ZMUserSession *)session;
- (void)refetchConversationLists;

@end
