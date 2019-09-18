//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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

#import "AggregateArray.h"

@interface ConversationListViewModel ()
@property (nonatomic) id<NSObject> selfUserObserver;
- (NSArray *)newConversationList;
@end

@interface ConversationListViewModel () <ZMConversationListReloadObserver>

@property (nonatomic, strong) ConversationListConnectRequestsItem *contactRequestsItem;
@property (nonatomic, strong) AggregateArray *aggregatedItems;
@property (nonatomic, readwrite) id selectedItem;

// Local copies of the lists.

///TODO: [[Any]]
@property (nonatomic, copy) NSArray *inbox;
@property (nonatomic, copy) NSArray *conversations;
@property (nonatomic, copy) NSArray *oneOnOneConversations;

@property (nonatomic) id pendingConversationListObserverToken;
@property (nonatomic) id conversationListObserverToken;
@property (nonatomic) id clearedConversationListObserverToken;
@property (nonatomic) id conversationListsReloadObserverToken;

@end
